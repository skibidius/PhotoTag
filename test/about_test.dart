import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:phototag/l10n/app_localizations.dart';
import 'package:phototag/screens/about_screen.dart';

void main() {
  testWidgets('About screen opens the open-source licenses page', (
    WidgetTester tester,
  ) async {
    PackageInfo.setMockInitialValues(
      appName: 'PhotoTag',
      packageName: 'com.phototag',
      version: '1.9.0',
      buildNumber: '23',
      buildSignature: '',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open source licenses'), findsOneWidget);
    expect(find.textContaining('© 2026 PhotoTag'), findsOneWidget);

    await tester.tap(find.text('Open source licenses'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Licenses'), findsWidgets);
  });
}
