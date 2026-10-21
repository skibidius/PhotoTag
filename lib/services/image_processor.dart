import 'dart:convert';

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
    double? accuracy,
    String? address,
    String? note,
    String? project,
    String? author,
    int? counter,
    int jpegQuality = 100,
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
        accuracy: accuracy,
        address: address,
        note: note,
        project: project,
        author: author,
        counter: counter,
        jpegQuality: jpegQuality,
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
  double? accuracy,
  String? address,
  String? note,
  String? project,
  String? author,
  int? counter,
  int jpegQuality,
});

ProcessedPhoto _process(_CompositeArgs args) {
  final img.Image? decoded =
      img.decodeJpg(args.photo) ?? img.decodeImage(args.photo);
  if (decoded == null) {
    return (jpeg: args.photo, thumbnail: args.photo);
  }

  // Normalise EXIF orientation so the overlay matches the framing, then crop
  // to a 4:3 frame so every photo has the classic camera aspect ratio.
  final int orientation = decoded.exif.imageIfd.orientation ?? 1;
  final img.Image oriented =
      orientation == 1 ? decoded : img.bakeOrientation(decoded);
  oriented.exif.imageIfd.orientation = 1;
  final img.Image photo = _cropToFourThree(oriented);

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

  final Uint8List jpeg = Uint8List.fromList(
      img.encodeJpg(photo, quality: args.jpegQuality));

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

/// Crops the image to the largest centred 4:3 region, keeping its orientation.
img.Image _cropToFourThree(img.Image image) {
  const double target = 4 / 3;
  final bool portrait = image.height >= image.width;
  final double ratio =
      portrait ? image.height / image.width : image.width / image.height;
  if ((ratio - target).abs() < 0.005) return image;

  if (portrait) {
    final int height =
        (image.width * target).round().clamp(1, image.height);
    final int y = (image.height - height) ~/ 2;
    return img.copyCrop(
      image,
      x: 0,
      y: y,
      width: image.width,
      height: height,
    );
  }

  final int width = (image.height * target).round().clamp(1, image.width);
  final int x = (image.width - width) ~/ 2;
  return img.copyCrop(
    image,
    x: x,
    y: 0,
    width: width,
    height: image.height,
  );
}

void _writeMetadata(img.Image photo, _CompositeArgs args) {
  try {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(args.timestampMs);
    final String dateTime = '${_date(time)} ${_time(time)}';
    final String offset = _utcOffset(time.timeZoneOffset);
    final String summary = _summary(args, time);
    final String project = args.project?.trim() ?? '';
    final String note = args.note?.trim() ?? '';
    final String author = args.author?.trim() ?? '';
    final String address = args.address?.trim() ?? '';

    photo.exif.imageIfd['DateTime'] = dateTime;
    photo.exif.imageIfd['Software'] = 'PhotoTag';
    photo.exif.imageIfd['ImageDescription'] = _ascii(summary);
    photo.exif.imageIfd['ImageUniqueID'] =
        'PT-${args.timestampMs}-${args.counter ?? 0}';
    if (author.isNotEmpty) {
      photo.exif.imageIfd['Artist'] = _ascii(author);
      photo.exif.imageIfd['Copyright'] = _ascii('(c) ${time.year} $author');
    }

    // Windows Explorer / photo apps read these as UTF-16LE.
    photo.exif.imageIfd['XPTitle'] =
        _utf16le(project.isEmpty ? 'PhotoTag' : 'PhotoTag — $project');
    photo.exif.imageIfd['XPSubject'] =
        _utf16le(project.isNotEmpty ? project : address);
    photo.exif.imageIfd['XPComment'] = _utf16le(summary);
    photo.exif.imageIfd['XPKeywords'] = _utf16le(<String>[
      project,
      note,
      author,
      address,
    ].where((String value) => value.isNotEmpty).join('; '));

    photo.exif.exifIfd['DateTimeOriginal'] = dateTime;
    photo.exif.exifIfd['DateTimeDigitized'] = dateTime;
    photo.exif.exifIfd['OffsetTime'] = offset;
    photo.exif.exifIfd['OffsetTimeOriginal'] = offset;
    photo.exif.exifIfd['OffsetTimeDigitized'] = offset;
    photo.exif.exifIfd['UserComment'] = img.IfdValueUndefined.list(<int>[
      ..._userCommentPrefix,
      ...utf8.encode(summary),
    ]);

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
    gps[0x0012] = img.IfdValueAscii('WGS-84');
    gps[0x001B] = img.IfdValueUndefined.list(<int>[
      ..._userCommentPrefix,
      ...utf8.encode('GPS'),
    ]);
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
    if (args.accuracy != null && args.accuracy! > 0) {
      gps[0x001F] =
          img.IfdValueRational((args.accuracy! * 100).round(), 100);
    }
  } catch (_) {
    // Metadata is best-effort; never fail a capture because of it.
  }
}

const List<int> _userCommentPrefix = <int>[
  0x41, 0x53, 0x43, 0x49, 0x49, 0x00, 0x00, 0x00, // "ASCII\0\0\0"
];

String _summary(_CompositeArgs args, DateTime time) {
  final List<String> parts = <String>['PhotoTag'];
  final String project = args.project?.trim() ?? '';
  final String note = args.note?.trim() ?? '';
  final String author = args.author?.trim() ?? '';
  final String address = args.address?.trim() ?? '';

  if (project.isNotEmpty) parts.add('Project: $project');
  if (args.counter != null) {
    parts.add('Photo #${args.counter!.toString().padLeft(3, '0')}');
  }
  parts.add('${_date(time)} ${_time(time)} ${_utcOffset(time.timeZoneOffset)}'.trim());
  if (args.lat != null && args.lng != null) {
    parts.add(
        '${args.lat!.toStringAsFixed(6)}, ${args.lng!.toStringAsFixed(6)}');
  }
  if (args.altitude != null) parts.add('${args.altitude!.round()} m');
  if (args.bearing != null) parts.add('${args.bearing!.round()}°');
  if (args.accuracy != null) parts.add('±${args.accuracy!.round()} m');
  if (address.isNotEmpty) parts.add(address);
  if (note.isNotEmpty) parts.add('Note: $note');
  if (author.isNotEmpty) parts.add(author);
  return parts.join(' | ');
}

String _utcOffset(Duration offset) {
  final Duration abs = offset.abs();
  final String sign = offset.isNegative ? '-' : '+';
  return '$sign${abs.inHours.toString().padLeft(2, '0')}:'
      '${(abs.inMinutes % 60).toString().padLeft(2, '0')}';
}

/// Replaces characters that cannot be stored in an EXIF ASCII field.
String _ascii(String input) {
  const Map<int, String> replacements = <int, String>{
    0x00b0: ' deg', // °
    0x00b1: '+/-', // ±
    0x2013: '-', // –
    0x2014: '-', // —
    0x2116: 'No.', // №
  };

  final StringBuffer buffer = StringBuffer();
  for (final int rune in input.runes) {
    final String? replacement = replacements[rune];
    if (replacement != null) {
      buffer.write(replacement);
    } else if (rune >= 0x20 && rune <= 0x7e) {
      buffer.writeCharCode(rune);
    } else {
      buffer.write('?');
    }
  }
  return buffer.toString();
}

/// Packs a string as UTF-16LE with a null terminator (Windows XP tags).
img.IfdValueUndefined _utf16le(String value) {
  final List<int> bytes = <int>[];
  for (final int unit in value.codeUnits) {
    bytes
      ..add(unit & 0xff)
      ..add((unit >> 8) & 0xff);
  }
  bytes.addAll(const <int>[0, 0]);
  return img.IfdValueUndefined.list(bytes);
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
