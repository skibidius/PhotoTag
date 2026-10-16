import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/location_service.dart';
import 'services/photo_store.dart';
import 'services/project_store.dart';
import 'services/settings_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  ));
}

class PhotoTagApp extends StatelessWidget {
  const PhotoTagApp({
    super.key,
    required this.settings,
    required this.photos,
    required this.projects,
    required this.location,
  });

  final SettingsController settings;
  final PhotoStore photos;
  final ProjectStore projects;
  final LocationService location;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<PhotoStore>.value(value: photos),
        ChangeNotifierProvider<ProjectStore>.value(value: projects),
        ChangeNotifierProvider<LocationService>.value(value: location),
      ],
      child: MaterialApp(
        title: 'PhotoTag',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
