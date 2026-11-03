import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api.dart';
import '../auth_store.dart';
import '../main.dart';
import '../services/group_message_watcher.dart';
import '../services/notification_service.dart';
import '../widgets/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';
import 'student_notes.dart';
import 'student_assignments.dart';
import 'student_timetable.dart';
import 'student_announcements.dart';
import 'student_submission_kit.dart';
import 'student_groups.dart';
import 'growth_screen.dart';
import 'planner_screen.dart' hide StatCard;

/// Primary navigation tabs (M3: max 5 destinations in bottom nav).
enum _StudentTab {
  subjects,
  assignments,
  timetable,
  announcements,
  more,
}

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  _StudentTab _currentTab = _StudentTab.subjects;

  late Future<List<dynamic>> _subjectsFuture;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _loadSubjects();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      final granted = await NotificationService.hasPermission();
      if (!granted) {
        final prefs = await SharedPreferences.getInstance();
        final alreadyAsked = prefs.getBool('notif_permission_asked') ?? false;
        if (!alreadyAsked && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await NotificationService.requestPermissionWithHelp(context);
            await prefs.setBool('notif_permission_asked', true);
          });
        }
      }
    } catch (_) {}
    GroupMessageWatcher.instance.start();
  }

  @override
  void dispose() {
    GroupMessageWatcher.instance.stop();
    super.dispose();
  }

  Future<List<dynamic>> _loadSubjects() async {
    final data = await apiGet('/api/academic/my-subjects');
    return data['subjects'] as List<dynamic>;
  }

  Future<void> refreshSubjects() async {
    setState(() {
      _subjectsFuture = _loadSubjects();
    });
    await _subjectsFuture;
  }

  Future<void> _logout() async {
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case _StudentTab.subjects:
        return _SubjectsTab(
          subjectsFuture: _subjectsFuture,
          onRefresh: refreshSubjects,
        );
      case _StudentTab.assignments:
        return const StudentAssignmentsScreen();
      case _StudentTab.timetable:
        return const StudentTimetableScreen();
      case _StudentTab.announcements:
        return const StudentAnnouncementsScreen();
      case _StudentTab.more:
        return const _MoreTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Academic'),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            onPressed: () {
              themeNotifier.setTheme(
                themeNotifier.mode == AppThemeMode.dark
                    ? AppThemeMode.light
                    : AppThemeMode.dark,
              );
            },
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildTabContent(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _StudentTab.values.indexOf(_currentTab),
        onDestinationSelected: (i) =>
            setState(() => _currentTab = _StudentTab.values[i]),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Subjects',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Assignments',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Timetable',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Announce.',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

/// "More" tab — grid of secondary modules (Groups, Submission Kit, Growth, Planner).
class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        SectionHeader(
          title: 'More',
          subtitle: 'Additional academic tools',
          icon: Icons.more_horiz,
        ),
        const SizedBox(height: AppTheme.spaceLg),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppTheme.spaceMd,
          crossAxisSpacing: AppTheme.spaceMd,
          childAspectRatio: 1.15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _MoreTile(
              icon: Icons.groups_outlined,
              label: 'Groups',
              subtitle: 'Study groups & channels',
              color: context.cs.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentGroupsScreen(),
                ),
              ),
            ),
            _MoreTile(
              icon: Icons.insert_drive_file_outlined,
              label: 'Submission Kit',
              subtitle: 'Submission templates',
              color: context.cs.secondary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const StudentSubmissionKitScreen(),
                ),
              ),
            ),
            _MoreTile(
              icon: Icons.trending_up_outlined,
              label: 'Growth',
              subtitle: 'Academic growth index',
              color: context.cs.tertiary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GrowthScreen()),
              ),
            ),
            _MoreTile(
              icon: Icons.calendar_today_outlined,
              label: 'Planner',
              subtitle: 'Personal task planner',
              color: context.cs.primary,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PlannerScreen()),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                label,
                style: context.tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.cs.onSurface,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXs),
              Text(
                subtitle,
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubjectsTab extends StatelessWidget {
  final Future<List<dynamic>> subjectsFuture;
  final RefreshCallback onRefresh;

  const _SubjectsTab({
    required this.subjectsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: subjectsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(context);
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64),
                const SizedBox(height: AppTheme.spaceMd),
                Text(
                  'Failed to load subjects',
                  style: context.tt.titleLarge?.copyWith(
                    color: context.cs.error,
                  ),
                ),
                const SizedBox(height: AppTheme.spaceSm),
                Text(
                  snapshot.error.toString(),
                  style: context.tt.bodyMedium?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceLg),
                FilledButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        final subjects = snapshot.data!;
        if (subjects.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppTheme.spaceMd),
              children: [
                _buildStatsSection(context, subjects.length),
                const SizedBox(height: AppTheme.spaceXl),
                EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No Subjects Yet',
                  subtitle: 'Your subjects will appear here once you\'re '
                      'enrolled in a batch.',
                  iconColor: context.cs.primary,
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            children: [
              _buildStatsSection(context, subjects.length),
              const SizedBox(height: AppTheme.spaceLg),
              SectionHeader(
                title: 'My Subjects',
                subtitle: '${subjects.length} subject'
                    '${subjects.length != 1 ? 's' : ''} enrolled',
                icon: Icons.menu_book,
              ),
              ...subjects.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value as Map<String, dynamic>;
                return AnimatedListItem(
                  index: index,
                  child: SubjectCard(
                    code: s['code'] as String? ?? '',
                    name: s['name'] as String? ?? '',
                    teacherName: s['teacher_name'] as String? ?? 'Unknown',
                    color: _getSubjectColor(context, index),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentNotesScreen(
                          subjectId: s['id'] as String,
                          subjectCode: s['code'] as String,
                          subjectName: s['name'] as String,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSection(BuildContext context, int subjectCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Overview',
          subtitle: 'Your academic snapshot',
          icon: Icons.dashboard_outlined,
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Subjects',
                value: subjectCount.toString(),
                icon: Icons.menu_book,
                color: context.cs.primary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: StatCard(
                label: 'This Week',
                value: '—',
                icon: Icons.schedule,
                color: context.cs.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceMd),
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Pending',
                value: '—',
                icon: Icons.assignment_late,
                color: context.cs.tertiary,
              ),
            ),
            const SizedBox(width: AppTheme.spaceSm),
            Expanded(
              child: StatCard(
                label: 'Completed',
                value: '—',
                icon: Icons.check_circle,
                color: context.cs.tertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spaceMd),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(height: 28, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: AppTheme.spaceLg),
            Row(
              children: [
                Expanded(child: LoadingShimmer(height: 100)),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(child: LoadingShimmer(height: 100)),
              ],
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Row(
              children: [
                Expanded(child: LoadingShimmer(height: 100)),
                const SizedBox(width: AppTheme.spaceSm),
                Expanded(child: LoadingShimmer(height: 100)),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spaceLg),
        LoadingShimmer(height: 28, borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: AppTheme.spaceMd),
        ...List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spaceMd),
          child: LoadingShimmer(height: 88),
        )),
      ],
    );
  }

  Color _getSubjectColor(BuildContext context, int index) {
    final cs = context.cs;
    final colors = [
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primary,
      cs.secondary,
      cs.tertiary,
      cs.primary,
      cs.secondary,
      cs.tertiary,
    ];
    return colors[index % colors.length];
  }
}
