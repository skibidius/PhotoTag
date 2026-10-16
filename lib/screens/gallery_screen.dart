import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../utils/page_route.dart';
import 'photo_detail_screen.dart';

/// A grid of captured photos, newest first. When [projectFilter] is provided,
/// only photos belonging to that project are shown.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, this.projectFilter});

  final String? projectFilter;

  @override
  Widget build(BuildContext context) {
    final PhotoStore store = context.watch<PhotoStore>();
    final List<PhotoRecord> records = projectFilter == null
        ? store.records
        : store.records
            .where((PhotoRecord r) => r.project == projectFilter)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(projectFilter ?? 'Photos${records.isEmpty ? '' : ' · ${records.length}'}'),
      ),
      body: records.isEmpty
          ? const _EmptyGallery()
          : GridView.builder(
              padding: const EdgeInsets.all(4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: records.length,
              itemBuilder: (BuildContext context, int index) {
                return _PhotoTile(record: records[index]);
              },
            ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.record});

  final PhotoRecord record;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'photo_${record.id}',
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            sharedAxisRoute(PhotoDetailScreen(record: record)),
          ),
          child: Image.file(
            File(record.thumbPath),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_outlined),
            ),
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
          Text(
            'No photos yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Photos you capture appear here.',
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
