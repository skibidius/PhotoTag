import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phototag/models/app_settings.dart';
import 'package:phototag/services/capture_queue.dart';
import 'package:phototag/services/photo_store.dart';

void main() {
  test('processes queued photos in the background and saves them', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final Directory tempDir =
        await Directory.systemTemp.createTemp('phototag_queue_test');
    final PhotoStore store = PhotoStore();
    await store.load(baseDirectory: tempDir);
    final CaptureQueue queue = CaptureQueue(store);

    final img.Image photo = img.Image(width: 800, height: 1000);
    img.fill(photo, color: img.ColorRgb8(80, 140, 90));
    final Uint8List photoBytes = Uint8List.fromList(img.encodeJpg(photo));

    final img.Image stamp = img.Image(width: 400, height: 120, numChannels: 4);
    img.fill(stamp, color: img.ColorRgba8(0, 0, 0, 0));
    img.fillRect(
      stamp,
      x1: 10,
      y1: 10,
      x2: 390,
      y2: 110,
      color: img.ColorRgba8(0, 0, 0, 200),
    );
    final Uint8List stampPng = Uint8List.fromList(img.encodePng(stamp));

    for (int i = 0; i < 3; i++) {
      queue.enqueue(CaptureTask(
        photoBytes: photoBytes,
        stampPng: stampPng,
        position: StampPosition.bottomLeft,
        timestamp: DateTime(2026, 10, 17, 12, 0, i),
        counter: i + 1,
        coordText: '55.755800° N · 37.617300° E',
        saveOriginal: true,
        latitude: 55.7558,
        longitude: 37.6173,
      ));
    }

    // Wait for the queue to drain.
    for (int i = 0; i < 200 && queue.pendingCount > 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    expect(queue.pendingCount, 0);
    expect(queue.savedCount, 3);
    expect(store.records.length, 3);
    expect(store.records.every((r) => r.originalPath != null), isTrue);

    await tempDir.delete(recursive: true);
  });
}
