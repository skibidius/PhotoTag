import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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
    final TextEditingController controller = TextEditingController();
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('New project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Project name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (String v) => Navigator.of(context).pop(v),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text(
            '“$project” will be removed. The photos keep their location but are no longer grouped.'),
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
      HapticFeedback.mediumImpact();
      await context.read<ProjectStore>().remove(project);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProjectStore projects = context.watch<ProjectStore>();
    final PhotoStore photos = context.watch<PhotoStore>();

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createProject(context),
        icon: const Icon(Icons.add),
        label: const Text('New project'),
      ),
      body: projects.projects.isEmpty
          ? const _EmptyProjects()
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('All photos'),
                  subtitle: Text('${photos.records.length}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context)
                      .push(sharedAxisRoute(const GalleryScreen())),
                ),
                const Divider(),
                for (final String project in projects.projects)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(project),
                    subtitle: Text('${_countFor(photos, project)} photos'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String value) {
                        if (value == 'delete') _confirmDelete(context, project);
                      },
                      itemBuilder: (BuildContext context) =>
                          const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
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
          Text('No projects yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Group photos by site, job or client.',
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
