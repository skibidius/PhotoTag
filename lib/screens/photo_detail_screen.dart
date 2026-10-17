import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../utils/formatters.dart';
import '../utils/page_route.dart';
import 'map_screen.dart';

/// A Google-Photos-style viewer: full-screen photos, swipe sideways to change,
/// swipe down to dismiss, pinch to zoom, tap to toggle the chrome.
class PhotoDetailScreen extends StatefulWidget {
  const PhotoDetailScreen({
    super.key,
    required this.records,
    required this.initialIndex,
  });

  final List<PhotoRecord> records;
  final int initialIndex;

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late final List<PhotoRecord> _records = List<PhotoRecord>.of(widget.records);
  late int _index = widget.initialIndex;

  late final AnimationController _spring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  double _dragOffset = 0;
  double _dragStart = 0;

  bool _zoomed = false;
  bool _chromeVisible = true;

  PhotoRecord get _record => _records[_index];

  @override
  void initState() {
    super.initState();
    _spring.addListener(() {
      setState(() {
        _dragOffset =
            _dragStart * (1 - Curves.easeOutCubic.transform(_spring.value));
      });
    });
  }

  @override
  void dispose() {
    _spring.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (_zoomed) return;
    _spring.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_zoomed) return;
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_zoomed) return;
    final double velocity = details.primaryVelocity ?? 0;
    if (_dragOffset.abs() > 120 || velocity.abs() > 700) {
      HapticFeedback.selectionClick();
      Navigator.of(context).pop();
      return;
    }
    _dragStart = _dragOffset;
    _spring.forward(from: 0);
  }

  double get _scrimOpacity =>
      (1 - (_dragOffset.abs() / 420)).clamp(0.15, 1.0);

  double get _photoScale => (1 - (_dragOffset.abs() / 1800)).clamp(0.78, 1.0);

  String get _locale => Localizations.localeOf(context).toString();

  Future<void> _share() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(_record.path)],
          text: _record.coordText.isEmpty ? null : _record.coordText,
        ),
      );
    } catch (_) {}
  }

  Future<void> _delete() async {
    HapticFeedback.mediumImpact();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final PhotoRecord record = _record;
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.photoDeleteTitle),
        content: Text(l10n.photoDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<PhotoStore>().delete(record);
    if (!mounted) return;

    if (_records.length <= 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _records.removeAt(_index);
      if (_index >= _records.length) _index = _records.length - 1;
    });
    _pageController.jumpToPage(_index);
  }

  void _showInfo() {
    final PhotoRecord record = _record;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) => _InfoSheet(
        record: record,
        onShowMap: record.hasLocation
            ? () {
                Navigator.of(context).pop();
                Navigator.of(this.context).push(
                  sharedAxisRoute(MapScreen(
                    latitude: record.latitude!,
                    longitude: record.longitude!,
                    label: record.address,
                  )),
                );
              }
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _chromeVisible = !_chromeVisible),
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(
                opacity: _scrimOpacity,
                child: const ColoredBox(color: Colors.black),
              ),
              Transform.translate(
                offset: Offset(0, _dragOffset),
                child: Transform.scale(
                  scale: _photoScale,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: _zoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    itemCount: _records.length,
                    onPageChanged: (int i) => setState(() {
                      _index = i;
                      _zoomed = false;
                    }),
                    itemBuilder: (BuildContext context, int i) => _ZoomablePage(
                      record: _records[i],
                      onZoomChanged: (bool z) {
                        if (i == _index && z != _zoomed) {
                          setState(() => _zoomed = z);
                        }
                      },
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                ignoring: !_chromeVisible,
                child: AnimatedOpacity(
                  opacity: _chromeVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _TopBar(
                      title: '${Formatters.date(_record.takenAt, _locale)} · '
                          '${Formatters.time(_record.takenAt, _locale)}',
                      onBack: () => Navigator.of(context).pop(),
                      onShare: _share,
                      onDelete: _delete,
                      onInfo: _showInfo,
                      infoTooltip: l10n.info,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.onBack,
    required this.onShare,
    required this.onDelete,
    required this.onInfo,
    required this.infoTooltip,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onInfo;
  final String infoTooltip;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Colors.black.withValues(alpha: 0.72),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                color: Colors.white,
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                color: Colors.white,
                tooltip: infoTooltip,
                onPressed: onInfo,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                color: Colors.white,
                onPressed: onShare,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.white,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({required this.record, required this.onZoomChanged});

  final PhotoRecord record;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> {
  final TransformationController _transform = TransformationController();
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _transform.addListener(_onTransform);
  }

  void _onTransform() {
    final bool zoomed = _transform.value.getMaxScaleOnAxis() > 1.02;
    if (zoomed != _zoomed) {
      setState(() => _zoomed = zoomed);
      widget.onZoomChanged(zoomed);
    }
  }

  @override
  void dispose() {
    _transform.removeListener(_onTransform);
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'photo_${widget.record.id}',
      child: InteractiveViewer(
        transformationController: _transform,
        panEnabled: _zoomed,
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Image.file(
            File(widget.record.path),
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

class _InfoSheet extends StatelessWidget {
  const _InfoSheet({required this.record, this.onShowMap});

  final PhotoRecord record;
  final VoidCallback? onShowMap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final ColorScheme scheme = Theme.of(context).colorScheme;

    final List<({IconData icon, String label, String value})> rows =
        <({IconData icon, String label, String value})>[
      (
        icon: Icons.schedule,
        label: l10n.fieldDateTime,
        value: Formatters.dateTime(record.takenAt, locale),
      ),
      if (record.coordText.isNotEmpty)
        (icon: Icons.place_outlined, label: l10n.fieldCoordinates, value: record.coordText),
      if (record.bearing != null)
        (
          icon: Icons.navigation_outlined,
          label: l10n.fieldBearing,
          value:
              '${Formatters.cardinal(record.bearing!)} ${record.bearing!.round()}°'
        ),
      if (record.altitude != null)
        (
          icon: Icons.height_outlined,
          label: l10n.fieldAltitude,
          value: '${record.altitude!.round()} m'
        ),
      if (record.accuracy != null)
        (
          icon: Icons.gps_fixed,
          label: l10n.fieldAccuracy,
          value: l10n.photoAccuracy(record.accuracy!.round().toString())
        ),
      if (record.address != null && record.address!.isNotEmpty)
        (
          icon: Icons.signpost_outlined,
          label: l10n.fieldAddress,
          value: record.address!
        ),
      if (record.project != null && record.project!.isNotEmpty)
        (
          icon: Icons.folder_outlined,
          label: l10n.project,
          value: record.project!
        ),
      if (record.note != null && record.note!.isNotEmpty)
        (icon: Icons.notes_outlined, label: l10n.detailsNote, value: record.note!),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(l10n.info, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final ({IconData icon, String label, String value}) row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(row.icon, size: 20, color: scheme.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            row.label,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: scheme.outline),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            row.value,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontFamily:
                                      row.icon == Icons.place_outlined
                                          ? 'RobotoMono'
                                          : 'GoogleSans',
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            if (onShowMap != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: onShowMap,
                  icon: const Icon(Icons.map_outlined),
                  label: Text(l10n.photoShowOnMap),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
