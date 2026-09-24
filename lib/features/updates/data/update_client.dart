import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../domain/update_manifest.dart';

enum UpdateFailure {
  /// No usable internet connection.
  offline,

  /// The server could not be reached, answered with an error or the
  /// connection broke off.
  server,

  /// The manifest is malformed or describes a different app.
  invalidManifest,

  /// The downloaded file does not match the published SHA-256 or size.
  checksum,

  /// The APK is not a newer DAWASA build signed by the same developer.
  packageMismatch,

  /// The file could not be written (for example, the phone is full).
  storage,

  /// Android's installer reported an error.
  install,
}

class UpdateException implements Exception {
  const UpdateException(this.failure, [this.detail]);

  final UpdateFailure failure;
  final String? detail;

  @override
  String toString() =>
      'UpdateException(${failure.name}${detail == null ? '' : ': $detail'})';
}

class DownloadCancelled implements Exception {
  const DownloadCancelled();
}

/// Cancels an ongoing download.
class CancelToken {
  final Completer<void> _completer = Completer<void>();

  bool get isCancelled => _completer.isCompleted;
  Future<void> get whenCancelled => _completer.future;

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }
}

typedef DownloadProgress = void Function(int received, int total);

/// Talks to the update server: fetches the manifest and downloads APKs.
///
/// Requests are plain GETs that carry no personal or financial data, no
/// identifiers and no cookies. Only HTTPS is used; redirects are followed
/// only to HTTPS addresses on the same host.
class UpdateClient {
  UpdateClient({
    required this._clientFactory,
    required this.userAgent,
    this.manifestTimeout = const Duration(seconds: 20),
    this.connectTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(seconds: 60),
  });

  final http.Client Function() _clientFactory;
  final String userAgent;
  final Duration manifestTimeout;
  final Duration connectTimeout;
  final Duration idleTimeout;

  static const int _maxRedirects = 3;

  Future<http.StreamedResponse> _send(
    http.Client client,
    Uri uri, {
    Map<String, String> headers = const {},
    Future<void>? abortTrigger,
  }) async {
    var current = uri;
    for (var i = 0; i <= _maxRedirects; i++) {
      final request =
          http.AbortableRequest('GET', current, abortTrigger: abortTrigger)
            ..followRedirects = false
            ..headers.addAll({'User-Agent': userAgent, ...headers});
      final response = await client.send(request).timeout(connectTimeout);
      if (!response.isRedirect &&
          !const {301, 302, 303, 307, 308}.contains(response.statusCode)) {
        return response;
      }
      final location = response.headers['location'];
      await response.stream.drain<void>();
      if (location == null) break;
      final next = current.resolve(location);
      if (next.scheme != 'https' ||
          next.host.toLowerCase() != uri.host.toLowerCase()) {
        throw const UpdateException(
          UpdateFailure.server,
          'redirect to another host refused',
        );
      }
      current = next;
    }
    throw const UpdateException(UpdateFailure.server, 'too many redirects');
  }

  Never _networkError(Object e) {
    if (e is UpdateException) throw e;
    if (e is SocketException) {
      throw UpdateException(UpdateFailure.offline, e.message);
    }
    if (e is TimeoutException) {
      throw const UpdateException(UpdateFailure.server, 'timeout');
    }
    throw UpdateException(UpdateFailure.server, '$e');
  }

  Future<UpdateManifest> fetchManifest(Uri uri) async {
    if (uri.scheme != 'https') {
      throw const UpdateException(UpdateFailure.invalidManifest, 'not https');
    }
    final client = _clientFactory();
    try {
      final List<int> body;
      try {
        final response = await _send(
          client,
          uri,
          headers: const {
            'Accept': 'application/json',
            'Cache-Control': 'no-cache',
          },
        );
        if (response.statusCode != 200) {
          await response.stream.drain<void>();
          throw UpdateException(
            UpdateFailure.server,
            'HTTP ${response.statusCode}',
          );
        }
        body = await _readLimited(
          response.stream,
          UpdateManifest.maxBytes,
        ).timeout(manifestTimeout);
      } on Object catch (e) {
        _networkError(e);
      }
      final Object? json;
      try {
        json = jsonDecode(utf8.decode(body));
      } on FormatException {
        throw const UpdateException(UpdateFailure.invalidManifest, 'not JSON');
      }
      try {
        return UpdateManifest.parse(json, uri);
      } on ManifestException catch (e) {
        throw UpdateException(UpdateFailure.invalidManifest, e.message);
      }
    } finally {
      client.close();
    }
  }

  static Future<List<int>> _readLimited(Stream<List<int>> stream, int max) {
    final completer = Completer<List<int>>();
    final bytes = BytesBuilder(copy: false);
    late StreamSubscription<List<int>> sub;
    sub = stream.listen(
      (chunk) {
        bytes.add(chunk);
        if (bytes.length > max) {
          sub.cancel();
          completer.completeError(
            const UpdateException(
              UpdateFailure.invalidManifest,
              'manifest too large',
            ),
          );
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(bytes.takeBytes());
      },
      cancelOnError: true,
    );
    return completer.future;
  }

  static File partialFile(Directory dir, UpdateRelease r) =>
      File(p.join(dir.path, '${r.sha256}.apk.part'));

  static File completeFile(Directory dir, UpdateRelease r) => File(
    p.join(
      dir.path,
      'dawasa-${r.versionCode}-${r.sha256.substring(0, 12)}.apk',
    ),
  );

  static Future<String> sha256OfFile(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();

  /// Downloads [release] into [dir], resuming an earlier partial download
  /// when possible, and verifies its size and SHA-256. Returns the verified
  /// APK. A partial file is kept after cancellation or a network error so
  /// that "retry" continues where it stopped; a file that fails
  /// verification is deleted.
  Future<File> download(
    UpdateRelease release,
    Directory dir, {
    required DownloadProgress onProgress,
    void Function()? onVerifying,
    CancelToken? cancel,
  }) async {
    final done = completeFile(dir, release);
    if (done.existsSync() &&
        done.lengthSync() == release.sizeBytes &&
        await sha256OfFile(done) == release.sha256) {
      return done;
    }
    final part = partialFile(dir, release);
    try {
      await _fetchInto(part, release, onProgress, cancel, retryFromStart: true);
    } on FileSystemException catch (e) {
      throw UpdateException(UpdateFailure.storage, e.message);
    }
    onVerifying?.call();
    final length = part.lengthSync();
    if (length != release.sizeBytes ||
        await sha256OfFile(part) != release.sha256) {
      await part.delete();
      throw UpdateException(
        UpdateFailure.checksum,
        'size $length, expected ${release.sizeBytes}',
      );
    }
    if (done.existsSync()) await done.delete();
    return part.rename(done.path);
  }

  Future<void> _fetchInto(
    File part,
    UpdateRelease release,
    DownloadProgress onProgress,
    CancelToken? cancel, {
    required bool retryFromStart,
  }) async {
    final total = release.sizeBytes;
    var offset = part.existsSync() ? part.lengthSync() : 0;
    if (offset > total) {
      await part.delete();
      offset = 0;
    }
    if (offset == total) return;
    if (cancel?.isCancelled ?? false) throw const DownloadCancelled();

    final client = _clientFactory();
    IOSink? sink;
    try {
      final http.StreamedResponse response;
      try {
        response = await _send(
          client,
          release.apkUri,
          headers: {
            if (offset > 0) 'Range': 'bytes=$offset-',
            'Accept-Encoding': 'identity',
          },
          abortTrigger: cancel?.whenCancelled,
        );
      } on http.RequestAbortedException {
        throw const DownloadCancelled();
      } on Object catch (e) {
        _networkError(e);
      }

      var append = false;
      if (response.statusCode == 206 && offset > 0) {
        final range = response.headers['content-range'] ?? '';
        append = range.startsWith('bytes $offset-');
      }
      if (response.statusCode == 416 && retryFromStart) {
        await response.stream.drain<void>();
        if (part.existsSync()) await part.delete();
        return await _fetchInto(
          part,
          release,
          onProgress,
          cancel,
          retryFromStart: false,
        );
      }
      if (response.statusCode != 200 && !append) {
        await response.stream.drain<void>();
        if (response.statusCode == 206) {
          // Unexpected range; start again from the beginning.
          if (part.existsSync()) await part.delete();
          if (retryFromStart) {
            return await _fetchInto(
              part,
              release,
              onProgress,
              cancel,
              retryFromStart: false,
            );
          }
        }
        throw UpdateException(
          UpdateFailure.server,
          'HTTP ${response.statusCode}',
        );
      }
      if (!append) offset = 0;

      sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
      var received = offset;
      var lastReport = DateTime.fromMillisecondsSinceEpoch(0);
      onProgress(received, total);
      try {
        await for (final chunk in response.stream.timeout(idleTimeout)) {
          if (cancel?.isCancelled ?? false) throw const DownloadCancelled();
          received += chunk.length;
          if (received > total) {
            throw const UpdateException(
              UpdateFailure.checksum,
              'larger than published size',
            );
          }
          sink.add(chunk);
          final now = DateTime.now();
          if (now.difference(lastReport).inMilliseconds >= 150 ||
              received == total) {
            lastReport = now;
            onProgress(received, total);
          }
        }
      } on http.RequestAbortedException {
        throw const DownloadCancelled();
      } on UpdateException {
        await sink.close();
        sink = null;
        if (part.existsSync()) await part.delete();
        rethrow;
      } on FileSystemException {
        rethrow;
      } on Object catch (e) {
        if (cancel?.isCancelled ?? false) throw const DownloadCancelled();
        _networkError(e);
      }
      if (cancel?.isCancelled ?? false) throw const DownloadCancelled();
      if (received != total) {
        throw const UpdateException(
          UpdateFailure.server,
          'connection closed early',
        );
      }
    } finally {
      await sink?.flush();
      await sink?.close();
      client.close();
    }
  }
}
