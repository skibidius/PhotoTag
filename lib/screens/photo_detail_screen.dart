import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../utils/formatters.dart';
import '../utils/page_route.dart';
import 'map_screen.dart';

/// Full-screen view of a single photo with its captured metadata.
class PhotoDetailScreen extends StatelessWidget {
  const PhotoDetailScreen({super.key, required this.record});

  final PhotoRecord record;

  Future<void> _share(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: <XFile>[XFile(record.path)],
          text: record.coordText.isEmpty ? null : record.coordText,
        ),
      );
    } catch (_) {}
  }

  Future<void> _delete(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This photo and its location data will be removed.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<PhotoStore>().delete(record);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${Formatters.date(record.takenAt)} · ${Formatters.time(record.takenAt)}',
          style: const TextStyle(fontSize: 16),
        ),
        actions: <Widget>[
          if (record.hasLocation)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: 'Show on map',
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
            tooltip: 'Share',
            onPressed: () => _share(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete',
            onPressed: () => _delete(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Hero(
              tag: 'photo_${record.id}',
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: Image.file(File(record.path), fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          _InfoPanel(record: record),
        ],
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
    final List<({IconData icon, String text})> rows = <({IconData icon, String text})>[
      if (record.coordText.isNotEmpty)
        (icon: Icons.place_outlined, text: record.coordText),
      if (record.bearing != null)
        (icon: Icons.navigation_outlined, text: '${Formatters.cardinal(record.bearing!)} ${record.bearing!.round()}°'),
      if (record.altitude != null)
        (icon: Icons.height_outlined, text: '${record.altitude!.round()} m'),
      if (record.accuracy != null)
        (icon: Icons.gps_fixed, text: 'Accuracy ±${record.accuracy!.round()} m'),
      if (record.address != null && record.address!.isNotEmpty)
        (icon: Icons.signpost_outlined, text: record.address!),
      if (record.project != null && record.project!.isNotEmpty)
        (icon: Icons.folder_outlined, text: record.project!),
      if (record.note != null && record.note!.isNotEmpty)
        (icon: Icons.notes_outlined, text: record.note!),
    ];

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

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
