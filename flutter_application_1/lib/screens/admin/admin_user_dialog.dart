import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminUserDialog extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AdminUserDialog({super.key, this.user});

  @override
  State<AdminUserDialog> createState() => _AdminUserDialogState();
}

class _AdminUserDialogState extends State<AdminUserDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isStudent = false;
  bool _isLoading = false;

  final List<String> _roles = ['admin', 'employee', 'user'];
  final List<String> _statuses = ['active', 'suspended'];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: widget.user?['last_name'] ?? '');
    _emailController = TextEditingController(text: widget.user?['email'] ?? '');
    _passwordController = TextEditingController();

    _selectedRole = (widget.user?['role'] ?? 'user').toString().toLowerCase();
    if (!_roles.contains(_selectedRole)) _selectedRole = 'user';

    _selectedStatus = (widget.user?['status'] ?? 'active').toString().toLowerCase();
    if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'active';

    _isStudent = (widget.user?['is_student'] == 1 || widget.user?['is_student'] == true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'employee':
        return Colors.orange.shade800;
      case 'user':
      default:
        return AppColors.primary;
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final Map<String, dynamic> resultData = {
        if (widget.user != null) 'user_id': widget.user!['user_id'] ?? widget.user!['id'],
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'role': _selectedRole,
        'status': _selectedStatus,
        'is_student': _isStudent ? 1 : 0,
      };

      if (_passwordController.text.isNotEmpty) {
        resultData['password'] = _passwordController.text.trim();
      }

      await Future.delayed(const Duration(milliseconds: 300)); // Smooth UI transition

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context, resultData);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.user != null;
    final firstChar = _firstNameController.text.isNotEmpty
        ? _firstNameController.text[0].toUpperCase()
        : 'U';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row: Avatar & Title & Close Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _getRoleColor(_selectedRole),
                    child: Text(
                      firstChar,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEditing ? 'ແກ້ໄຂຂໍ້ມູນຜູ້ໃຊ້' : 'ເພີ່ມຜູ້ໃຊ້ໃໝ່',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isEditing
                              ? 'ແກ້ໄຂລາຍລະອຽດບັນຊີຜູ້ໃຊ້ງານໃນລະບົບ'
                              : 'ສ້າງບັນຊີຜູ້ໃຊ້ໃໝ່ສຳລັບ Admin/ພະນັກງານ/ຜູ້ໃຊ້',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 20),

              // Form Section
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
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'ນາມສະກຸນ (Last Name)',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'ກະລຸນາປ້ອນນາມສະກຸນ' : null,
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
                        labelText: 'ອີເມວ (Email)',
                        hintText: 'example@gmail.com',
                        prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'ກະລຸນາປ້ອນອີເມວ';
                        if (!val.contains('@')) return 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Role & Account Status Dropdowns Row
                    Row(
                      children: [
                        // Role Selection
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'ສິດການນຳໃຊ້ (Role)',
                              prefixIcon: Icon(Icons.security_rounded, color: AppColors.primary),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'user', child: Text('User (ທົ່ວໄປ)')),
                              DropdownMenuItem(value: 'employee', child: Text('Employee (ພະນັກງານ)')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin (ຜູ້ດູແລ)')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRole = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Account Status Selection
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'ສະຖານະບັນຊີ (Status)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active (ປົກກະຕິ)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'suspended',
                                child: Text('Suspended (ລະງັບ)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password Input Field (Optional for edit, required for creation)
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'ລະຫັດຜ່ານໃໝ່ (ບໍ່ປ້ອນຫາກບໍ່ປ່ຽນ)' : 'ລະຫັດຜ່ານ (Password)',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                      ),
                      validator: (val) {
                        if (!isEditing && (val == null || val.trim().isEmpty)) {
                          return 'ກະລຸນາປ້ອນລະຫັດຜ່ານສຳລັບບັນຊີໃໝ່';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Student Status Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'ສະຖານະນັກຮຽນ / ສະມາຊິກພຣີມ່ຽມ',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'ເປີດນຳໃຊ້ສິດສ່ວນຫຼຸດພິເສດສຳລັບນັກຮຽນ',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        value: _isStudent,
                        activeColor: AppColors.primary,
                        onChanged: (val) => setState(() => _isStudent = val),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('ຍົກເລີກ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _onSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48),
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(isEditing ? 'ບັນທຶກການແກ້ໄຂ' : 'ສ້າງບັນຊີຜູ້ໃຊ້'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
