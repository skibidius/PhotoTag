import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../services/settings_controller.dart';
import '../utils/coords.dart';

/// Full settings surface, grouped into logical sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController controller = context.watch<SettingsController>();
    final AppSettings settings = controller.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          const _Header('Coordinates'),
          ListTile(
            leading: const Icon(Icons.pin_drop_outlined),
            title: const Text('Format'),
            trailing: DropdownButton<CoordFormat>(
              value: settings.coordFormat,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(16),
              onChanged: (CoordFormat? v) {
                if (v != null) {
                  HapticFeedback.selectionClick();
                  controller.update((AppSettings s) => s.copyWith(coordFormat: v));
                }
              },
              items: CoordFormat.values
                  .map((CoordFormat f) =>
                      DropdownMenuItem<CoordFormat>(value: f, child: Text(f.label)))
                  .toList(),
            ),
          ),

          const _Header('Stamp appearance'),
          _Segmented<StampStyle>(
            label: 'Style',
            value: settings.stampStyle,
            options: const <(StampStyle, String)>[
              (StampStyle.card, 'Card'),
              (StampStyle.minimal, 'Minimal'),
              (StampStyle.outline, 'Outline'),
            ],
            onChanged: (StampStyle v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampStyle: v));
            },
          ),
          const SizedBox(height: 8),
          _PositionPicker(
            value: settings.stampPosition,
            onChanged: (StampPosition v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampPosition: v));
            },
          ),
          _Segmented<StampSize>(
            label: 'Size',
            value: settings.stampSize,
            options: const <(StampSize, String)>[
              (StampSize.small, 'S'),
              (StampSize.medium, 'M'),
              (StampSize.large, 'L'),
            ],
            onChanged: (StampSize v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampSize: v));
            },
          ),
          _Segmented<StampTone>(
            label: 'Text colour',
            value: settings.stampTone,
            options: const <(StampTone, String)>[
              (StampTone.light, 'Light'),
              (StampTone.dark, 'Dark'),
            ],
            onChanged: (StampTone v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(stampTone: v));
            },
          ),
          ListTile(
            leading: const Icon(Icons.opacity_outlined),
            title: const Text('Background opacity'),
            subtitle: Slider(
              value: settings.opacity,
              min: 0.3,
              max: 1.0,
              onChanged: (double v) =>
                  controller.update((AppSettings s) => s.copyWith(opacity: v)),
            ),
          ),

          const _Header('Stamp fields'),
          _Toggle(
            icon: Icons.calendar_today_outlined,
            label: 'Date & time',
            value: settings.showDate && settings.showTime,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) =>
                  s.copyWith(showDate: v, showTime: v));
            },
          ),
          _Toggle(
            icon: Icons.place_outlined,
            label: 'Coordinates',
            value: settings.showCoordinates,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showCoordinates: v));
            },
          ),
          _Toggle(
            icon: Icons.navigation_outlined,
            label: 'Compass bearing',
            value: settings.showBearing,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showBearing: v));
            },
          ),
          _Toggle(
            icon: Icons.height_outlined,
            label: 'Altitude',
            value: settings.showAltitude,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAltitude: v));
            },
          ),
          _Toggle(
            icon: Icons.gps_fixed,
            label: 'Accuracy',
            value: settings.showAccuracy,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAccuracy: v));
            },
          ),
          _Toggle(
            icon: Icons.signpost_outlined,
            label: 'Address',
            value: settings.showAddress,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showAddress: v));
            },
          ),
          _Toggle(
            icon: Icons.tag,
            label: 'Photo number',
            value: settings.showCounter,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showCounter: v));
            },
          ),

          const _Header('Details'),
          _TextField(
            icon: Icons.notes_outlined,
            label: 'Note',
            hint: 'e.g. Foundation inspection',
            value: settings.note,
            onChanged: (String v) => controller
                .update((AppSettings s) => s.copyWith(note: v, showNote: v.isNotEmpty)),
          ),
          _TextField(
            icon: Icons.person_outline,
            label: 'Author',
            hint: 'Your name or company',
            value: settings.author,
            onChanged: (String v) => controller
                .update((AppSettings s) => s.copyWith(author: v, showAuthor: v.isNotEmpty)),
          ),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Photo counter'),
            subtitle: Text('Next photo will be № ${settings.counter.toString().padLeft(3, '0')}'),
            trailing: IconButton(
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Reset counter',
              onPressed: () {
                HapticFeedback.selectionClick();
                controller.update((AppSettings s) => s.copyWith(counter: 1));
              },
            ),
          ),

          const _Header('Camera'),
          _Toggle(
            icon: Icons.grid_4x4,
            label: 'Rule-of-thirds grid',
            value: settings.showGrid,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showGrid: v));
            },
          ),
          _Toggle(
            icon: Icons.visibility_outlined,
            label: 'Live stamp preview',
            value: settings.showHud,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(showHud: v));
            },
          ),
          _Toggle(
            icon: Icons.high_quality_outlined,
            label: 'Maximum resolution',
            subtitle: 'Capture at the sensor\'s full resolution',
            value: settings.highResolution,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(highResolution: v));
            },
          ),
          _Toggle(
            icon: Icons.layers_outlined,
            label: 'Keep original copy',
            subtitle: 'Also save the photo without the stamp',
            value: settings.saveOriginal,
            onChanged: (bool v) {
              HapticFeedback.selectionClick();
              controller.update((AppSettings s) => s.copyWith(saveOriginal: v));
            },
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
            width: 120,
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
  const _PositionPicker({required this.value, required this.onChanged});

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
          Text('Position', style: Theme.of(context).textTheme.bodyMedium),
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

class _TextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: TextField(
        controller: TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const UnderlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
