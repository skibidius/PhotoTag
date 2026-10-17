import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'package:phototag/models/app_settings.dart';
import 'package:phototag/services/image_processor.dart';

void main() {
  test('composites the stamp and embeds GPS EXIF metadata', () async {
    final img.Image photo = img.Image(width: 1200, height: 1600);
    img.fill(photo, color: img.ColorRgb8(80, 140, 90));
    final Uint8List photoBytes = Uint8List.fromList(img.encodeJpg(photo));

    final img.Image stamp = img.Image(width: 600, height: 200, numChannels: 4);
    img.fill(stamp, color: img.ColorRgba8(0, 0, 0, 0));
    img.fillRect(
      stamp,
      x1: 10,
      y1: 10,
      x2: 590,
      y2: 190,
      color: img.ColorRgba8(0, 0, 0, 200),
    );
    final Uint8List stampPng = Uint8List.fromList(img.encodePng(stamp));

    final ProcessedPhoto processed = await ImageProcessor.process(
      photoBytes: photoBytes,
      stampPng: stampPng,
      position: StampPosition.bottomLeft,
      timestamp: DateTime(2026, 10, 17, 12, 30, 45),
      latitude: 55.7558,
      longitude: 37.6173,
      altitude: 156,
      bearing: 315,
    );

    final img.Image? decoded = img.decodeJpg(processed.jpeg);
    expect(decoded, isNotNull);

    final img.IfdDirectory gps = decoded!.exif.gpsIfd;
    expect(gps.gpsLatitudeRef, 'N');
    expect(gps.gpsLongitudeRef, 'E');

    double dms(img.IfdValue? value) {
      if (value == null) return double.nan;
      return value.toDouble(0) +
          value.toDouble(1) / 60 +
          value.toDouble(2) / 3600;
    }

    expect(dms(gps[0x0002]), closeTo(55.7558, 0.0005));
    expect(dms(gps[0x0004]), closeTo(37.6173, 0.0005));
    expect(gps[0x0006]?.toDouble(), closeTo(156, 0.5));
    expect(gps[0x0011]?.toDouble(), closeTo(315, 0.5));
  });
}
