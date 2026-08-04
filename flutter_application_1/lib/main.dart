import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/User/user_home_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/employee/employee_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Book App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isChecking = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final hasSession = await ApiService.loadSession();
    await NotificationService.init();
    if (mounted) {
      setState(() {
        if (hasSession && ApiService.currentUser != null) {
          final role = ApiService.currentUser!['role'] ?? 'user';
          if (role == 'admin') {
            _initialScreen = const AdminDashboardScreen();
          } else if (role == 'employee') {
            _initialScreen = const EmployeeDashboardScreen();
          } else {
            _initialScreen = const UserHomeScreen();
          }
        } else {
          _initialScreen = const LoginScreen();
        }
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return _initialScreen ?? const LoginScreen();
  }
}
