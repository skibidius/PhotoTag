import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../utils/formatters.dart';
import '../utils/page_route.dart';
import 'photo_detail_screen.dart';
import 'photo_map_screen.dart';

/// A grid of captured photos, grouped by month like Google Photos. When
/// [projectFilter] is provided, only photos belonging to that project are shown.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, this.projectFilter});

  final String? projectFilter;

  @override
  Widget build(BuildContext context) {
    final PhotoStore store = context.watch<PhotoStore>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<PhotoRecord> records = projectFilter == null
        ? store.records
        : store.records
            .where((PhotoRecord r) => r.project == projectFilter)
            .toList();

    final List<PhotoRecord> located =
        records.where((PhotoRecord r) => r.hasLocation).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(projectFilter ??
            (records.isEmpty
                ? l10n.photosAll
                : l10n.photosAllCount(records.length))),
        actions: <Widget>[
          if (located.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: l10n.photoShowOnMap,
              onPressed: () => Navigator.of(context).push(
                sharedAxisRoute(PhotoMapScreen(
                  title: projectFilter ?? l10n.photosAll,
                  records: located,
                )),
              ),
            ),
        ],
      ),
      body: records.isEmpty
          ? const _EmptyGallery()
          : _PhotoGrid(records: records),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid({required this.records});

  final List<PhotoRecord> records;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final Map<String, List<PhotoRecord>> groups =
        <String, List<PhotoRecord>>{};
    for (final PhotoRecord record in records) {
      final String key = '${record.takenAt.year}-${record.takenAt.month}';
      groups.putIfAbsent(key, () => <PhotoRecord>[]).add(record);
    }

    final List<String> keys = groups.keys.toList()
      ..sort((String a, String b) => b.compareTo(a));

    return CustomScrollView(
      slivers: <Widget>[
        for (final String key in keys) ...<Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
              child: Text(
                Formatters.monthYear(groups[key]!.first.takenAt, locale),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int i) {
                final PhotoRecord record = groups[key]![i];
                return _PhotoTile(
                  record: record,
                  records: records,
                  index: records.indexOf(record),
                );
              },
              childCount: groups[key]!.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.record,
    required this.records,
    required this.index,
  });

  final PhotoRecord record;
  final List<PhotoRecord> records;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            photoViewerRoute(
              PhotoDetailScreen(records: records, initialIndex: index),
            ),
          );
        },
        child: Image.file(
          File(record.thumbPath),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          errorBuilder: (_, _, _) => const Center(
            child: Icon(Icons.broken_image_outlined),
          ),
        ),
      ),
    );
  }
}

class _EmptyGallery extends StatelessWidget {
  const _EmptyGallery();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.add_a_photo_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(l10n.photosEmpty,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.photosEmptyHint,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
