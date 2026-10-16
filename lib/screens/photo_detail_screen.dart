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

/// Full-screen, swipeable view of one or more photos with their metadata.
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

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late final List<PhotoRecord> _records = List<PhotoRecord>.of(widget.records);
  late int _index = widget.initialIndex;

  PhotoRecord get _record => _records[_index];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    final PhotoRecord record = _record;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${Formatters.date(record.takenAt, Localizations.localeOf(context).toString())} · '
          '${Formatters.time(record.takenAt, Localizations.localeOf(context).toString())}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          if (record.hasLocation)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: l10n.photoShowOnMap,
              onPressed: () => Navigator.of(context).push(
                sharedAxisRoute(MapScreen(
                  latitude: record.latitude!,
                  longitude: record.longitude!,
                  label: record.address,
                )),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: l10n.share,
            onPressed: _share,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.delete,
            onPressed: _delete,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _records.length,
              onPageChanged: (int i) => setState(() => _index = i),
              itemBuilder: (BuildContext context, int i) =>
                  _ZoomablePage(record: _records[i]),
            ),
          ),
          _InfoPanel(record: record),
        ],
      ),
    );
  }
}

/// A single photo that can be pinched to zoom; panning only takes over once
/// zoomed in, so horizontal swipes still change pages.
class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({required this.record});

  final PhotoRecord record;

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
    if (zoomed != _zoomed) setState(() => _zoomed = zoomed);
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
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.record});

  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<({IconData icon, String text})> rows = <({IconData icon, String text})>[
      if (record.coordText.isNotEmpty)
        (icon: Icons.place_outlined, text: record.coordText),
      if (record.bearing != null)
        (
          icon: Icons.navigation_outlined,
          text: '${Formatters.cardinal(record.bearing!)} ${record.bearing!.round()}°'
        ),
      if (record.altitude != null)
        (icon: Icons.height_outlined, text: '${record.altitude!.round()} m'),
      if (record.accuracy != null)
        (
          icon: Icons.gps_fixed,
          text: l10n.photoAccuracy(record.accuracy!.round().toString())
        ),
      if (record.address != null && record.address!.isNotEmpty)
        (icon: Icons.signpost_outlined, text: record.address!),
      if (record.project != null && record.project!.isNotEmpty)
        (icon: Icons.folder_outlined, text: record.project!),
      if (record.note != null && record.note!.isNotEmpty)
        (icon: Icons.notes_outlined, text: record.note!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (int i = 0; i < rows.length; i++)
              Padding(
                padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(rows[i].icon, size: 18, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rows[i].text,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontFamily: rows[i].icon == Icons.place_outlined
                                  ? 'RobotoMono'
                                  : 'GoogleSans',
                            ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
