import 'package:flutter/material.dart';

import '../api.dart';
import '../auth_store.dart';
import '../models/parent.dart';
import '../widgets/app_theme.dart';
import 'login_screen.dart';
import 'parent_children.dart';
import 'parent_child_overview.dart';

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({super.key});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  late Future<Map<String, dynamic>> _childrenFuture;

  @override
  void initState() {
    super.initState();
    _childrenFuture = _loadChildren();
  }

  Future<Map<String, dynamic>> _loadChildren() async {
    return apiGetChildren();
  }

  Future<void> _logout() async {
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _childrenFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to load: ${snapshot.error}'));
          }
          final data = snapshot.data!;
          final children = (data['children'] as List).map((e) => Child.fromJson(e)).toList();

          if (children.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.family_restroom, size: 64,
                      color: context.cs.onSurfaceVariant),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text('No children linked yet',
                      style: context.tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.cs.onSurface,
                      )),
                  const SizedBox(height: AppTheme.spaceXs),
                  Text('Link a child to view their academic overview',
                      style: context.tt.bodyMedium?.copyWith(
                        color: context.cs.onSurfaceVariant,
                      )),
                  const SizedBox(height: AppTheme.spaceLg),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ParentChildrenScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Link First Child'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            itemCount: children.length,
            itemBuilder: (context, i) {
              final c = children[i];
              return Card(
                margin: const EdgeInsets.only(bottom: AppTheme.spaceSm),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: context.cs.primaryContainer,
                    child: Text(c.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.email,
                          style: TextStyle(
                            color: context.cs.onSurfaceVariant,
                          )),
                      Text('Relationship: ${c.relationship}',
                          style: TextStyle(
                            color: context.cs.onSurfaceVariant,
                            fontSize: 12,
                          )),
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
          );
        },
      ),
    );
  }
}
