import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import '../../utils/image_helper.dart';

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
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _profileImageController;

  late String _selectedRole;
  late String _selectedStatus;
  bool _isStudent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isUploadingImage = false;
  String _profileImageUrl = '';

  final List<String> _roles = ['admin', 'employee', 'user'];
  final List<String> _statuses = ['active', 'suspended', 'banned'];

  // Preset avatar recommendations for quick selection
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
  ];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _firstNameController = TextEditingController(text: u?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: u?['last_name'] ?? '');
    _emailController = TextEditingController(text: u?['email'] ?? '');
    _phoneController = TextEditingController(text: u?['phone_number'] ?? u?['phone'] ?? '');
    _passwordController = TextEditingController();
    
    _profileImageUrl = (u?['profile_image_url'] ?? u?['profile_image'] ?? u?['avatar_url'] ?? u?['avatar'] ?? '').toString();
    _profileImageController = TextEditingController(text: _profileImageUrl);

    _selectedRole = (u?['role'] ?? 'user').toString().toLowerCase();
    if (!_roles.contains(_selectedRole)) _selectedRole = 'user';

    _selectedStatus = (u?['status'] ?? 'active').toString().toLowerCase();
    if (!_statuses.contains(_selectedStatus)) _selectedStatus = 'active';

    _isStudent = (u?['is_student'] == 1 || u?['is_student'] == true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _profileImageController.dispose();
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

  Future<void> _pickProfileImage() async {
    setState(() => _isUploadingImage = true);
    try {
      final fileInfo = await FilePickerHelper.pickFile(accept: 'image/*');
      if (fileInfo != null) {
        // Mock image upload or data URL string
        final mockUrl = 'assets/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        setState(() {
          _profileImageUrl = mockUrl;
          _profileImageController.text = mockUrl;
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final isEditing = widget.user != null;
      final userId = widget.user?['user_id'] ?? widget.user?['id'];

      final Map<String, dynamic> userData = {
        if (userId != null) 'user_id': userId,
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim().toLowerCase(),
        'phone_number': _phoneController.text.trim(),
        'role': _selectedRole,
        'status': _selectedStatus,
        'is_student': _isStudent ? 1 : 0,
        'profile_image_url': _profileImageUrl.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        userData['password'] = _passwordController.text.trim();
      }

      bool success = false;
      if (isEditing && userId != null) {
        final parsedId = int.tryParse(userId.toString()) ?? 1;
        success = await ApiService.updateUser(parsedId, userData);
      } else {
        success = await ApiService.createUser(userData);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'บันทึกข้อมูลผู้ใช้เรียบร้อยแล้ว' : 'สร้างบัญชีผู้ใช้ใหม่เรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการบันทึกข้อมูล'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
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
      elevation: 10,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Title & Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRoleColor(_selectedRole).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEditing ? Icons.manage_accounts_rounded : Icons.person_add_alt_1_rounded,
                          color: _getRoleColor(_selectedRole),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'แก้ไขข้อมูลผู้ใช้ (Edit User)' : 'เพิ่มผู้ใช้ใหม่ (Add User)',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isEditing
                                ? 'ปรับปรุงรายละเอียดโปรไฟล์และสิทธิ์การใช้งาน'
                                : 'สร้างบัญชีผู้ใช้ใหม่สำหรับ Admin / พนักงาน / สมาชิก',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
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

              // Profile Picture Upload & Avatar Picker Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getRoleColor(_selectedRole).withOpacity(0.1),
                            border: Border.all(color: _getRoleColor(_selectedRole), width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _profileImageUrl.isNotEmpty
                                ? ImageHelper.buildImage(
                                    _profileImageUrl,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Text(
                                      firstChar,
                                      style: TextStyle(
                                        color: _getRoleColor(_selectedRole),
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        InkWell(
                          onTap: _isUploadingImage ? null : _pickProfileImage,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _pickProfileImage,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('อัปโหลดรูปโปรไฟล์ (Upload Photo)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),

                    // Quick Preset Avatars
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _presetAvatars.map((url) {
                          final isSelected = _profileImageUrl == url;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _profileImageUrl = url;
                                _profileImageController.text = url;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(url),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Form Section
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title: Personal Info
                    const Text('ข้อมูลส่วนตัว (Personal Details)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 10),

                    // First Name & Last Name Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อ (First Name) *',
                              prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'กรุณากรอกชื่อ' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: 'นามสกุล (Last Name) *',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty ? 'กรุณากรอกนามสกุล' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Email & Phone Number Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'อีเมล (Email) *',
                              hintText: 'example@gmail.com',
                              prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'กรุณากรอกอีเมล';
                              if (!val.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'เบอร์โทรศัพท์ (Phone)',
                              hintText: '020-XXXX-XXXX',
                              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section Title: Security & Role
                    const Text('สิทธิ์และระบบความปลอดภัย (Security & Role)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 10),

                    // Role & Account Status Dropdowns Row
                    Row(
                      children: [
                        // Role Selection
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: const InputDecoration(
                              labelText: 'สิทธิ์การใช้งาน (Role) *',
                              prefixIcon: Icon(Icons.security_rounded, color: AppColors.primary),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'user', child: Text('User (ผู้ใช้ทั่วไป)')),
                              DropdownMenuItem(value: 'employee', child: Text('Employee (พนักงาน)')),
                              DropdownMenuItem(value: 'admin', child: Text('Admin (ผู้ดูแลระบบ)')),
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
                              labelText: 'สถานะบัญชี (Status) *',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'active',
                                child: Text('Active (ปกติ)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'suspended',
                                child: Text('Suspended (ระงับ)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                              ),
                              DropdownMenuItem(
                                value: 'banned',
                                child: Text('Banned (บล็อก)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                    const SizedBox(height: 14),

                    // Password Input Field with Eye Toggle
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: isEditing ? 'รหัสผ่านใหม่ (ว่างไว้หากไม่ต้องการเปลี่ยน)' : 'รหัสผ่าน (Password) *',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (!isEditing && (val == null || val.trim().isEmpty)) {
                          return 'กรุณากรอกรหัสผ่านสำหรับบัญชีใหม่';
                        }
                        if (val != null && val.isNotEmpty && val.length < 6) {
                          return 'รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Student & Premiere Member Status Switch
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'สถานะนักเรียน / สมาชิกพรีเมี่ยม (Student / Premiere Member)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text(
                          'เปิดใช้งานสิทธิ์ส่วนลดและสิทธิพิเศษสำหรับนักเรียนนักศึกษา',
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
                            child: const Text('ยกเลิก (Cancel)'),
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
                                : Text(isEditing ? 'บันทึกการแก้ไข' : 'สร้างบัญชีผู้ใช้'),
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
