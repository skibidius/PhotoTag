import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';

/// A small About screen with the app icon, name, version and license.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo info) {
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.about)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: <Widget>[
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF009586), Color(0xFF004940)],
                ),
              ),
              child: const Icon(Icons.place, color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.appTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (_version.isNotEmpty)
            Center(
              child: Text(
                '${l10n.aboutVersion} $_version',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.outline),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.appTagline,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.balance_outlined),
            title: Text(l10n.aboutLicense),
            trailing: Text(l10n.aboutLicenseValue),
          ),
          const _UpdateTile(),
        ],
      ),
    );
  }
}

class _UpdateTile extends StatefulWidget {
  const _UpdateTile();

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  bool _checking = true;
  UpdateInfo? _update;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check({bool manual = false}) async {
    setState(() => _checking = true);
    final UpdateInfo? info = await UpdateService.check();
    if (!mounted) return;
    setState(() {
      _update = info;
      _checking = false;
    });
    if (info == null && manual) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).upToDate)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    if (_checking) {
      return ListTile(
        leading: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(l10n.checkingUpdates),
      );
    }

    final UpdateInfo? update = _update;
    if (update != null) {
      return ListTile(
        leading: const Icon(Icons.system_update_outlined),
        title: Text(l10n.updateAvailable(update.version)),
        trailing: FilledButton(
          onPressed: () => UpdateService.openUpdate(update),
          child: Text(l10n.update),
        ),
      );
    }

    return ListTile(
      leading: const Icon(Icons.refresh),
      title: Text(l10n.checkForUpdates),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _check(manual: true),
    );
  }
}
