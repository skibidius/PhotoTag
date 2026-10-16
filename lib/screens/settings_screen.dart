import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../services/settings_controller.dart';
import '../utils/coords.dart';
import '../utils/page_route.dart';
import 'about_screen.dart';

/// Full settings surface, grouped into logical sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  String _coordLabel(AppLocalizations l10n, CoordFormat f) {
    switch (f) {
      case CoordFormat.decimal:
        return l10n.coordDecimal;
      case CoordFormat.dms:
        return l10n.coordDms;
      case CoordFormat.ddm:
        return l10n.coordDdm;
      case CoordFormat.utm:
        return l10n.coordUtm;
      case CoordFormat.mgrs:
        return l10n.coordMgrs;
    }
  }

  String _languageLabel(AppLocalizations l10n, AppLanguage language) {
    switch (language) {
      case AppLanguage.system:
        return l10n.languageSystem;
      case AppLanguage.english:
        return l10n.languageEnglish;
      case AppLanguage.russian:
        return l10n.languageRussian;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final AppSettings settings = controller.value;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          _Header(l10n.sectionCoordinates),
          _PickerTile<CoordFormat>(
            icon: Icons.pin_drop_outlined,
            label: l10n.coordFormat,
            value: settings.coordFormat,
            options: CoordFormat.values
                .map((CoordFormat f) => (f, _coordLabel(l10n, f)))
                .toList(),
            onChanged: (CoordFormat v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(coordFormat: v));
            },
          ),

          _Header(l10n.sectionAppearance),
          _Segmented<StampStyle>(
            label: l10n.stampStyle,
            value: settings.stampStyle,
            options: <(StampStyle, String)>[
              (StampStyle.card, l10n.styleCard),
              (StampStyle.minimal, l10n.styleMinimal),
              (StampStyle.outline, l10n.styleOutline),
            ],
            onChanged: (StampStyle v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampStyle: v));
            },
          ),
          const SizedBox(height: 8),
          _PositionPicker(
            label: l10n.stampPosition,
            value: settings.stampPosition,
            onChanged: (StampPosition v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampPosition: v));
            },
          ),
          _Segmented<StampSize>(
            label: l10n.stampSize,
            value: settings.stampSize,
            options: <(StampSize, String)>[
              (StampSize.small, l10n.sizeSmall),
              (StampSize.medium, l10n.sizeMedium),
              (StampSize.large, l10n.sizeLarge),
            ],
            onChanged: (StampSize v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampSize: v));
            },
          ),
          _Segmented<StampTone>(
            label: l10n.stampTone,
            value: settings.stampTone,
            options: <(StampTone, String)>[
              (StampTone.light, l10n.toneLight),
              (StampTone.dark, l10n.toneDark),
            ],
            onChanged: (StampTone v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampTone: v));
            },
          ),
          ListTile(
            leading: const Icon(Icons.opacity_outlined),
            title: Text(l10n.stampOpacity((settings.opacity * 100).round())),
            subtitle: Slider(
              value: settings.opacity,
              min: 0.3,
              max: 1.0,
              onChanged: (double v) =>
                  controller.update((AppSettings s) => s.copyWith(opacity: v)),
            ),
          ),

          _Header(l10n.sectionFields),
          _Toggle(
            icon: Icons.calendar_today_outlined,
            label: l10n.fieldDateTime,
            value: settings.showDate && settings.showTime,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update(
                  (AppSettings s) => s.copyWith(showDate: v, showTime: v));
            },
          ),
          _Toggle(
            icon: Icons.place_outlined,
            label: l10n.fieldCoordinates,
            value: settings.showCoordinates,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller
                  .update((AppSettings s) => s.copyWith(showCoordinates: v));
            },
          ),
          _Toggle(
            icon: Icons.navigation_outlined,
            label: l10n.fieldBearing,
            value: settings.showBearing,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showBearing: v));
            },
          ),
          _Toggle(
            icon: Icons.height_outlined,
            label: l10n.fieldAltitude,
            value: settings.showAltitude,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAltitude: v));
            },
          ),
          _Toggle(
            icon: Icons.gps_fixed,
            label: l10n.fieldAccuracy,
            value: settings.showAccuracy,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAccuracy: v));
            },
          ),
          _Toggle(
            icon: Icons.signpost_outlined,
            label: l10n.fieldAddress,
            value: settings.showAddress,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAddress: v));
            },
          ),
          _Toggle(
            icon: Icons.tag,
            label: l10n.fieldPhotoNumber,
            value: settings.showCounter,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showCounter: v));
            },
          ),

          _Header(l10n.sectionDetails),
          _TextField(
            icon: Icons.notes_outlined,
            label: l10n.detailsNote,
            hint: l10n.detailsNoteHint,
            value: settings.note,
            onChanged: (String v) => controller.update(
                (AppSettings s) => s.copyWith(note: v, showNote: v.isNotEmpty)),
          ),
          _TextField(
            icon: Icons.person_outline,
            label: l10n.detailsAuthor,
            hint: l10n.detailsAuthorHint,
            value: settings.author,
            onChanged: (String v) => controller.update((AppSettings s) =>
                s.copyWith(author: v, showAuthor: v.isNotEmpty)),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(l10n.detailsCounter),
            subtitle: Text(l10n
                .detailsNextNumber(settings.counter.toString().padLeft(3, '0'))),
            trailing: IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: l10n.detailsResetCounter,
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.update((AppSettings s) => s.copyWith(counter: 1));
              },
            ),
          ),

          _Header(l10n.sectionCamera),
          _Toggle(
            icon: Icons.grid_4x4,
            label: l10n.cameraGridSetting,
            value: settings.showGrid,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showGrid: v));
            },
          ),
          _Toggle(
            icon: Icons.visibility_outlined,
            label: l10n.cameraHud,
            value: settings.showHud,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showHud: v));
            },
          ),
          _Toggle(
            icon: Icons.high_quality_outlined,
            label: l10n.cameraMaxResolution,
            subtitle: l10n.cameraMaxResolutionHint,
            value: settings.highResolution,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(highResolution: v));
            },
          ),
          _Toggle(
            icon: Icons.layers_outlined,
            label: l10n.cameraKeepOriginal,
            subtitle: l10n.cameraKeepOriginalHint,
            value: settings.saveOriginal,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(saveOriginal: v));
            },
          ),

          _Header(l10n.language),
          _PickerTile<AppLanguage>(
            icon: Icons.language,
            label: l10n.language,
            value: settings.language,
            options: AppLanguage.values
                .map((AppLanguage l) => (l, _languageLabel(l10n, l)))
                .toList(),
            onChanged: (AppLanguage v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(language: v));
            },
          ),

          _Header(l10n.sectionAbout),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appTitle),
            subtitle: Text(l10n.appTagline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              sharedAxisRoute(const AboutScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _PickerTile<T> extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  String get _currentLabel =>
      options.firstWhere((o) => o.$1 == value, orElse: () => options.first).$2;

  Future<void> _pick(BuildContext context) async {
    final T? result = await showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            for (final (T, String) option in options)
              ListTile(
                title: Text(option.$2),
                trailing:
                    option.$1 == value ? const Icon(Icons.check) : null,
                onTap: () => Navigator.of(context).pop(option.$1),
              ),
          ],
        ),
      ),
    );
    if (result != null && result != value) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(
        _currentLabel,
        style: TextStyle(color: Theme.of(context).colorScheme.primary),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _pick(context),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label),
      subtitle: subtitle == null ? null : Text(subtitle!),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: SegmentedButton<T>(
              segments: options
                  .map(((T, String) o) =>
                      ButtonSegment<T>(value: o.$1, label: Text(o.$2)))
                  .toList(),
              selected: <T>{value},
              onSelectionChanged: (Set<T> s) => onChanged(s.first),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionPicker extends StatelessWidget {
  const _PositionPicker({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final StampPosition value;
  final ValueChanged<StampPosition> onChanged;

  static const List<StampPosition> _order = <StampPosition>[
    StampPosition.topLeft,
    StampPosition.topCenter,
    StampPosition.topRight,
    StampPosition.bottomLeft,
    StampPosition.bottomCenter,
    StampPosition.bottomRight,
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.8,
            children: _order.map((StampPosition p) {
              final bool selected = p == value;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onChanged(p),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHighest,
                    border: Border.all(
                      color: selected ? scheme.primary : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  alignment: p.alignment,
                  padding: const EdgeInsets.all(6),
                  child: Container(
                    width: 18,
                    height: 12,
                    decoration: BoxDecoration(
                      color: selected ? scheme.primary : scheme.outline,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_TextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep in sync if the value changes elsewhere, without disturbing typing.
    if (widget.value != oldWidget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: Icon(widget.icon),
          border: const OutlineInputBorder(),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}
