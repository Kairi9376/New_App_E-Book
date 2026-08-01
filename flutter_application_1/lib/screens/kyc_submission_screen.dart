import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/kyc_model.dart';
import 'membership_package_screen.dart';

class KycSubmissionScreen extends StatefulWidget {
  final KycModel currentKyc;
  final ValueChanged<KycModel>? onKycUpdated;

  const KycSubmissionScreen({
    super.key,
    required this.currentKyc,
    this.onKycUpdated,
  });

  @override
  State<KycSubmissionScreen> createState() => _KycSubmissionScreenState();
}

class _KycSubmissionScreenState extends State<KycSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _idCardController;

  late KycStatus _currentStatus;
  String? _idCardImagePath;
  String? _selfieImagePath;
  String? _rejectReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.currentKyc.status;
    _fullNameController = TextEditingController(text: widget.currentKyc.fullName);
    _idCardController = TextEditingController(text: widget.currentKyc.idCardNumber);
    _idCardImagePath = widget.currentKyc.idCardImagePath.isNotEmpty ? widget.currentKyc.idCardImagePath : null;
    _selfieImagePath = widget.currentKyc.selfieImagePath.isNotEmpty ? widget.currentKyc.selfieImagePath : null;
    _rejectReason = widget.currentKyc.rejectReason;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idCardController.dispose();
    super.dispose();
  }

  void _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idCardImagePath == null || _selfieImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາອັບໂຫຼດຮູບພາບບັດປະຈຳຕົວ ແລະ ຮູບຖ່າຍຄູ່ກັບບັດປະຈຳຕົວໃຫ້ຄົບຖ້ວນ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    await Future.delayed(const Duration(seconds: 1));

    final updatedKyc = widget.currentKyc.copyWith(
      status: KycStatus.pending,
      rejectReason: null,
      reviewedAt: null,
    );

    setState(() {
      _isSubmitting = false;
      _currentStatus = KycStatus.pending;
      _rejectReason = null;
    });

    if (widget.onKycUpdated != null) {
      widget.onKycUpdated!(updatedKyc);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ສົ່ງຂໍ້ມູນຢືນຢັນຕົວຕົນ (KYC) ສຳເລັດ! ກະລຸນາລໍຖ້າແອດມິນອະນຸມັດ'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Widget _buildImagePreview(String? path, String placeholderText, VoidCallback onPick) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: path != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
            width: path != null ? 2 : 1,
          ),
        ),
        child: path != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'ແນບໄຟລ໌ແລ້ວ ($placeholderText)',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                        onPressed: onPick,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo_outlined, size: 36, color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    placeholderText,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ຄລິກເພື່ອເລືອກຮູບພາບ ຫຼື ຖ່າຍຮູບ',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('ຢືນຢັນຕົວຕົນ (KYC Verification)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeaderBanner(),
                const SizedBox(height: 20),

                if (_currentStatus == KycStatus.approved) ...[
                  _buildApprovedCard(),
                ] else if (_currentStatus == KycStatus.pending) ...[
                  _buildPendingCard(),
                ] else ...[
                  _buildKycFormCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeaderBanner() {
    Color bannerColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String titleText;
    String descText;

    switch (_currentStatus) {
      case KycStatus.approved:
        bannerColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF6EE7B7);
        textColor = const Color(0xFF065F46);
        icon = Icons.verified_user_rounded;
        titleText = 'ສະຖານະ: ຢືນຢັນຕົວຕົນຜ່ານແລ້ວ (Approved)';
        descText = 'ບັນຊີຂອງທ່ານໄດ້ຮັບການກວດສອບ ແລະ ອະນຸມັດ KYC ຮຽບຮ້ອຍ ສາມາດສະໝັກແພັກເກັດສະມາຊິກ Premiere ໄດ້ທັນທີ!';
        break;
      case KycStatus.pending:
        bannerColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        icon = Icons.pending_actions_rounded;
        titleText = 'ສະຖານະ: ລໍຖ້າແອດມິນກວດສອບເອກະສານ (Pending)';
        descText = 'ແອດມິນກຳລັງດຳເນີນການກວດສອບບັດປະຈຳຕົວ ແລະ ຫຼັກຖານຂອງທ່ານ ໂດຍປົກກະຕິຈະໃຊ້ເວລາ 1-24 ຊົ່ວໂມງ';
        break;
      case KycStatus.rejected:
        bannerColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        icon = Icons.gpp_bad_rounded;
        titleText = 'ສະຖານະ: ການຢືນຢັນຕົວຕົນຖືກປະຕິເສດ (Rejected)';
        descText = _rejectReason ?? 'ເອກະສານຂອງທ່ານບໍ່ຜ່ານການອະນຸມັດ ກະລຸນາກວດສອບ ແລະ ແກ້ໄຂຂໍ້ມູນກ່ອນສົ່ງອີກຄັ້ງ';
        break;
      case KycStatus.notSubmitted:
        bannerColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.shield_outlined;
        titleText = 'ຂັ້ນຕອນການຢືນຢັນຕົວຕົນ (KYC Setup)';
        descText = 'ປ້ອນເລກບັດປະຈຳຕົວ ແລະ ແນບຫຼັກຖານຮູບຖ່າຍເພື່ອຍື່ນເລື່ອງໃຫ້ແອດມິນອະນຸມັດສິດສະໝັກແພັກເກັດສະມາຊິກ';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bannerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: textColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleText,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: 4),
                Text(
                  descText,
                  style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.stars_rounded, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 12),
          const Text(
            'ຍິນດີດ້ວຍ! ບັນຊີຂອງທ່ານຢືນຢັນຕົວຕົນສຳເລັດແລ້ວ',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'ທ່ານໄດ້ຮັບສິດເຂົ້າເຖິງການສະໝັກສະມາຊິກ ແລະ ແພັກເກັດອ່ານ e-Book ແບບບໍ່ຈຳກັດ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MembershipPackageScreen()),
                );
              },
              icon: const Icon(Icons.workspace_premium_rounded, color: Colors.white),
              label: const Text('ໄປທີ່ໜ້າສະໝັກແພັກເກັດສະມາຊິກ (Premiere Member)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          const Text(
            'ເອກະສານຂອງທ່ານຢູ່ລະຫວ່າງການກວດສອບໂດຍແອດມິນ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'ເມື່ອແອດມິນດຳເນີນການອະນຸມັດແລ້ວ ທ່ານຈະໄດ້ຮັບແຈ້ງເຕືອນ ແລະ ສາມາດກົດສະໝັກແພັກເກັດສະມາຊິກໄດ້ທັນທີ',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('ກັບສູ່ໜ້າຫຼັກ'),
          ),
        ],
      ),
    );
  }

  Widget _buildKycFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ປ້ອນຂໍ້ມູນບັດປະຈຳຕົວ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'ຊື່ ແລະ ນາມສະກຸນ (ກົງກັບບັດປະຈຳຕົວ)',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ກະລຸນາປ້ອນຊື່ ແລະ ນາມສະກຸນ';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _idCardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ເລກປະຈຳຕົວປະຊາຊົນ 13 ຫຼັກ',
                hintText: '1-1002-34567-89-0',
                prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ກະລຸນາປ້ອນເລກບັດປະຈຳຕົວ 13 ຫຼັກ';
                }
                if (value.replaceAll('-', '').trim().length < 13) {
                  return 'ເລກບັດປະຈຳຕົວຕ້ອງມີ 13 ຫຼັກ';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'ແນບຫຼັກຖານຮູບຖ່າຍເພື່ອຢືນຢັນຕົວຕົນ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            _buildImagePreview(
              _idCardImagePath,
              'ຮູບຖ່າຍໜ້າບັດປະຈຳຕົວ',
              () {
                setState(() {
                  _idCardImagePath = 'assets/sample_id_card.png';
                });
              },
            ),
            const SizedBox(height: 14),

            _buildImagePreview(
              _selfieImagePath,
              'ຮູບຖ່າຍເຊວຟີຄູ່ກັບບັດປະຈຳຕົວ',
              () {
                setState(() {
                  _selfieImagePath = 'assets/sample_selfie.png';
                });
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitKyc,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'ກຳລັງສົ່ງຂໍ້ມູນ...' : 'ສົ່ງຂໍ້ມູນຍື່ນເລື່ອງໃຫ້ແອດມິນອະນຸມັດ',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
