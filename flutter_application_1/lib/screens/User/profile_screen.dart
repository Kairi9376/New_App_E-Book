import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/membership.dart';
import '../../services/file_picker_helper.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
import '../../utils/image_helper.dart';
import 'user_login_screen.dart';
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
    _loadSettings();
    _fetchProfile();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _pushNotificationsEnabled = prefs.getBool('push_notifications') ?? true;
        _soundEnabled = prefs.getBool('notification_sound') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
      });
    }
  }

  Future<void> _fetchProfile() async {
    final profile = await ApiService.getUserProfile();
    final rawUserId = profile['user_id'] ?? profile['id'];
    final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;
    final liveKyc = await ApiService.getUserKycStatus(userId);
    // # ເຮັດຫຍັງ: ຫຸ້ມ getUserSubscriptionStatus ດ້ວຍ try/catch
    // # ຍ້ອນຫຍັງ: method ນີ້ຖືກແກ້ໃຫ້ throw ຕອນຄຳຮ້ອງລົ້ມເຫຼວ (ແທນທີ່ຈະຄືນ null
    // #          ທັງກໍລະນີ 'ບໍ່ມີແພັກເກັດ' ແລະ 'ຕິດຕໍ່ບໍ່ໄດ້') ຖ້າບໍ່ຫຸ້ມໄວ້
    // #          exception ຈະຕັດ method ກາງຄັນ ແລ້ວ setState ດ້ານລຸ່ມບໍ່ຖືກເອີ້ນ
    // #          ໜ້າຈະຄ້າງຢູ່ສະຖານະກຳລັງໂຫຼດຕະຫຼອດ
    // # ແກ້ຈາກສ່ວນໃດ: ການເອີ້ນແບບບໍ່ມີ try/catch
    // # ແກ້ເຮັດຫຍັງ: ຖ້າດຶງບໍ່ໄດ້ໃຫ້ເປັນ null ແລ້ວໜ້າຈໍໂຫຼດສ່ວນທີ່ເຫຼືອຕໍ່ໄດ້
    Map<String, dynamic>? liveSub;
    try {
      liveSub = await ApiService.getUserSubscriptionStatus(userId);
    } catch (_) {
      liveSub = null;
    }

    if (mounted) {
      setState(() {
        _userProfile = profile;
        _userSubscription = liveSub;
        _avatarPath = profile['profile_image_url'] ?? profile['avatar'];
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

  Future<void> _changeAvatarImage() async {
    setState(() => _isUploadingAvatar = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*,.jpg,.jpeg,.png');
      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'profile',
        );

        if (result['success'] == true) {
          final uploadedPath = result['url'] ?? result['path'] ?? 'uploads/profiles/${picked.name}';
          final rawUserId = _userProfile['user_id'] ?? _userProfile['id'];
          final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;

          // Save new profile picture URL to MySQL database
          await ApiService.updateUser(userId, {
            'profile_image_url': uploadedPath,
          });

          // Sync in memory user model
          if (ApiService.currentUser != null) {
            ApiService.currentUser!['profile_image_url'] = uploadedPath;
          }
          _userProfile['profile_image_url'] = uploadedPath;

          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() {
                _avatarBytes = bytes;
                _avatarPath = uploadedPath;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ອັບເດດຮູບໂປຣໄຟລ໌ສຳເລັດ!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );

              NotificationService.addNotification(
                context,
                title: '👤 ອັບເດດຮູບໂປຣໄຟລ໌ສຳເລັດ',
                message: 'ຮູບໂປຣໄຟລ໌ໃໝ່ຂອງທ່ານຖືກບັນທຶກເຂົ້າສູ່ລະບົບແລ້ວ',
                type: NotificationType.system,
              );
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ອັບໂຫຼດຮູບບໍ່ສຳເລັດ: ${result['message'] ?? 'Unknown error'}'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫຼດ: $e'), backgroundColor: Colors.redAccent),
          );
        });
      }
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _isUploadingAvatar = false);
        });
      }
    }
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
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
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      setDialogState(() => _pushNotificationsEnabled = val);
                      setState(() => _pushNotificationsEnabled = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('push_notifications', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ສຽງແຈ້ງເຕືອນ (Notification Sound)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    value: _soundEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      setDialogState(() => _soundEnabled = val);
                      setState(() => _soundEnabled = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('notification_sound', val);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('ໂໝດກາງຄືນ (Dark Mode)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('ປ່ຽນທີມແອັບເປັນໂໝດກາງຄືນ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    value: _darkModeEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) async {
                      setDialogState(() => _darkModeEnabled = val);
                      setState(() => _darkModeEnabled = val);
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('dark_mode', val);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.cleaning_services_rounded, color: Colors.amber),
                    title: const Text('ລ້າງໄຟລ໌ແຄຊ (Clear PDF Cache)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('ລົບໄຟລ໌ PDF ຊົ່ວຄາວ (ຂະໜາດປະມານ 24.5 MB)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.remove('cached_pdfs');
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ລ້າງໄຟລ໌ແຄຊ PDF ອອບໄລນ໌ 24.5 MB ສຳເລັດແລ້ວ!'),
                            backgroundColor: Color(0xFF10B981),
                          ),
                        );
                      }
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
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
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
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('ຍົກເລີກ'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final newPass = newPassCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (newPass.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ລະຫັດຜ່ານໃໝ່ຕ້ອງມີຢ່າງນ້ອຍ 6 ຕົວອັກສອນ'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        if (newPass != confirmPass) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ລະຫັດຜ່ານໃໝ່ບໍ່ກົງກັນ'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final user = _userProfile.isNotEmpty ? _userProfile : (ApiService.currentUser ?? {});
                        final rawUserId = user['user_id'] ?? user['id'];
                        final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;

                        final success = await ApiService.updateUser(userId, {'password': newPass});

                        if (context.mounted) {
                          if (success) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ປ່ຽນລະຫັດຜ່ານໃນລະບົບສຳເລັດແລ້ວ!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                            NotificationService.addNotification(
                              context,
                              title: '🔒 ປ່ຽນລະຫັດຜ່ານສຳເລັດ',
                              message: 'ລະຫັດຜ່ານບັນຊີຂອງທ່ານໄດ້ຮັບການອັບເດດຮຽບຮ້ອຍແລ້ວ',
                              type: NotificationType.system,
                            );
                          } else {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ບໍ່ສາມາດອັບເດດຂໍ້ມູນໄດ້'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF059669)),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ບັນທຶກລະຫັດຜ່ານ'),
              ),
            ],
          );
        },
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

  void _openEditProfileModal() {
    final user = _userProfile.isNotEmpty ? _userProfile : (ApiService.currentUser ?? {});
    final firstNameCtrl = TextEditingController(text: user['first_name'] ?? '');
    final lastNameCtrl = TextEditingController(text: user['last_name'] ?? '');
    final phoneCtrl = TextEditingController(text: user['phone_number'] ?? '');
    String selectedGender = (user['gender'] ?? 'male').toString().toLowerCase();

    DateTime? selectedBirthDate;
    if (user['birth_date'] != null && user['birth_date'].toString().isNotEmpty) {
      try {
        selectedBirthDate = DateTime.parse(user['birth_date'].toString());
      } catch (_) {}
    }

    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.manage_accounts_rounded, color: AppColors.primary, size: 24),
                SizedBox(width: 10),
                Text('ແກ້ໄຂຂໍ້ມູນສ່ວນຕົວ (Edit Profile)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: firstNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'ຊື່ (First Name)',
                              prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: lastNameCtrl,
                            decoration: InputDecoration(
                              labelText: 'ນາມສະກຸນ (Last Name)',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'ເບີໂທລະສັບ (Phone Number)',
                        prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('ເພດ (Gender)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ຊາຍ (Male)', style: TextStyle(fontSize: 12))),
                            selected: selectedGender == 'male',
                            onSelected: (sel) {
                              if (sel) setDialogState(() => selectedGender = 'male');
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            side: BorderSide(color: selectedGender == 'male' ? AppColors.primary : Colors.grey.shade300),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('ຍິງ (Female)', style: TextStyle(fontSize: 12))),
                            selected: selectedGender == 'female',
                            onSelected: (sel) {
                              if (sel) setDialogState(() => selectedGender = 'female');
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                            side: BorderSide(color: selectedGender == 'female' ? AppColors.primary : Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedBirthDate ?? DateTime(2000, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          setDialogState(() => selectedBirthDate = pickedDate);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('ວັນເດືອນປີເກີດ (Birth Date)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  Text(
                                    selectedBirthDate != null
                                        ? '${selectedBirthDate!.day.toString().padLeft(2, '0')}/${selectedBirthDate!.month.toString().padLeft(2, '0')}/${selectedBirthDate!.year}'
                                        : 'ກະລຸນາເລືອກວັນເກີດ',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('ຍົກເລີກ'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setDialogState(() => isSaving = true);
                        final rawUserId = user['user_id'] ?? user['id'];
                        final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;

                        final updatePayload = {
                          'first_name': firstNameCtrl.text.trim(),
                          'last_name': lastNameCtrl.text.trim(),
                          'phone_number': phoneCtrl.text.trim(),
                          'gender': selectedGender,
                          if (selectedBirthDate != null)
                            'birth_date': selectedBirthDate!.toIso8601String().substring(0, 10),
                        };

                        final success = await ApiService.updateUser(userId, updatePayload);

                        if (context.mounted) {
                          if (success) {
                            setState(() {
                              _userProfile['first_name'] = firstNameCtrl.text.trim();
                              _userProfile['last_name'] = lastNameCtrl.text.trim();
                              _userProfile['phone_number'] = phoneCtrl.text.trim();
                              _userProfile['gender'] = selectedGender;
                              if (selectedBirthDate != null) {
                                _userProfile['birth_date'] = selectedBirthDate!.toIso8601String().substring(0, 10);
                              }
                              if (ApiService.currentUser != null) {
                                ApiService.currentUser!.addAll(updatePayload);
                              }
                            });

                            Navigator.pop(ctx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ບັນທຶກຂໍ້ມູນສ່ວນຕົວສຳເລັດ!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );

                            NotificationService.addNotification(
                              context,
                              title: '👤 ອັບເດດຂໍ້ມູນສ່ວນຕົວສຳເລັດ',
                              message: 'ຂໍ້ມູນຂອງທ່ານໄດ້ຮັບການບັນທຶກຮຽບຮ້ອຍແລ້ວ',
                              type: NotificationType.system,
                            );
                          } else {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('ບໍ່ສາມາດອັບເດດຂໍ້ມູນໄດ້'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ບັນທຶກ (Save)'),
              ),
            ],
          );
        },
      ),
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
              // # ເຮັດຫຍັງ: ປ່ຽນປາຍທາງຫຼັງອອກຈາກລະບົບເປັນ UserLoginScreen
              // # ຍ້ອນຫຍັງ: ໜ້າ LoginScreen ເດີມກາຍເປັນ StaffLoginScreen ຂອງ Web ໄປແລ້ວ
              // #          ຖ້າຍັງຊີ້ໄປບ່ອນເກົ່າ ຜູ້ໃຊ້ໃນແອັບຈະຕົກໄປໜ້າ login ຂອງພະນັກງານ
              // #          ແລ້ວ login ບັນຊີຕົນເອງກັບຄືນບໍ່ໄດ້
              // # ແກ້ຈາກສ່ວນໃດ: ປຸ່ມຢືນຢັນອອກຈາກລະບົບໃນ dialog ຂອງໜ້າໂປຣໄຟລ໌
              // # ແກ້ເຮັດຫຍັງ: ພາກັບໄປໜ້າ login ຝັ່ງແອັບ ໃຫ້ວົນກັບເຂົ້າໃຊ້ໄດ້ຄືເກົ່າ
              await ApiService.clearSession();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserLoginScreen()),
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
    final email = user['email'] ?? 'user@gmail.com';
    // # ເຮັດຫຍັງ: ປ່ຽນມາອ່ານ Membership.isPremiere ແທນການຕັດສິນເອງ
    // # ຍ້ອນຫຍັງ: ເງື່ອນໄຂເກົ່າ role=='admin'||role=='employee'||email=='member@gmail.com'
    // #          ຕັດສິນດ້ວຍ email ທີ່ hardcode ໄວ້ ຜູ້ໃຊ້ຈິງທີ່ຊື້ແພັກເກັດແລ້ວ
    // #          ຈຶ່ງບໍ່ເຄີຍຖືກນັບເປັນສະມາຊິກ ແລະ ບໍ່ໄດ້ກວດວັນໝົດອາຍຸນຳ
    // # ແກ້ຈາກສ່ວນໃດ: ເງື່ອນໄຂທີ່ຂຽນຊ້ຳກັນຢູ່ 4 ໜ້າ
    // # ແກ້ເຮັດຫຍັງ: ອີງ subscription ຈິງຈາກ backend + ກວດວັນໝົດອາຍຸ ບ່ອນດຽວ
    final isPremiere = Membership.isPremiere;

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
                    child: ClipOval(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: ImageHelper.buildImage(
                          _avatarPath,
                          bytes: _avatarBytes,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            child: Center(
                              child: Text(
                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ),
                        ),
                      ),
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
            const SizedBox(height: 10),

            // Quick Edit Profile Button
            ElevatedButton.icon(
              onPressed: _openEditProfileModal,
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text('ແກ້ໄຂຂໍ້ມູນສ່ວນຕົວ (Edit Profile)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            if (!isPremiere) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4338CA).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade400.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ອັບເກຣດເປັນ Premiere Member 👑',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'ອ່ານ ແລະ ໂຫຼດ e-Book PDF ໄດ້ແບບບໍ່ຈຳກັດ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFC7D2FE),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Color(0xFF4C51BF), height: 1),
                    const SizedBox(height: 14),
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text('ເຂົ້າເຖິງຄັງປຶ້ມ VIP ຫຼາຍກວ່າ 1,000+ ເຫຼັ້ມ', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text('ດາວໂຫຼດອ່ານອອບໄລນ໌ ໂດຍບໍ່ມີໂຄສະນາ', style: TextStyle(fontSize: 12, color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                        icon: const Icon(Icons.flash_on_rounded, color: Colors.black87, size: 18),
                        label: const Text(
                          'ສະໝັກແພັກເກັດ VIP ຕອນນີ້',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'ແກ້ໄຂຂໍ້ມູນສ່ວນຕົວ (Edit Profile)',
                    subtitle: 'ຊື່-ນາມສະກຸນ, ເບີໂທ, ເພດ, ວັນເດືອນປີເກີດ',
                    onTap: _openEditProfileModal,
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFDC2626),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
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
          color: AppColors.primary.withValues(alpha: 0.08),
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
