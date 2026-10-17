import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Regenerates the launcher icon assets:
///  - assets/icon/icon.png       — full-bleed icon (iOS / legacy Android)
///  - assets/icon/foreground.png — transparent adaptive foreground (Android)
///
/// A white location pin with a teal "lens" hole, over a teal→blue gradient
/// with a faint compass ring. Geometry is kept simple and symmetric.
void main() {
  const int size = 1024;

  final img.Image icon = img.Image(width: size, height: size, numChannels: 4);
  _gradient(icon);
  _compass(icon, cx: 512, cy: 430, radius: 404);
  _pin(icon, cx: 512, cy: 430, headRadius: 246, tailTipY: 928, tailHalf: 214);
  File('assets/icon/icon.png').writeAsBytesSync(img.encodePng(icon));

  final img.Image fg = img.Image(width: size, height: size, numChannels: 4);
  _pin(fg, cx: 512, cy: 470, headRadius: 182, tailTipY: 840, tailHalf: 158);
  File('assets/icon/foreground.png').writeAsBytesSync(img.encodePng(fg));
}

void _gradient(img.Image image) {
  final int n = image.width;
  // teal -> blue -> deep blue
  const int g0 = 0xC9, b0 = 0xA7; // (0, 201, 167)
  const int g1 = 0x66, b1 = 0xCC; // (0, 102, 204)
  const int g2 = 0x28, b2 = 0x6E; // (0, 40, 110)
  for (int y = 0; y < n; y++) {
    for (int x = 0; x < n; x++) {
      final double t = (x + y) / (2.0 * n);
      final int g = _ramp(g0, g1, g2, t);
      final int b = _ramp(b0, b1, b2, t);
      image.setPixelRgba(x, y, 0, g, b, 255);
    }
  }
}

int _ramp(int a, int b, int c, double t) {
  if (t < 0.5) return (a + (b - a) * (t * 2)).round();
  return (b + (c - b) * ((t - 0.5) * 2)).round();
}

void _compass(img.Image image,
    {required int cx, required int cy, required double radius}) {
  const double ringThickness = 10;
  const int ringAlpha = 56;
  final double tickInner = radius - 34;
  final double tickOuter = radius + 6;
  const double tickHalfWidth = 6;
  const int tickAlpha = 76;
  final List<double> angles = <double>[
    0,
    math.pi / 2,
    math.pi,
    3 * math.pi / 2,
  ];

  final double ringInner = radius - ringThickness / 2;
  final double ringOuter = radius + ringThickness / 2;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final double dx = (x - cx).toDouble();
      final double dy = (y - cy).toDouble();
      final double dist = math.sqrt(dx * dx + dy * dy);

      double coverage = 0;

      // Ring band with 1px anti-aliasing.
      if (dist >= ringInner - 1 && dist <= ringOuter + 1) {
        final double e = math.min(dist - ringInner, ringOuter - dist);
        coverage = ringAlpha * e.clamp(0.0, 1.0);
      }

      // Four cardinal ticks crossing the ring.
      if (dist >= tickInner - 1 && dist <= tickOuter + 1) {
        final double angle = math.atan2(dy, dx);
        for (final double a in angles) {
          double da = (angle - a).abs() % (2 * math.pi);
          if (da > math.pi) da = 2 * math.pi - da;
          final double perp = dist * math.sin(da);
          if (perp.abs() <= tickHalfWidth + 1) {
            final double e = math.min(
              math.min(dist - tickInner, tickOuter - dist),
              tickHalfWidth - perp.abs(),
            );
            final double c = tickAlpha * e.clamp(0.0, 1.0);
            if (c > coverage) coverage = c;
          }
        }
      }

      if (coverage <= 0) continue;
      final int a = coverage.clamp(0, 255).round();
      final img.Pixel p = image.getPixel(x, y);
      final int r = p.r.toInt();
      final int g = p.g.toInt();
      final int b = p.b.toInt();
      image.setPixelRgba(
        x,
        y,
        r + ((255 - r) * a ~/ 255),
        g + ((255 - g) * a ~/ 255),
        b + ((255 - b) * a ~/ 255),
        255,
      );
    }
  }
}

void _pin(img.Image image,
    {required int cx,
    required int cy,
    required int headRadius,
    required int tailTipY,
    required int tailHalf}) {
  final img.Color white = img.ColorRgba8(255, 255, 255, 255);

  // Sample the gradient before drawing the pin so the lens hole blends in.
  final img.Color lens = _backgroundAt(image, cx, cy);

  // Tail: a triangle whose top hides behind the head.
  final int baseY = cy + (headRadius * 0.5).round();
  img.fillPolygon(
    image,
    vertices: <img.Point>[
      img.Point(cx, tailTipY),
      img.Point(cx - tailHalf, baseY),
      img.Point(cx + tailHalf, baseY),
    ],
    color: white,
  );

  // Head.
  img.fillCircle(
    image,
    x: cx,
    y: cy,
    radius: headRadius,
    color: white,
    antialias: true,
  );

  // Lens hole with a soft highlight.
  final int hole = (headRadius * 0.42).round();
  img.fillCircle(
      image, x: cx, y: cy, radius: hole, color: lens, antialias: true);

  img.fillCircle(
    image,
    x: cx - (hole * 0.30).round(),
    y: cy - (hole * 0.30).round(),
    radius: (hole * 0.22).round(),
    color: img.ColorRgba8(255, 255, 255, 225),
    antialias: true,
  );
}

img.Color _backgroundAt(img.Image image, int x, int y) {
  final img.Pixel p = image.getPixel(x, y);
  return img.ColorRgba8(p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
}
