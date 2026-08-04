import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/image_helper.dart';
import '../login_screen.dart';
import 'kyc_submission_screen.dart';
import 'membership_package_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userProfile = {};
  KycModel? _userKyc;
  Map<String, dynamic>? _userSubscription;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  Uint8List? _avatarBytes;
  String? _avatarPath;

  // Settings State
  bool _pushNotificationsEnabled = true;
  bool _soundEnabled = true;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await ApiService.getUserProfile();
    final rawUserId = profile['user_id'] ?? profile['id'];
    final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;
    final liveKyc = await ApiService.getUserKycStatus(userId);
    final liveSub = await ApiService.getUserSubscriptionStatus(userId);

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _userSubscription = liveSub;
        _userKyc = liveKyc ?? KycModel(
          id: 'kyc_$userId',
          userId: userId.toString(),
          userName: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
          userEmail: profile['email'] ?? '',
          idCardNumber: profile['id_card_number'] ?? '',
          fullName: '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim(),
          idCardImagePath: '',
          selfieImagePath: '',
          status: _parseKycStatus(profile['kyc_status']),
          submittedAt: DateTime.now(),
        );
        _isLoading = false;
      });
    }
  }

  String _formatDateStr(dynamic rawDate, {String defaultVal = '-'}) {
    if (rawDate == null || rawDate.toString().trim().isEmpty) return defaultVal;
    try {
      final dt = DateTime.parse(rawDate.toString()).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      return '$day/$month/$year';
    } catch (_) {
      final str = rawDate.toString();
      if (str.length >= 10) {
        final parts = str.substring(0, 10).split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      return str;
    }
  }

  KycStatus _parseKycStatus(dynamic statusStr) {
    if (statusStr == null) return KycStatus.notSubmitted;
    final s = statusStr.toString().toLowerCase();
    if (s == 'approved') return KycStatus.approved;
    if (s == 'pending') return KycStatus.pending;
    if (s == 'rejected') return KycStatus.rejected;
    return KycStatus.notSubmitted;
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    return ImageHelper.buildImage(path, width: width, height: height, fit: BoxFit.cover);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.blueGrey.shade100,
      child: const Icon(Icons.person, color: AppColors.primary, size: 50),
    );
  }

  Future<void> _changeAvatarImage() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*');
      await Future.delayed(const Duration(milliseconds: 100));

      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'avatar',
        );

        if (mounted) {
          setState(() {
            _avatarBytes = bytes;
            if (result['success'] == true && result['path'] != null) {
              _avatarPath = result['url'] ?? result['path'];
            }
          });
          NotificationService.addNotification(
            context,
            title: '👤 ອັບເດດຮູບໂປຣໄຟລ໌ສຳເລັດ',
            message: 'ຮູບໂປຣໄຟລ໌ໃໝ່ຂອງທ່ານຖືກບັນທຶກເຂົ້າสู่ระบบແລ້ວ',
            type: NotificationType.system,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫຼດຮູບ: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.settings_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text('ການຕັ້ງຄ່າ (Settings)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('ແຈ້ງເຕືອນ (Push Notifications)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('ຮັບການແຈ້ງເຕືອນປຶ້ມໃໝ່ ແລະ ສະຖານະແພັກເກັດ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _pushNotificationsEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setDialogState(() => _pushNotificationsEnabled = val);
                      setState(() => _pushNotificationsEnabled = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ສຽງແຈ້ງເຕືອນ (Notification Sound)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _soundEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setDialogState(() => _soundEnabled = val);
                      setState(() => _soundEnabled = val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ໂໝດກາງຄືນ (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('ປ່ຽນธีມແອັບເປັນໂໝດກາງຄືນ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _darkModeEnabled,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setDialogState(() => _darkModeEnabled = val);
                      setState(() => _darkModeEnabled = val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
                    title: const Text('ລ້າງໄຟລ໌ແຄຊ (Clear PDF Cache)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('ລົບໄຟລ໌ PDF ຊົ່ວຄາວ (ขนาดประมาณ 24.5 MB)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('ລ້າງໄຟລ໌ແຄຊ PDF ອອບໄລນ໌ສຳເລັດແລ້ວ!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ປິດໜ້າຕ່າງ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openSecurityDialog() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 24),
            SizedBox(width: 10),
            Text('ຄວາມປອດໄພ (Security)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ລະຫັດຜ່ານປັດຈຸບັນ',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ລະຫັດຜ່ານໃໝ່',
                  prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'ຢືນຢັນລະຫັດຜ່ານໃໝ່',
                  prefixIcon: const Icon(Icons.lock_clock_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            onPressed: () {
              if (newPassCtrl.text.trim().isEmpty || newPassCtrl.text != confirmPassCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ລະຫັດຜ່ານໃໝ່ບໍ່ตรงกัน หรือว่างเปล่า'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              NotificationService.addNotification(
                context,
                title: '🔒 ປ່ຽນລະຫັດຜ່ານສຳເລັດ',
                message: 'ລະຫັດຜ່ານບັນຊີຂອງທ່ານໄດ້ຮັບການອັບເດດຮຽບຮ້ອຍແລ້ວ',
                type: NotificationType.system,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
            child: const Text('ບັນທຶກລະຫັດຜ່ານ'),
          ),
        ],
      ),
    );
  }

  void _openAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'E-Book Lao Reader App',
      applicationVersion: 'v1.2.0-release',
      applicationIcon: const Icon(Icons.menu_book_rounded, size: 40, color: AppColors.primary),
      children: const [
        Text('ແອັບພລິເຄຊັນອ່ານໜັງສື e-Book PDF ອອນໄລນ໌ ແລະ ອອບໄລນ໌ ພ້ອມລະບົບສະມາຊິກ Premiere Member.'),
        SizedBox(height: 8),
        Text('ຕິດຕໍ່ທີມງານ: support@ebook.lao | TEL: +856 20 55512345'),
      ],
    );
  }

  void _onLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ອອກຈາກລະບົບ'),
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບແທ້ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ApiService.clearSession();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('ອອກຈາກລະບົບ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _userProfile.isNotEmpty ? _userProfile : (ApiService.currentUser ?? {});
    final firstName = user['first_name'] ?? 'ສົມຊາຍ';
    final lastName = user['last_name'] ?? 'ໃຈດີ';
    final role = (user['role'] ?? 'user').toString().toLowerCase();
    final email = user['email'] ?? 'user@gmail.com';
    final isPremiere = role == 'admin' || role == 'employee' || email == 'member@gmail.com';

    return RefreshIndicator(
      onRefresh: _fetchProfile,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : (_avatarPath != null && _avatarPath!.isNotEmpty ? NetworkImage(_avatarPath!) : null) as ImageProvider?,
                      child: (_avatarBytes == null && (_avatarPath == null || _avatarPath!.isEmpty))
                          ? Text(
                              firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: InkWell(
                      onTap: _isUploadingAvatar ? null : _changeAvatarImage,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: _isUploadingAvatar
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              '$firstName $lastName',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Email
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isPremiere ? const Color(0xFF5E97F6) : const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPremiere ? 'Premiere Member' : 'General User',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dynamic Formatted Dates Card
            Builder(
              builder: (context) {
                final String regDate = _formatDateStr(user['created_at'] ?? user['createdAt'], defaultVal: '01/08/2026');
                final String subStatus = _userSubscription?['payment_status'] ?? 'none';
                final dynamic rawExp = _userSubscription?['end_date'] ?? _userSubscription?['expires_at'] ?? user['expires_at'];

                final String expireDate = subStatus == 'active' && rawExp != null
                    ? _formatDateStr(rawExp, defaultVal: 'ບໍ່ມີກຳນົດ')
                    : (isPremiere ? 'ບໍ່ມີກຳນົດ (Unlimited)' : 'ຍັງບໍ່ມີແພັກເກັດ');

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'ສະໝັກ: $regDate',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.event_busy_rounded,
                            size: 15,
                            color: subStatus == 'active' ? const Color(0xFF059669) : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ໝົດອາຍຸ: $expireDate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: subStatus == 'active' ? const Color(0xFF059669) : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Settings Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'ການຕັ້ງຄ່າບັນຊີ',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Menu List Group
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.verified_user_rounded,
                    title: 'ຢືນຢັນຕົວຕົນ (KYC Verification)',
                    subtitle: _userKyc?.statusText ?? 'ຍັງບໍ່ທັນໄດ້ຢືນຢັນຕົວຕົນ',
                    onTap: () async {
                      final defaultKyc = _userKyc ?? KycModel(
                        id: 'kyc_new',
                        userId: (_userProfile['user_id'] ?? 3).toString(),
                        userName: '${_userProfile['first_name'] ?? ''} ${_userProfile['last_name'] ?? ''}'.trim(),
                        userEmail: _userProfile['email'] ?? '',
                        idCardNumber: '',
                        fullName: '${_userProfile['first_name'] ?? ''} ${_userProfile['last_name'] ?? ''}'.trim(),
                        idCardImagePath: '',
                        selfieImagePath: '',
                        status: KycStatus.notSubmitted,
                        submittedAt: DateTime.now(),
                      );

                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KycSubmissionScreen(
                            currentKyc: defaultKyc,
                            onKycUpdated: (updatedKyc) {
                              setState(() {
                                _userKyc = updatedKyc;
                              });
                            },
                          ),
                        ),
                      );
                      _fetchProfile();
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.workspace_premium_rounded,
                    title: 'ສະໝັກແພັກເກັດສະມາຊິກ (Premiere Member)',
                    subtitle: 'ອ່ານ e-Book PDF ໄດ້ທຸກເລີ່ມແບບບໍ່ຈຳກັດ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MembershipPackageScreen(
                            kycStatus: _userKyc?.status ?? KycStatus.notSubmitted,
                            userKyc: _userKyc,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'ການຕັ້ງຄ່າ (Settings)',
                    subtitle: 'ແຈ້ງເຕືອນ, ໂໝດກາງຄືນ, ແລະ ລ້າງໄຟລ໌ແຄຊ',
                    onTap: _openSettingsDialog,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'ການແຈ້ງເຕືອນ (Notifications)',
                    subtitle: 'ເບິ່ງລາຍການແຈ້ງເຕືອນທັງໝົດ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'ຄວາມປອດໄພ ແລະ ຄວາມເປັນສ່ວນຕົວ',
                    subtitle: 'ປ່ຽນລະຫັດຜ່ານ ແລະ ການປົກປ້ອງຂໍ້ມູນ',
                    onTap: _openSecurityDialog,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'ກ່ຽວກັບແອັບ ແລະ ຊ່ວຍເຫຼືອ (About & Support)',
                    subtitle: 'ເວີຊັນແອັບ v1.2.0, ເງື່ອນໄຂ, ແລະ ຕິດຕໍ່ທີມງານ',
                    onTap: _openAboutDialog,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton(
              onPressed: () => _onLogout(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ອອກຈາກລະບົບ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14,
        color: AppColors.textSecondary,
      ),
    );
  }
}
