import 'dart:convert';
import 'dart:io' show ZLibCodec;
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// DAWASA encrypted backup container (".dawasa").
///
/// ```
/// "DAWASABK"            8 bytes magic
/// format version        uint16 (big endian)
/// header length         uint32 (big endian)
/// header                UTF-8 JSON (not secret, but authenticated)
/// ciphertext            AES-256-GCM of zlib(archive)
/// tag                   16 bytes GCM authentication tag
/// ```
///
/// The key is derived from the user's password with Argon2id using a random
/// salt; nothing secret is stored in the app or the file. Everything before
/// the ciphertext is passed to AES-GCM as associated data, so any change to
/// the header, the ciphertext or the tag is detected.
abstract final class BackupFormat {
  static const List<int> magic = [
    0x44,
    0x41,
    0x57,
    0x41,
    0x53,
    0x41,
    0x42,
    0x4B,
  ];
  static const int formatVersion = 1;
  static const String fileExtension = 'dawasa';
  static const String mimeType = 'application/octet-stream';

  /// Default Argon2id cost (OWASP recommends at least 19 MiB / 2 passes).
  static const int argonMemoryKiB = 32768;
  static const int argonIterations = 3;
  static const int argonParallelism = 1;

  /// Upper bounds accepted when reading, so a crafted file cannot make the
  /// app allocate unbounded memory.
  static const int maxArgonMemoryKiB = 262144;
  static const int maxArgonIterations = 10;
  static const int maxHeaderLength = 64 * 1024;
  static const int minPasswordLength = 8;
}

enum BackupErrorKind {
  notABackup,
  unsupportedFormat,
  wrongPasswordOrCorrupted,
  corruptedPayload,
  newerSchema,
  missingDatabase,
}

class BackupException implements Exception {
  const BackupException(this.kind, [this.detail]);

  final BackupErrorKind kind;
  final String? detail;

  @override
  String toString() =>
      'BackupException($kind${detail == null ? '' : ': $detail'})';
}

/// Plain-text metadata stored in the header.
class BackupHeader {
  const BackupHeader({
    required this.appVersion,
    required this.appVersionCode,
    required this.schemaVersion,
    required this.createdAt,
    required this.salt,
    required this.nonce,
    this.memoryKiB = BackupFormat.argonMemoryKiB,
    this.iterations = BackupFormat.argonIterations,
    this.parallelism = BackupFormat.argonParallelism,
  });

  final String appVersion;
  final int appVersionCode;
  final int schemaVersion;
  final DateTime createdAt;
  final List<int> salt;
  final List<int> nonce;
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  Map<String, Object?> toJson() => {
    'app': 'dawasa',
    'appVersion': appVersion,
    'appVersionCode': appVersionCode,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'kdf': {
      'name': 'argon2id',
      'memoryKiB': memoryKiB,
      'iterations': iterations,
      'parallelism': parallelism,
      'salt': base64Encode(salt),
    },
    'cipher': {'name': 'aes-256-gcm', 'nonce': base64Encode(nonce)},
    'compression': 'zlib',
  };

  static BackupHeader fromJson(Map<String, Object?> json) {
    try {
      if (json['app'] != 'dawasa') {
        throw const BackupException(BackupErrorKind.notABackup);
      }
      final kdf = json['kdf']! as Map<String, Object?>;
      final cipher = json['cipher']! as Map<String, Object?>;
      if (kdf['name'] != 'argon2id' || cipher['name'] != 'aes-256-gcm') {
        throw const BackupException(BackupErrorKind.unsupportedFormat);
      }
      final memory = kdf['memoryKiB']! as int;
      final iterations = kdf['iterations']! as int;
      final parallelism = kdf['parallelism']! as int;
      if (memory < 8 ||
          memory > BackupFormat.maxArgonMemoryKiB ||
          iterations < 1 ||
          iterations > BackupFormat.maxArgonIterations ||
          parallelism < 1 ||
          parallelism > 8) {
        throw const BackupException(BackupErrorKind.unsupportedFormat);
      }
      final salt = base64Decode(kdf['salt']! as String);
      final nonce = base64Decode(cipher['nonce']! as String);
      if (salt.length < 16 || nonce.length != 12) {
        throw const BackupException(BackupErrorKind.unsupportedFormat);
      }
      return BackupHeader(
        appVersion: json['appVersion']! as String,
        appVersionCode: json['appVersionCode']! as int,
        schemaVersion: json['schemaVersion']! as int,
        createdAt: DateTime.parse(json['createdAt']! as String),
        salt: salt,
        nonce: nonce,
        memoryKiB: memory,
        iterations: iterations,
        parallelism: parallelism,
      );
    } on BackupException {
      rethrow;
    } on Object catch (e) {
      throw BackupException(BackupErrorKind.notABackup, '$e');
    }
  }
}

/// A named file inside the backup archive.
class BackupEntry {
  const BackupEntry(this.name, this.data);

  final String name;
  final Uint8List data;
}

/// Minimal length-prefixed archive: "DWPL", uint32 count, then for each
/// entry uint16 name length, UTF-8 name, uint64 data length, data.
abstract final class BackupArchive {
  static const _magic = [0x44, 0x57, 0x50, 0x4C];

  static Uint8List pack(List<BackupEntry> entries) {
    final builder = BytesBuilder(copy: false)
      ..add(_magic)
      ..add(_u32(entries.length));
    for (final e in entries) {
      final name = utf8.encode(e.name);
      builder
        ..add(_u16(name.length))
        ..add(name)
        ..add(_u64(e.data.length))
        ..add(e.data);
    }
    return builder.takeBytes();
  }

  static List<BackupEntry> unpack(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);
    var offset = 0;
    void need(int n) {
      if (offset + n > bytes.length) {
        throw const BackupException(BackupErrorKind.corruptedPayload);
      }
    }

    need(8);
    for (var i = 0; i < 4; i++) {
      if (bytes[i] != _magic[i]) {
        throw const BackupException(BackupErrorKind.corruptedPayload);
      }
    }
    offset = 4;
    final count = data.getUint32(offset);
    offset += 4;
    if (count > 100000) {
      throw const BackupException(BackupErrorKind.corruptedPayload);
    }
    final entries = <BackupEntry>[];
    for (var i = 0; i < count; i++) {
      need(2);
      final nameLength = data.getUint16(offset);
      offset += 2;
      need(nameLength);
      final name = utf8.decode(bytes.sublist(offset, offset + nameLength));
      offset += nameLength;
      need(8);
      final length = data.getUint64(offset);
      offset += 8;
      need(length);
      entries.add(
        BackupEntry(
          name,
          Uint8List.sublistView(bytes, offset, offset + length),
        ),
      );
      offset += length;
    }
    return entries;
  }

  static Uint8List _u16(int v) =>
      (ByteData(2)..setUint16(0, v)).buffer.asUint8List();
  static Uint8List _u32(int v) =>
      (ByteData(4)..setUint32(0, v)).buffer.asUint8List();
  static Uint8List _u64(int v) =>
      (ByteData(8)..setUint64(0, v)).buffer.asUint8List();
}

/// Result of reading a container without decrypting it.
class ParsedBackup {
  const ParsedBackup(this.header, this.aad, this.cipherText, this.tag);

  final BackupHeader header;
  final Uint8List aad;
  final Uint8List cipherText;
  final Uint8List tag;
}

abstract final class BackupCrypto {
  static List<int> randomBytes(int length) {
    final r = Random.secure();
    return List<int>.generate(length, (_) => r.nextInt(256));
  }

  static Future<SecretKey> deriveKey(String password, BackupHeader h) {
    final kdf = Argon2id(
      parallelism: h.parallelism,
      memory: h.memoryKiB,
      iterations: h.iterations,
      hashLength: 32,
    );
    return kdf.deriveKeyFromPassword(password: password, nonce: h.salt);
  }

  /// Encrypts [entries] into a complete backup file.
  static Future<Uint8List> seal({
    required List<BackupEntry> entries,
    required String password,
    required String appVersion,
    required int appVersionCode,
    required int schemaVersion,
    DateTime? createdAt,
    int memoryKiB = BackupFormat.argonMemoryKiB,
    int iterations = BackupFormat.argonIterations,
  }) async {
    final header = BackupHeader(
      appVersion: appVersion,
      appVersionCode: appVersionCode,
      schemaVersion: schemaVersion,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      salt: randomBytes(16),
      nonce: randomBytes(12),
      memoryKiB: memoryKiB,
      iterations: iterations,
    );
    final headerBytes = utf8.encode(jsonEncode(header.toJson()));
    final prefix = BytesBuilder(copy: false)
      ..add(BackupFormat.magic)
      ..add(
        (ByteData(
          2,
        )..setUint16(0, BackupFormat.formatVersion)).buffer.asUint8List(),
      )
      ..add(
        (ByteData(4)..setUint32(0, headerBytes.length)).buffer.asUint8List(),
      )
      ..add(headerBytes);
    final aad = prefix.takeBytes();
    final compressed = ZLibCodec(level: 6).encode(BackupArchive.pack(entries));
    final key = await deriveKey(password, header);
    final box = await AesGcm.with256bits().encrypt(
      compressed,
      secretKey: key,
      nonce: header.nonce,
      aad: aad,
    );
    return (BytesBuilder(copy: false)
          ..add(aad)
          ..add(box.cipherText)
          ..add(box.mac.bytes))
        .takeBytes();
  }

  /// Parses the container structure (no password needed).
  static ParsedBackup parse(Uint8List file) {
    if (file.length < 8 + 2 + 4 + 16) {
      throw const BackupException(BackupErrorKind.notABackup);
    }
    for (var i = 0; i < 8; i++) {
      if (file[i] != BackupFormat.magic[i]) {
        throw const BackupException(BackupErrorKind.notABackup);
      }
    }
    final data = ByteData.sublistView(file);
    final version = data.getUint16(8);
    if (version != BackupFormat.formatVersion) {
      throw const BackupException(BackupErrorKind.unsupportedFormat);
    }
    final headerLength = data.getUint32(10);
    if (headerLength == 0 ||
        headerLength > BackupFormat.maxHeaderLength ||
        14 + headerLength + 16 > file.length) {
      throw const BackupException(BackupErrorKind.notABackup);
    }
    final headerEnd = 14 + headerLength;
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(file.sublist(14, headerEnd)));
    } on Object {
      throw const BackupException(BackupErrorKind.notABackup);
    }
    if (json is! Map<String, Object?>) {
      throw const BackupException(BackupErrorKind.notABackup);
    }
    return ParsedBackup(
      BackupHeader.fromJson(json),
      Uint8List.sublistView(file, 0, headerEnd),
      Uint8List.sublistView(file, headerEnd, file.length - 16),
      Uint8List.sublistView(file, file.length - 16),
    );
  }

  /// Decrypts and unpacks a backup. Throws [BackupException] with
  /// [BackupErrorKind.wrongPasswordOrCorrupted] on a wrong password or any
  /// modification of the file.
  static Future<List<BackupEntry>> open(Uint8List file, String password) async {
    final parsed = parse(file);
    final key = await deriveKey(password, parsed.header);
    final List<int> clear;
    try {
      clear = await AesGcm.with256bits().decrypt(
        SecretBox(
          parsed.cipherText,
          nonce: parsed.header.nonce,
          mac: Mac(parsed.tag),
        ),
        secretKey: key,
        aad: parsed.aad,
      );
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupErrorKind.wrongPasswordOrCorrupted);
    }
    final Uint8List archive;
    try {
      archive = Uint8List.fromList(ZLibCodec().decode(clear));
    } on Object {
      throw const BackupException(BackupErrorKind.corruptedPayload);
    }
    return BackupArchive.unpack(archive);
  }
}
