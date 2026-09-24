import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/platform/data_paths.dart';

/// Stores receipt images inside the app's private directory. Files are never
/// uploaded anywhere; they are included in encrypted backups.
class AttachmentStore {
  AttachmentStore(this._db, this._baseDirectory);

  final AppDatabase _db;
  final Future<Directory> Function() _baseDirectory;

  static const String folderName = DataPaths.attachmentsFolder;

  Future<Directory> directory() async {
    final base = await _baseDirectory();
    final dir = Directory(p.join(base.path, folderName));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  /// Copies [source] (already compressed by the image picker) into private
  /// storage and records it. Returns the attachment id.
  Future<String> importImage(File source) async {
    final id = newId();
    final ext = p.extension(source.path).toLowerCase();
    final safeExt = const {'.jpg', '.jpeg', '.png', '.webp'}.contains(ext)
        ? ext
        : '.jpg';
    final relative = '$id$safeExt';
    final dir = await directory();
    final target = await source.copy(p.join(dir.path, relative));
    await _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: Value(id),
            relativePath: relative,
            mimeType: safeExt == '.png'
                ? 'image/png'
                : safeExt == '.webp'
                ? 'image/webp'
                : 'image/jpeg',
            sizeBytes: await target.length(),
          ),
        );
    return id;
  }

  Future<File?> fileFor(String attachmentId) async {
    final row = await (_db.select(
      _db.attachments,
    )..where((a) => a.id.equals(attachmentId))).getSingleOrNull();
    if (row == null) return null;
    final file = File(p.join((await directory()).path, row.relativePath));
    return file.existsSync() ? file : null;
  }

  Future<void> delete(String attachmentId) async {
    final file = await fileFor(attachmentId);
    await (_db.delete(
      _db.attachments,
    )..where((a) => a.id.equals(attachmentId))).go();
    if (file != null && file.existsSync()) await file.delete();
  }

  /// Removes files that are no longer referenced by any row.
  Future<int> cleanupOrphans() async {
    final rows = await _db.select(_db.attachments).get();
    final known = rows.map((r) => r.relativePath).toSet();
    final dir = await directory();
    var removed = 0;
    await for (final entity in dir.list()) {
      if (entity is File && !known.contains(p.basename(entity.path))) {
        await entity.delete();
        removed++;
      }
    }
    return removed;
  }
}
