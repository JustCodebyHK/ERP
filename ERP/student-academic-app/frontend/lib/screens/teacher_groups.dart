import 'package:flutter/material.dart';

import '../api.dart';
import '../auth_store.dart';
import '../widgets/app_theme.dart';
import 'group_chat.dart';

class TeacherGroupsScreen extends StatefulWidget {
  const TeacherGroupsScreen({super.key});

  @override
  State<TeacherGroupsScreen> createState() => _TeacherGroupsScreenState();
}

class _TeacherGroupsScreenState extends State<TeacherGroupsScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    return apiGetGroups();
  }

  Future<void> _refresh() async {
    try {
      final newFuture = _load();
      setState(() {
        _future = newFuture;
      });
      await newFuture;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
    }
  }

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String type = 'group';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Create Study Group'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: 'group',
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(
                      value: 'group',
                      child: Text('Group (Chat)'),
                    ),
                    DropdownMenuItem(
                      value: 'channel',
                      child: Text('Channel (Broadcast)'),
                    ),
                  ],
                  onChanged: (v) => setState(() => type = v ?? 'group'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                try {
                  await apiCreateGroup({
                    'name': nameCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'type': type,
                  });
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Group created successfully')),
                  );
                  _refresh();
                } catch (e) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteGroup(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
        ),
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
    if (confirm != true) return;

    try {
      await _deleteGroupApi(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Group deleted')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteGroupApi(String id) async {
    await apiDelete('/api/groups/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Study Groups'),
        actions: [
          IconButton(
            tooltip: 'Create Group',
            onPressed: _showCreateDialog,
            icon: const Icon(Icons.add),
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
          final groups = data['groups'] as List;

          if (groups.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.group_outlined,
                            size: 64,
                            color: AppTheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No study groups yet',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 8),
                          const Text('Tap + to create your first study group'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i] as Map<String, dynamic>;
                final memberCount = (g['member_count'] is int)
                    ? g['member_count'] as int
                    : int.tryParse(g['member_count']?.toString() ?? '0') ?? 0;
                final type = g['type'] as String? ?? 'group';
                final isPublic = g['is_public'] as bool? ?? false;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: type == 'channel'
                            ? context.cs.tertiary.withValues(alpha: 0.1)
                            : context.cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        type == 'channel' ? Icons.campaign : Icons.group,
                        color: type == 'channel'
                            ? context.cs.tertiary
                            : context.cs.primary,
                      ),
                    ),
                    title: Text(
                      g['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((g['description'] as String?)?.isNotEmpty == true)
                          Text(
                            g['description'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                type == 'channel' ? 'Channel' : 'Group',
                                style: const TextStyle(fontSize: 10),
                              ),
                              backgroundColor:
                                  (type == 'channel'
                                          ? context.cs.tertiary
                                          : context.cs.primary)
                                      .withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: type == 'channel'
                                    ? context.cs.tertiary
                                    : context.cs.primary,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            const SizedBox(width: 8),
                            if (isPublic)
                              Chip(
                                label: const Text(
                                  'Public',
                                  style: TextStyle(fontSize: 10),
                                ),
                                backgroundColor: AppTheme.tertiary.withValues(
                                  alpha: 0.1,
                                ),
                                labelStyle: TextStyle(
                                  color: context.cs.tertiary,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              '$memberCount members',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          _deleteGroup(g['id'] as String, g['name'] as String);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDetailScreen(
                            groupId: g['id'] as String,
                            groupName: g['name'] as String,
                          ),
                        ),
                      );
                    },
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

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late Future<Map<String, dynamic>> _future;
  late Future<Map<String, dynamic>> _membersFuture;
  String _groupType = 'group';

  @override
  void initState() {
    super.initState();
    _future = _load();
    _membersFuture = apiGetGroupMembers(widget.groupId);
  }

  Future<Map<String, dynamic>> _load() async {
    return apiGetGroup(widget.groupId);
  }

  Future<void> _refresh() async {
    try {
      final newFuture = _load();
      final newMembers = apiGetGroupMembers(widget.groupId);
      setState(() {
        _future = newFuture;
        _membersFuture = newMembers;
      });
      await Future.wait([newFuture, newMembers]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Refresh failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        actions: [
          IconButton(
            tooltip: 'Chat',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    groupId: widget.groupId,
                    groupName: widget.groupName,
                    groupType: _groupType,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline),
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
          final group = data['group'] as Map<String, dynamic>;

          _groupType = group['type'] as String? ?? 'group';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Group Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Type',
                          value: group['type'] == 'channel'
                              ? 'Channel (Broadcast)'
                              : 'Group (Chat)',
                        ),
                        _InfoRow(
                          label: 'Public',
                          value: group['is_public'] == true ? 'Yes' : 'No',
                        ),
                        _InfoRow(
                          label: 'Invite Code',
                          value: group['invite_code'] as String? ?? 'N/A',
                        ),
                        _InfoRow(
                          label: 'Created',
                          value: DateTime.parse(group['created_at'] as String)
                              .toLocal()
                              .toString()
                              .split('.')[0],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _membersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Failed to load members: ${snapshot.error}',
                          ),
                        );
                      }
                      final members = snapshot.data!['members'] as List;
                      final currentUserId = AuthStore.user?.id;
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Members',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.cs.primaryContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${members.length} members',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: context.cs.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: members.length,
                              itemBuilder: (context, i) {
                                final m = members[i] as Map<String,
                                    dynamic>;
                                final role =
                                    m['role'] as String? ?? 'member';
                                final isCurrentUser =
                                    m['user_id'] == currentUserId;
                                final isOwner = role == 'owner';
                                return Container(
                                  width: 88,
                                  margin: const EdgeInsets.only(right: 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 26,
                                            backgroundColor:
                                                _getRoleColor(role)
                                                    .withValues(alpha: 0.2),
                                            child: Text(
                                              (m['name']
                                                          as String?
                                                          ??
                                                          'U')
                                                      [0]
                                                      .toUpperCase(),
                                                    style: TextStyle(
                                                      color: _getRoleColor(
                                                          role),
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                          ),
                                          if (role == 'owner')
                                            Positioned(
                                              right: -4,
                                              bottom: -4,
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .all(4),
                                                decoration: BoxDecoration(
                                                  color: context.cs
                                                      .secondary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.star,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          else if (role == 'admin')
                                            Positioned(
                                              right: -4,
                                              bottom: -4,
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .all(4),
                                                decoration: BoxDecoration(
                                                  color: context.cs
                                                      .primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.admin_panel_settings,
                                                  size: 10,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        m['name'] as String? ??
                                            'Unknown',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        role,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: context.cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 6),
                                      if (!isCurrentUser && !isOwner) ...[
                                        PopupMenuButton<String>(
                                          onSelected: (value) async {
                                            if (value == 'remove') {
                                              await _removeMember(
                                                m['user_id'] as String,
                                                m['name'] as String,
                                              );
                                            }
                                            if (value == 'make_admin') {
                                              await _updateMemberRole(
                                                m['user_id'] as String,
                                                'admin',
                                              );
                                            }
                                            if (value == 'make_member') {
                                              await _updateMemberRole(
                                                m['user_id'] as String,
                                                'member',
                                              );
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            if (role != 'admin')
                                              const PopupMenuItem(
                                                value: 'make_admin',
                                                child: Text('Make Admin'),
                                              ),
                                            if (role == 'admin')
                                              const PopupMenuItem(
                                                value: 'make_member',
                                                child: Text(
                                                    'Demote to Member'),
                                              ),
                                            PopupMenuItem(
                                              value: 'remove',
                                              child: Text(
                                                'Remove',
                                                style: TextStyle(
                                                  color: context.cs.error,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddMemberDialog() async {
    final emailCtrl = TextEditingController();
    String role = 'member';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Student to Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Student Email *',
                  hintText: 'student@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: 'member',
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'member'),
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
                final email = emailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await apiAddGroupMember(
                    widget.groupId,
                    email: email,
                    role: role,
                  );
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Student added successfully')),
                  );
                  _refresh();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed: ${e.message}')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(String userId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove "$name" from this group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: context.cs.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await apiRemoveGroupMember(widget.groupId, userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Member removed')));
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    }
  }

  Future<void> _updateMemberRole(String userId, String role) async {
    try {
      await apiUpdateGroupMemberRole(widget.groupId, userId, role);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Role updated to $role')));
      _refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed: ${e.message}')));
    }
  }
}

Color _getRoleColor(String role) {
  switch (role) {
    case 'owner':
      return AppTheme.secondary;
    case 'admin':
      return AppTheme.primary;
    default:
      return AppTheme.onSurfaceVariant;
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
