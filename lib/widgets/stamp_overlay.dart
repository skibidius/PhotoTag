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
/// [context], which lets the same widget render the live camera HUD and the
/// final high-resolution image.
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
    final bool dark = settings.stampTone == StampTone.light;

    final Color text = dark ? Colors.white : const Color(0xFF1F1F1F);
    final Color secondary = dark
        ? Colors.white.withValues(alpha: 0.80)
        : const Color(0xFF1F1F1F).withValues(alpha: 0.68);
    final Color scrim = dark
        ? Colors.black.withValues(alpha: settings.opacity)
        : Colors.white.withValues(alpha: settings.opacity);
    final Color border = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.10);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: kStampReferenceWidth),
      child: Material(
        color: Colors.transparent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scrim,
            borderRadius: BorderRadius.circular(30 * s),
            border: Border.all(color: border, width: 1),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.12),
                blurRadius: 40 * s,
                offset: Offset(0, 16 * s),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Accent rule across the top.
                Container(height: 6 * s, color: accent),
                Padding(
                  padding: EdgeInsets.fromLTRB(34 * s, 28 * s, 34 * s, 32 * s),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _lines(
                      text,
                      secondary,
                      border,
                      s,
                      AppLocalizations.of(context),
                      Localizations.localeOf(context).toString(),
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  List<Widget> _lines(Color text, Color secondary, Color border, double s,
      AppLocalizations l10n, String locale) {
    final List<Widget> lines = <Widget>[];

    final String dateTime = _dateTimeText(locale);
    final String coords = data.coordText;
    final String meta = _metaText;
    final String address = _addressText;

    void addSpace([double factor = 1]) {
      if (lines.isNotEmpty) lines.add(SizedBox(height: 14 * s * factor));
    }

    if (dateTime.isNotEmpty) {
      lines.add(Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 14 * s,
            height: 14 * s,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Text(
              dateTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'GoogleSans',
                fontSize: 40 * s,
                fontWeight: FontWeight.w500,
                height: 1.1,
                color: text,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ));
    }

    if (coords.isNotEmpty && settings.showCoordinates) {
      addSpace(1.4);
      lines.add(Text(
        coords,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 34 * s,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: text,
        ),
      ));
    }

    if (meta.isNotEmpty) {
      addSpace();
      lines.add(Text(
        meta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'RobotoMono',
          fontSize: 27 * s,
          fontWeight: FontWeight.w400,
          height: 1.25,
          color: secondary,
        ),
      ));
    }

    if (address.isNotEmpty) {
      addSpace(1.3);
      lines.add(Text(
        address,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 30 * s,
          fontWeight: FontWeight.w400,
          height: 1.3,
          color: secondary,
        ),
      ));
    }

    if (_footerText(l10n).isNotEmpty) {
      addSpace(1.4);
      lines.add(Container(
        width: double.infinity,
        height: 1,
        color: border,
      ));
      addSpace(1.1);
      lines.add(Text(
        _footerText(l10n),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'GoogleSans',
          fontSize: 30 * s,
          fontWeight: FontWeight.w400,
          height: 1.35,
          color: secondary,
        ),
      ));
    }

    if (data.counter != null && settings.showCounter) {
      addSpace(1.5);
      lines.add(Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 8 * s),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            l10n.stampCounter(data.counter.toString().padLeft(3, '0')),
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontSize: 24 * s,
              fontWeight: FontWeight.w500,
              color: accent.computeLuminance() > 0.5
                  ? const Color(0xFF1F1F1F)
                  : Colors.white,
              letterSpacing: 1,
            ),
          ),
        ),
      ));
    }

    if (lines.isEmpty) {
      // A place-holder so the widget still has a sensible intrinsic size.
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
      parts.add(
          '${Formatters.cardinal(data.bearing!)} ${data.bearing!.round()}°');
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
