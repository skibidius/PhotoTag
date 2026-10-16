import 'dart:io';

import 'package:image/image.dart' as img;

/// Generates the launcher icon assets:
///  - assets/icon/icon.png      — full-bleed icon (iOS / legacy Android)
///  - assets/icon/foreground.png — transparent adaptive foreground (Android)
///
/// The motif is a location pin with a camera aperture, on a teal gradient that
/// matches the app's seed colour.
void main() {
  const int size = 1024;

  final img.Image icon = img.Image(width: size, height: size, numChannels: 4);
  _paintGradient(icon);
  _paintPin(icon, centerX: 512, centerY: 448, radius: 250, hole: 92);
  File('assets/icon/icon.png').writeAsBytesSync(
    img.encodePng(icon),
  );

  final img.Image fg = img.Image(width: size, height: size, numChannels: 4);
  // Adaptive foregrounds sit inside a 66%-diameter safe zone.
  _paintPin(fg, centerX: 512, centerY: 512, radius: 168, hole: 62);
  File('assets/icon/foreground.png').writeAsBytesSync(
    img.encodePng(fg),
  );
}

void _paintGradient(img.Image image) {
  final int topR = 0x00, topG = 0x95, topB = 0x86; // #009586
  final int botR = 0x00, botG = 0x49, botB = 0x40; // #004940
  for (int y = 0; y < image.height; y++) {
    final double t = y / (image.height - 1);
    final int r = (topR + (botR - topR) * t).round();
    final int g = (topG + (botG - topG) * t).round();
    final int b = (topB + (botB - topB) * t).round();
    for (int x = 0; x < image.width; x++) {
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

void _paintPin(img.Image image,
    {required int centerX, required int centerY, required int radius, required int hole}) {
  final img.Color white = img.ColorRgba8(255, 255, 255, 255);
  final int tailTipY = centerY + radius + radius ~/ 2;
  final int tailBaseY = centerY + radius ~/ 3;
  final int tailHalfWidth = (radius * 0.62).round();

  img.fillPolygon(
    image,
    vertices: <img.Point>[
      img.Point(centerX, tailTipY),
      img.Point(centerX - tailHalfWidth, tailBaseY),
      img.Point(centerX + tailHalfWidth, tailBaseY),
    ],
    color: white,
  );
  img.fillCircle(
    image,
    x: centerX,
    y: centerY,
    radius: radius,
    color: white,
    antialias: true,
  );

  // The aperture hole reuses the background teal.
  final img.Color holeColor = _holeColor(image, centerX, centerY);
  img.fillCircle(
    image,
    x: centerX,
    y: centerY,
    radius: hole,
    color: holeColor,
    antialias: true,
  );
}

img.Color _holeColor(img.Image image, int x, int y) {
  final img.Pixel p = image.getPixel(x, y);
  return img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
}
