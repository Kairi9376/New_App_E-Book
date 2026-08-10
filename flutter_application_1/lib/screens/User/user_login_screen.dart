import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_gate.dart';
import 'user_home_screen.dart';
import 'register_screen.dart';

// # ເຮັດຫຍັງ: ເພີ່ມໜ້າ login ໃໝ່ສະເພາະຝັ່ງ Flutter App (ຜູ້ໃຊ້ທົ່ວໄປ ແລະ Premiere Member)
// # ຍ້ອນຫຍັງ: ຕາມທີ່ກຳນົດໄວ້ ໃຫ້ແຍກໜ້າ login ຕາມ role ໂດຍ User/Member ຢູ່ແອັບ
// #          ສ່ວນ Admin/Employee ຢູ່ Web ບໍ່ປົນກັນ
// # ແກ້ຈາກສ່ວນໃດ: ແຍກອອກມາຈາກ screens/login_screen.dart ທີ່ແຕ່ກ່ອນຮັບທຸກ role ໃນໜ້າດຽວ
// # ແກ້ເຮັດຫຍັງ: ໜ້ານີ້ຮັບແຕ່ບັນຊີຜູ້ໃຊ້ ແລະ ເປັນບ່ອນດຽວທີ່ຍັງມີລິ້ງລົງທະບຽນ
// #             ເພາະມີແຕ່ບັນຊີຜູ້ໃຊ້ເທົ່ານັ້ນທີ່ສະໝັກເອງໄດ້
class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
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

        // # ເຮັດຫຍັງ: ປະຕິເສດບັນຊີ Admin/Employee ພ້ອມລ້າງ session ຖິ້ມ
        // # ຍ້ອນຫຍັງ: ApiService.login ບັນທຶກ session ໄວ້ແລ້ວກ່ອນທີ່ເຮົາຈະກວດ role
        // #          ຖ້າພຽງແຕ່ບໍ່ navigate ບັນຊີ Admin ຈະຄ້າງຢູ່ໃນ SharedPreferences
        // #          ຂອງເຄື່ອງ ແລ້ວຖືກກູ້ຄືນຕອນເປີດແອັບຮອບໜ້າ
        // # ແກ້ຈາກສ່ວນໃດ: ຕັດສິນໃຈດ້ວຍ AuthGate ດຽວກັນກັບໜ້າ Staff ບໍ່ຂຽນເງື່ອນໄຂຊ້ຳ
        // # ແກ້ເຮັດຫຍັງ: ຮັບປະກັນວ່າ Admin ບໍ່ມີທາງເຂົ້າເຖິງຜ່ານແອັບໄດ້ເລີຍ
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

        // "Member" ບໍ່ແມ່ນ role ໃນຖານຂໍ້ມູນ ແຕ່ແມ່ນ user ທີ່ມີ subscription ຢູ່
        final isMember = (user['is_member'] == true) ||
            (user['subscription_status']?.toString() == 'active');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ເຂົ້າສູ່ລະບົບສຳເລັດໃນຖານະ: ${isMember ? 'Premiere Member' : 'ຜູ້ໃຊ້ທົ່ວໄປ'}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
        _navigateTo(const UserHomeScreen());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ??
                'ອີເມວ ຫຼື ລະຫັດຜ່ານບໍ່ຖືກຕ້ອງ ກະລຸນາລອງໃໝ່ອີກຄັ້ງ'),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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

                const Text(
                  'ຍິນດີຕ້ອນຮັບ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ເຂົ້າສູ່ລະບົບເພື່ອອ່ານ ແລະ ບັນທຶກປຶ້ມທີ່ທ່ານມັກ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

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
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: AppColors.primary),
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
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColors.primary),
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
                const SizedBox(height: 16),

                // # ເຮັດຫຍັງ: ຍ້າຍລິ້ງລົງທະບຽນມາໄວ້ໜ້ານີ້
                // # ຍ້ອນຫຍັງ: ບັນຊີທີ່ສະໝັກເອງໄດ້ຮັບ role=user ຈຶ່ງເໝາະກັບຝັ່ງແອັບເທົ່ານັ້ນ
                // # ແກ້ຈາກສ່ວນໃດ: ຍົກມາຈາກ Register Link Row ໃນ screens/login_screen.dart ເດີມ
                // # ແກ້ເຮັດຫຍັງ: ຜູ້ໃຊ້ໃໝ່ສະໝັກແລ້ວເຂົ້າໃຊ້ໄດ້ທັນທີໃນທາງດຽວກັນ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ຍັງບໍ່ມີບັນຊີຜູ້ໃຊ້?',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () async {
                        final registeredEmail = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                        if (registeredEmail != null &&
                            registeredEmail.isNotEmpty) {
                          setState(() {
                            _emailController.text = registeredEmail;
                            _passwordController.clear();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'ກະລຸນາປ້ອນລະຫັດຜ່ານຂອງ "$registeredEmail" ເພື່ອເຂົ້າສູ່ລະບົບ'),
                                backgroundColor: AppColors.primary,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'ລົງທະບຽນຜູ້ໃຊ້ໃໝ່',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // # ເຮັດຫຍັງ: ກ່ອງບັນຊີທົດລອງເຫຼືອແຕ່ຝັ່ງຜູ້ໃຊ້
                // # ຍ້ອນຫຍັງ: ບັນຊີ Admin/Employee ເຂົ້າຜ່ານແອັບບໍ່ໄດ້ ຈຶ່ງບໍ່ຄວນສະແດງໄວ້ນີ້
                // # ແກ້ຈາກສ່ວນໃດ: ຄັດມາຈາກກ່ອງ Mock Data ໃນ login_screen.dart ທີ່ມີຄົບ 4 ບັນຊີ
                // # ແກ້ເຮັດຫຍັງ: ຜູ້ທົດສອບເຫັນສະເພາະບັນຊີທີ່ໃຊ້ໄດ້ຈິງໃນຊ່ອງທາງນີ້
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
