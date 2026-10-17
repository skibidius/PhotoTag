import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

/// A snapshot of the device's position and heading at a point in time.
class LocationFix {
  const LocationFix({
    this.latitude,
    this.longitude,
    this.altitude,
    this.accuracy,
    this.heading,
    required this.timestamp,
  });

  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? accuracy;
  final double? heading;
  final DateTime timestamp;

  bool get hasLocation => latitude != null && longitude != null;
}

/// Combines the GPS position stream with the magnetometer so the camera always
/// has a fresh fix and a compass bearing, even while standing still.
class LocationService extends ChangeNotifier {
  Position? _position;
  double? _compassHeading;

  StreamSubscription<Position>? _positionSub;
  StreamSubscription<CompassEvent>? _compassSub;

  bool _serviceEnabled = false;
  bool _permissionGranted = false;
  bool _running = false;

  bool get serviceEnabled => _serviceEnabled;
  bool get permissionGranted => _permissionGranted;
  bool get running => _running;

  LocationFix? get fix {
    final Position? p = _position;
    if (p == null) return null;
    final double? heading = _compassHeading ??
        ((p.heading > 0 && p.heading <= 360) ? p.heading : null);
    return LocationFix(
      latitude: p.latitude,
      longitude: p.longitude,
      altitude: p.altitude,
      accuracy: p.accuracy,
      heading: heading,
      timestamp: p.timestamp,
    );
  }

  /// Starts the GPS and compass streams. Returns false when location services
  /// are off or permission was denied, so the caller can prompt the user.
  Future<bool> start() async {
    if (_running) return true;

    // Ask for permission before checking whether services are enabled, so the
    // system prompt always appears on first launch.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    _permissionGranted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (!_permissionGranted) return false;

    _serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_serviceEnabled) return false;

    _running = true;

    try {
      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (event.heading != null) {
          _compassHeading = event.heading;
          notifyListeners();
        }
      });
    } catch (_) {
      // Compass is optional; heading simply stays null if unavailable.
    }

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position position) {
      _position = position;
      notifyListeners();
    }, onError: (Object _) {
      // A transient GPS error should not tear down the service.
    });

    return true;
  }

  /// Requests a single high-accuracy fix, used to refresh the position right
  /// before a photo is captured.
  Future<Position?> refresh() async {
    if (!_permissionGranted || !_serviceEnabled) return null;
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 6),
        ),
      );
      _position = position;
      notifyListeners();
      return position;
    } catch (_) {
      return null;
    }
  }

  /// Opens the most relevant settings screen: the system location toggle when
  /// location services are off, otherwise the app's own permission screen.
  Future<void> openSettings() async {
    if (!_serviceEnabled) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _compassSub?.cancel();
    super.dispose();
  }
}
