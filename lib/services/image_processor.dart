
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../models/app_settings.dart';

/// Composites the stamp onto a full-resolution photo without downscaling it.
///
/// The photo is decoded, its EXIF orientation is baked into the pixels so the
/// stamp always aligns with what the photographer framed, the stamp is scaled
/// to a fixed fraction of the frame width, and the result is re-encoded at the
/// highest JPEG quality.
class ImageProcessor {
  ImageProcessor._();

  /// Fraction of the photo width occupied by the stamp.
  static const double _stampWidthFraction = 0.78;

  static Future<Uint8List> compositeJpeg({
    required Uint8List photoBytes,
    required Uint8List stampPng,
    required StampPosition position,
  }) {
    return compute(
      _composite,
      (photo: photoBytes, stamp: stampPng, position: position.index),
      debugLabel: 'composite-stamp',
    );
  }
}

typedef _CompositeArgs = ({Uint8List photo, Uint8List stamp, int position});

Uint8List _composite(_CompositeArgs args) {
  final img.Image? decoded = img.decodeImage(args.photo);
  if (decoded == null) return args.photo;

  // Normalise EXIF orientation so the overlay matches the framing.
  final img.Image photo = img.bakeOrientation(decoded);
  photo.exif.imageIfd.orientation = 1;

  final img.Image? stamp = img.decodePng(args.stamp);
  if (stamp == null) {
    return Uint8List.fromList(img.encodeJpg(photo, quality: 100));
  }

  final int targetWidth = (photo.width * ImageProcessor._stampWidthFraction).round();
  final int targetHeight = (stamp.height * targetWidth / stamp.width).round();

  final img.Image scaled = (targetWidth == stamp.width && targetHeight == stamp.height)
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

  return Uint8List.fromList(img.encodeJpg(photo, quality: 100));
}
