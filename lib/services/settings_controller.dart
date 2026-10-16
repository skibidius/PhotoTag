import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

/// Holds the current [AppSettings] and persists every change to disk.
///
/// Writes are debounced so rapid updates (dragging a slider, typing) stay
/// smooth instead of hitting disk on every change.
class SettingsController extends ChangeNotifier {
  static const String _key = 'settings.v1';

  AppSettings _value = const AppSettings();
  AppSettings get value => _value;

  bool _loaded = false;
  bool get loaded => _loaded;

  Timer? _saveTimer;

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_key);
      if (raw != null) {
        _value = AppSettings.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );
      }
    } catch (_) {
      // Fall back to defaults if the stored settings are unreadable.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(AppSettings Function(AppSettings) transform) async {
    _value = transform(_value);
    notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _persist);
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_value.toJson()));
    } catch (_) {
      // Persistence is best-effort; a failed write must never break capture.
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
