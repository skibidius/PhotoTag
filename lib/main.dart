import 'package:flutter/foundation.dart'
    show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'models/app_settings.dart';
import 'screens/home_screen.dart';
import 'services/capture_queue.dart';
import 'services/location_service.dart';
import 'services/photo_store.dart';
import 'services/project_store.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';
import 'utils/route_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerBundledFontLicenses();
  await initializeDateFormatting();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  final SettingsController settings = SettingsController();
  final PhotoStore photos = PhotoStore();
  final ProjectStore projects = ProjectStore();
  final LocationService location = LocationService();

  await Future.wait(<Future<void>>[
    settings.load(),
    photos.load(),
    projects.load(),
  ]);

  runApp(PhotoTagApp(
    settings: settings,
    photos: photos,
    projects: projects,
    location: location,
    captureQueue: CaptureQueue(photos),
  ));
}

/// Flutter's license page collects pub-package licenses automatically, but the
/// bundled Google Sans and Roboto Mono font assets need to be registered.
void _registerBundledFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final String license =
        await rootBundle.loadString('assets/licenses/GoogleSans-OFL.txt');
    yield LicenseEntryWithLineBreaks(const <String>['Google Sans'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final String license =
        await rootBundle.loadString('assets/licenses/RobotoMono-OFL.txt');
    yield LicenseEntryWithLineBreaks(const <String>['Roboto Mono'], license);
  });
  LicenseRegistry.addLicense(() async* {
    final String license = await rootBundle
        .loadString('assets/licenses/MaterialIcons-CC-BY-4.0.txt');
    yield LicenseEntryWithLineBreaks(const <String>['Material Icons'], license);
  });
}

class PhotoTagApp extends StatelessWidget {
  const PhotoTagApp({
    super.key,
    required this.settings,
    required this.photos,
    required this.projects,
    required this.location,
    required this.captureQueue,
  });

  final SettingsController settings;
  final PhotoStore photos;
  final ProjectStore projects;
  final LocationService location;
  final CaptureQueue captureQueue;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<PhotoStore>.value(value: photos),
        ChangeNotifierProvider<ProjectStore>.value(value: projects),
        ChangeNotifierProvider<LocationService>.value(value: location),
        ChangeNotifierProvider<CaptureQueue>.value(value: captureQueue),
      ],
      child: Consumer<SettingsController>(
        builder: (BuildContext context, SettingsController controller, _) {
          return MaterialApp(
            title: 'PhotoTag',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.system,
            locale: _localeFor(controller.value.language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            navigatorObservers: <NavigatorObserver>[routeObserver],
            home: const HomeScreen(),
          );
        },
      ),
    );
  }

  Locale? _localeFor(AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return null;
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.russian:
        return const Locale('ru');
    }
  }
}
