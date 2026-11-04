import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

import '../api.dart';
import '../utils/download_helper.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';

class Note {
  final String id;
  final String title;
  final String originalName;
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.title,
    required this.originalName,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) => Note(
    id: json['id'] as String,
    title: json['title'] as String,
    originalName: json['original_name'] as String,
    mimeType: json['mime_type'] as String? ?? '',
    sizeBytes: _parseSize(json['size_bytes']),
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  static int _parseSize(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData get fileIcon {
    final ext = originalName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color get fileColor {
    final ext = originalName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return AppTheme.error;
      case 'doc':
      case 'docx':
        return AppTheme.primary;
      case 'ppt':
      case 'pptx':
        return AppTheme.secondary;
      case 'txt':
        return AppTheme.onSurfaceVariant;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return AppTheme.tertiary;
      default:
        return AppTheme.primary;
    }
  }
}

class TeacherNotesScreen extends StatefulWidget {
  final String subjectId;
  final String subjectCode;
  final String subjectName;

  const TeacherNotesScreen({
    super.key,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  State<TeacherNotesScreen> createState() => _TeacherNotesScreenState();
}

class _TeacherNotesScreenState extends State<TeacherNotesScreen> {
  late Future<List<Note>> _future;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Note>> _load() async {
    final data = await apiGet('/api/notes?subject_id=${widget.subjectId}');
    return (data['notes'] as List).map((e) => Note.fromJson(e)).toList();
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'txt',
        'jpg',
        'jpeg',
        'png',
      ],
      withData: true,
    );
    if (result == null) return;

    final pickedFile = result.files.single;
    setState(() => _uploading = true);
    try {
      final mimeType = _getMimeType(pickedFile.name);
      if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        await apiUploadFile('/api/notes', 'file', file, pickedFile.name,
            fields: {'subject_id': widget.subjectId, 'title': pickedFile.name});
      } else if (pickedFile.bytes != null) {
        await apiUploadBytes(
          '/api/notes',
          'file',
          pickedFile.bytes!,
          pickedFile.name,
          fields: {'subject_id': widget.subjectId, 'title': pickedFile.name},
        );
      } else {
        throw Exception(
          'Unable to read file. On web, ensure file_picker_web is properly configured.',
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note uploaded successfully')),
      );
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: ${e.message}')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.subjectCode} - Notes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Upload Note',
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Note>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(context);
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load notes: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final notes = snapshot.data!;
          if (notes.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  EmptyState(
                    icon: Icons.description_outlined,
                    title: 'No Notes Yet',
                    subtitle:
                        'Tap the upload button to add your first note for ${widget.subjectName}.',
                    action: FilledButton.icon(
                      onPressed: _pickAndUpload,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Upload Note'),
                    ),
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return AnimatedListItem(
                  index: index,
                  child: NoteCard(
                    note: note,
                    onDownload: () => _download(note),
                    onDelete: () => _confirmDelete(note),
                    showDelete: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LoadingShimmer(
            height: 88,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Future<void> _download(Note note) async {
    try {
      final perm = await ensureStoragePermission(context);
      final notesDir = await resolveDownloadDirectory('Notes');
      final dest =
          '${notesDir}${Platform.pathSeparator}${note.originalName}';

      await apiDownloadFile('/api/notes/${note.id}/download', dest);

      if (!mounted) return;

      // Open file with external app
      final result = await OpenFile.open(dest);
      if (!mounted) return;
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved note - could not open: ${result.message}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              perm
                  ? 'Saved to Downloads/Notes and opened ${note.originalName}'
                  : 'Downloaded and opened ${note.originalName} (in app storage)',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _confirmDelete(Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Note'),
        content: Text('Are you sure you want to delete "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.cs.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await apiDelete('/api/notes/${note.id}');
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Note deleted')));
        setState(() => _future = _load());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
      }
    }
  }
}

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDownload;
  final VoidCallback? onDelete;
  final bool showDelete;

  const NoteCard({
    super.key,
    required this.note,
    required this.onDownload,
    this.onDelete,
    this.showDelete = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onDownload,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: note.fileColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(note.fileIcon, color: note.fileColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note.originalName,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: context.cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: context.cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(note.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.cs.onSurfaceVariant),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.data_usage,
                          size: 12,
                          color: context.cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          note.formattedSize,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Download',
                    icon: Icon(
                      Icons.download,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: onDownload,
                  ),
                  if (showDelete && onDelete != null)
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
