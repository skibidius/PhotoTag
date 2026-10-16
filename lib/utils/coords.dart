import 'dart:math' as math;

/// A UTM coordinate on the WGS84 ellipsoid.
class UtmCoord {
  const UtmCoord({
    required this.zoneNumber,
    required this.zoneLetter,
    required this.easting,
    required this.northing,
  });

  final int zoneNumber;
  final String zoneLetter;
  final int easting;
  final int northing;
}

/// Coordinate formatting and conversion helpers.
///
/// Decimal, DMS and DDM are derived directly from latitude/longitude. UTM and
/// MGRS are computed with the standard WGS84 transverse Mercator projection,
/// including the Norway and Svalbard zone exceptions.
class Coords {
  Coords._();

  // WGS84 constants -----------------------------------------------------------
  static const double _semiMajorAxis = 6378137.0;
  static const double _eccSquared = 0.00669438;
  static const double _scaleFactor = 0.9996;
  static const double _eastingOffset = 500000.0;
  static const double _northingOffset = 10000000.0;
  static const int _utmZoneWidth = 6;
  static const double _halfZoneWidth = _utmZoneWidth / 2;

  static const String _colOriginLetters = 'AJSAJS';
  static const String _rowOriginLetters = 'AFAFAF';
  static const String _bandLetters = 'CDEFGHJKLMNPQRSTUVWX';

  // Public formatting ---------------------------------------------------------

  /// `55.755826° N · 37.617300° E`
  static String decimal(double lat, double lng) {
    if (!_inRange(lat, lng)) return '—';
    return '${lat.abs().toStringAsFixed(6)}° ${_ns(lat)} · '
        '${lng.abs().toStringAsFixed(6)}° ${_ew(lng)}';
  }

  /// `55°45'20.97"N · 37°37'02.28"E`
  static String dms(double lat, double lng) {
    if (!_inRange(lat, lng)) return '—';
    return '${_toDms(lat, isLat: true)} · ${_toDms(lng, isLat: false)}';
  }

  /// `55°45.350'N · 37°37.038'E`
  static String ddm(double lat, double lng) {
    if (!_inRange(lat, lng)) return '—';
    return '${_toDdm(lat, isLat: true)} · ${_toDdm(lng, isLat: false)}';
  }

  /// `37U · 413150 E · 6173685 N`
  static String utm(double lat, double lng) {
    final UtmCoord c = toUtm(lat, lng);
    if (c.zoneLetter == 'Z') return '—';
    return '${c.zoneNumber}${c.zoneLetter} · ${c.easting} E · ${c.northing} N';
  }

  /// `37U DB 13150 73685` — the default accuracy is five digits (1 m).
  static String mgrs(double lat, double lng, {int accuracy = 5}) {
    final UtmCoord c = toUtm(lat, lng);
    if (c.zoneLetter == 'Z') return '—';
    final String easting = c.easting.toString().padLeft(5, '0');
    final String northing = c.northing.toString().padLeft(5, '0');
    final String e = easting.substring(easting.length - 5);
    final String n = northing.substring(northing.length - 5);
    final int acc = accuracy.clamp(0, 5);
    final String square = _get100kId(c.easting, c.northing, c.zoneNumber);
    return '${c.zoneNumber}${c.zoneLetter} $square '
        '${e.substring(0, acc)} ${n.substring(0, acc)}';
  }

  /// Formats coordinates according to a [CoordFormat].
  static String format(CoordFormat format, double lat, double lng) {
    switch (format) {
      case CoordFormat.decimal:
        return decimal(lat, lng);
      case CoordFormat.dms:
        return dms(lat, lng);
      case CoordFormat.ddm:
        return ddm(lat, lng);
      case CoordFormat.utm:
        return utm(lat, lng);
      case CoordFormat.mgrs:
        return mgrs(lat, lng);
    }
  }

  // Converters ----------------------------------------------------------------

  static UtmCoord toUtm(double lat, double lng) {
    if (lat < -80 || lat > 84) {
      return UtmCoord(zoneNumber: 0, zoneLetter: 'Z', easting: 0, northing: 0);
    }

    final double latRad = _degToRad(lat);
    final double lngRad = _degToRad(lng);

    int zoneNumber = ((lng + 180) / 6).floor() + 1;
    if (lng == 180) zoneNumber = 60;

    // Norway.
    if (lat >= 56.0 && lat < 64.0 && lng >= 3.0 && lng < 12.0) zoneNumber = 32;
    // Svalbard.
    if (lat >= 72.0 && lat < 84.0) {
      if (lng >= 0 && lng < 9) {
        zoneNumber = 31;
      } else if (lng >= 9 && lng < 21) {
        zoneNumber = 33;
      } else if (lng >= 21 && lng < 33) {
        zoneNumber = 35;
      } else if (lng >= 33 && lng < 42) {
        zoneNumber = 37;
      }
    }

    final double lngOrigin =
        (zoneNumber - 1) * _utmZoneWidth - 180 + _halfZoneWidth;
    final double lngOriginRad = _degToRad(lngOrigin);

    final double eccPrimeSquared = _eccSquared / (1 - _eccSquared);
    final double e2 = _eccSquared;

    final double n = _semiMajorAxis /
        math.sqrt(1 - e2 * math.sin(latRad) * math.sin(latRad));
    final double t = math.tan(latRad) * math.tan(latRad);
    final double c = eccPrimeSquared * math.cos(latRad) * math.cos(latRad);
    final double a = math.cos(latRad) * (lngRad - lngOriginRad);

    final double m = _semiMajorAxis *
        ((1 - e2 / 4 - 3 * e2 * e2 / 64 - 5 * e2 * e2 * e2 / 256) * latRad -
            (3 * e2 / 8 + 3 * e2 * e2 / 32 + 45 * e2 * e2 * e2 / 1024) *
                math.sin(2 * latRad) +
            (15 * e2 * e2 / 256 + 45 * e2 * e2 * e2 / 1024) *
                math.sin(4 * latRad) -
            (35 * e2 * e2 * e2 / 3072) * math.sin(6 * latRad));

    final double easting = (_scaleFactor *
            n *
            (a +
                (1 - t + c) * a * a * a / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * eccPrimeSquared) *
                    a *
                    a *
                    a *
                    a *
                    a /
                    120) +
        _eastingOffset);

    double northing = (_scaleFactor *
        (m +
            n *
                math.tan(latRad) *
                (a * a / 2 +
                    (5 - t + 9 * c + 4 * c * c) * a * a * a * a / 24 +
                    (61 -
                            58 * t +
                            t * t +
                            600 * c -
                            330 * eccPrimeSquared) *
                        a *
                        a *
                        a *
                        a *
                        a *
                        a /
                        720)));
    if (lat < 0) northing += _northingOffset;

    return UtmCoord(
      zoneNumber: zoneNumber,
      zoneLetter: _latBand(lat),
      easting: easting.truncate(),
      northing: northing.truncate(),
    );
  }

  static String _latBand(double lat) {
    if (lat >= 72 && lat <= 84) return 'X';
    if (lat < 72 && lat >= -80) {
      final int index = ((lat + 80) / 8).floor();
      return _bandLetters[index];
    }
    return 'Z';
  }

  static String _get100kId(int easting, int northing, int zoneNumber) {
    final int setParm = _get100kSetForZone(zoneNumber);
    final int column = (easting / 100000).floor();
    final int row = (northing / 100000).floor() % 20;
    return _getLetter100kId(column, row, setParm);
  }

  static int _get100kSetForZone(int zone) {
    int set = zone % 6;
    if (set == 0) set = 6;
    return set;
  }

  static String _getLetter100kId(int column, int row, int parm) {
    const int a = 65; // 'A'
    const int i = 73; // 'I'
    const int o = 79; // 'O'
    const int v = 86; // 'V'
    const int z = 90; // 'Z'

    final int index = parm - 1;
    final int colOrigin = _colOriginLetters.codeUnitAt(index);
    final int rowOrigin = _rowOriginLetters.codeUnitAt(index);

    int colInt = colOrigin + column - 1;
    int rowInt = rowOrigin + row;
    bool rollover = false;

    if (colInt > z) {
      colInt = colInt - z + a - 1;
      rollover = true;
    }
    if (colInt == i ||
        (colOrigin < i && colInt > i) ||
        ((colInt > i || colOrigin < i) && rollover)) {
      colInt++;
    }
    if (colInt == o ||
        (colOrigin < o && colInt > o) ||
        ((colInt > o || colOrigin < o) && rollover)) {
      colInt++;
      if (colInt == i) colInt++;
    }
    if (colInt > z) colInt = colInt - z + a - 1;

    if (rowInt > v) {
      rowInt = rowInt - v + a - 1;
      rollover = true;
    } else {
      rollover = false;
    }
    if ((rowInt == i) ||
        ((rowOrigin < i) && (rowInt > i)) ||
        (((rowInt > i) || (rowOrigin < i)) && rollover)) {
      rowInt++;
    }
    if ((rowInt == o) ||
        ((rowOrigin < o) && (rowInt > o)) ||
        (((rowInt > o) || (rowOrigin < o)) && rollover)) {
      rowInt++;
      if (rowInt == i) rowInt++;
    }
    if (rowInt > v) rowInt = rowInt - v + a - 1;

    return String.fromCharCodes([colInt, rowInt]);
  }

  // Helpers -------------------------------------------------------------------

  static bool _inRange(double lat, double lng) =>
      lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

  static String _ns(double lat) => lat >= 0 ? 'N' : 'S';
  static String _ew(double lng) => lng >= 0 ? 'E' : 'W';

  static String _toDms(double value, {required bool isLat}) {
    final double abs = value.abs();
    final int d = abs.floor();
    final double mFloat = (abs - d) * 60;
    final int m = mFloat.floor();
    final double s = (mFloat - m) * 60;
    final String dir = isLat ? _ns(value) : _ew(value);
    final String dStr = isLat ? d.toString().padLeft(2, '0') : d.toString().padLeft(3, '0');
    return '$dStr°${m.toString().padLeft(2, '0')}′'
        '${s.toStringAsFixed(2).padLeft(5, '0')}″$dir';
  }

  static String _toDdm(double value, {required bool isLat}) {
    final double abs = value.abs();
    final int d = abs.floor();
    final double m = (abs - d) * 60;
    final String dir = isLat ? _ns(value) : _ew(value);
    final String dStr = isLat ? d.toString().padLeft(2, '0') : d.toString().padLeft(3, '0');
    return '$dStr°${m.toStringAsFixed(3).padLeft(6, '0')}′$dir';
  }

  static double _degToRad(double deg) => deg * (math.pi / 180);
}

/// Supported coordinate output formats.
enum CoordFormat {
  decimal,
  dms,
  ddm,
  utm,
  mgrs;

  String get label {
    switch (this) {
      case CoordFormat.decimal:
        return 'Decimal degrees';
      case CoordFormat.dms:
        return 'Degrees · minutes · seconds';
      case CoordFormat.ddm:
        return 'Degrees · decimal minutes';
      case CoordFormat.utm:
        return 'UTM';
      case CoordFormat.mgrs:
        return 'MGRS';
    }
  }
}
