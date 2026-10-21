import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

import '../models/app_settings.dart';
import 'image_processor.dart';
import 'photo_store.dart';

/// A captured photo waiting to be watermarked and saved.
class CaptureTask {
  const CaptureTask({
    required this.photoBytes,
    required this.stampPng,
    required this.position,
    required this.timestamp,
    required this.counter,
    required this.coordText,
    required this.saveOriginal,
    this.jpegQuality = 100,
    this.latitude,
    this.longitude,
    this.altitude,
    this.bearing,
    this.accuracy,
    this.address,
    this.note,
    this.project,
    this.author,
  });

  final Uint8List photoBytes;
  final Uint8List stampPng;
  final StampPosition position;
  final DateTime timestamp;
  final int counter;
  final String coordText;
  final bool saveOriginal;
  final int jpegQuality;

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? bearing;
  final double? accuracy;
  final String? address;
  final String? note;
  final String? project;
  final String? author;
}

/// Processes captured photos sequentially in the background so the shutter
/// stays instant and the user can keep shooting.
class CaptureQueue extends ChangeNotifier {
  CaptureQueue(this._store);

  final PhotoStore _store;
  final List<CaptureTask> _queue = <CaptureTask>[];

  bool _processing = false;
  int _saved = 0;
  int _failed = 0;
  Object? _lastError;

  /// Number of photos waiting or currently being processed.
  int get pendingCount => _queue.length;
  bool get processing => _processing;
  int get savedCount => _saved;
  int get failedCount => _failed;
  Object? get lastError => _lastError;

  void enqueue(CaptureTask task) {
    _queue.add(task);
    notifyListeners();
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_processing) return;
    _processing = true;
    notifyListeners();

    while (_queue.isNotEmpty) {
      final CaptureTask task = _queue.first;
      try {
        final ProcessedPhoto processed = await ImageProcessor.process(
          photoBytes: task.photoBytes,
          stampPng: task.stampPng,
          position: task.position,
          timestamp: task.timestamp,
          latitude: task.latitude,
          longitude: task.longitude,
          altitude: task.altitude,
          bearing: task.bearing,
          accuracy: task.accuracy,
          address: task.address,
          note: task.note,
          project: task.project,
          author: task.author,
          counter: task.counter,
          jpegQuality: task.jpegQuality,
        );

        final record = await _store.save(
          jpeg: processed.jpeg,
          thumbnailJpeg: processed.thumbnail,
          originalJpeg: task.saveOriginal ? task.photoBytes : null,
          takenAt: task.timestamp,
          latitude: task.latitude,
          longitude: task.longitude,
          altitude: task.altitude,
          accuracy: task.accuracy,
          bearing: task.bearing,
          address: task.address,
          note: task.note,
          project: task.project,
          counter: task.counter,
          coordText: task.coordText,
        );

        // Copy to the system gallery in the background; not critical.
        unawaited(_saveToGallery(record.path));
        _saved++;
      } catch (error) {
        _failed++;
        _lastError = error;
        debugPrint('Photo processing failed: $error');
      }

      if (_queue.isNotEmpty) _queue.removeAt(0);
      notifyListeners();
    }

    _processing = false;
    notifyListeners();
  }

  Future<void> _saveToGallery(String path) async {
    try {
      if (!await Gal.hasAccess(toAlbum: false)) {
        await Gal.requestAccess(toAlbum: false);
      }
      await Gal.putImage(path, album: 'PhotoTag');
    } catch (_) {
      // Gallery access is optional; the photo is already saved locally.
    }
  }

  @override
  void dispose() {
    _queue.clear();
    super.dispose();
  }
}
