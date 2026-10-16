import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Generates the launcher icon assets:
///  - assets/icon/icon.png       — full-bleed icon (iOS / legacy Android)
///  - assets/icon/foreground.png — transparent adaptive foreground (Android)
///
/// The motif is a location pin whose head is a camera aperture (a hexagon
/// shutter), over a teal-to-blue gradient with faint compass ticks.
void main() {
  const int size = 1024;

  final img.Image icon = img.Image(width: size, height: size, numChannels: 4);
  _paintGradient(icon);
  _paintCompassTicks(icon);
  _paintPin(icon, centerX: 512, centerY: 470, radius: 268, aperture: 96);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));

  final img.Image fg = img.Image(width: size, height: size, numChannels: 4);
  _paintPin(fg, centerX: 512, centerY: 512, radius: 190, aperture: 68);
  File('assets/icon/foreground.png').writeAsBytesSync(img.encodePng(fg));
}

void _paintGradient(img.Image image) {
  // Diagonal gradient teal -> blue -> deep blue.
  final int size = image.width;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final double t = (x + y) / (2.0 * size);
      final int r = _lerp3(0x00, 0x00, 0x02, t);
      final int g = _lerp3(0xC7, 0x77, 0x3E, t);
      final int b = _lerp3(0xA8, 0xB6, 0x8A, t);
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }
}

int _lerp3(int a, int b, int c, double t) {
  if (t < 0.5) {
    final double u = t * 2;
    return (a + (b - a) * u).round();
  }
  final double u = (t - 0.5) * 2;
  return (b + (c - b) * u).round();
}

void _paintCompassTicks(img.Image image) {
  final img.Color tick =
      img.ColorRgba8(255, 255, 255, 40); // faint white
  const int cx = 512, cy = 470;
  const int inner = 388, outer = 420;
  for (int i = 0; i < 8; i++) {
    final double angle = i * math.pi / 4;
    final double dx = math.cos(angle);
    final double dy = math.sin(angle);
    final int x1 = (cx + dx * inner).round();
    final int y1 = (cy + dy * inner).round();
    final int x2 = (cx + dx * outer).round();
    final int y2 = (cy + dy * outer).round();
    img.drawLine(image, x1: x1, y1: y1, x2: x2, y2: y2, color: tick);
  }
}

void _paintPin(img.Image image,
    {required int centerX,
    required int centerY,
    required int radius,
    required int aperture}) {
  final img.Color white = img.ColorRgba8(255, 255, 255, 255);

  // Tail.
  final int tipY = centerY + radius + (radius * 0.6).round();
  final int baseY = centerY + (radius * 0.55).round();
  final int half = (radius * 0.62).round();
  img.fillPolygon(
    image,
    vertices: <img.Point>[
      img.Point(centerX, tipY),
      img.Point(centerX - half, baseY),
      img.Point(centerX + half, baseY),
    ],
    color: white,
  );

  // Head.
  img.fillCircle(
      image, x: centerX, y: centerY, radius: radius, color: white,
      antialias: true);

  // Aperture: a dark lens with a white hexagon shutter and a center dot.
  final img.Color lens = _holeColor(image, centerX, centerY - 4);
  img.fillCircle(
      image, x: centerX, y: centerY, radius: aperture, color: lens,
      antialias: true);

  const double h = 0.52; // hexagon radius relative to aperture
  final List<img.Point> hex = <img.Point>[];
  for (int i = 0; i < 6; i++) {
    final double a = i * math.pi / 3 - math.pi / 6;
    hex.add(img.Point(
      (centerX + math.cos(a) * aperture * h).round(),
      (centerY + math.sin(a) * aperture * h).round(),
    ));
  }
  img.fillPolygon(image, vertices: hex, color: white);

  img.fillCircle(
      image, x: centerX, y: centerY, radius: (aperture * 0.14).round(),
      color: white);
}

img.Color _holeColor(img.Image image, int x, int y) {
  final img.Pixel p = image.getPixel(x, y);
  return img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
}
