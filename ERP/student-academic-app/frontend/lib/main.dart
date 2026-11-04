import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_store.dart';
import 'screens/login_screen.dart';
import 'screens/student_home.dart';
import 'screens/teacher_home.dart';
import 'screens/parent_home.dart';
import 'services/notification_service.dart';
import 'widgets/app_theme.dart';

enum AppThemeMode { system, light, dark }

class ThemeNotifier extends ChangeNotifier {
  AppThemeMode _mode = AppThemeMode.system;

  AppThemeMode get mode => _mode;

  ThemeNotifier() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('theme_mode') ?? 0;
    _mode = AppThemeMode.values[index];
    notifyListeners();
  }

  Future<void> setTheme(AppThemeMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
    notifyListeners();
  }

  ThemeMode get themeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

final themeNotifier = ThemeNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthStore.load();
  await themeNotifier._loadTheme();
  await NotificationService.init();
  await NotificationService.requestPermission();
  runApp(const StudentAcademicApp());
}

Widget homeForRole(String role) {
  switch (role) {
    case 'teacher':
      return const TeacherHomeScreen();
    case 'parent':
      return const ParentHomeScreen();
    default:
      return const StudentHomeScreen();
  }
}

class StudentAcademicApp extends StatelessWidget {
  const StudentAcademicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Student Academic',
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeNotifier.themeMode,
          home: AuthStore.isLoggedIn
              ? homeForRole(AuthStore.user?.role ?? '')
              : const LoginScreen(),
        );
      },
    );
  }
}
