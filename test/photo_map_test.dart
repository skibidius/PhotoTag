import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import 'package:phototag/l10n/app_localizations.dart';
import 'package:phototag/models/app_settings.dart';
import 'package:phototag/models/photo_record.dart';
import 'package:phototag/screens/photo_map_screen.dart';
import 'package:phototag/services/basemaps.dart';
import 'package:phototag/services/settings_controller.dart';
import 'package:phototag/utils/yandex_crs.dart';
import 'package:phototag/widgets/direction_marker.dart';

PhotoRecord _record({
  required String id,
  required double lat,
  required double lng,
  double? bearing,
  String? project,
}) {
  return PhotoRecord(
    id: id,
    path: '/tmp/$id.jpg',
    thumbPath: '/tmp/${id}_thumb.jpg',
    takenAt: DateTime(2026, 10, 16, 12),
    latitude: lat,
    longitude: lng,
    bearing: bearing,
    project: project,
    counter: 1,
    coordText: '$lat, $lng',
  );
}

void main() {
  test('Yandex CRS matches Leaflet EPSG:3395', () {
    const Crs crs = YandexCrs();
    const List<LatLng> points = <LatLng>[
      LatLng(55.7558, 37.6173),
      LatLng(0, 0),
      LatLng(-33.8688, 151.2093),
      LatLng(69.6492, 18.9553),
    ];
    const int zoom = 10;
    for (final LatLng p in points) {
      final Offset xy = crs.latLngToOffset(p, zoom.toDouble());

      const double r = 6378137;
      const double rMinor = 6356752.314245;
      final double lat = p.latitude * math.pi / 180;
      final double tmp = rMinor / r;
      final double eccent = math.sqrt(1 - tmp * tmp);
      final double con = eccent * math.sin(lat);
      final double ts = math.tan(math.pi / 4 - lat / 2) /
          math.pow((1 - con) / (1 + con), 0.5 * eccent);
      final double mx = r * p.longitude * math.pi / 180;
      final double my = -r * math.log(math.max(ts, 1e-10));
      final double scale = 256.0 * math.pow(2.0, zoom);
      final double nx = (0.5 / (math.pi * r) * mx + 0.5) * scale;
      final double ny = (0.5 - 0.5 / (math.pi * r) * my) * scale;

      expect((xy.dx - nx).abs(), lessThan(0.01));
      expect((xy.dy - ny).abs(), lessThan(0.01));
    }

    final LatLng back =
        crs.offsetToLatLng(crs.latLngToOffset(points.first, 12), 12);
    expect((back.latitude - points.first.latitude).abs(), lessThan(1e-5));
    expect((back.longitude - points.first.longitude).abs(), lessThan(1e-5));
  });

  test('basemap catalog is consistent', () {
    final Set<String> keys = kBasemaps.map((BasemapDef b) => b.key).toSet();
    expect(keys.length, kBasemaps.length);
    expect(basemapByKey(kDefaultBasemapKey).key, kDefaultBasemapKey);
    for (final BasemapDef basemap in kBasemaps) {
      expect(basemap.maxZoom, greaterThan(0));
      if (basemap.key.startsWith('yandex-')) {
        expect(basemap.crs, isA<YandexCrs>());
      } else {
        expect(basemap.crs, isA<Epsg3857>());
      }
    }
    expect(basemapByKey('yandex-map').url('ru').contains('ru_RU'), isTrue);
    expect(basemapByKey('yandex-map').url('en').contains('en_US'), isTrue);
  });

  test('basemap setting survives a JSON round-trip', () {
    const AppSettings settings = AppSettings(basemap: 'google-sat');
    final AppSettings restored =
        AppSettings.fromJson(settings.toJson());
    expect(restored.basemap, 'google-sat');
    expect(const AppSettings().basemap, 'yandex-map');
  });

  testWidgets('map screen shows markers and selects a photo', (
    WidgetTester tester,
  ) async {
    final SettingsController controller = SettingsController();
    final List<PhotoRecord> records = <PhotoRecord>[
      _record(id: 'a', lat: 55.7558, lng: 37.6173, bearing: 90, project: 'Trip'),
      _record(id: 'b', lat: 55.7600, lng: 37.6300, project: 'Trip'),
    ];

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsController>.value(
        value: controller,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PhotoMapScreen(title: 'Trip', records: records),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(DirectionMarker), findsNWidgets(2));
    expect(find.text('2 photos'), findsOneWidget);

    await tester.tap(find.byType(DirectionMarker).first);
    await tester.pump();

    // The preview card is now visible and offers to close/open the photo.
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    expect(find.byIcon(Icons.close), findsNothing);
  });
}
