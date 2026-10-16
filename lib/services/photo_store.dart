import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/photo_record.dart';

/// Persists captured photos (and their metadata) on disk and exposes them to
/// the gallery.
class PhotoStore extends ChangeNotifier {
  static const String _recordsKey = 'photos.v1';

  final List<PhotoRecord> _records = <PhotoRecord>[];
  List<PhotoRecord> get records => List<PhotoRecord>.unmodifiable(_records);

  Directory? _photoDir;
  bool _loaded = false;
  bool get loaded => _loaded;

  Directory get photoDir => _photoDir!;

  /// Replaces the in-memory records, used by tests and the screenshot tool.
  @visibleForTesting
  void debugSetRecords(List<PhotoRecord> records) {
    _records
      ..clear()
      ..addAll(records);
    notifyListeners();
  }

  Future<void> load({Directory? baseDirectory}) async {
    final Directory docs =
        baseDirectory ?? await getApplicationDocumentsDirectory();
    _photoDir = Directory(p.join(docs.path, 'phototag', 'photos'));
    await _photoDir!.create(recursive: true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_recordsKey);
      if (raw != null) {
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
        _records
          ..clear()
          ..addAll(list.map((dynamic e) =>
              PhotoRecord.fromJson(Map<String, dynamic>.from(e as Map))));
        _records.sort((a, b) => b.takenAt.compareTo(a.takenAt));
      }
    } catch (_) {
      // Ignore corrupt metadata; the gallery simply starts empty.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<PhotoRecord> save({
    required Uint8List jpeg,
    Uint8List? originalJpeg,
    required DateTime takenAt,
    double? latitude,
    double? longitude,
    double? altitude,
    double? accuracy,
    double? bearing,
    String? address,
    String? note,
    String? project,
    required int counter,
    required String coordText,
  }) async {
    final String id =
        '${takenAt.millisecondsSinceEpoch}_${counter.toString().padLeft(3, '0')}';

    final File fullFile = File(p.join(_photoDir!.path, '$id.jpg'));
    await fullFile.writeAsBytes(jpeg, flush: true);

    final Uint8List thumb =
        await compute(_makeThumbnail, jpeg, debugLabel: 'thumb');
    final File thumbFile = File(p.join(_photoDir!.path, '${id}_thumb.jpg'));
    await thumbFile.writeAsBytes(thumb, flush: true);

    String? originalPath;
    if (originalJpeg != null) {
      final File originalFile =
          File(p.join(_photoDir!.path, '${id}_original.jpg'));
      await originalFile.writeAsBytes(originalJpeg, flush: true);
      originalPath = originalFile.path;
    }

    final PhotoRecord record = PhotoRecord(
      id: id,
      path: fullFile.path,
      thumbPath: thumbFile.path,
      originalPath: originalPath,
      takenAt: takenAt,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      accuracy: accuracy,
      bearing: bearing,
      address: address,
      note: note,
      project: project,
      counter: counter,
      coordText: coordText,
    );

    _records.insert(0, record);
    await _persist();
    notifyListeners();
    return record;
  }

  Future<void> delete(PhotoRecord record) async {
    for (final String path in <String>[
      record.path,
      record.thumbPath,
      if (record.originalPath != null) record.originalPath!,
    ]) {
      try {
        final File file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
    _records.removeWhere((PhotoRecord r) => r.id == record.id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _recordsKey,
        jsonEncode(_records.map((PhotoRecord r) => r.toJson()).toList()),
      );
    } catch (_) {}
  }
}

Uint8List _makeThumbnail(Uint8List jpeg) {
  final img.Image? decoded = img.decodeImage(jpeg);
  if (decoded == null) return jpeg;

  const int maxDim = 512;
  int width = decoded.width;
  int height = decoded.height;
  if (width >= height && width > maxDim) {
    height = (height * maxDim / width).round();
    width = maxDim;
  } else if (height > width && height > maxDim) {
    width = (width * maxDim / height).round();
    height = maxDim;
  }

  final img.Image resized = img.copyResize(
    decoded,
    width: width,
    height: height,
    interpolation: img.Interpolation.average,
  );
  return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
}
