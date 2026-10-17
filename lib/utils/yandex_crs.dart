import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// EPSG:3395 (World Mercator) as used by the Yandex raster tile grid.
///
/// Yandex tiles are not Web Mercator: they are drawn with the ellipsoidal
/// Mercator projection. Rendering them in EPSG:3857 shifts everything north or
/// south of the equator, which is why a naive tile layer looks "off". This CRS
/// reproduces Leaflet's `L.CRS.EPSG3395` exactly, so the tiles line up with the
/// geographic coordinates.
class YandexCrs extends Crs {
  const YandexCrs()
      : super(code: 'EPSG:3395', infinite: false, wrapLng: (-180, 180));

  /// Semi-major axis of WGS84, also used by Leaflet's EPSG:3395.
  static const double radius = 6378137;

  static const double _radiusMinor = 6356752.314245179;
  static const double _scale = 0.5 / (math.pi * radius);
  static final double _eccentricity = math.sqrt(
    1 - (_radiusMinor / radius) * (_radiusMinor / radius),
  );

  @override
  Projection get projection => const _EllipticalMercator();

  @override
  (double, double) transform(double x, double y, double scale) => (
        scale * (_scale * x + 0.5),
        scale * (-_scale * y + 0.5),
      );

  @override
  (double, double) untransform(double x, double y, double scale) => (
        (x / scale - 0.5) / _scale,
        (0.5 - y / scale) / _scale,
      );

  @override
  (double, double) latLngToXY(LatLng latlng, double scale) {
    final (double x, double y) = projection.projectXY(latlng);
    return transform(x, y, scale);
  }

  @override
  LatLng offsetToLatLng(Offset point, double zoom) {
    final (double x, double y) =
        untransform(point.dx, point.dy, scale(zoom));
    return projection.unprojectXY(x, y);
  }

  @override
  Rect? getProjectedBounds(double zoom) {
    final double s = scale(zoom);
    return Rect.fromLTWH(0, 0, s, s);
  }
}

/// Ellipsoidal Mercator projection (WGS84), matching Leaflet's `Mercator`.
class _EllipticalMercator extends Projection {
  const _EllipticalMercator()
      : super(const Rect.fromLTRB(
          -YandexCrs.radius * math.pi,
          -YandexCrs.radius * math.pi,
          YandexCrs.radius * math.pi,
          YandexCrs.radius * math.pi,
        ));

  @override
  (double, double) projectXY(LatLng latlng) {
    final double lon = latlng.longitude * math.pi / 180;
    final double lat = latlng.latitude * math.pi / 180;
    final double con = YandexCrs._eccentricity * math.sin(lat);
    final double ts = math.tan(math.pi / 4 - lat / 2) /
        math.pow((1 - con) / (1 + con), YandexCrs._eccentricity / 2);
    return (
      YandexCrs.radius * lon,
      -YandexCrs.radius * math.log(math.max(ts, 1e-10)),
    );
  }

  @override
  LatLng unprojectXY(double x, double y) {
    final double ts = math.exp(-y / YandexCrs.radius);
    double phi = math.pi / 2 - 2 * math.atan(ts);
    for (int i = 0; i < 15; i++) {
      final double con = YandexCrs._eccentricity * math.sin(phi);
      final double dphi = math.pi / 2 -
          2 *
              math.atan(ts *
                  math.pow(
                    (1 - con) / (1 + con),
                    YandexCrs._eccentricity / 2,
                  )) -
          phi;
      phi += dphi;
      if (dphi.abs() < 1e-7) break;
    }
    return LatLng(
      phi * 180 / math.pi,
      x / YandexCrs.radius * 180 / math.pi,
    );
  }
}
