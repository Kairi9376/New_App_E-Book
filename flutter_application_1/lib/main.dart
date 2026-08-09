import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/auth_gate.dart';
import 'services/membership.dart';
import 'services/notification_service.dart';
import 'screens/login_screen.dart';
import 'screens/User/user_login_screen.dart';
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

  // # ເຮັດຫຍັງ: ເລືອກໜ້າ login ຕາມ platform ແທນທີ່ຈະໃຊ້ໜ້າດຽວກັນທຸກບ່ອນ
  // # ຍ້ອນຫຍັງ: Web ຕ້ອງເຂົ້າໄດ້ແຕ່ Admin/Employee ສ່ວນ Flutter App ຕ້ອງເຂົ້າໄດ້ແຕ່ User/Member
  // # ແກ້ຈາກສ່ວນໃດ: ຂອງເກົ່າ return const LoginScreen() ຢູ່ 2 ບ່ອນໂດຍບໍ່ສົນ platform
  // # ແກ້ເຮັດຫຍັງ: ຮວມການເລືອກໄວ້ຟັງຊັນດຽວ ໃຫ້ທັງການເປີດແອັບ ແລະ fallback ໃຊ້ຄ່າດຽວກັນ
  Widget get _loginScreenForPlatform =>
      AuthGate.audienceForPlatform == AuthAudience.staff
          ? const StaffLoginScreen()
          : const UserLoginScreen();

  Future<void> _checkSavedSession() async {
    final hasSession = await ApiService.loadSession();
    await NotificationService.init();

    // # ເຮັດຫຍັງ: ດຶງສະຖານະສະມາຊິກຫຼັງກູ້ session ຄືນ
    // # ຍ້ອນຫຍັງ: session ທີ່ເກັບໄວ້ມີແຕ່ຂໍ້ມູນ user ບໍ່ມີ subscription ຖ້າບໍ່ດຶງໃໝ່
    // #          ຜູ້ໃຊ້ທີ່ຊື້ແພັກເກັດແລ້ວ ພໍເປີດແອັບຮອບໜ້າຈະກາຍເປັນ General User ອີກ
    // # ແກ້ຈາກສ່ວນໃດ: _checkSavedSession() ທີ່ໂຫຼດແຕ່ session ກັບ notification
    // # ແກ້ເຮັດຫຍັງ: ທຸກໜ້າອ່ານ Membership.isPremiere ໄດ້ຄ່າຖືກຕັ້ງແຕ່ເປີດແອັບ
    if (hasSession && ApiService.currentUser != null) {
      await Membership.refresh();
    }
    if (!mounted) return;

    // # ເຮັດຫຍັງ: ກວດ role ຂອງ session ທີ່ກູ້ຄືນມາ ວ່າກົງກັບ platform ປັດຈຸບັນບໍ່
    // # ຍ້ອນຫຍັງ: session ເກົ່າທີ່ບັນທຶກໄວ້ກ່ອນການແຍກໜ້າ login (ຫຼື session ຂອງ Admin
    // #          ທີ່ຄ້າງຢູ່ໃນເຄື່ອງ) ຈະພາເຂົ້າ AdminDashboard ໄດ້ໂດຍບໍ່ຜ່ານໜ້າ login ເລີຍ
    // #          ເຮັດໃຫ້ການກັ້ນ role ຢູ່ໜ້າ login ບໍ່ມີຄວາມໝາຍ
    // # ແກ້ຈາກສ່ວນໃດ: ຂອງເກົ່າເຊື່ອ role ໃນ session ທັນທີແລ້ວແຍກທາງໄປ 3 dashboard
    // # ແກ້ເຮັດຫຍັງ: ຖ້າ role ຜິດ platform ໃຫ້ລ້າງ session ຖິ້ມ ແລ້ວກັບໄປໜ້າ login
    if (hasSession && ApiService.currentUser != null) {
      final role = ApiService.currentUser!['role'] ?? AuthGate.roleUser;

      if (!AuthGate.isAllowedHere(role)) {
        await ApiService.clearSession();
        if (!mounted) return;
        setState(() {
          _initialScreen = _loginScreenForPlatform;
          _isChecking = false;
        });
        return;
      }

      setState(() {
        if (role == AuthGate.roleAdmin) {
          _initialScreen = const AdminDashboardScreen();
        } else if (role == AuthGate.roleEmployee) {
          _initialScreen = const EmployeeDashboardScreen();
        } else {
          _initialScreen = const UserHomeScreen();
        }
        _isChecking = false;
      });
      return;
    }

    setState(() {
      _initialScreen = _loginScreenForPlatform;
      _isChecking = false;
    });
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
    return _initialScreen ?? _loginScreenForPlatform;
  }
}
