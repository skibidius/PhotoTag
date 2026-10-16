import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

import '../models/photo_record.dart';

/// What gets bundled when exporting a project.
enum ExportVariant { original, watermarked, both }

/// Bundles a project's photos into a zip archive that can be shared.
class ProjectExportService {
  ProjectExportService._();

  static Future<String> export({
    required List<PhotoRecord> records,
    required String projectName,
    required ExportVariant variant,
  }) async {
    final bool includeWatermarked = variant != ExportVariant.original;
    final bool includeOriginal = variant != ExportVariant.watermarked;

    final Archive archive = Archive();
    for (final PhotoRecord record in records) {
      final String name = _fileName(record);
      if (includeWatermarked) {
        await _add(archive, 'watermarked/$name', record.path);
      }
      if (includeOriginal && record.originalPath != null) {
        await _add(archive, 'original/$name', record.originalPath!);
      }
    }

    final List<int> encoded = ZipEncoder().encode(archive);
    final Uint8List bytes = Uint8List.fromList(encoded);
    final Directory dir =
        await Directory.systemTemp.createTemp('phototag_export');
    final File out = File(p.join(dir.path, '$projectName.zip'));
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }

  static String _fileName(PhotoRecord record) {
    final String num = record.counter.toString().padLeft(3, '0');
    final String stamp = record.takenAt
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    return '${num}_$stamp.jpg';
  }

  static Future<void> _add(Archive archive, String name, String path) async {
    final File file = File(path);
    if (!await file.exists()) return;
    final Uint8List bytes = await file.readAsBytes();
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }
}
