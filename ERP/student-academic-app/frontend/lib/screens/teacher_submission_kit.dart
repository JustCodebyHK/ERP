import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../api.dart';
import '../models/submission_template.dart';
import '../widgets/app_theme.dart';

class TeacherSubmissionKitScreen extends StatefulWidget {
  const TeacherSubmissionKitScreen({super.key});

  @override
  State<TeacherSubmissionKitScreen> createState() => _TeacherSubmissionKitScreenState();
}

class _TeacherSubmissionKitScreenState extends State<TeacherSubmissionKitScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiListTemplates();
  }

  Future<void> _refresh() async {
    setState(() => _future = apiListTemplates());
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _showUploadDialog() async {
    final titleCtrl = TextEditingController();
    String type = 'front_page';
    PlatformFile? pickedFile;
    String? pickedName;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Upload New Template Version'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Template Type'),
                  items: const [
                    DropdownMenuItem(value: 'front_page', child: Text('Front Page')),
                    DropdownMenuItem(value: 'index_page', child: Text('Index Page')),
                    DropdownMenuItem(value: 'certificate', child: Text('Certificate')),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'front_page'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf', 'doc', 'docx'],
                      withData: true,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      setState(() {
                        pickedFile = result.files.single;
                        pickedName = result.files.single.name;
                      });
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: Text(pickedFile == null ? 'Pick File (PDF/DOC)' : 'File: $pickedName'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
FilledButton(
              onPressed: (pickedFile == null || titleCtrl.text.trim().isEmpty)
                  ? null
                  : () async {
                      try {
                        final mimeType = _getMimeType(pickedName!);
                        if (pickedFile!.path != null) {
                          await apiUploadTemplate(
                            {
                              'type': type,
                              'title': titleCtrl.text.trim(),
                            },
                            File(pickedFile!.path!),
                            pickedName!,
                            mimeType: mimeType,
                          );
                        } else if (pickedFile!.bytes != null) {
                          await apiUploadTemplateBytes(
                            {
                              'type': type,
                              'title': titleCtrl.text.trim(),
                            },
                            pickedFile!.bytes!,
                            pickedName!,
                            mimeType: mimeType,
                          );
                        } else {
                          throw Exception('Unable to read file');
                        }
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Template uploaded')),
                        );
                        _refresh();
                      } catch (e) {
                        if (!ctx.mounted) return;
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    },
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setCurrent(SubmissionTemplate t) async {
    try {
      await apiSetTemplateCurrent(t.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.typeLabel} v${t.version} set as current')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submission Kit Manager'),
        actions: [
          IconButton(
            tooltip: 'Upload New Version',
            onPressed: _showUploadDialog,
            icon: const Icon(Icons.cloud_upload),
          ),
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
            return const Center(child: Text('No templates yet. Tap upload to add.'));
          }

          // Group by type
          final grouped = <String, List<SubmissionTemplate>>{};
          for (final t in templates) {
            grouped.putIfAbsent(t.type, () => []).add(t);
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...grouped.entries.map((entry) {
                  final list = entry.value;
                  final current = list.firstWhere((t) => t.isCurrent, orElse: () => list.first);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(current.icon),
                      ),
                      title: Text(
                        current.typeLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('Current: v${current.version} - ${current.title}'),
                      children: list.map((t) => ListTile(
                        leading: Icon(t.isCurrent ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                        title: Text('v${t.version} - ${t.title}'),
                        subtitle: Text('${t.formattedSize} • ${t.createdAt.toLocal().toString().split('.')[0]}'),
                        trailing: t.isCurrent
                            ? Chip(
                                label: Text('CURRENT', style: TextStyle(fontSize: 10)),
                                backgroundColor: AppTheme.tertiary,
                                labelStyle: TextStyle(color: AppTheme.onPrimary),
                              )
                            : TextButton(
                                onPressed: () => _setCurrent(t),
                                child: const Text('Set Current'),
                              ),
                        onTap: t.isCurrent ? null : () => _setCurrent(t),
                      )).toList(),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}
