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
          content: Text('กรุณาอัปโหลดรูปภาพบัตรประชาชนและรูปถ่ายคู่กับบัตรประชาชนให้ครบถ้วน'),
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
          content: Text('ส่งข้อมูลยืนยันตัวตน (KYC) สำเร็จ! กรุณารอแอดมินอนุมัติ'),
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
                              'แนบไฟล์แล้ว ($placeholderText)',
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
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'คลิกเพื่อเลือกรูปภาพ หรือถ่ายภาพ',
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
        title: const Text('ยืนยันตัวตน (KYC Verification)'),
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
                // 1. Status Banner Card
                _buildStatusHeaderBanner(),
                const SizedBox(height: 20),

                // 2. Form or Summary depending on status
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
        titleText = 'สถานะ: ยืนยันตัวตนผ่านแล้ว (Approved)';
        descText = 'บัญชีของคุณได้รับการตรวจสอบและอนุมัติ KYC เรียบร้อย สามารถสมัครแพ็กเกจสมาชิก Premiere ได้ทันที!';
        break;
      case KycStatus.pending:
        bannerColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFF92400E);
        icon = Icons.pending_actions_rounded;
        titleText = 'สถานะ: รอแอดมินตรวจสอบเอกสาร (Pending)';
        descText = 'แอดมินกำลังดำเนินการตรวจสอบบัตรประชาชนและหลักฐานของคุณ โดยปกติจะใช้เวลา 1-24 ชั่วโมง';
        break;
      case KycStatus.rejected:
        bannerColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        icon = Icons.gpp_bad_rounded;
        titleText = 'สถานะ: การยืนยันตัวตนถูกปฏิเสธ (Rejected)';
        descText = _rejectReason ?? 'เอกสารของคุณไม่ผ่านการอนุมัติ โปรดตรวจสอบและแก้ไขข้อมูลก่อนส่งอีกครั้ง';
        break;
      case KycStatus.notSubmitted:
        bannerColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1E40AF);
        icon = Icons.shield_outlined;
        titleText = 'ขั้นตอนการยืนยันตัวตน (KYC Setup)';
        descText = 'กรอกเลขบัตรประชาชนและแนบหลักฐานรูปถ่ายเพื่อยื่นเรื่องให้แอดมินอนุมัติสิทธิ์สมัครแพ็กเกจสมาชิก';
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
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
            'ยินดีด้วย! บัญชีของคุณยืนยันตัวตนสำเร็จแล้ว',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'คุณได้รับสิทธิ์เข้าถึงการสมัครสมาชิกและแพ็กเกจอ่าน e-Book แบบไม่จำกัด',
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
              label: const Text('ไปที่หน้าสมัครแพ็กเกจสมาชิก (Premiere Member)', style: TextStyle(fontWeight: FontWeight.bold)),
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
            'เอกสารของคุณอยู่ระหว่างการตรวจสอบโดยแอดมิน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          const Text(
            'เมื่อแอดมินทำการอนุมัติแล้ว คุณจะได้รับแจ้งเตือนและสามารถกดสมัครแพ็กเกจสมาชิกได้ทันที',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('กลับสู่หน้าหลัก'),
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
              'กรอกข้อมูลบัตรประชาชน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),

            // Full Name
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'ชื่อ-นามสกุล (ตรงตามบัตรประชาชน)',
                prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกชื่อ-นามสกุล';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ID Card Number
            TextFormField(
              controller: _idCardController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'เลขประจำตัวประชาชน 13 หลัก',
                hintText: '1-1002-34567-89-0',
                prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'กรุณากรอกเลขบัตรประชาชน 13 หลัก';
                }
                if (value.replaceAll('-', '').trim().length < 13) {
                  return 'เลขบัตรประชาชนต้องมี 13 หลัก';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'แนบหลักฐานรูปถ่ายเพื่อยืนยันตัวตน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Document 1: ID Card Photo
            _buildImagePreview(
              _idCardImagePath,
              'รูปถ่ายหน้าบัตรประชาชน',
              () {
                setState(() {
                  _idCardImagePath = 'assets/sample_id_card.png';
                });
              },
            ),
            const SizedBox(height: 14),

            // Document 2: Selfie with ID Card Photo
            _buildImagePreview(
              _selfieImagePath,
              'รูปถ่ายเซลฟี่คู่กับบัตรประชาชน',
              () {
                setState(() {
                  _selfieImagePath = 'assets/sample_selfie.png';
                });
              },
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitKyc,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'กำลังส่งข้อมูล...' : 'ส่งข้อมูลยื่นเรื่องให้แอดมินอนุมัติ',
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
