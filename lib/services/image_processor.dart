import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/app_settings.dart';

/// Result of compressing a captured photo in one background pass.
typedef ProcessedPhoto = ({Uint8List jpeg, Uint8List thumbnail});

/// Composites the stamp onto a full-resolution photo, writes GPS/altitude/
/// direction into the JPEG's EXIF metadata, and produces a thumbnail — all in
/// a single background isolate so capture stays responsive.
class ImageProcessor {
  ImageProcessor._();

  static const double _stampWidthFraction = 0.78;
  static const int _thumbnailWidth = 512;

  static Future<ProcessedPhoto> process({
    required Uint8List photoBytes,
    required Uint8List stampPng,
    required StampPosition position,
    required DateTime timestamp,
    double? latitude,
    double? longitude,
    double? altitude,
    double? bearing,
  }) {
    return compute(
      _process,
      (
        photo: photoBytes,
        stamp: stampPng,
        position: position.index,
        timestampMs: timestamp.millisecondsSinceEpoch,
        lat: latitude,
        lng: longitude,
        altitude: altitude,
        bearing: bearing,
      ),
      debugLabel: 'process-photo',
    );
  }
}

typedef _CompositeArgs = ({
  Uint8List photo,
  Uint8List stamp,
  int position,
  int timestampMs,
  double? lat,
  double? lng,
  double? altitude,
  double? bearing,
});

ProcessedPhoto _process(_CompositeArgs args) {
  final img.Image? decoded =
      img.decodeJpg(args.photo) ?? img.decodeImage(args.photo);
  if (decoded == null) {
    return (jpeg: args.photo, thumbnail: args.photo);
  }

  // Normalise EXIF orientation so the overlay matches the framing.
  final int orientation = decoded.exif.imageIfd.orientation ?? 1;
  final img.Image photo =
      orientation == 1 ? decoded : img.bakeOrientation(decoded);
  photo.exif.imageIfd.orientation = 1;

  final img.Image? stamp = img.decodePng(args.stamp);
  if (stamp != null) {
    final int targetWidth =
        (photo.width * ImageProcessor._stampWidthFraction).round();
    final int targetHeight = (stamp.height * targetWidth / stamp.width).round();

    final img.Image scaled =
        (targetWidth == stamp.width && targetHeight == stamp.height)
            ? stamp
            : img.copyResize(
                stamp,
                width: targetWidth,
                height: targetHeight,
                interpolation: img.Interpolation.average,
              );

    final int margin = (photo.width * 0.03).round();
    final int dx;
    final int dy;
    switch (args.position) {
      case 0: // topLeft
        dx = margin;
        dy = margin;
        break;
      case 1: // topCenter
        dx = (photo.width - scaled.width) ~/ 2;
        dy = margin;
        break;
      case 2: // topRight
        dx = photo.width - scaled.width - margin;
        dy = margin;
        break;
      case 3: // bottomLeft
        dx = margin;
        dy = photo.height - scaled.height - margin;
        break;
      case 4: // bottomCenter
        dx = (photo.width - scaled.width) ~/ 2;
        dy = photo.height - scaled.height - margin;
        break;
      default: // bottomRight
        dx = photo.width - scaled.width - margin;
        dy = photo.height - scaled.height - margin;
        break;
    }

    img.compositeImage(
      photo,
      scaled,
      dstX: dx,
      dstY: dy,
      srcX: 0,
      srcY: 0,
      srcW: scaled.width,
      srcH: scaled.height,
      dstW: scaled.width,
      dstH: scaled.height,
      blend: img.BlendMode.alpha,
    );
  }

  _writeMetadata(photo, args);

  final Uint8List jpeg = Uint8List.fromList(img.encodeJpg(photo, quality: 100));

  final int thumbWidth =
      photo.width < ImageProcessor._thumbnailWidth ? photo.width : ImageProcessor._thumbnailWidth;
  final img.Image thumb = img.copyResize(
    photo,
    width: thumbWidth,
    height: (thumbWidth * photo.height / photo.width).round(),
    interpolation: img.Interpolation.average,
  );
  final Uint8List thumbnail =
      Uint8List.fromList(img.encodeJpg(thumb, quality: 82));

  return (jpeg: jpeg, thumbnail: thumbnail);
}

void _writeMetadata(img.Image photo, _CompositeArgs args) {
  try {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(args.timestampMs);
    final String dateTime = '${_date(time)} ${_time(time)}';
    photo.exif.imageIfd['DateTime'] = dateTime;
    photo.exif.imageIfd['Software'] = 'PhotoTag';
    photo.exif.exifIfd['DateTimeOriginal'] = dateTime;
    photo.exif.exifIfd['DateTimeDigitized'] = dateTime;

    final double? lat = args.lat;
    final double? lng = args.lng;
    if (lat == null || lng == null) return;

    final img.IfdDirectory gps = photo.exif.gpsIfd;
    gps[0x0000] = img.IfdByteValue.list(Uint8List.fromList(<int>[2, 3, 0, 0]));
    gps[0x0001] = img.IfdValueAscii(lat >= 0 ? 'N' : 'S');
    gps[0x0002] = _dms(lat.abs());
    gps[0x0003] = img.IfdValueAscii(lng >= 0 ? 'E' : 'W');
    gps[0x0004] = _dms(lng.abs());
    gps[0x0007] = _triple(time.hour, time.minute, time.second);
    gps[0x001D] = img.IfdValueAscii(_date(time));

    if (args.altitude != null) {
      gps[0x0005] = img.IfdByteValue(args.altitude! >= 0 ? 0 : 1);
      gps[0x0006] =
          img.IfdValueRational((args.altitude!.abs() * 100).round(), 100);
    }
    if (args.bearing != null) {
      gps[0x0010] = img.IfdValueAscii('T');
      gps[0x0011] = img.IfdValueRational((args.bearing! * 100).round(), 100);
    }
  } catch (_) {
    // Metadata is best-effort; never fail a capture because of it.
  }
}

/// Builds the three-value (degrees, minutes, seconds) GPS rational.
img.IfdValueRational _dms(double degrees) {
  final int d = degrees.floor();
  final double minutesFloat = (degrees - d) * 60;
  final int m = minutesFloat.floor();
  final int s = ((minutesFloat - m) * 60 * 10000).round();
  return _triple(d, m, s, cDenom: 10000);
}

/// Builds a rational list [a/1, b/1, c/cDenom] without importing the private
/// `Rational` type.
img.IfdValueRational _triple(int a, int b, int c, {int cDenom = 1}) {
  final img.IfdValueRational value = img.IfdValueRational(a, 1);
  value.value
    ..add(img.IfdValueRational(b, 1).value.first)
    ..add(img.IfdValueRational(c, cDenom).value.first);
  return value;
}

String _two(int v) => v.toString().padLeft(2, '0');
String _date(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}:${_two(t.month)}:${_two(t.day)}';
String _time(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';
