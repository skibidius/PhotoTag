import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/basemaps.dart';

/// Shows a grouped list of available basemaps and returns the selected key.
Future<String?> showBasemapPicker(
  BuildContext context,
  String currentKey,
) {
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final AppLocalizations l10n = AppLocalizations.of(context);
      final ColorScheme scheme = Theme.of(context).colorScheme;
      final String locale = Localizations.localeOf(context).toString();

      final Map<String, List<BasemapDef>> groups = <String, List<BasemapDef>>{};
      for (final BasemapDef basemap in kBasemaps) {
        groups.putIfAbsent(basemap.group(locale), () => <BasemapDef>[]).add(basemap);
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 12),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  l10n.mapStyle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              for (final MapEntry<String, List<BasemapDef>> group
                  in groups.entries) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                  child: Text(
                    group.key,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                for (final BasemapDef basemap in group.value)
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: basemap.key == currentKey
                            ? scheme.primaryContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        basemap.icon,
                        color: basemap.key == currentKey
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(basemap.name(locale)),
                    trailing: basemap.key == currentKey
                        ? Icon(Icons.check, color: scheme.primary)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.of(context).pop(basemap.key);
                    },
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
