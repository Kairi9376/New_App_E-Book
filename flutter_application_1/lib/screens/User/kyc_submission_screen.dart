import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import '../../utils/image_helper.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
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
  late TextEditingController _dobController;

  String _selectedGender = 'male';
  DateTime? _selectedDob;

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

  bool _isLoadingLiveKyc = true;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.currentKyc.status;
    _fullNameController = TextEditingController(text: widget.currentKyc.fullName);
    _idCardController = TextEditingController(text: widget.currentKyc.idCardNumber);
    _schoolNameController = TextEditingController(text: widget.currentKyc.schoolName ?? '');

    _selectedGender = widget.currentKyc.gender.isNotEmpty ? widget.currentKyc.gender : 'male';
    final initialDobStr = widget.currentKyc.dateOfBirth.isNotEmpty ? widget.currentKyc.dateOfBirth : '2000-01-01';
    _dobController = TextEditingController(text: initialDobStr);
    _selectedDob = DateTime.tryParse(initialDobStr) ?? DateTime(2000, 1, 1);

    _selectedDocumentType = widget.currentKyc.documentType.isNotEmpty ? widget.currentKyc.documentType : 'national_id';
    _isStudent = widget.currentKyc.isStudent || _selectedDocumentType == 'student_card';

    _idCardImagePath = widget.currentKyc.idCardImagePath.isNotEmpty ? widget.currentKyc.idCardImagePath : null;
    _selfieImagePath = widget.currentKyc.selfieImagePath.isNotEmpty ? widget.currentKyc.selfieImagePath : null;
    _rejectReason = widget.currentKyc.rejectReason;

    _fetchLiveKycFromBackend();
  }

  Future<void> _fetchLiveKycFromBackend() async {
    // # ເຮັດຫຍັງ: ອ່ານ user_id ຜ່ານ ApiService.currentUserId ແທນການຕັ້ງຄ່າເລີ່ມຕົ້ນເປັນ 3
    // # ຍ້ອນຫຍັງ: `?? 3` ໝາຍຄວາມວ່າຖ້າບໍ່ມີຜູ້ໃຊ້ login ຢູ່ ໜ້ານີ້ຈະໄປອ່ານ/ຂຽນ
    // #          ຂໍ້ມູນຂອງບັນຊີ user_id = 3 (ສົມຊາຍ ໃຈດີ) ໂດຍອັດຕະໂນມັດ
    // # ແກ້ຈາກສ່ວນໃດ: `int.tryParse(...) ?? 3 : 3` ທີ່ຂຽນຊ້ຳຢູ່ຫຼາຍໜ້າ
    // # ແກ້ເຮັດຫຍັງ: ໃຊ້ຄ່າຈິງຂອງຜູ້ທີ່ login ຢູ່ ຖ້າບໍ່ມີກໍ່ໃຫ້ເປັນ 0 ເຊິ່ງບໍ່ຕົງກັບໃຜ
    final int userId = ApiService.currentUserId ?? 0;

    final liveKyc = await ApiService.getUserKycStatus(userId);
    if (mounted && liveKyc != null) {
      setState(() {
        _currentStatus = liveKyc.status;
        if (liveKyc.fullName.isNotEmpty) _fullNameController.text = liveKyc.fullName;
        if (liveKyc.gender.isNotEmpty) _selectedGender = liveKyc.gender;
        if (liveKyc.dateOfBirth.isNotEmpty) {
          _dobController.text = liveKyc.dateOfBirth;
          _selectedDob = DateTime.tryParse(liveKyc.dateOfBirth);
        }
        if (liveKyc.idCardNumber.isNotEmpty) _idCardController.text = liveKyc.idCardNumber;
        if (liveKyc.schoolName != null && liveKyc.schoolName!.isNotEmpty) _schoolNameController.text = liveKyc.schoolName!;
        if (liveKyc.documentType.isNotEmpty) _selectedDocumentType = liveKyc.documentType;
        _isStudent = liveKyc.isStudent || _selectedDocumentType == 'student_card';
        if (liveKyc.idCardImagePath.isNotEmpty) _idCardImagePath = liveKyc.idCardImagePath;
        if (liveKyc.selfieImagePath.isNotEmpty) _selfieImagePath = liveKyc.selfieImagePath;
        _rejectReason = liveKyc.rejectReason;
        _isLoadingLiveKyc = false;
      });

      if (widget.onKycUpdated != null) {
        widget.onKycUpdated!(liveKyc);
      }
    } else {
      if (mounted) setState(() => _isLoadingLiveKyc = false);
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _idCardController.dispose();
    _schoolNameController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // --- Real Image File Picker & Backend Upload ---
  Future<void> _pickAndUploadDocumentImage() async {
    setState(() => _isUploadingDoc = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*');
      await Future.delayed(const Duration(milliseconds: 100));
      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        // Upload to backend API
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'kyc_doc',
        );

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (result['success'] == true && result['path'] != null) {
              setState(() {
                _idCardBytes = bytes;
                _idCardImagePath = result['url'] ?? result['path'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ອັບໂຫຼດຮູບເອກະສານສຳເລັດ!'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              setState(() => _idCardBytes = bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ອັບໂຫຼດລົ້ມເຫຼວ: ${result['message'] ?? 'Unknown error'}'), backgroundColor: Colors.redAccent),
              );
            }
          });
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
          if (mounted) setState(() => _isUploadingDoc = false);
        });
      }
    }
  }

  Future<void> _pickAndUploadSelfieImage() async {
    setState(() => _isUploadingSelfie = true);
    try {
      final picked = await FilePickerHelper.pickFile(accept: 'image/*');
      await Future.delayed(const Duration(milliseconds: 100));
      if (picked != null) {
        final bytes = Uint8List.fromList(picked.bytes);
        // Upload to backend API
        final result = await ApiService.uploadFile(
          bytes: picked.bytes,
          filename: picked.name,
          fieldName: 'selfie',
        );

        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (result['success'] == true && result['path'] != null) {
              setState(() {
                _selfieBytes = bytes;
                _selfieImagePath = result['url'] ?? result['path'];
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ອັບໂຫຼດຮູບເຊວຟີສຳເລັດ!'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),
                ),
              );
            } else {
              setState(() => _selfieBytes = bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('ອັບໂຫຼດລົ້ມເຫຼວ: ${result['message'] ?? 'Unknown error'}'), backgroundColor: Colors.redAccent),
              );
            }
          });
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
          if (mounted) setState(() => _isUploadingSelfie = false);
        });
      }
    }
  }

  void _submitKyc() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ ກະລຸນາປ້ອນຂໍ້ມູນສ່ວນຕົວໃຫ້ຄົບຖ້ວນທຸກຊ່ອງກ່ອນ!'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_idCardImagePath == null || _idCardImagePath!.trim().isEmpty || _selfieImagePath == null || _selfieImagePath!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ ກະລຸນາອັບໂຫຼດຮູບພາບບັດປະຈຳຕົວ/ເອກະສານ ແລະ ຮູບຖ່າຍເຊວຟີໃຫ້ຄົບຖ້ວນ!'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // # ເຮັດຫຍັງ: ໃຊ້ ApiService.currentUserId ແທນຄ່າເລີ່ມຕົ້ນ 3
    // # ຍ້ອນຫຍັງ: ການສົ່ງ KYC ດ້ວຍ user_id = 3 ຈະບັນທຶກເອກະສານຢືນຢັນຕົວຕົນ
    // #          (ຮູບບັດປະຈຳຕົວ ແລະ ຮູບເຊວຟີ) ໃສ່ບັນຊີຄົນອື່ນ ຖ້າ session ຫາຍ
    // #          ເປັນຂໍ້ມູນສ່ວນຕົວທີ່ອ່ອນໄຫວທີ່ສຸດໃນລະບົບ
    // # ແກ້ຈາກສ່ວນໃດ: user['user_id'] ?? 3
    // # ແກ້ເຮັດຫຍັງ: ບໍ່ມີ session ກໍ່ຢຸດ ພ້ອມແຈ້ງໃຫ້ເຂົ້າສູ່ລະບົບໃໝ່
    final userId = ApiService.currentUserId;
    if (userId == null) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ ບໍ່ພົບຂໍ້ມູນຜູ້ໃຊ້ ກະລຸນາເຂົ້າສູ່ລະບົບໃໝ່'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    final success = await ApiService.submitKyc({
      'user_id': userId,
      'full_name': _fullNameController.text.trim(),
      'gender': _selectedGender,
      'date_of_birth': _dobController.text.trim(),
      'document_type': _selectedDocumentType,
      'document_number': _idCardController.text.trim(),
      'document_image_url': _idCardImagePath ?? '',
      'selfie_image_url': _selfieImagePath ?? '',
      'is_student': _isStudent,
      'school_name': _isStudent ? _schoolNameController.text.trim() : null,
    });

    // The server is the source of truth for KYC status - only flip the local
    // status to pending once it actually accepted the submission, otherwise the
    // user is told it succeeded while the server holds nothing.
    if (!success) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ ສົ່ງຂໍ້ມູນຢືນຢັນຕົວຕົນບໍ່ສຳເລັດ ກະລຸນາລອງໃໝ່ອີກຄັ້ງ!'),
            backgroundColor: Colors.redAccent,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final updatedKyc = widget.currentKyc.copyWith(
      fullName: _fullNameController.text.trim(),
      gender: _selectedGender,
      dateOfBirth: _dobController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
      documentType: _selectedDocumentType,
      idCardImagePath: _idCardImagePath ?? '',
      selfieImagePath: _selfieImagePath ?? '',
      isStudent: _isStudent,
      schoolName: _isStudent ? _schoolNameController.text.trim() : null,
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

      NotificationService.addNotification(
        context,
        title: '🛡️ ສົ່ງຂໍ້ມູນຢືນຢັນຕົວຕົນ (KYC) ສຳເລັດແລ້ວ',
        message: 'ຂໍ້ມູນເອກະສານຂອງທ່ານຖືກສົ່ງເຂົ້າສູ່ລະບົບແລ້ວ ກະລຸນາລໍຖ້າການກວດສອບ ແລະ ອະນຸມັດຈາກແອດມິນ',
        type: NotificationType.kyc,
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
      contentWidget = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 10),
          Text('ກຳລັງອັບໂຫຼດຮູບພາບ...', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      );
    } else if (imageBytes != null || (imagePath != null && imagePath.isNotEmpty)) {
      contentWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ImageHelper.buildImage(
          imagePath,
          bytes: imageBytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: _buildImagePlaceholder(hint),
        ),
      );
    } else {
      contentWidget = _buildImagePlaceholder(hint);
    }

    final bool hasImage = imageBytes != null || (imagePath != null && imagePath.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: isUploading
              ? null
              : (hasImage
                  ? () => ImageHelper.showPreviewModal(context, path: imagePath, bytes: imageBytes, title: title)
                  : onPick),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                width: hasImage ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(child: contentWidget),
                if (hasImage)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.zoom_in_rounded, size: 16, color: Colors.white),
                            onPressed: () => ImageHelper.showPreviewModal(context, path: imagePath, bytes: imageBytes, title: title),
                            tooltip: 'ເບິ່ງຮູບຂະຫຍາຍ',
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                            onPressed: onPick,
                            tooltip: 'ປ່ຽນຮູບພາບ',
                          ),
                        ),
                      ],
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
                // Loading indicator while fetching live KYC status
                if (_isLoadingLiveKyc) ...[
                  const SizedBox(height: 60),
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  const SizedBox(height: 16),
                  const Center(child: Text('ກຳລັງໂຫຼດຂໍ້ມູນສະຖານະ KYC...', style: TextStyle(color: AppColors.textSecondary))),
                ] else ...[
                  _buildStatusHeaderBanner(),
                  const SizedBox(height: 20),

                  if (_currentStatus == KycStatus.approved) ...[
                    _buildApprovedCard(),
                  ] else if (_currentStatus == KycStatus.pending) ...[
                    _buildPendingCard(),
                  ] else if (_currentStatus == KycStatus.rejected) ...[
                    _buildRejectedCard(),
                  ] else ...[
                    _buildKycFormCard(),
                  ],
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
              color: textColor.withValues(alpha: 0.15),
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
                  style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.9)),
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
            color: Colors.black.withValues(alpha: 0.04),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated pending icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 18),
          const Center(
            child: Text(
              'ເອກະສານຂອງທ່ານຢູ່ລະຫວ່າງການກວດສອບ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'ແອດມິນກຳລັງພິຈາລະນາເອກະສານຂອງທ່ານ ໂດຍປົກກະຕິໃຊ້ເວລາ 1-24 ຊົ່ວໂມງ\nທ່ານບໍ່ສາມາດສົ່ງຄຳຂໍໃໝ່ໄດ້ໃນລະຫວ່າງນີ້',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          // Divider with label
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ຂໍ້ມູນທີ່ສົ່ງໄປ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 16),
          // Previously submitted data
          _buildSubmittedDataSummary(),
          const SizedBox(height: 24),
          // Back button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('ກັບສູ່ໜ້າຫຼັກ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Dedicated Rejected Card with Previous Data & Re-submit ---
  bool _isResubmitMode = false;

  Widget _buildRejectedCard() {
    if (_isResubmitMode) {
      return _buildKycFormCard();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: [
          BoxShadow(color: Colors.red.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rejection header icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
              ),
              child: const Icon(Icons.gpp_bad_rounded, size: 48, color: Color(0xFFDC2626)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'ການຢືນຢັນຕົວຕົນຖືກປະຕິເສດ',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),

          // Rejection reason card (prominent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'ເຫດຜົນທີ່ຖືກປະຕິເສດ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _rejectReason ?? 'ເອກະສານບໍ່ຊັດເຈນ ຫຼື ຂໍ້ມູນບໍ່ກົງກັນ',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F1D1D),
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Divider with label
          Row(
            children: [
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('ຂໍ້ມູນທີ່ສົ່ງກ່ອນໜ້ານີ້', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),
          const SizedBox(height: 16),

          // Previously submitted data
          _buildSubmittedDataSummary(),
          const SizedBox(height: 28),

          // Re-submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isResubmitMode = true);
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
              label: const Text(
                'ແກ້ໄຂ ແລະ ສົ່ງຂໍ້ມູນໃໝ່ (Re-submit)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('ກັບສູ່ໜ້າຫຼັກ', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable summary of previously submitted data ---
  Widget _buildSubmittedDataSummary() {
    final docTypeLabel = _selectedDocumentType == 'passport'
        ? '📕 ໜັງສືຜ່ານແດນ (Passport)'
        : (_selectedDocumentType == 'student_card'
            ? '🎓 ບັດນັກຮຽນ (Student Card)'
            : '🪪 ບັດປະຈຳຕົວ (National ID)');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info rows
        _buildInfoRow(Icons.assignment_ind_outlined, 'ປະເພດເອກະສານ', docTypeLabel),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.badge_outlined, 'ຊື່ ແລະ ນາມສະກຸນ', _fullNameController.text.isNotEmpty ? _fullNameController.text : 'ບໍ່ລະບຸ'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildInfoRow(Icons.wc_rounded, 'ເພດ', _selectedGender == 'female' ? 'ຍິງ (Female)' : (_selectedGender == 'other' ? 'ອື່ນໆ (Other)' : 'ຊາຍ (Male)'))),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoRow(Icons.cake_rounded, 'ວັນເດືອນປີເກີດ', _dobController.text.isNotEmpty ? _dobController.text : 'ບໍ່ລະບຸ')),
          ],
        ),
        const SizedBox(height: 10),
        _buildInfoRow(Icons.credit_card_rounded, 'ເລກເອກະສານ', _idCardController.text.isNotEmpty ? _idCardController.text : 'ບໍ່ລະບຸ'),
        if (_isStudent) ...[
          const SizedBox(height: 10),
          _buildInfoRow(Icons.school_rounded, 'ໂຮງຮຽນ / ມະຫາວິທະຍາໄລ', _schoolNameController.text.isNotEmpty ? _schoolNameController.text : 'ບໍ່ລະບຸ'),
        ],
        const SizedBox(height: 18),

        // Document image preview
        const Text('ຮູບຖ່າຍເອກະສານ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: (_idCardImagePath != null && _idCardImagePath!.isNotEmpty)
                ? () => ImageHelper.showPreviewModal(context, path: _idCardImagePath, bytes: _idCardBytes, title: 'ຮູບເອກະສານ')
                : null,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: (_idCardBytes != null || (_idCardImagePath != null && _idCardImagePath!.isNotEmpty))
                  ? ImageHelper.buildImage(_idCardImagePath, bytes: _idCardBytes, fit: BoxFit.cover, width: double.infinity, height: 140)
                  : const Center(child: Text('ບໍ່ມີຮູບ', style: TextStyle(color: AppColors.textSecondary))),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Selfie image preview
        const Text('ຮູບຖ່າຍເຊວຟີ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: (_selfieImagePath != null && _selfieImagePath!.isNotEmpty)
                ? () => ImageHelper.showPreviewModal(context, path: _selfieImagePath, bytes: _selfieBytes, title: 'ຮູບເຊວຟີ')
                : null,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: (_selfieBytes != null || (_selfieImagePath != null && _selfieImagePath!.isNotEmpty))
                  ? ImageHelper.buildImage(_selfieImagePath, bytes: _selfieBytes, fit: BoxFit.cover, width: double.infinity, height: 140)
                  : const Center(child: Text('ບໍ່ມີຮູບ', style: TextStyle(color: AppColors.textSecondary))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
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
            color: Colors.black.withValues(alpha: 0.04),
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
            if (_currentStatus == KycStatus.rejected) ...[
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ເອກະສານຂອງທ່ານຖືກປະຕິເສດ! (Rejected Request)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ເຫດຜົນ: ${_rejectReason ?? "ເອກະສານບໍ່ຊັດເຈນ ຫຼື ຂໍ້ມູນບໍ່ກົງກັນ"}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ກະລຸນາກວດສອບ ແກ້ໄຂຂໍ້ມູນ ຫຼື ແນບຮູບພາບເອກະສານໃໝ່ ແລ້ວກົດປຸ່ມ "ສົ່ງຂໍ້ມູນ Re-submit" ດ້ານລຸ່ມເພື່ອໃຫ້ແອດມິນພິຈາລະນາອີກຄັ້ງ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Text(
              '1. ເລືອກປະເພດເອກະສານຢືນຢັນຕົວຕົນ (Document Type)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            // DOCUMENT TYPE SELECTOR (ChoiceChips / Dropdown)
            DropdownButtonFormField<String>(
              initialValue: _selectedDocumentType,
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
              '2. ປ້ອນຂໍ້ມູນສ່ວນຕົວ',
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
            const SizedBox(height: 14),

            // Gender & Date of Birth Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: ['male', 'female', 'other'].contains(_selectedGender.toLowerCase())
                        ? _selectedGender.toLowerCase()
                        : 'male',
                    decoration: InputDecoration(
                      labelText: 'ເພດ (Gender)',
                      prefixIcon: const Icon(Icons.wc_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('👨 ຊາຍ (Male)')),
                      DropdownMenuItem(value: 'female', child: Text('👩 ຍິງ (Female)')),
                      DropdownMenuItem(value: 'other', child: Text('⚧ ອື່ນໆ (Other)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedGender = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: _selectDateOfBirth,
                    decoration: InputDecoration(
                      labelText: 'ວັນເກີດ (DOB)',
                      prefixIcon: const Icon(Icons.cake_rounded, color: AppColors.primary),
                      suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'ກະລຸນາເລືອກວັນເກີດ';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

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
                    activeThumbColor: AppColors.primary,
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
                  _isSubmitting
                      ? 'ກຳລັງສົ່ງຂໍ້ມູນ...'
                      : (_currentStatus == KycStatus.rejected
                          ? 'ສົ່ງຂໍ້ມູນ Re-submit ໃຫ້ແອດມິນພິຈາລະນາອີກຄັ້ງ'
                          : 'ສົ່ງຂໍ້ມູນຍື່ນເລື່ອງໃຫ້ແອດມິນອະນຸມັດ'),
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
