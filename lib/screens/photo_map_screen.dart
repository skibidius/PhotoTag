import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/photo_record.dart';
import '../services/basemaps.dart';
import '../services/settings_controller.dart';
import '../utils/formatters.dart';
import '../utils/page_route.dart';
import '../widgets/basemap_picker.dart';
import '../widgets/photo_cluster_layer.dart';
import 'photo_detail_screen.dart';

/// Shows every geotagged photo of a project (or of the whole library) on a map.
///
/// Markers point in the direction the camera was facing, tapping one opens a
/// preview card, and the basemap can be switched between the working sources
/// from PhotoMap. The choice is remembered across launches.
class PhotoMapScreen extends StatefulWidget {
  const PhotoMapScreen({
    super.key,
    required this.title,
    required this.records,
    this.initialSelectedId,
  });

  final String title;
  final List<PhotoRecord> records;
  final String? initialSelectedId;

  @override
  State<PhotoMapScreen> createState() => _PhotoMapScreenState();
}

class _PhotoMapScreenState extends State<PhotoMapScreen> {
  final MapController _mapController = MapController();
  late final List<PhotoRecord> _records = widget.records
      .where((PhotoRecord r) => r.hasLocation)
      .toList(growable: false);

  PhotoRecord? _selected;
  String? _basemapKey;

  @override
  void initState() {
    super.initState();
    if (widget.initialSelectedId != null) {
      for (final PhotoRecord record in _records) {
        if (record.id == widget.initialSelectedId) {
          _selected = record;
          break;
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_basemapKey != null) return;
    final String stored = context.read<SettingsController>().value.basemap;
    _basemapKey =
        basemapByKeyOrNull(stored) == null ? kDefaultBasemapKey : stored;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  BasemapDef get _basemap => basemapByKey(_basemapKey);

  String get _locale => Localizations.localeOf(context).toString();

  void _setBasemap(String key) {
    if (key == _basemap.key) return;
    setState(() => _basemapKey = key);
    context.read<SettingsController>().update(
          (settings) => settings.copyWith(basemap: key),
        );
  }

  Future<void> _pickBasemap() async {
    final String? key = await showBasemapPicker(context, _basemap.key);
    if (key != null && mounted) _setBasemap(key);
  }

  void _select(PhotoRecord record, {bool center = false}) {
    HapticFeedback.selectionClick();
    setState(() => _selected = record);
    if (!center) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double zoom = _mapController.camera.zoom;
      _mapController.move(
        LatLng(record.latitude!, record.longitude!),
        zoom < 14 ? 15 : zoom,
      );
    });
  }

  void _fitAll() {
    if (_records.isEmpty) return;
    HapticFeedback.selectionClick();
    if (_records.length == 1) {
      _mapController.move(
        LatLng(_records.first.latitude!, _records.first.longitude!),
        16,
      );
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(
          _records
              .map((PhotoRecord r) => LatLng(r.latitude!, r.longitude!))
              .toList(),
        ),
        padding: const EdgeInsets.fromLTRB(48, 96, 48, 220),
        maxZoom: 16,
      ),
    );
  }

  void _openViewer(PhotoRecord record) {
    final int index = _records.indexOf(record);
    if (index < 0) return;
    Navigator.of(context).push(
      photoViewerRoute(
        PhotoDetailScreen(records: _records, initialIndex: index),
      ),
    );
  }

  void _zoomToCluster(List<PhotoRecord> records) {
    if (records.isEmpty) return;
    HapticFeedback.selectionClick();
    if (records.length == 1) {
      _select(records.first, center: true);
      return;
    }

    final double current = _mapController.camera.zoom;
    final double target = math.min(
      current + 2,
      _basemap.maxZoom.toDouble(),
    );
    final LatLng center = LatLngBounds.fromPoints(
      records
          .map((PhotoRecord r) => LatLng(r.latitude!, r.longitude!))
          .toList(),
    ).center;
    _mapController.move(center, target);
  }

  void _showPhotoList({List<PhotoRecord>? photos}) {
    final List<PhotoRecord> list = photos ?? _records;
    if (list.isEmpty) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        final AppLocalizations l10n = AppLocalizations.of(sheetContext);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 12, 12),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          l10n.photosAllCount(list.length),
                          style: Theme.of(sheetContext).textTheme.titleLarge,
                        ),
                      ),
                      if (photos != null)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.of(sheetContext).pop();
                            _zoomToCluster(list);
                          },
                          icon: const Icon(Icons.zoom_in),
                          label: Text(l10n.mapZoomIn),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                    ),
                    itemCount: list.length,
                    itemBuilder: (BuildContext context, int i) {
                      final PhotoRecord record = list[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _select(record, center: true);
                        },
                        child: Image.file(
                          File(record.thumbPath),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Colors.transparent,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  MapOptions _mapOptions(BasemapDef basemap, Color surface) {
    const InteractionOptions interaction = InteractionOptions(
      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    );

    final PhotoRecord? initial = _selected;
    if (initial != null) {
      return MapOptions(
        crs: basemap.crs,
        initialCenter: LatLng(initial.latitude!, initial.longitude!),
        initialZoom: 16,
        maxZoom: basemap.maxZoom.toDouble(),
        minZoom: 2,
        backgroundColor: surface,
        interactionOptions: interaction,
        onTap: (_, _) => setState(() => _selected = null),
      );
    }

    if (_records.length > 1) {
      return MapOptions(
        crs: basemap.crs,
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(
            _records
                .map((PhotoRecord r) => LatLng(r.latitude!, r.longitude!))
                .toList(),
          ),
          padding: const EdgeInsets.fromLTRB(48, 96, 48, 220),
          maxZoom: 16,
        ),
        maxZoom: basemap.maxZoom.toDouble(),
        minZoom: 2,
        backgroundColor: surface,
        interactionOptions: interaction,
        onTap: (_, _) => setState(() => _selected = null),
      );
    }

    return MapOptions(
      crs: basemap.crs,
      initialCenter: LatLng(_records.first.latitude!, _records.first.longitude!),
      initialZoom: 15,
      maxZoom: basemap.maxZoom.toDouble(),
      minZoom: 2,
      backgroundColor: surface,
      interactionOptions: interaction,
      onTap: (_, _) => setState(() => _selected = null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final BasemapDef basemap = _basemap;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (_records.isNotEmpty)
              Text(
                l10n.photosCount(_records.length),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
        actions: _records.isEmpty
            ? null
            : <Widget>[
                IconButton(
                  icon: const Icon(Icons.layers_outlined),
                  tooltip: l10n.mapStyle,
                  onPressed: _pickBasemap,
                ),
                IconButton(
                  icon: const Icon(Icons.zoom_out_map),
                  tooltip: l10n.mapFitAll,
                  onPressed: _fitAll,
                ),
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  tooltip: l10n.photosAll,
                  onPressed: _showPhotoList,
                ),
              ],
      ),
      body: _records.isEmpty
          ? _EmptyMap(l10n: l10n)
          : Stack(
              children: <Widget>[
                Positioned.fill(
                  child: FlutterMap(
                    key: ValueKey<String>('map_${basemap.crs.code}'),
                    mapController: _mapController,
                    options: _mapOptions(basemap, scheme.surface),
                    children: <Widget>[
                      ...basemapTileLayers(basemap, _locale),
                      PhotoClusterLayer(
                        records: _records,
                        selected: _selected,
                        onPhotoTap: _select,
                        onClusterTap: (List<PhotoRecord> photos) =>
                            _showPhotoList(photos: photos),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 8,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        child: Text(
                          basemap.attribution,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_selected != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: SafeArea(
                      top: false,
                      child: _SelectedPhotoCard(
                        record: _selected!,
                        locale: _locale,
                        onOpen: () => _openViewer(_selected!),
                        onClose: () => setState(() => _selected = null),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

}

class _SelectedPhotoCard extends StatelessWidget {
  const _SelectedPhotoCard({
    required this.record,
    required this.locale,
    required this.onOpen,
    required this.onClose,
  });

  final PhotoRecord record;
  final String locale;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;

    final String title = (record.address?.isNotEmpty ?? false)
        ? record.address!
        : (record.project?.isNotEmpty ?? false)
            ? record.project!
            : Formatters.date(record.takenAt, locale);

    return Material(
      elevation: 4,
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  File(record.thumbPath),
                  width: 68,
                  height: 68,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (_, _, _) => Container(
                    width: 68,
                    height: 68,
                    color: scheme.surfaceContainerHighest,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.dateTime(record.takenAt, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.coordText.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 3),
                      Text(
                        record.coordText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          fontFamily: 'RobotoMono',
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (record.bearing != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Transform.rotate(
                            angle: record.bearing! * math.pi / 180,
                            child: Icon(
                              Icons.navigation,
                              size: 14,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${Formatters.cardinal(record.bearing!)} · '
                              '${record.bearing!.round()}°',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    visualDensity: VisualDensity.compact,
                    onPressed: onClose,
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.layers_clear_outlined, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(l10n.mapNoPhotos, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              l10n.mapNoPhotosHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}
