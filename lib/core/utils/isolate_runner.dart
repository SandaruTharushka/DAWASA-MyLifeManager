import 'dart:async';
import 'dart:isolate';

/// Runs CPU-heavy work (key derivation, encryption, SQLite validation) off
/// the UI thread. Tests pass [runInline] instead.
typedef TaskRunner = Future<R> Function<R>(FutureOr<R> Function() task);

Future<R> runInIsolate<R>(FutureOr<R> Function() task) => Isolate.run(task);

Future<R> runInline<R>(FutureOr<R> Function() task) async => task();
