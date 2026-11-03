import 'package:flutter/material.dart';

import '../api.dart';
import '../models/parent.dart';
import '../widgets/app_theme.dart';
import 'parent_child_overview.dart';

class ParentChildrenScreen extends StatefulWidget {
  const ParentChildrenScreen({super.key});

  @override
  State<ParentChildrenScreen> createState() => _ParentChildrenScreenState();
}

class _ParentChildrenScreenState extends State<ParentChildrenScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = apiGetChildren();
  }

  Future<void> _refresh() async {
    setState(() => _future = apiGetChildren());
  }

  Future<void> _showLinkDialog() async {
    final emailCtrl = TextEditingController();
    final relationCtrl = TextEditingController(text: 'parent');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Child Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Child\'s College Email *',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: relationCtrl.text,
              decoration: const InputDecoration(labelText: 'Relationship'),
              items: const [
                DropdownMenuItem(value: 'parent', child: Text('Parent')),
                DropdownMenuItem(value: 'guardian', child: Text('Guardian')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => relationCtrl.text = v ?? 'parent',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (emailCtrl.text.trim().isEmpty) return;
              try {
                await apiLinkChild(emailCtrl.text.trim(), relationCtrl.text);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Child linked successfully')),
                );
                _refresh();
              } catch (e) {
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx)
                    .showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Children'),
        actions: [
          IconButton(
            tooltip: 'Link Child',
            onPressed: _showLinkDialog,
            icon: const Icon(Icons.person_add),
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
          final children = (data['children'] as List)
              .map((e) => Child.fromJson(e))
              .toList();

          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.family_restroom,
                    size: 64,
                    color: context.cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No children linked yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to link your child\'s account',
                    style: TextStyle(color: context.cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: children.length,
              itemBuilder: (context, i) {
                final c = children[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      child: Text(
                        c.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.email),
                        Text(
                          'Relationship: ${c.relationship}',
                          style: TextStyle(
                            color: context.cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParentChildOverviewScreen(child: c),
                        ),
                      ),
                      child: const Text('View Details'),
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ParentChildOverviewScreen(child: c),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

