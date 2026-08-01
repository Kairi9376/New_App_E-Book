import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/kyc_model.dart';
import 'kyc_submission_screen.dart';

class MembershipPackageScreen extends StatefulWidget {
  final KycStatus kycStatus;
  final KycModel? userKyc;

  const MembershipPackageScreen({
    super.key,
    this.kycStatus = KycStatus.approved,
    this.userKyc,
  });

  @override
  State<MembershipPackageScreen> createState() => _MembershipPackageScreenState();
}

class _MembershipPackageScreenState extends State<MembershipPackageScreen> {
  int _selectedPackageIndex = 1;

  final List<Map<String, dynamic>> _packages = [
    {
      'title': 'ແພັກເກັດທົດລອງອ່ານ (Basic)',
      'price': 'ຟຣີ 0 ກີບ',
      'duration': 'ຖາວອນ',
      'features': [
        'ອ່ານປຶ້ມສາທາລະນະທົ່ວໄປ',
        'ບັນທຶກປຶ້ມທີ່ມັກໄດ້ 5 ເລີ່ມ',
        'ອ່ານຕົວຢ່າງໄຟລ໌ PDF ຟຣີ 10 ໜ້າທຳອິດ',
      ],
      'color': const Color(0xFF64748B),
      'isPopular': false,
    },
    {
      'title': 'ແພັກເກັດພຣີມ່ຽມລາຍເດືອນ (Premiere Monthly)',
      'price': '199,000 ກີບ',
      'duration': '/ ເດືອນ',
      'features': [
        'ອ່ານປຶ້ມ PDF ທຸກເລີ່ມໃນຄັງແບບບໍ່ຈຳກັດ',
        'ດາວໂຫຼດໄວ້ອ່ານອອບໄລນ໌ໄດ້ແບບບໍ່ຈຳກັດ',
        'ບໍ່ມີໂຄສະນາຄັ້ນ',
        'ຕາສັນຍາລັກ Premiere ບົນໂປຣໄຟລ໌',
      ],
      'color': AppColors.primary,
      'isPopular': true,
    },
    {
      'title': 'ແພັກເກັດພຣີມ່ຽມລາຍປີ (Premiere Yearly)',
      'price': '1,890,000 ກີບ',
      'duration': '/ ປີ (ປະຢັດ 20%)',
      'features': [
        'ສິດທັງໝົດຂອງພຣີມ່ຽມລາຍເດືອນ',
        'ຮັບປຶ້ມເລີ່ມພິເສດຟຣີທຸກເດືອນ',
        'ສິດສະຕຣີມມິ່ງປຶ້ມສຽງ (Audiobook)',
        'ຊັບພອດລະດັບ VIP ຕະຫຼອດ 24 ຊົ່ວໂມງ',
      ],
      'color': const Color(0xFF7C3AED),
      'isPopular': false,
    },
  ];

  void _onSubscribe(int index) {
    if (widget.kycStatus != KycStatus.approved) {
      _showKycRequiredDialog();
      return;
    }

    final pkg = _packages[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 8),
            const Text('ຢືນຢັນສະໝັກແພັກເກັດ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ທ່ານກຳລັງເລືອກສະໝັກ: ${pkg['title']}'),
            const SizedBox(height: 6),
            Text('ລາຄາ: ${pkg['price']} ${pkg['duration']}'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 6),
                  const Text('ກວດສອບ KYC ອະນຸມັດແລ້ວ', style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ສະໝັກ ${pkg['title']} ສຳເລັດຮຽບຮ້ອຍແລ້ວ!'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ຢືນຢັນຊຳລະເງິນ'),
          ),
        ],
      ),
    );
  }

  void _showKycRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFEF4444), size: 28),
            const SizedBox(width: 8),
            const Text('ຕ້ອງຢືນຢັນຕົວຕົນ (KYC) ກ່ອນ'),
          ],
        ),
        content: const Text(
          'ຕາມນະໂຍບາຍຄວາມປອດໄພ ຜູ້ໃຊ້ຕ້ອງດຳເນີນການຢືນຢັນຕົວຕົນ (KYC) ແລະ ໄດ້ຮັບການອະນຸມັດຈາກແອດມິນກ່ອນ ຈຶ່ງຈະສາມາດສະໝັກແພັກເກັດສະມາຊິກໄດ້',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ໄວ້ທີຫຼັງ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KycSubmissionScreen(
                    currentKyc: widget.userKyc ??
                        KycModel(
                          id: 'kyc_new',
                          userId: 'u123',
                          userName: 'ຜູ້ໃຊ້ງານລະບົບ',
                          userEmail: 'user1234@gmail.com',
                          idCardNumber: '',
                          fullName: '',
                          idCardImagePath: '',
                          selfieImagePath: '',
                          status: KycStatus.notSubmitted,
                          submittedAt: DateTime.now(),
                        ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ໄປທີ່ໜ້າຢືນຢັນຕົວຕົນ KYC'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ເລືອກແພັກເກັດສະມາຊິກ (Subscription Packages)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                _buildHeaderBanner(),
                const SizedBox(height: 24),
                _buildKycStatusNotice(),
                const SizedBox(height: 24),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _packages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final pkg = _packages[index];
                    final isSelected = _selectedPackageIndex == index;
                    return _buildPackageCard(pkg, index, isSelected);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFFEF3C7),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 40),
        ),
        const SizedBox(height: 12),
        const Text(
          'ເລືອກແພັກເກັດທີ່ເໝາະສົມກັບສະໄຕລ໌ການອ່ານຂອງທ່ານ',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'ເຂົ້າເຖິງຄັງປຶ້ມ PDF ແລະ e-Book ຄຸນນະພາບສູງນັບໝື່ນເລີ່ມໄດ້ແບບບໍ່ຈຳກັດ',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildKycStatusNotice() {
    final isApproved = widget.kycStatus == KycStatus.approved;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isApproved ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          Icon(
            isApproved ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isApproved ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isApproved
                  ? 'ຢືນຢັນຕົວຕົນ KYC ຜ່ານແລ້ວ: ທ່ານປົດລັອກສິດສະໝັກແພັກເກັດສະມາຊິກໄດ້ຮຽບຮ້ອຍ'
                  : 'ເງື່ອນໄຂການສະໝັກ: ທ່ານຕ້ອງຢືນຢັນຕົວຕົນ (KYC) ແລະ ໄດ້ຮັບການອະນຸມັດຈາກແອດມິນກ່ອນສະໝັກແພັກເກັດ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isApproved ? const Color(0xFF065F46) : const Color(0xFF991B1B),
              ),
            ),
          ),
          if (!isApproved)
            TextButton(
              onPressed: _showKycRequiredDialog,
              child: const Text('ຢືນຢັນຕົວຕົນທັນທີ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> pkg, int index, bool isSelected) {
    final Color pkgColor = pkg['color'];
    final bool isPopular = pkg['isPopular'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? pkgColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: pkgColor.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      pkg['title'],
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: pkgColor),
                    ),
                    if (isPopular) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('ຂາຍດີທີ່ສຸດ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                Radio<int>(
                  value: index,
                  groupValue: _selectedPackageIndex,
                  activeColor: pkgColor,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPackageIndex = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  pkg['price'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Text(
                  pkg['duration'],
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            Column(
              children: (pkg['features'] as List<String>).map((feat) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: pkgColor),
                      const SizedBox(width: 8),
                      Text(feat, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _onSubscribe(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: pkgColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ເລືອກແພັກເກັດນີ້', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
