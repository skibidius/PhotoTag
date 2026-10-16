import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages the list of projects and the currently active project. Photos are
/// tagged with the active project when captured.
class ProjectStore extends ChangeNotifier {
  static const String _projectsKey = 'projects.v1';
  static const String _activeKey = 'projects.active';

  List<String> _projects = <String>[];
  String? _active;

  List<String> get projects => List<String>.unmodifiable(_projects);
  String? get active => _active;

  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _projects = (prefs.getStringList(_projectsKey) ?? <String>[]).toList();
      _active = prefs.getString(_activeKey);
      if (_active != null && !_projects.contains(_active)) _active = null;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> add(String name) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty || _projects.contains(trimmed)) return;
    _projects.add(trimmed);
    _active = trimmed;
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String name) async {
    _projects.remove(name);
    if (_active == name) _active = null;
    notifyListeners();
    await _persist();
  }

  Future<void> setActive(String? name) async {
    _active = name;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_projectsKey, _projects);
      if (_active == null) {
        await prefs.remove(_activeKey);
      } else {
        await prefs.setString(_activeKey, _active!);
      }
    } catch (_) {}
  }
}
