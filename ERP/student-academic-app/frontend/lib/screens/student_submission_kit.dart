import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

import '../api.dart';
import '../models/submission_template.dart';
import '../utils/download_helper.dart';
import '../widgets/app_theme.dart';

class StudentSubmissionKitScreen extends StatefulWidget {
  const StudentSubmissionKitScreen({super.key});

  @override
  State<StudentSubmissionKitScreen> createState() =>
      _StudentSubmissionKitScreenState();
}

class _StudentSubmissionKitScreenState
    extends State<StudentSubmissionKitScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiListTemplatesCached();
  }

  Future<void> _refresh() async {
    setState(() => _future = apiListTemplatesCached());
  }

  Future<void> _downloadAndShare(SubmissionTemplate t) async {
    try {
      final perm = await ensureStoragePermission(context);
      if (!perm) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'File access permission is required to download files'),
          ),
        );
        return;
      }

      final kitDir = await resolveDownloadDirectory('SubmissionKit');
      final dest =
          '${kitDir}${Platform.pathSeparator}${t.originalName}';

      await apiDownloadTemplate(t.id, dest);

      if (!mounted) return;
      
      // Open file with external app
      final openResult = await OpenFile.open(dest);
      if (!mounted) return;
      if (openResult.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to Downloads/SubmissionKit - could not open: ${openResult.message}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to Downloads/SubmissionKit and opened ${t.originalName}')),
        );
      }

      // Also offer to share via system share sheet (WhatsApp, Email, etc.)
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(dest)],
          text: '${t.typeLabel} v${t.version} - ${t.title}',
          subject: t.title,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Kit'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final templates = (data['templates'] as List)
              .map((e) => SubmissionTemplate.fromJson(e))
              .toList();

          if (templates.isEmpty) {
            return const Center(child: Text('No templates available yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, i) {
              final t = templates[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    child: Icon(
                      t.icon,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(
                    t.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Chip(
                            label: Text(
                              t.typeLabel,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              'v${t.version}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: context.cs.tertiary.withValues(
                              alpha: 0.1,
                            ),
                            labelStyle: const TextStyle(
                              color: AppTheme.tertiary,
                              fontSize: 11,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      Text(
                        '${t.formattedSize} • Updated ${t.createdAt.toLocal().toString().split('.')[0]}',
                      ),
                    ],
                  ),
                  trailing: FilledButton.tonal(
                    onPressed: () => _downloadAndShare(t),
                    child: const Text('Get & Share'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

