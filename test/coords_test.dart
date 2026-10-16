import 'package:flutter_test/flutter_test.dart';
import 'package:phototag/utils/coords.dart';

void main() {
  group('Coordinate formatting', () {
    test('decimal degrees', () {
      expect(
        Coords.decimal(55.7558, 37.6173),
        '55.755800° N · 37.617300° E',
      );
      expect(
        Coords.decimal(-33.8688, -70.6693),
        '33.868800° S · 70.669300° W',
      );
    });

    test('degrees-minutes-seconds', () {
      final String dms = Coords.dms(55.7558, 37.6173);
      expect(dms.startsWith('55°45′'), isTrue);
      expect(dms.endsWith('″E'), isTrue);
      expect(dms.contains('N · '), isTrue);
    });

    test('degrees-decimal-minutes', () {
      final String ddm = Coords.ddm(55.7558, 37.6173);
      expect(ddm, contains('55°45.348′N'));
      expect(ddm, contains('037°37.038′E'));
    });
  });

  group('UTM / MGRS conversion', () {
    // Reference values cross-checked against the `utm` and `mgrs` libraries.
    const List<({double lat, double lng, int zone, String band, String square})>
        refs = <({double lat, double lng, int zone, String band, String square})>[
      (lat: 38.8977, lng: -77.0365, zone: 18, band: 'S', square: 'UJ'),
      (lat: 40.7128, lng: -74.0060, zone: 18, band: 'T', square: 'WL'),
      (lat: 55.7558, lng: 37.6173, zone: 37, band: 'U', square: 'DB'),
      (lat: 47.3769, lng: 8.5417, zone: 32, band: 'T', square: 'MT'),
      (lat: -33.8688, lng: 151.2093, zone: 56, band: 'H', square: 'LH'),
    ];

    test('UTM zone and latitude band', () {
      for (final r in refs) {
        final UtmCoord c = Coords.toUtm(r.lat, r.lng);
        expect(c.zoneNumber, r.zone, reason: 'zone for ${r.lat},${r.lng}');
        expect(c.zoneLetter, r.band, reason: 'band for ${r.lat},${r.lng}');
      }
    });

    test('MGRS zone, band and 100km square', () {
      for (final r in refs) {
        final String m = Coords.mgrs(r.lat, r.lng);
        final String prefix = '${r.zone}${r.band} ${r.square}';
        expect(m.startsWith(prefix), isTrue,
            reason: '$m should start with $prefix');
        expect(m.length, '00X AA 00000 00000'.length, reason: 'length of $m');
      }
    });

    test('MGRS reference points match', () {
      // Verified against a second, independent implementation.
      expect(Coords.mgrs(38.8977, -77.0365), '18S UJ 23394 07395');
      expect(Coords.mgrs(40.7128, -74.0060), '18T WL 83959 07350');
      expect(Coords.mgrs(55.7558, 37.6173), '37U DB 13224 79766');
    });
  });
}
