import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/photo_record.dart';
import '../services/photo_store.dart';
import '../services/project_store.dart';
import '../utils/page_route.dart';
import 'gallery_screen.dart';

/// Lists projects with their photo counts, and lets you create or remove them.
class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  int _countFor(PhotoStore photos, String project) =>
      photos.records.where((PhotoRecord r) => r.project == project).length;

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
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(sharedAxisRoute(const GalleryScreen())),
                ),
                const Divider(),
                for (final String project in projects.projects)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(project),
                    subtitle: Text(l10n.photosCount(_countFor(photos, project))),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'delete') _confirmDelete(context, project);
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text(l10n.delete),
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
