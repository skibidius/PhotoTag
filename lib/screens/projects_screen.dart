import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../services/project_export_service.dart';
import '../services/project_store.dart';
import '../utils/page_route.dart';
import 'gallery_screen.dart';
import 'photo_map_screen.dart';

/// Lists projects with their photo counts, and lets you create or remove them.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  int _countFor(PhotoStore photos, String project) =>
      photos.records.where((PhotoRecord r) => r.project == project).length;

  bool _hasLocated(PhotoStore photos, String? project) => photos.records.any(
        (PhotoRecord r) =>
            r.hasLocation && (project == null || r.project == project),
      );

  Future<void> _createProject(BuildContext context) async {
    final ProjectStore store = context.read<ProjectStore>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.projectNew),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.projectName,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      HapticFeedback.selectionClick();
      await store.add(name);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String project) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(l10n.projectDeleteTitle),
        content: Text(l10n.projectDeleteBody(project)),
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
    if (confirmed == true && context.mounted) {
      HapticFeedback.mediumImpact();
      await context.read<ProjectStore>().remove(project);
    }
  }

  void _openMap(BuildContext context, String? project) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<PhotoRecord> records = context
        .read<PhotoStore>()
        .records
        .where((PhotoRecord r) =>
            r.hasLocation && (project == null || r.project == project))
        .toList();

    if (records.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.mapNoPhotos)));
      return;
    }

    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      sharedAxisRoute(PhotoMapScreen(
        title: project ?? l10n.photosAll,
        records: records,
      )),
    );
  }

  Future<void> _exportProject(BuildContext context, String project) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final List<PhotoRecord> records = context
        .read<PhotoStore>()
        .records
        .where((PhotoRecord r) => r.project == project)
        .toList();

    if (records.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
      return;
    }

    final bool hasOriginals =
        records.any((PhotoRecord r) => r.originalPath != null);

    final ExportVariant? variant = await showModalBottomSheet<ExportVariant>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(l10n.exportTitle,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined),
              title: Text(l10n.exportOriginal),
              enabled: hasOriginals,
              subtitle: hasOriginals ? null : Text(l10n.exportNoOriginals),
              onTap: () => Navigator.of(context).pop(ExportVariant.original),
            ),
            ListTile(
              leading: const Icon(Icons.branding_watermark_outlined),
              title: Text(l10n.exportWatermarked),
              onTap: () => Navigator.of(context).pop(ExportVariant.watermarked),
            ),
            ListTile(
              leading: const Icon(Icons.layers_outlined),
              title: Text(l10n.exportBoth),
              enabled: hasOriginals,
              onTap: () => Navigator.of(context).pop(ExportVariant.both),
            ),
          ],
        ),
      ),
    );

    if (variant == null) return;

    HapticFeedback.selectionClick();
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exportPreparing)));
    }

    final String zipPath = await ProjectExportService.export(
      records: records,
      projectName: project,
      variant: variant,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      try {
        await SharePlus.instance.share(
          ShareParams(files: <XFile>[XFile(zipPath)]),
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectStore projects = context.watch<ProjectStore>();
    final PhotoStore photos = context.watch<PhotoStore>();
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabProjects)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.projectNew),
      ),
      body: projects.projects.isEmpty
          ? const _EmptyProjects()
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(l10n.projectsAllPhotos),
                  subtitle: Text(l10n.photosCount(photos.records.length)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (_hasLocated(photos, null))
                        IconButton(
                          icon: const Icon(Icons.map_outlined),
                          tooltip: l10n.photoShowOnMap,
                          onPressed: () => _openMap(context, null),
                        ),
                      const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context)
                      .push(sharedAxisRoute(const GalleryScreen())),
                ),
                const Divider(),
                for (final String project in projects.projects)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(project),
                    subtitle: Text(l10n.photosCount(_countFor(photos, project))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (_hasLocated(photos, project))
                          IconButton(
                            icon: const Icon(Icons.map_outlined),
                            tooltip: l10n.photoShowOnMap,
                            onPressed: () => _openMap(context, project),
                          ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          tooltip: l10n.exportTitle,
                          onPressed: () => _showProjectMenu(context, project),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      sharedAxisRoute(GalleryScreen(projectFilter: project)),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<void> _showProjectMenu(BuildContext context, String project) async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: Text(l10n.photoShowOnMap),
              onTap: () => Navigator.of(context).pop('map'),
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n.exportTitle),
              onTap: () => Navigator.of(context).pop('export'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.delete),
              onTap: () => Navigator.of(context).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'map') {
      _openMap(context, project);
    } else if (action == 'export') {
      await _exportProject(context, project);
    } else if (action == 'delete') {
      await _confirmDelete(context, project);
    }
  }
}

class _EmptyProjects extends StatelessWidget {
  const _EmptyProjects();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.create_new_folder_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(l10n.projectsEmpty,
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            l10n.projectsEmptyHint,
            textAlign: TextAlign.center,
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
