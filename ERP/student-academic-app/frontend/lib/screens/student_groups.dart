import 'package:flutter/material.dart';

import '../api.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'group_chat.dart';

String friendlyErrorMessage(dynamic error) => 'Error: $error';

class Group {
  final String id;
  final String name;
  final String? description;
  final String type;
  final String inviteCode;
  final bool isPublic;
  final int? memberCount;
  final String? role;
  final DateTime? mutedUntil;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.inviteCode,
    required this.isPublic,
    this.memberCount,
    this.role,
    this.mutedUntil,
  });

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        type: json['type'] as String,
        inviteCode: json['invite_code'] as String,
        isPublic: json['is_public'] as bool? ?? false,
        memberCount: _parseMemberCount(json['member_count']),
        role: json['role'] as String?,
        mutedUntil: json['muted_until'] != null
            ? DateTime.parse(json['muted_until'] as String)
            : null,
      );

  static int? _parseMemberCount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  String get typeLabel => type == 'channel' ? 'Channel' : 'Group';
  Color get typeColor =>
      type == 'channel' ? AppTheme.tertiary : AppTheme.primary;
}

class StudentGroupsScreen extends StatefulWidget {
  const StudentGroupsScreen({super.key});

  @override
  State<StudentGroupsScreen> createState() => _StudentGroupsScreenState();
}

class _StudentGroupsScreenState extends State<StudentGroupsScreen> {
  late Future<Map<String, dynamic>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: \$e')),
      );
    }
  }

  Future<void> _showJoinDialog() async {
    final codeCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the invite code to join a group'),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Invite Code *',
                hintText: 'e.g., ABC123XY',
              ),
              textCapitalization: TextCapitalization.characters,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.isEmpty) return;
              try {
                await apiJoinGroup(code);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Joined group successfully')),
                );
                _refresh();
              } on ApiException catch (e) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text('Failed: \$e')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  List<Group> _filterGroups(List<Group> groups) {
    return groups.where((g) {
      final matchesSearch = _searchQuery.isEmpty ||
          g.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (g.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          g.inviteCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesType = _filterType == 'all' || g.type == _filterType;
      return matchesSearch && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            tooltip: 'Join Group',
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.group_add),
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
            return Center(child: Text(friendlyErrorMessage(snapshot.error)));
          }
          final groupsData = snapshot.data!['groups'] as List;
          final groups = groupsData.map((g) => Group.fromJson(g)).toList();
          final filtered = _filterGroups(groups);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Groups',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        )),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () {
                            _showFilterDialog(context);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: EmptyState(
                          icon: Icons.groups,
                          title: 'No groups found',
                          subtitle: 'Try adjusting your search or filters.',
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final g = filtered[index];
                          return GroupCard(
                            group: g,
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => GroupDetailScreen(
                                  groupId: g.id,
                                  groupName: g.name,
                                ),
                              ));
                            },
                            onChat: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => GroupChatScreen(
                                  groupId: g.id,
                                  groupName: g.name,
                                  groupType: g.type,
                                ),
                              ));
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Groups'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _filterType,
                onChanged: (v) => setState(() => _filterType = v!),
              ),
            ),
            ListTile(
              title: const Text('Groups'),
              leading: Radio<String>(
                value: 'group',
                groupValue: _filterType,
                onChanged: (v) => setState(() => _filterType = v!),
              ),
            ),
            ListTile(
              title: const Text('Channels'),
              leading: Radio<String>(
                value: 'channel',
                groupValue: _filterType,
                onChanged: (v) => setState(() => _filterType = v!),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final Group group;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const GroupCard({
    required this.group,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      group.typeColor.withValues(alpha: 0.8),
                      group.typeColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  group.type == 'channel' ? Icons.campaign : Icons.group,
                  color: context.cs.onPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      group.typeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: group.typeColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people_outline, size: 14,
                            color: context.cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '\${group.memberCount ?? 0} members',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (group.isPublic) ...[
                          Icon(Icons.public, size: 14,
                              color: context.cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Public',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onChat != null)
                IconButton(
                  tooltip: 'Open Chat',
                  icon: Icon(Icons.chat_bubble_outline,
                      color: Theme.of(context).colorScheme.primary),
                  onPressed: onChat,
                )
            ],
          ),
        ),
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
  final String _groupType = 'group';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    return apiGetGroup(widget.groupId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refresh failed: \$e')),
      );
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
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GroupChatScreen(
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  groupType: _groupType,
                ),
              ));
            },
            icon: const Icon(Icons.chat),
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
            return Center(child: Text(friendlyErrorMessage(snapshot.error)));
          }
          final group = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                group['type'] == 'channel'
                                    ? context.cs.tertiary.withValues(alpha: 0.8)
                                    : context.cs.primary.withValues(alpha: 0.8),
                                group['type'] == 'channel'
                                    ? context.cs.tertiary
                                    : context.cs.primary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            group['type'] == 'channel'
                                ? Icons.campaign
                                : Icons.group,
                            color: context.cs.onPrimary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group['name'] as String? ?? 'Unknown',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                (group['type'] as String? ?? 'group') == 'channel'
                                    ? 'Channel (Broadcast)'
                                    : 'Group (Chat)',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: (group['type'] as String? ?? 'group') == 'channel'
                                          ? context.cs.tertiary
                                          : context.cs.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<Map<String, dynamic>>(
                      future: apiGetGroupMembers(widget.groupId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Column(
                            children: [
                              SectionHeader(
                                title: 'Members',
                                subtitle: 'Loading members...',
                                icon: Icons.people,
                              ),
                              const SizedBox(height: 8),
                            ] + List.generate(5, (i) => LoadingShimmer(
                              height: 72,
                              borderRadius: BorderRadius.circular(12),
                            )),
                          );
                        }
                        if (snapshot.hasError) {
                          return Column(
                            children: [
                              SectionHeader(
                                title: 'Members',
                                subtitle: 'Failed to load members',
                                icon: Icons.people,
                              ),
                              const SizedBox(height: 8),
                              Center(
                                child: Text('Failed to load members: \$snapshot.error'),
                              ),
                            ],
                          );
                        }
                        final members = snapshot.data!['members'] as List;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SectionHeader(
                                    title: 'Members',
                                    subtitle: '${members.length} total',
                                    icon: Icons.people,
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
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 90,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: members.length,
                                itemBuilder: (context, i) {
                                  final m = members[i] as Map<String, dynamic>;
                                  final role = m['role'] as String? ?? 'member';
                                  final name = m['name'] as String? ?? 'Unknown';
                                  final email = m['email'] as String? ?? '';
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
                                                  _getRoleColor(
                                                        context,
                                                        role,
                                                      )
                                                      .withValues(alpha: 0.2),
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: _getRoleColor(
                                                        context,
                                                        role,
                                                      ),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (role == 'owner')
                                              Positioned(
                                                right: -4,
                                                bottom: -4,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        context.cs.secondary,
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
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        context.cs.primary,
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
                                          name,
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
                                        const SizedBox(height: 2),
                                        Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 8,
                                            color:
                                                context.cs.onSurfaceVariant,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
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
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    final cs = context.cs;
    switch (role) {
      case 'owner':
        return cs.tertiary;
      case 'admin':
        return cs.primary;
      default:
        return cs.onSurfaceVariant;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.cs.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

