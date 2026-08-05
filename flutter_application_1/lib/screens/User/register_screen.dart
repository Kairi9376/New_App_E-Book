import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'user_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onRegisterPressed() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      setState(() => _isLoading = true);

      final res = await ApiService.register({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'password': _passwordController.text.trim(),
        'role': 'user', // Strictly General User Role
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (res['success'] == true) {
        final String registeredEmail = _emailController.text.trim().toLowerCase();

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Colors.white,
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'ລົງທະບຽນສຳເລັດແລ້ວ! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'ບັນຊີຜູ້ໃຊ້ "$registeredEmail" ຖືກສ້າງຮຽບຮ້ອຍແລ້ວ!\nກະລຸນາເຂົ້າສູ່ລະບົບດ້ວຍອີເມວ ແລະ ລະຫັດຜ່ານຂອງທ່ານ',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogCtx);
                      Navigator.pop(context, registeredEmail);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ໄປທີ່ໜ້າເຂົ້າສູ່ລະບົບ (Go to Login)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'ລົງທະບຽນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ລົງທະບຽນຜູ້ໃຊ້ໃໝ່',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Logo Icon
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Welcome Text
                const Text(
                  'ສ້າງບັນຊີຜູ້ໃຊ້ງານ e-Book',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ກະລຸນາປ້ອນຂໍ້ມູນດ້ານລຸ່ມເພື່ອສະໝັກສະມາຊິກໃໝ່',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Role Enforcement Notice Chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 20, color: AppColors.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ບັນຊີທີ່ລົງທະບຽນໃໝ່ນີ້ຈະໄດ້ຮັບສິດເປັນ: ຜູ້ໃຊ້ທົ່ວໄປ (General User) ເທົ່ານັ້ນ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Registration Form
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // First Name & Last Name Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'ຊື່ (First Name)',
                                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'ກະລຸນາປ້ອນຊື່';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'ນາມສະກຸນ (Last Name)',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'ກະລຸນາປ້ອນນາມສະກຸນ';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'ອີເມວ (Email) *',
                          hintText: 'example@gmail.com',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'ກະລຸນາປ້ອນອີເມວ';
                          }
                          if (!value.contains('@')) {
                            return 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Number Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'ເບີໂທລະສັບ (Phone Number) *',
                          hintText: '020 99887766 ຫຼື 2099887766',
                          prefixIcon: Icon(Icons.phone_android_rounded, color: AppColors.primary),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'ກະລຸນາປ້ອນເບີໂທລະສັບ';
                          }
                          if (value.trim().length < 6) {
                            return 'ເບີໂທລະສັບບໍ່ຖືກຕ້ອງ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'ລະຫັດຜ່ານ (Password)',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
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
                          if (value.length < 6) {
                            return 'ລະຫັດຜ່ານຕ້ອງມີຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _isConfirmPasswordObscured,
                        decoration: InputDecoration(
                          labelText: 'ຢືນຢັນລະຫັດຜ່ານ (Confirm Password)',
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordObscured
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ກະລຸນາປ້ອນຢືນຢັນລະຫັດຜ່ານ';
                          }
                          if (value != _passwordController.text) {
                            return 'ລະຫັດຜ່ານບໍ່ກົງກັນ';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Register Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _onRegisterPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'ລົງທະບຽນຜູ້ໃຊ້ງານ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Already Have Account Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ມີບັນຊີຢູ່ແລ້ວ?',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'ເຂົ້າສູ່ລະບົບ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
