import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Information about a newer release published on GitHub.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tag,
    required this.releaseUrl,
  });

  final String version;
  final String tag;
  final String releaseUrl;
}

/// Checks GitHub Releases for a newer version and opens the right download.
class UpdateService {
  UpdateService._();

  static const String _owner = 'skibidius';
  static const String _repo = 'PhotoTag';

  static const String apkUrl =
      'https://github.com/$_owner/$_repo/releases/latest/download/phototag.apk';
  static const String ipaUrl =
      'https://github.com/$_owner/$_repo/releases/latest/download/phototag.ipa';
  static const String altStoreSource =
      'https://raw.githubusercontent.com/$_owner/$_repo/altstore/altstore.json';

  /// Returns the newer release, or null when already up to date / offline.
  static Future<UpdateInfo?> check() async {
    try {
      final http.Response response = await http
          .get(
            Uri.parse(
                'https://api.github.com/repos/$_owner/$_repo/releases/latest'),
            headers: const <String, String>{
              'Accept': 'application/vnd.github+json',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final String tag = (data['tag_name'] as String? ?? '').trim();
      final String latest = tag.replaceFirst(RegExp(r'^v'), '');
      if (latest.isEmpty) return null;

      final PackageInfo info = await PackageInfo.fromPlatform();
      if (!_isNewer(latest, info.version)) return null;

      return UpdateInfo(
        version: latest,
        tag: tag,
        releaseUrl: data['html_url'] as String? ??
            'https://github.com/$_owner/$_repo/releases/latest',
      );
    } catch (_) {
      // Offline or rate-limited: treat as "no update".
      return null;
    }
  }

  /// Opens the APK on Android and the release page on iOS (install via
  /// AltStore).
  static Future<void> openUpdate(UpdateInfo info) async {
    final bool ios = defaultTargetPlatform == TargetPlatform.iOS;
    final Uri uri = Uri.parse(ios ? info.releaseUrl : apkUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static bool _isNewer(String candidate, String current) {
    final List<int> a = _parts(candidate);
    final List<int> b = _parts(current);
    for (int i = 0; i < a.length || i < b.length; i++) {
      final int x = i < a.length ? a[i] : 0;
      final int y = i < b.length ? b[i] : 0;
      if (x > y) return true;
      if (x < y) return false;
    }
    return false;
  }

  static List<int> _parts(String version) => version
      .split('+')
      .first
      .split('.')
      .map((String p) => int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
      .toList();
}
