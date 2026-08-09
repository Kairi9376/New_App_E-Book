import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import '../../utils/image_helper.dart';

class AdminUserFormScreen extends StatefulWidget {
  final Map<String, dynamic>? user;

  const AdminUserFormScreen({super.key, this.user});

  @override
  State<AdminUserFormScreen> createState() => _AdminUserFormScreenState();
}

class _AdminUserFormScreenState extends State<AdminUserFormScreen> {
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
      if (fileInfo != null && fileInfo.bytes.isNotEmpty) {
        final res = await ApiService.uploadFile(
          bytes: fileInfo.bytes,
          filename: fileInfo.name,
          fieldName: 'profile',
        );
        final uploadedUrl = res['url'] ?? res['path'] ?? '';
        if (uploadedUrl.toString().isNotEmpty) {
          setState(() {
            _profileImageUrl = uploadedUrl.toString();
            _profileImageController.text = uploadedUrl.toString();
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking profile image: $e');
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
          ApiService.logAudit(
            action: isEditing ? 'ແກ້ໄຂຂໍ້ມູນຜູ້ໃຊ້' : 'ເພີ່ມຜູ້ໃຊ້ໃໝ່',
            details: '${isEditing ? "ແກ້ໄຂ" : "ເພີ່ມ"} ບັນຊີຜູ້ໃຊ້ "${_emailController.text.trim()}" (Role: $_selectedRole)',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing ? 'ບັນທຶກຂໍ້ມູນຜູ້ໃຊ້ສຳເລັດແລ້ວ' : 'ສ້າງບັນຊີຜູ້ໃຊ້ໃໝ່ສຳເລັດແລ້ວ'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນ'),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ແກ້ໄຂຂໍ້ມູນຜູ້ໃຊ້ (Edit User)' : 'ເພີ່ມຜູ້ໃຊ້ໃໝ່ (Add User)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                              color: _getRoleColor(_selectedRole).withValues(alpha: 0.1),
                              border: Border.all(color: _getRoleColor(_selectedRole), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ImageHelper.buildAvatar(
                              _profileImageUrl,
                              firstName: firstChar,
                              size: 90,
                              backgroundColor: _getRoleColor(_selectedRole).withValues(alpha: 0.15),
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
                        label: const Text('ອັບໂຫຼດຮູບໂປຣໄຟລ໌ (Upload Photo)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
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
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ຂໍ້ມູນສ່ວນຕົວ (Personal Details)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'ຊື່ (First Name) *',
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
                                labelText: 'ນາມສະກຸນ (Last Name) *',
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty ? 'ກະລຸນາປ້ອນນາມສະກຸນ' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'ອີເມວ (Email) *',
                                hintText: 'example@gmail.com',
                                prefixIcon: Icon(Icons.email_outlined, color: AppColors.primary),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'ກະລຸນາປ້ອນອີເມວ';
                                if (!val.contains('@')) return 'ຮູບແບບອີເມວບໍ່ຖືກຕ້ອງ';
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
                                labelText: 'ເບີໂທລະສັບ (Phone)',
                                hintText: '020-XXXX-XXXX',
                                prefixIcon: Icon(Icons.phone_outlined, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('ສິດ ແລະ ລະບົບຄວາມປອດໄພ (Security & Role)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'ສິດການນຳໃຊ້ (Role) *',
                                prefixIcon: Icon(Icons.security_rounded, color: AppColors.primary),
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'user', child: Text('User (ຜູ້ໃຊ້ທົ່ວໄປ)')),
                                DropdownMenuItem(value: 'employee', child: Text('Employee (ພະນັກງານ)')),
                                DropdownMenuItem(value: 'admin', child: Text('Admin (ຜູ້ດູແລລະບົບ)')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedRole = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'ສະຖານະບັນຊີ (Status) *',
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'active',
                                  child: Text('Active (ປົກກະຕິ)', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ),
                                DropdownMenuItem(
                                  value: 'suspended',
                                  child: Text('Suspended (ລະງັບ)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                ),
                                DropdownMenuItem(
                                  value: 'banned',
                                  child: Text('Banned (ບລັອກ)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
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
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: isEditing ? 'ລະຫັດຜ່ານໃໝ່ (ຫວ່າງໄວ້ຫາກບໍ່ຕ້ອງການປ່ຽນ)' : 'ລະຫັດຜ່ານ (Password) *',
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
                            return 'ກະລຸນາປ້ອນລະຫັດຜ່ານສຳລັບບັນຊີໃໝ່';
                          }
                          if (val != null && val.isNotEmpty && val.length < 6) {
                            return 'ລະຫັດຜ່ານຕ້ອງມີຄວາມຍາວຢ່າງໜ້ອຍ 6 ຕົວອັກສອນ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'ສະຖານະນັກຮຽນ / ສະມາຊິກພຣີມ່ຽມ (Student / Premiere Member)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'ເປີດນຳໃຊ້ສິດສ່ວນຫຼຸດ ແລະ ສິດທິພິເສດສຳລັບນັກຮຽນນັກສຶກສາ',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          value: _isStudent,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) => setState(() => _isStudent = val),
                        ),
                      ),
                      const SizedBox(height: 24),
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
                              child: const Text('ຍົກເລີກ (Cancel)'),
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
      ),
    );
  }
}
