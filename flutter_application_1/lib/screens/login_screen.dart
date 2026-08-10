import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_gate.dart';
import 'admin/admin_dashboard_screen.dart';
import 'employee/employee_dashboard_screen.dart';

// # ເຮັດຫຍັງ: ປ່ຽນໜ້ານີ້ຈາກ login ລວມທຸກ role ມາເປັນ login ສະເພາະ Staff (Admin/Employee) ບົນ Web
// # ຍ້ອນຫຍັງ: ຕາມທີ່ກຳນົດໄວ້ Admin ຕ້ອງເຮັດວຽກຢູ່ Web ເທົ່ານັ້ນ ບໍ່ກ່ຽວຂ້ອງກັບ Flutter App
// # ແກ້ຈາກສ່ວນໃດ: ຂອງເກົ່າຊື່ LoginScreen ຮັບທຸກ role ແລ້ວແຍກທາງໄປ 3 ໜ້າ
// #              (Admin / Employee / User) ຈາກໜ້າດຽວກັນ
// # ແກ້ເຮັດຫຍັງ: ເຫຼືອແຕ່ 2 ທາງ (Admin/Employee) ແລະ ປະຕິເສດບັນຊີຜູ້ໃຊ້ທົ່ວໄປ
// #             ສ່ວນ User/Member ຍ້າຍໄປ UserLoginScreen ໃນ screens/User/user_login_screen.dart
class StaffLoginScreen extends StatefulWidget {
  const StaffLoginScreen({super.key});

  @override
  State<StaffLoginScreen> createState() => _StaffLoginScreenState();
}

class _StaffLoginScreenState extends State<StaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _onLoginPressed() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final result = await ApiService.login(email, password);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog

      if (result['success'] == true) {
        final user = result['user'] ?? {};
        final role = user['role'] ?? AuthGate.roleUser;

        // # ເຮັດຫຍັງ: ກວດ role ຕໍ່ platform ກ່ອນ ຖ້າບໍ່ແມ່ນ Staff ໃຫ້ລ້າງ session ຖິ້ມ
        // # ຍ້ອນຫຍັງ: ApiService.login ບັນທຶກ session ໄວ້ແລ້ວຕັ້ງແຕ່ຕອນ request ສຳເລັດ
        // #          ຖ້າພຽງແຕ່ບໍ່ navigate ຜູ້ໃຊ້ທົ່ວໄປຈະຍັງຄ້າງ login ຢູ່ ແລ້ວໂຫຼດໜ້າໃໝ່
        // #          ຈະຖືກກູ້ session ເຂົ້າລະບົບໄດ້ ກາຍເປັນຊ່ອງຮົ່ວ
        // # ແກ້ຈາກສ່ວນໃດ: ຂອງເກົ່າມີ else ສຸດທ້າຍພາ role ອື່ນໄປ UserHomeScreen ໂດຍບໍ່ກວດຫຍັງ
        // # ແກ້ເຮັດຫຍັງ: ຕັດ session ຖິ້ມ ແລ້ວແຈ້ງເຫດຜົນ ບໍ່ໃຫ້ຄ້າງສະຖານະເຄິ່ງກາງ
        if (!AuthGate.isAllowedHere(role)) {
          await ApiService.clearSession();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AuthGate.deniedMessage(role)),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        if (role == AuthGate.roleAdmin) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ເຂົ້າສູ່ລະບົບສຳເລັດໃນຖານະ: Admin (ຜູ້ດູແລລະບົບ)'),
              backgroundColor: AppColors.primary,
            ),
          );
          _navigateTo(const AdminDashboardScreen());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ເຂົ້າສູ່ລະບົບສຳເລັດໃນຖານະ: Employee (ພະນັກງານຈັດການ PDF)'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
          _navigateTo(const EmployeeDashboardScreen());
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ ກະລຸນາລອງໃໝ່ອີກຄັ້ງ'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    size: 48,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // # ເຮັດຫຍັງ: ປ່ຽນຫົວຂໍ້ໃຫ້ບອກຊັດວ່າເປັນປະຕູຂອງພະນັກງານ
                // # ຍ້ອນຫຍັງ: ຫົວຂໍ້ເກົ່າຂຽນວ່າ "ສຳລັບ Admin, ພະນັກງານ ແລະ ຜູ້ໃຊ້ງານ"
                // #          ເຊິ່ງບໍ່ຈິງອີກຕໍ່ໄປ ຜູ້ໃຊ້ທົ່ວໄປຈະລອງ login ຢູ່ນີ້ແລ້ວຖືກປະຕິເສດ
                // # ແກ້ຈາກສ່ວນໃດ: ຂໍ້ຄວາມສ່ວນຫົວຂອງໜ້າ login ເດີມ
                // # ແກ້ເຮັດຫຍັງ: ບອກແຕ່ຕົ້ນວ່າໜ້ານີ້ແມ່ນ Staff Portal ສະເພາະ Web
                const Text(
                  'ເຂົ້າສູ່ລະບົບຜູ້ດູແລ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ລະບົບຈັດການ E-Book ສຳລັບ Admin ແລະ ພະນັກງານ (Web ເທົ່ານັ້ນ)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ອີເມວ ຫຼື ເບີໂທລະສັບ (Email or Phone)',
                          hintText: 'example@gmail.com ຫຼື 020 99887766',
                          prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'ກະລຸນາປ້ອນອີເມວ ຫຼື ເບີໂທລະສັບ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'ລະຫັດຜ່ານ',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາປ້ອນລະຫັດຜ່ານ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ຈື່ຂ້ອຍໄວ້ໃນລະບົບ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'ລືມລະຫັດຜ່ານ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onLoginPressed,
                    child: const Text('ເຂົ້າສູ່ລະບົບ'),
                  ),
                ),
                // # ເຮັດຫຍັງ: ຕັດແຖວລິ້ງ "ລົງທະບຽນຜູ້ໃຊ້ໃໝ່" ອອກຈາກໜ້າ Staff
                // # ຍ້ອນຫຍັງ: ບັນຊີ Admin/ພະນັກງານ ຕ້ອງຖືກສ້າງໂດຍຜູ້ດູແລ ບໍ່ແມ່ນສະໝັກເອງ
                // #          ແລະ ບັນຊີທີ່ສະໝັກຜ່ານໜ້ານີ້ຈະໄດ້ role=user ເຊິ່ງ login ຢູ່ Web ບໍ່ໄດ້
                // #          ຢູ່ແລ້ວ ກາຍເປັນທາງຕັນໃຫ້ຜູ້ໃຊ້
                // # ແກ້ຈາກສ່ວນໃດ: Register Link Row ເດີມທີ່ push ໄປ RegisterScreen
                // # ແກ້ເຮັດຫຍັງ: ຍ້າຍລິ້ງລົງທະບຽນໄປໄວ້ທີ່ UserLoginScreen ຝັ່ງແອັບແທນ
                const SizedBox(height: 20),

                // Mock Accounts Reference Helper Box
                // # ເຮັດຫຍັງ: ຕັດກ່ອງ "ບັນຊີສຳລັບທົດລອງລະບົບ (Mock Data)" ອອກ
                // # ຍ້ອນຫຍັງ: ເປັນອີເມວ ແລະ ລະຫັດຜ່ານທີ່ hardcode ໄວ້ໃນ UI ຊຶ່ງ
                // #          ຜູ້ໃຊ້ທົ່ວໄປເຫັນໄດ້ໝົດ - ໃຜເປີດແອັບກໍ່ຮູ້ລະຫັດ admin ທັນທີ
                // #          ແລະ ຄ່າເຫຼົ່ານີ້ຈະລ້າສະໄໝທັນທີທີ່ປ່ຽນລະຫັດຜ່ານໃນຖານຂໍ້ມູນ
                // # ແກ້ຈາກສ່ວນໃດ: Container ກ່ອງ Mock Data ພ້ອມ _buildCredentialRow
                // # ແກ້ເຮັດຫຍັງ: ບັນຊີທົດລອງຍ້າຍໄປຢູ່ seed (Backend/database.sql) ແລະ
                // #             ເອກະສານ GEMINI.md ຂໍ້ 3 ແທນ ບໍ່ຢູ່ໃນ UI ທີ່ສົ່ງໃຫ້ຜູ້ໃຊ້

              ],
            ),
          ),
        ),
      ),
    );
  }

}
