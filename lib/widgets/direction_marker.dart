import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A photo marker with a compass cone showing the camera direction.
///
/// [bearing] is clockwise from north in degrees. When it is null (no compass
/// fix) only the round marker is drawn.
class DirectionMarker extends StatelessWidget {
  const DirectionMarker({
    super.key,
    this.bearing,
    required this.color,
    this.iconColor = Colors.white,
    this.selected = false,
    this.onTap,
  });

  final double? bearing;
  final Color color;
  final Color iconColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double size = selected ? 72 : 60;
    final double dot = selected ? 32 : 26;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            if (bearing != null)
              Transform.rotate(
                angle: bearing! * math.pi / 180,
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _ConePainter(
                    color: color,
                    opacity: selected ? 0.78 : 0.56,
                    radius: size / 2,
                  ),
                ),
              ),
            Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: selected ? 3 : 2.5,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.32),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.photo_camera,
                size: dot * 0.5,
                color: iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConePainter extends CustomPainter {
  const _ConePainter({
    required this.color,
    required this.opacity,
    required this.radius,
  });

  final Color color;
  final double opacity;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    const double halfAngle = math.pi / 6; // 60° field of view.

    final Paint paint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.6),
          color.withValues(alpha: opacity * 0.18),
        ],
        stops: const <double>[0, 0.6, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final Path path = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        center.dx - radius * math.sin(halfAngle),
        center.dy - radius * math.cos(halfAngle),
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 - halfAngle,
        halfAngle * 2,
        false,
      )
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ConePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.radius != radius;
}
