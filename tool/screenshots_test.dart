// Screenshot generator: renders the real app screens to PNG via golden tests.
//
// Run manually (not part of CI):
//   flutter test tool/screenshots_test.dart --update-goldens
//
// Output: docs/screenshots/*.png
// ignore_for_file: invalid_use_of_visible_for_testing_member, unused_element_parameter
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:phototag/models/app_settings.dart';
import 'package:phototag/models/photo_record.dart';
import 'package:phototag/screens/projects_screen.dart';
import 'package:phototag/screens/settings_screen.dart';
import 'package:phototag/services/photo_store.dart';
import 'package:phototag/services/project_store.dart';
import 'package:phototag/services/settings_controller.dart';
import 'package:phototag/theme/app_theme.dart';
import 'package:phototag/widgets/stamp_overlay.dart';

String _flutterRoot() {
  final String? env = Platform.environment['FLUTTER_ROOT'];
  if (env != null && Directory(env).existsSync()) return env;
  for (final String p in <String>[
    '/opt/homebrew/share/flutter',
    '/usr/local/share/flutter',
  ]) {
    if (Directory(p).existsSync()) return p;
  }
  return '';
}

Future<void> _loadFonts() async {
  ByteData fileBytes(String path) =>
      ByteData.sublistView(File(path).readAsBytesSync());

  final FontLoader gs = FontLoader('GoogleSans')
    ..addFont(Future<ByteData>.value(fileBytes('assets/fonts/GoogleSans-Regular.ttf')))
    ..addFont(Future<ByteData>.value(fileBytes('assets/fonts/GoogleSans-Medium.ttf')))
    ..addFont(Future<ByteData>.value(fileBytes('assets/fonts/GoogleSans-Bold.ttf')));
  await gs.load();

  final FontLoader mono = FontLoader('RobotoMono')
    ..addFont(Future<ByteData>.value(fileBytes('assets/fonts/RobotoMono-Regular.ttf')))
    ..addFont(Future<ByteData>.value(fileBytes('assets/fonts/RobotoMono-Medium.ttf')));
  await mono.load();

  final String iconsDir = '${_flutterRoot()}/bin/cache/artifacts/material_fonts';
  if (Directory(iconsDir).existsSync()) {
    final FontLoader icons = FontLoader('MaterialIcons')
      ..addFont(Future<ByteData>.value(
          fileBytes('$iconsDir/MaterialIcons-Regular.otf')));
    await icons.load();
  }
}

Future<void> _render(
  WidgetTester tester, {
  required Widget screen,
  required String golden,
}) async {
  tester.view.physicalSize = const Size(780, 1688);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(find.byType(MaterialApp), matchesGoldenFile(golden));
}

// -----------------------------------------------------------------------------
// Demo data
// -----------------------------------------------------------------------------

AppSettings _demoSettings() => const AppSettings(
      note: 'Facade inspection',
      author: 'A. Volkov',
      showNote: true,
      showAuthor: true,
      counter: 42,
    );

StampContext _demoContext() => StampContext(
      timestamp: DateTime(2026, 10, 16, 14, 32, 5),
      latitude: 55.7558,
      longitude: 37.6173,
      bearing: 315,
      altitude: 156,
      accuracy: 5,
      address: 'Tverskaya St, 1, Moscow',
      project: 'North wing',
      note: 'Facade inspection',
      author: 'A. Volkov',
      counter: 42,
    );

// -----------------------------------------------------------------------------
// Scene painter (a fake "photo")
// -----------------------------------------------------------------------------

class _ScenePainter extends CustomPainter {
  const _ScenePainter(this.seed);

  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final double h = size.height;
    final double w = size.width;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.62),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.center,
          colors: <Color>[
            HSLColor.fromAHSL(1, 205 - seed * 4, 0.72, 0.78).toColor(),
            const Color(0xFFEAF5FB),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.62)),
    );

    canvas.drawCircle(
      Offset(w * 0.78, h * 0.16),
      h * 0.055,
      Paint()..color = const Color(0xFFFFE0A3),
    );

    final Path farHill = Path()
      ..moveTo(0, h * 0.56)
      ..quadraticBezierTo(w * 0.35, h * 0.36, w, h * 0.58)
      ..lineTo(w, h * 0.62)
      ..lineTo(0, h * 0.62)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()..color = HSLColor.fromAHSL(1, 160 - seed * 3, 0.35, 0.52).toColor(),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.6, w, h * 0.4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            HSLColor.fromAHSL(1, 120 - seed * 5, 0.38, 0.48).toColor(),
            HSLColor.fromAHSL(1, 130 - seed * 5, 0.30, 0.24).toColor(),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.6, w, h * 0.4)),
    );
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) =>
      oldDelegate.seed != seed;
}

class _Scene extends StatelessWidget {
  const _Scene({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ScenePainter(seed), size: Size.infinite);
}

// -----------------------------------------------------------------------------
// Camera mock
// -----------------------------------------------------------------------------

class _CameraMock extends StatelessWidget {
  const _CameraMock({
    required this.settings,
    required this.data,
    required this.accent,
  });

  final AppSettings settings;
  final StampContext data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _Scene(seed: 1),
          Align(
            alignment: settings.stampPosition.alignment,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: settings.stampPosition.alignment,
                  child: StampOverlay(settings: settings, data: data, accent: accent),
                ),
              ),
            ),
          ),
          _topBar(),
          _bottomControls(),
        ],
      ),
    );
  }

  Widget _topBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal:12, vertical: 8),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.folder_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text('North wing', style: TextStyle(color: Colors.white, fontSize: 13)),
                  Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                ],
              ),
            ),
            const Spacer(),
            _pill(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const <Widget>[
                  Icon(Icons.gps_fixed, size: 16, color: Color(0xFF4FD1C5)),
                  SizedBox(width: 6),
                  Text('±5 m', style: TextStyle(color: Colors.white, fontSize: 12)),
                  SizedBox(width: 8),
                  Icon(Icons.navigation, size: 14, color: Colors.white70),
                  Text('315°', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            _circle(child: const Icon(Icons.grid_4x4, color: Colors.white)),
            _circle(child: const Icon(Icons.settings_outlined, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _bottomControls() {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: Row(
            children: <Widget>[
              _circle(child: const Icon(Icons.flash_off_outlined, color: Colors.white)),
              const Spacer(),
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _circle(child: const Icon(Icons.cameraswitch_outlined, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circle({required Widget child}) => Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 44, height: 44, child: child),
      );

  Widget _pill(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: child,
      );
}

// -----------------------------------------------------------------------------
// Watermark shot
// -----------------------------------------------------------------------------

class _WatermarkShot extends StatelessWidget {
  const _WatermarkShot({
    required this.settings,
    required this.data,
    required this.accent,
  });

  final AppSettings settings;
  final StampContext data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _Scene(seed: 2),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.82,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomLeft,
                  child: StampOverlay(settings: settings, data: data, accent: accent),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Gallery mock
// -----------------------------------------------------------------------------

class _GalleryMock extends StatelessWidget {
  const _GalleryMock({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photos · 6')),
      body: GridView.builder(
        padding: const EdgeInsets.all(4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
        ),
        itemCount: 6,
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _Scene(seed: index + 2),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '55.7558° N',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Entrypoint
// -----------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await _loadFonts();
  });

  final Color accent = AppTheme.light().colorScheme.primary;

  testWidgets('camera', (WidgetTester tester) async {
    await _render(
      tester,
      screen: _CameraMock(
        settings: _demoSettings(),
        data: _demoContext(),
        accent: accent,
      ),
      golden: '../docs/screenshots/camera.png',
    );
  });

  testWidgets('watermark', (WidgetTester tester) async {
    await _render(
      tester,
      screen: _WatermarkShot(
        settings: _demoSettings(),
        data: _demoContext(),
        accent: accent,
      ),
      golden: '../docs/screenshots/watermark.png',
    );
  });

  testWidgets('projects', (WidgetTester tester) async {
    final ProjectStore projects = ProjectStore();
    await projects.add('North wing');
    await projects.add('Site survey');
    await projects.add('Client — Acme');

    final PhotoStore photos = PhotoStore();
    photos.debugSetRecords(<PhotoRecord>[
      PhotoRecord(
        id: 'a',
        path: '',
        thumbPath: '',
        takenAt: DateTime(2026, 10, 16, 14, 0),
        project: 'North wing',
        counter: 42,
        coordText: '55.755800° N · 37.617300° E',
      ),
      PhotoRecord(
        id: 'b',
        path: '',
        thumbPath: '',
        takenAt: DateTime(2026, 10, 16, 13, 30),
        project: 'North wing',
        counter: 41,
        coordText: '55.755800° N · 37.617300° E',
      ),
      PhotoRecord(
        id: 'c',
        path: '',
        thumbPath: '',
        takenAt: DateTime(2026, 10, 15, 9, 0),
        project: 'Site survey',
        counter: 40,
        coordText: '55.755800° N · 37.617300° E',
      ),
    ]);

    await _render(
      tester,
      screen: MultiProvider(
        providers: [
          ChangeNotifierProvider<ProjectStore>.value(value: projects),
          ChangeNotifierProvider<PhotoStore>.value(value: photos),
        ],
        child: const ProjectsScreen(),
      ),
      golden: '../docs/screenshots/projects.png',
    );
  });

  testWidgets('settings', (WidgetTester tester) async {
    final SettingsController controller = SettingsController();
    await controller.load();
    await _render(
      tester,
      screen: ChangeNotifierProvider<SettingsController>.value(
        value: controller,
        child: const SettingsScreen(),
      ),
      golden: '../docs/screenshots/settings.png',
    );
  });

  testWidgets('gallery', (WidgetTester tester) async {
    await _render(
      tester,
      screen: const _GalleryMock(),
      golden: '../docs/screenshots/gallery.png',
    );
  });
}
