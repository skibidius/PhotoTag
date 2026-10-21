import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Store flavor baked in with `--dart-define=PHOTOTAG_STORE=rustore`.
///
/// The regular (GitHub / AltStore) build keeps checking GitHub Releases. The
/// RuStore build uses the official RuStore In-App Updates SDK instead, so it
/// never offers an APK from a different store.
const String _storeFlavor =
    String.fromEnvironment('PHOTOTAG_STORE', defaultValue: 'github');

const bool isRuStoreBuild = _storeFlavor == 'rustore';

/// Information about an available update.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.tag,
    required this.releaseUrl,
    this.buildNumber,
    this.ruStore = false,
  });

  final String version;
  final String tag;
  final String releaseUrl;
  final int? buildNumber;
  final bool ruStore;
}

/// Checks for updates in the store the build came from and starts the right
/// update flow.
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
  static const String ruStoreAppUrl =
      'https://www.rustore.ru/catalog/app/com.phototag';

  /// Returns the newer release, or null when already up to date / offline.
  static Future<UpdateInfo?> check() async {
    if (isRuStoreBuild) return _checkRuStore();
    return _checkGitHub();
  }

  /// RuStore exposes the published version of a package on its public
  /// catalog backend. The regular GitHub API is deliberately not used here:
  /// a RuStore build must never offer an APK from another store.
  static Future<UpdateInfo?> _checkRuStore() async {
    try {
      final http.Response response = await http.get(
        Uri.parse(
            'https://backapi.rustore.ru/applicationData/overallInfo/com.phototag'),
        headers: const <String, String>{
          // A RuStore client version is required by the catalog backend.
          'ruStoreVerCode': '12000',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data =
          jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> body = <String, dynamic>{
        ...?data['body'] as Map<String, dynamic>?,
      };
      final int latestCode = (body['versionCode'] as num?)?.toInt() ??
          (body['activeVerCode'] as num?)?.toInt() ??
          0;
      if (latestCode <= 0) return null;

      final PackageInfo info = await PackageInfo.fromPlatform();
      final int current = int.tryParse(info.buildNumber) ?? 0;
      if (latestCode <= current) return null;

      return UpdateInfo(
        version: body['versionName'] as String? ?? '',
        tag: '',
        releaseUrl: ruStoreAppUrl,
        buildNumber: latestCode,
        ruStore: true,
      );
    } catch (_) {
      // The catalog backend is best-effort; never block startup.
      return null;
    }
  }

  static Future<UpdateInfo?> _checkGitHub() async {
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
        buildNumber: int.tryParse(info.buildNumber),
      );
    } catch (_) {
      // Offline or rate-limited: treat as "no update".
      return null;
    }
  }

  /// Starts the update flow for the build's own store.
  static Future<void> openUpdate(UpdateInfo info) async {
    if (info.ruStore) {
      await _openUrl(ruStoreAppUrl);
      return;
    }

    final bool ios = defaultTargetPlatform == TargetPlatform.iOS;
    await _openUrl(ios ? info.releaseUrl : apkUrl);
  }

  static Future<void> _openUrl(String url) async {
    try {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
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
