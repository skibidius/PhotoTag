import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../models/photo_record.dart';
import '../utils/formatters.dart';

/// The reference width (in logical pixels) at which the stamp is laid out.
/// Everywhere else the same widget is scaled up or down, so the on-screen
/// preview and the exported image stay pixel-identical in proportion.
const double kStampReferenceWidth = 1000.0;

/// The stamp burned onto each photo. It is a pure function of [settings] and
/// [data], which lets the same widget render the live camera HUD and the final
/// high-resolution image.
class StampOverlay extends StatelessWidget {
  const StampOverlay({
    super.key,
    required this.settings,
    required this.data,
    required this.accent,
  });

  final AppSettings settings;
  final StampContext data;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double s = _sizeScale;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final _StampPalette p = _StampPalette(settings.stampTone, settings.opacity);
    final List<Widget> lines = _lines(s, p, l10n, locale);

    if (settings.stampStyle == StampStyle.card) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kStampReferenceWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.scrim,
            borderRadius: BorderRadius.circular(28 * s),
            border: Border.all(color: p.border, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: p.dark ? 0.38 : 0.14),
                blurRadius: 46 * s,
                offset: Offset(0, 18 * s),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(height: 5 * s, color: accent),
                Padding(
                  padding: EdgeInsets.fromLTRB(32 * s, 26 * s, 32 * s, 30 * s),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: lines,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Minimal / outline: no background, just well-contrasted text.
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kStampReferenceWidth),
      child: Padding(
        padding: EdgeInsets.all(16 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines,
        ),
      ),
    );
  }

  double get _sizeScale {
    switch (settings.stampSize) {
      case StampSize.small:
        return 0.82;
      case StampSize.medium:
        return 1.0;
      case StampSize.large:
        return 1.2;
    }
  }

  List<Shadow> _shadows(double s, _StampPalette p) {
    switch (settings.stampStyle) {
      case StampStyle.card:
        return const <Shadow>[];
      case StampStyle.minimal:
        return <Shadow>[
          Shadow(
            color: p.halo.withValues(alpha: 0.6),
            blurRadius: 18 * s,
            offset: Offset(0, 3 * s),
          ),
        ];
      case StampStyle.outline:
        final Color outline = p.halo.withValues(alpha: 0.9);
        final double o = 2.4 * s;
        return <Shadow>[
          Shadow(color: outline, offset: Offset(-o, -o)),
          Shadow(color: outline, offset: Offset(o, -o)),
          Shadow(color: outline, offset: Offset(-o, o)),
          Shadow(color: outline, offset: Offset(o, o)),
          Shadow(color: outline, offset: Offset(-o, 0)),
          Shadow(color: outline, offset: Offset(o, 0)),
          Shadow(color: outline, offset: Offset(0, -o)),
          Shadow(color: outline, offset: Offset(0, o)),
        ];
    }
  }

  TextStyle _ts(
    double size,
    FontWeight weight,
    Color color,
    List<Shadow> shadows, {
    bool mono = false,
    double height = 1.25,
    double letterSpacing = 0,
  }) {
    return TextStyle(
      fontFamily: mono ? 'RobotoMono' : 'GoogleSans',
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
      letterSpacing: letterSpacing,
      shadows: shadows,
    );
  }

  List<Widget> _lines(
      double s, _StampPalette p, AppLocalizations l10n, String locale) {
    final List<Widget> lines = <Widget>[];
    final List<Shadow> shadows = _shadows(s, p);
    final bool isCard = settings.stampStyle == StampStyle.card;

    final String dateTime = _dateTimeText(locale);
    final String coords = data.coordText;
    final String meta = _metaText;
    final String address = _addressText;
    final String footer = _footerText(l10n);

    void addSpace([double factor = 1]) {
      if (lines.isNotEmpty) lines.add(SizedBox(height: 14 * s * factor));
    }

    if (dateTime.isNotEmpty) {
      lines.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 13 * s,
            height: 13 * s,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          SizedBox(width: 15 * s),
          Expanded(
            child: Text(
              dateTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _ts(40 * s, FontWeight.w600, p.text, shadows,
                  height: 1.1, letterSpacing: 0.2),
            ),
          ),
        ],
      ));
    }

    if (coords.isNotEmpty && settings.showCoordinates) {
      addSpace(1.35);
      lines.add(Text(
        coords,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _ts(34 * s, FontWeight.w500, p.text, shadows, mono: true),
      ));
    }

    if (meta.isNotEmpty) {
      addSpace(0.9);
      lines.add(Text(
        meta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _ts(27 * s, FontWeight.w400, p.secondary, shadows, mono: true),
      ));
    }

    if (address.isNotEmpty) {
      addSpace(1.25);
      lines.add(Text(
        address,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: _ts(30 * s, FontWeight.w400, p.secondary, shadows, height: 1.3),
      ));
    }

    if (footer.isNotEmpty) {
      addSpace(1.3);
      if (isCard) {
        lines.add(Container(width: double.infinity, height: 1, color: p.border));
        addSpace(1.05);
      }
      lines.add(Text(
        footer,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: _ts(30 * s, FontWeight.w400, p.secondary, shadows, height: 1.35),
      ));
    }

    if (data.counter != null && settings.showCounter) {
      addSpace(1.4);
      final Color onAccent = accent.computeLuminance() > 0.5
          ? const Color(0xFF1F1F1F)
          : Colors.white;
      lines.add(Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: isCard
                ? accent.withValues(alpha: 0.20)
                : accent.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.stampCounter(data.counter.toString().padLeft(3, '0')),
            style: _ts(24 * s, FontWeight.w500,
                isCard ? onAccent : onAccent, const <Shadow>[],
                mono: true, letterSpacing: 1),
          ),
        ),
      ));
    }

    if (lines.isEmpty) {
      lines.add(SizedBox(width: 340 * s, height: 90 * s));
    }
    return lines;
  }

  String _dateTimeText(String locale) {
    if (!settings.showDate && !settings.showTime) return '';
    if (settings.showDate && settings.showTime) {
      return Formatters.dateTime(data.timestamp, locale);
    }
    if (settings.showDate) return Formatters.date(data.timestamp, locale);
    return Formatters.time(data.timestamp, locale);
  }

  String get _addressText {
    if (!settings.showAddress) return '';
    final String? a = data.address;
    return (a == null || a.isEmpty) ? '' : a;
  }

  String _footerText(AppLocalizations l10n) {
    final List<String> parts = <String>[];
    if (data.project != null && data.project!.isNotEmpty) {
      parts.add(data.project!);
    }
    if (settings.showNote && data.note != null && data.note!.isNotEmpty) {
      parts.add(data.note!);
    }
    if (settings.showAuthor && data.author != null && data.author!.isNotEmpty) {
      parts.add(l10n.stampByAuthor(data.author!));
    }
    return parts.join('  ·  ');
  }

  String get _metaText {
    final List<String> parts = <String>[];
    if (settings.showBearing && data.bearing != null) {
      parts.add('${Formatters.cardinal(data.bearing!)} ${data.bearing!.round()}°');
    }
    if (settings.showAltitude && data.altitude != null) {
      parts.add('${data.altitude!.round()} m');
    }
    if (settings.showAccuracy && data.accuracy != null) {
      parts.add('±${data.accuracy!.round()} m');
    }
    return parts.join(' · ');
  }
}

/// Colours for the two stamp tones.
class _StampPalette {
  _StampPalette(StampTone tone, double opacity)
      : dark = tone == StampTone.light,
        text = tone == StampTone.light ? Colors.white : const Color(0xFF1F1F1F),
        secondary = tone == StampTone.light
            ? Colors.white.withValues(alpha: 0.82)
            : const Color(0xFF1F1F1F).withValues(alpha: 0.70),
        scrim = tone == StampTone.light
            ? Colors.black.withValues(alpha: opacity)
            : Colors.white.withValues(alpha: opacity),
        border = tone == StampTone.light
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.black.withValues(alpha: 0.10),
        halo = tone == StampTone.light ? Colors.black : Colors.white;

  final bool dark;
  final Color text;
  final Color secondary;
  final Color scrim;
  final Color border;
  final Color halo;
}
