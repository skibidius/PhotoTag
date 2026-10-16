import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:phototag/l10n/app_localizations.dart';
import 'package:phototag/models/app_settings.dart';
import 'package:phototag/models/photo_record.dart';
import 'package:phototag/widgets/stamp_overlay.dart';

void main() {
  testWidgets('StampOverlay renders coordinate and bearing text', (WidgetTester tester) async {
    const AppSettings settings = AppSettings();
    final StampContext ctx = StampContext(
      timestamp: DateTime(2026, 10, 16, 12, 0, 0),
      latitude: 55.7558,
      longitude: 37.6173,
      bearing: 315,
      altitude: 156,
      accuracy: 5,
      counter: 7,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: StampOverlay(
            settings: settings,
            data: ctx,
            accent: Colors.teal,
          ),
        ),
      ),
    );

    expect(find.textContaining('55.755800'), findsOneWidget);
    expect(find.textContaining('315°'), findsOneWidget);
    expect(find.textContaining('№ 007'), findsOneWidget);
  });
}
