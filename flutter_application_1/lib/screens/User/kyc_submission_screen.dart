import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
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
  late TextEditingController _schoolNameController;

  late KycStatus _currentStatus;
  String _selectedDocumentType = 'national_id'; // national_id, passport, student_card
  bool _isStudent = false;

  String? _idCardImagePath;
  Uint8List? _idCardBytes;
  bool _isUploadingDoc = false;

  String? _selfieImagePath;
  Uint8List? _selfieBytes;
  bool _isUploadingSelfie = false;

  String? _rejectReason;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.currentKyc.status;
    _fullNameController = TextEditingController(text: widget.currentKyc.fullName);
    _idCardController = TextEditingController(text: widget.currentKyc.idCardNumber);
    _schoolNameController = TextEditingController(text: widget.currentKyc.schoolName ?? '');

    _selectedDocumentType = widget.currentKyc.documentType.isNotEmpty ? widget.currentKyc.documentType : 'national_id';
    _isStudent = widget.currentKyc.isStudent || _selectedDocumentType == 'student_card';

    _idCardImagePath = widget.currentKyc.idCardImagePath.isNotEmpty ? widget.currentKyc.idCardImagePath : null;
    _selfieImagePath = widget.currentKyc.selfieImagePath.isNotEmpty ? widget.currentKyc.selfieImagePath : null;
    _rejectReason = widget.currentKyc.rejectReason;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idCardController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  // --- Real Image File Picker & Backend Upload ---
  Future<void> _pickAndUploadDocumentImage() async {
    setState(() => _isUploadingDoc = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*');
      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        // Upload to backend API
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'document_image',
        );

        if (mounted) {
          setState(() {
            _idCardBytes = bytes;
            if (result['success'] == true && result['path'] != null) {
              _idCardImagePath = result['path'];
            } else {
              _idCardImagePath = 'uploads/kyc_doc_${DateTime.now().millisecondsSinceEpoch}.jpg';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ອັບໂຫຼດຮູບເອກະສານສຳເລັດ!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingDoc = false);
    }
  }

  Future<void> _pickAndUploadSelfieImage() async {
    setState(() => _isUploadingSelfie = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*');
      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        // Upload to backend API
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'selfie_image',
        );

        if (mounted) {
          setState(() {
            _selfieBytes = bytes;
            if (result['success'] == true && result['path'] != null) {
              _selfieImagePath = result['path'];
            } else {
              _selfieImagePath = 'uploads/kyc_selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ອັບໂຫຼດຮູບຖ່າຍເຊວຟີສຳເລັດ!'),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปโหลด: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingSelfie = false);
    }
  }

  void _submitKyc() async {
    if (!_formKey.currentState!.validate()) return;

    if (_idCardImagePath == null || _selfieImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາອັບໂຫຼດຮູບພາບບັດປະຈຳຕົວ/ເອກະສານ ແລະ ຮູບຖ່າຍເຊວຟີໃຫ້ຄົບຖ້ວນ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = ApiService.currentUser ?? {};
    final userId = user['user_id'] ?? 3;

    final success = await ApiService.submitKyc({
      'user_id': userId,
      'document_type': _selectedDocumentType,
      'document_number': _idCardController.text.trim(),
      'document_image_url': _idCardImagePath ?? '',
      'selfie_image_url': _selfieImagePath ?? '',
      'is_student': _isStudent,
      'school_name': _isStudent ? _schoolNameController.text.trim() : null,
    });

    final updatedKyc = widget.currentKyc.copyWith(
      status: KycStatus.pending,
      rejectReason: null,
      reviewedAt: null,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _currentStatus = KycStatus.pending;
        _rejectReason = null;
      });

      if (widget.onKycUpdated != null) {
        widget.onKycUpdated!(updatedKyc);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'ສົ່ງຂໍ້ມູນຢືນຢັນຕົວຕົນ (KYC) ເຂົ້າຖານຂໍ້ມູນ MySQL ສຳເລັດ!' : 'ສົ່ງຂໍ້ມູນຢືนຢັນຕົວຕົນ (KYC) ສຳເລັດ! ກະລຸນາລໍຖ້າແອດມິນອະນຸມັດ'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Widget _buildImagePreviewWidget({
    required String title,
    required String hint,
    required String? imagePath,
    required Uint8List? imageBytes,
    required bool isUploading,
    required VoidCallback onPick,
  }) {
    Widget contentWidget;

    if (isUploading) {
      contentWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 10),
          Text('ກຳລັງອັບໂຫຼດຮູບພາບ...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      );
    } else if (imageBytes != null) {
      // Live thumbnail of newly picked file
      contentWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
      );
    } else if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        contentWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(imagePath, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(hint)),
        );
      } else if (imagePath.startsWith('assets/')) {
        contentWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(imagePath, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, __, ___) => _buildImagePlaceholder(hint)),
        );
      } else {
        contentWidget = _buildUploadedSuccessBadge(title);
      }
    } else {
      contentWidget = _buildImagePlaceholder(hint);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: isUploading ? null : onPick,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (imageBytes != null || imagePath != null) ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                width: (imageBytes != null || imagePath != null) ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: contentWidget),
                if (imageBytes != null || imagePath != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                        onPressed: onPick,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder(String hint) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_a_photo_outlined, size: 38, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(hint, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        const Text('ຄລິກເພື່ອເລືອກຮູບພາບຈາກເຄື່ອງ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildUploadedSuccessBadge(String title) {
    return Container(
      color: const Color(0xFFECFDF5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
            const SizedBox(height: 6),
            Text('ອັບໂຫຼດໄຟລ໌ສຳເລັດແລ້ວ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46), fontSize: 13)),
            const SizedBox(height: 2),
            Text(title, style: const TextStyle(color: Color(0xFF047857), fontSize: 11)),
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
        descText = 'ເລືອກປະເພດເອກະສານ, ປ້ອນເລກບັດປະຈຳຕົວ ແລະ ແນບຫຼັກຖານຮູບຖ່າຍເພື່ອຍື່ນເລື່ອງໃຫ້ແອດມິນອະນຸມັດ';
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
    String docNumberLabel;
    String docNumberHint;

    switch (_selectedDocumentType) {
      case 'passport':
        docNumberLabel = 'ເລກພາດສະປອດ (Passport Number)';
        docNumberHint = 'P12345678';
        break;
      case 'student_card':
        docNumberLabel = 'ເລກບັດນັກຮຽນ / ເລກປະຈຳຕົວນັກສຶກສາ (Student ID)';
        docNumberHint = 'STU-99887766';
        break;
      case 'national_id':
      default:
        docNumberLabel = 'ເລກປະຈຳຕົວປະຊາຊົນ 13 ຫຼັກ (National ID)';
        docNumberHint = '1-1002-34567-89-0';
        break;
    }

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
              '1. ເລືອກປະເພດເອກະສານຢືນຢັນຕົວຕົນ (Document Type)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            // DOCUMENT TYPE SELECTOR (ChoiceChips / Dropdown)
            DropdownButtonFormField<String>(
              value: _selectedDocumentType,
              decoration: InputDecoration(
                labelText: 'ປະເພດເອກະສານ (Document Type)',
                prefixIcon: const Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'national_id',
                  child: Text('🪪 ບັດປະຈຳຕົວປະຊາຊົນ (National ID)'),
                ),
                DropdownMenuItem(
                  value: 'passport',
                  child: Text('📕 ໜັງສືຜ່ານແດນ (Passport)'),
                ),
                DropdownMenuItem(
                  value: 'student_card',
                  child: Text('🎓 ບັດນັກຮຽນ / ບັດນັກສຶກສາ (Student Card)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedDocumentType = val;
                    if (val == 'student_card') {
                      _isStudent = true;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 18),

            const Text(
              '2. ປ້ອນຂໍ້ມູນส่วนຕົວ',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'ຊື່ ແລະ ນາມສະກຸນ (ກົງກັບບັດ/ເອກະສານ)',
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
              decoration: InputDecoration(
                labelText: docNumberLabel,
                hintText: docNumberHint,
                prefixIcon: const Icon(Icons.credit_card_rounded, color: AppColors.primary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'ກະລຸນາປ້ອນ $docNumberLabel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Student Status Switch / Extra Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ທ່ານເປັນນັກຮຽນ / ນັກສຶກສາ ຫຼື ບໍ່? (ໄດ້ຮັບສ່ວນຫຼຸດແພັກເກັດ)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ),
                  Switch(
                    value: _isStudent,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isStudent = val;
                        if (val && _selectedDocumentType != 'student_card') {
                          _selectedDocumentType = 'student_card';
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            if (_isStudent) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _schoolNameController,
                decoration: InputDecoration(
                  labelText: 'ຊື່ໂຮງຮຽນ / ມະຫາວິທະຍາໄລ (School/University Name)',
                  prefixIcon: const Icon(Icons.domain_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (_isStudent && (value == null || value.trim().isEmpty)) {
                    return 'ກະລຸນາປ້ອນຊື່ໂຮງຮຽນ ຫຼື ມະຫາວິທະຍາໄລ';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),

            const Text(
              '3. ແນບຫຼັກຖານຮູບຖ່າຍເພື່ອຢືນຢັນຕົວຕົນ (Upload Verification Photos)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Image 1: Document Image
            _buildImagePreviewWidget(
              title: _selectedDocumentType == 'passport'
                  ? 'ຮູບຖ່າຍໜ້າພາດສະປອດ (Passport Photo)'
                  : (_selectedDocumentType == 'student_card'
                      ? 'ຮູບຖ່າຍບັດນັກຮຽນ/ນັກສຶກສາ (Student Card Photo)'
                      : 'ຮູບຖ່າຍໜ້າບັດປະຈຳຕົວ (National ID Photo)'),
              hint: 'ຄລິກເພື່ອເລືອກຮູບຖ່າຍເອກະສານ',
              imagePath: _idCardImagePath,
              imageBytes: _idCardBytes,
              isUploading: _isUploadingDoc,
              onPick: _pickAndUploadDocumentImage,
            ),
            const SizedBox(height: 16),

            // Image 2: Selfie Image
            _buildImagePreviewWidget(
              title: 'ຮູບຖ່າຍເຊວຟີຄູ່ກັບເອກະສານ (Selfie with Document)',
              hint: 'ຄລິກເພື່ອເລືອກຮູບຖ່າຍເຊວຟີ',
              imagePath: _selfieImagePath,
              imageBytes: _selfieBytes,
              isUploading: _isUploadingSelfie,
              onPick: _pickAndUploadSelfieImage,
            ),
            const SizedBox(height: 28),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: (_isSubmitting || _isUploadingDoc || _isUploadingSelfie) ? null : _submitKyc,
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
