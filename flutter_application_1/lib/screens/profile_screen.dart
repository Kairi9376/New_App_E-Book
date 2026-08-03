import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/kyc_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'kyc_submission_screen.dart';
import 'membership_package_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _userProfile = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await ApiService.getUserProfile();
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    }
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder(width, height));
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, width: width, height: height, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _buildPlaceholder(width, height));
    }
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, width: width, height: height, fit: BoxFit.cover);
      }
    }
    return _buildPlaceholder(width, height);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.blueGrey.shade100,
      child: const Icon(Icons.person, color: AppColors.primary, size: 50),
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
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
                      child: Text(
                        firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: Colors.white,
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

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ສະໝັກ: ${user['created_at'] ?? "04/11/2026"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'ໝົດອາຍຸ: ${user['expires_at'] ?? "04/12/2026"}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
                    subtitle: 'ຍື່ນເອກະສານອະນຸມັດກ່ອນສະໝັກແພັກເກັດ',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KycSubmissionScreen(
                            currentKyc: MockKycData.submissions.first,
                          ),
                        ),
                      );
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
                          builder: (context) => const MembershipPackageScreen(
                            kycStatus: KycStatus.pending,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'ການຕັ້ງຄ່າ',
                    onTap: () {},
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'ການແຈ້ງເຕືອນ',
                    onTap: () {},
                  ),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                  _buildMenuItem(
                    icon: Icons.shield_outlined,
                    title: 'ຄວາມປອດໄພ ແລະ ຄວາມເປັນສ່ວນຕົວ',
                    onTap: () {},
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
