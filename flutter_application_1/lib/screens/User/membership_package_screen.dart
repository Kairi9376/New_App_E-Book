import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import '../../utils/image_helper.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';
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
  int _selectedPackageIndex = 0;
  List<Map<String, dynamic>> _fetchedPackages = [];
  bool _isLoading = true;

  KycStatus _liveKycStatus = KycStatus.notSubmitted;
  KycModel? _liveKycModel;
  Map<String, dynamic>? _liveSubscription;
  bool _isResubmitMode = false;

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    setState(() => _isLoading = true);

    final user = ApiService.currentUser ?? {};
    final rawUserId = user['user_id'] ?? user['id'];
    final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;

    final packages = await ApiService.getPackages();
    final kycModel = await ApiService.getUserKycStatus(userId);
    final subData = await ApiService.getUserSubscriptionStatus(userId);

    if (mounted) {
      setState(() {
        _fetchedPackages = packages;
        _liveKycModel = kycModel;
        _liveKycStatus = kycModel?.status ?? widget.kycStatus;
        _liveSubscription = subData;
        _isLoading = false;
      });
    }
  }

  bool get _isUserStudent {
    final user = ApiService.currentUser ?? {};
    final bool userFlag = user['is_student'] == 1 || user['is_student'] == true || user['role'] == 'student';
    final bool kycFlag = _liveKycModel?.isStudent == true || widget.userKyc?.isStudent == true;
    return userFlag || kycFlag;
  }

  String _formatKipPrice(dynamic priceVal) {
    if (priceVal == null) return '0 ກີບ';
    final double numVal = double.tryParse(priceVal.toString()) ?? 0.0;
    final int intVal = numVal.round();
    final str = intVal.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final formatted = str.replaceAllMapped(reg, (Match m) => '${m[1]},');
    return '$formatted ກີບ';
  }

  void _onSubscribeClicked(int index) {
    if (_liveKycStatus != KycStatus.approved) {
      _showKycRequiredDialog();
      return;
    }

    if (index < 0 || index >= _fetchedPackages.length) return;
    final pkg = _fetchedPackages[index];
    final bool isStudentPkg = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;

    if (isStudentPkg && !_isUserStudent) {
      _showStudentRequiredDialog();
      return;
    }

    _openPaymentDialog(pkg);
  }

  void _showStudentRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 44, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 16),
              const Text(
                'ສະຫງວນສິດเฉพาะນັກຮຽນ/ນັກສຶກສາ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'ແພັກເກັດນີ້ເປັນແພັກເກັດລາຄາພິເສດສະເພາະຜູ້ໃຊ້ທີ່ມີສະຖານະນັກຮຽນ/ນັກສຶກສາເທົ່ານັ້ນ\n\nຫາກທ່ານເປັນນັກຮຽນ/ນັກສຶກສາ ກະລຸນາຍື່ນຢືນຢັນຕົວຕົນ KYC ເພີ່ມເຕີມດ້ວຍບັດນັກຮຽນເພື່ອຮັບສິດທິພິເສດນີ້',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => KycSubmissionScreen(
                          currentKyc: _liveKycModel ??
                              widget.userKyc ??
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
                                isStudent: true,
                                submittedAt: DateTime.now(),
                              ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
                  label: const Text('ຢືນຢັນຕົວຕົນດ້ວຍບັດນັກຮຽນ (KYC)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ປິດໜ້າຕ່າງ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Payment Modal Dialog with Real Transfer Slip Upload ---
  void _openPaymentDialog(Map<String, dynamic> pkg) {
    Uint8List? slipBytes;
    String? slipPath;
    String? slipUrl;
    bool isUploading = false;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final String pkgName = pkg['name'] ?? 'Package';
            final String pkgPriceFormatted = _formatKipPrice(pkg['price']);
            final int durationDays = int.tryParse(pkg['duration_days']?.toString() ?? '30') ?? 30;
            final int packageId = pkg['package_id'] ?? 1;
            final double amount = double.tryParse(pkg['price']?.toString() ?? '0') ?? 0.0;

            Future<void> pickAndUploadSlip() async {
              setDialogState(() => isUploading = true);
              try {
                final picked = await FilePickerHelper.pickFile(accept: 'image/*');
                await Future.delayed(const Duration(milliseconds: 100));

                if (picked != null) {
                  final bytes = Uint8List.fromList(picked.bytes);
                  final tempName = 'slip_${DateTime.now().millisecondsSinceEpoch}.jpg';

                  // Immediately set image bytes & fallback path for instant preview
                  setDialogState(() {
                    slipBytes = bytes;
                    slipPath = tempName;
                    slipUrl = tempName;
                  });

                  final result = await ApiService.uploadFile(
                    bytes: picked.bytes,
                    filename: picked.name,
                    fieldName: 'slip',
                  );

                  if (result['success'] == true && result['path'] != null) {
                    setDialogState(() {
                      slipPath = result['path'];
                      slipUrl = result['url'] ?? result['path'];
                    });
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດໃນການອັບໂຫຼດ: $e'), backgroundColor: Colors.redAccent),
                );
              } finally {
                setDialogState(() => isUploading = false);
              }
            }

            Future<void> submitPayment() async {
              if (slipUrl == null || slipUrl!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ກະລຸນາອັບໂຫຼດຫຼັກຖານການໂອນເງິນ (ສະລິບ) ກ່ອນຢືນຢັນ'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }

              setDialogState(() => isSubmitting = true);

              final user = ApiService.currentUser ?? {};
              final rawUserId = user['user_id'] ?? user['id'];
              final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;

              final success = await ApiService.createSubscription({
                'user_id': userId,
                'package_id': packageId,
                'amount': amount,
                'slip_image_url': slipUrl,
                'payment_method': 'bank_transfer',
              });

              setDialogState(() => isSubmitting = false);

              if (success) {
                Navigator.pop(ctx);
                _loadBackendData();
                NotificationService.addNotification(
                  context,
                  title: '💳 ແຈ້ງຊຳລະເງິນສະໝັກແພັກເກັດແລ້ວ',
                  message: 'ສົ່ງຫຼັກຖານການໂອນເງິນສະໝັກແພັກເກັດ "${pkgName}" ຮຽບຮ້ອຍແລ້ວ ກະລຸນາລໍຖ້າແອດມິນກວດສອບອະນຸມັດ',
                  type: NotificationType.subscription,
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ເກີດຂໍ້ຜິດພາດໃນການບັນທຶກຂໍ້ມູນການຊຳລະເງິນ'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: const [
                  Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 28),
                  SizedBox(width: 10),
                  Text('ຊຳລະເງິນສະໝັກສະມາຊິກ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Package info box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkgName,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ລາຄາ: $pkgPriceFormatted / $durationDays ວັນ',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Bank Details Section
                      const Text(
                        '1. ໂອນເງິນເຂົ້າບັນຊີທະນາຄານ (BCEL One)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('🏛️ ທະນາຄານການຄ້າຕ່າງປະເທດລາວ (BCEL)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                  SizedBox(height: 6),
                                  SelectableText('ເລກບັນຊີ: 160-12-00-01234567-001', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  SizedBox(height: 4),
                                  Text('ຊື່ບັນຊີ: E-Book Application Co., Ltd.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  SizedBox(height: 6),
                                  Text('ສະແກນ QR Code ຜ່ານ BCEL One', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: SvgPicture.asset(
                                'assets/QRcodeDemo.svg',
                                width: 95,
                                height: 95,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Upload Slip Section
                      const Text(
                        '2. ແນບຫຼັກຖານການໂອນເງິນ (Upload Payment Slip)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),

                      if (isUploading)
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              CircularProgressIndicator(color: AppColors.primary),
                              SizedBox(height: 8),
                              Text('ກຳລັງອັບໂຫຼດສະລິບ...', style: TextStyle(fontSize: 12, color: AppColors.primary)),
                            ],
                          ),
                        )
                      else if (slipBytes != null || (slipUrl != null && slipUrl!.isNotEmpty))
                        Container(
                          height: 140,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF10B981), width: 2),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 140,
                                  child: ImageHelper.buildImage(
                                    slipUrl,
                                    bytes: slipBytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 140,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => ImageHelper.showPreviewModal(
                                        context,
                                        path: slipUrl,
                                        bytes: slipBytes,
                                        title: 'ຮູບສະລິບການໂອນເງິນ',
                                      ),
                                      icon: const Icon(Icons.zoom_in_rounded, size: 14, color: Colors.white),
                                      label: const Text('ຂະຫຍາຍ', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black54,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton.icon(
                                      onPressed: pickAndUploadSlip,
                                      icon: const Icon(Icons.refresh_rounded, size: 14, color: Colors.white),
                                      label: const Text('ປ່ຽນຮູບ', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        InkWell(
                          onTap: pickAndUploadSlip,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 130,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_photo_alternate_outlined, size: 36, color: AppColors.primary),
                                SizedBox(height: 6),
                                Text('ຄລິກເພື່ອເລືອກຮູບສະລິບການໂອນເງິນ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting || isUploading ? null : submitPayment,
                  icon: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  label: Text(isSubmitting ? 'ກຳລັງສົ່ງข้อมูล...' : 'ຢືນຢັນການຊຳລະເງິນ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKycRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.gpp_maybe_rounded, color: Color(0xFFEF4444), size: 28),
            SizedBox(width: 8),
            Text('ຕ້ອງຢືນຢັນຕົວຕົນ (KYC) ກ່ອນ'),
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
    final subStatus = _liveSubscription?['payment_status'] ?? 'none';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderBanner(),
                const SizedBox(height: 24),

                if (_isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.all(60.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  ),
                ] else if (subStatus == 'active') ...[
                  _buildActiveSubscriptionCard(),
                ] else if (subStatus == 'pending') ...[
                  _buildPendingSubscriptionCard(),
                ] else if (subStatus == 'rejected' && !_isResubmitMode) ...[
                  _buildRejectedSubscriptionCard(),
                ] else ...[
                  if (_liveKycStatus != KycStatus.approved) _buildKycWarningBanner(),
                  const SizedBox(height: 16),
                  _buildPackageCardsGrid(),
                  const SizedBox(height: 32),
                  _buildFaqSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKycWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ກະລຸນາຢືນຢັນຕົວຕົນ (KYC) ກ່ອນສະໝັກ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                ),
                SizedBox(height: 2),
                Text(
                  'ບັນຊີຂອງທ່ານຕ້ອງได้รับการອະນຸມັດ KYC จากแอดมินก่อนจึงจะสามารถทำรายการชำระเงินได้',
                  style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _showKycRequiredDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ยื่น KYC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // --- Active Subscription View ---
  Widget _buildActiveSubscriptionCard() {
    final pkgName = _liveSubscription?['package_name'] ?? 'Premiere Member';
    final price = _formatKipPrice(_liveSubscription?['amount'] ?? _liveSubscription?['price']);
    final startDateStr = _liveSubscription?['start_date'] != null
        ? DateTime.tryParse(_liveSubscription!['start_date'].toString())?.toLocal().toString().split(' ')[0] ?? ''
        : '';
    final endDateStr = _liveSubscription?['end_date'] != null
        ? DateTime.tryParse(_liveSubscription!['end_date'].toString())?.toLocal().toString().split(' ')[0] ?? ''
        : '';

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF10B981), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF10B981).withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFECFDF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, size: 54, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 16),
          const Text(
            'ທ່ານເປັນສະມາຊິກ Premiere Member ແລ້ວ!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'ແພັກເກັດປັດຈຸບັນ: $pkgName ($price)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          if (startDateStr.isNotEmpty || endDateStr.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('ระยะเวลาใช้งาน: $startDateStr ถึง $endDateStr', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
              label: const Text('เริ่มอ่าน e-Book PDF ได้ทันที', style: TextStyle(fontWeight: FontWeight.bold)),
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

  // --- Pending Subscription View ---
  Widget _buildPendingSubscriptionCard() {
    final pkgName = _liveSubscription?['package_name'] ?? 'Premiere Package';
    final amountFormatted = _formatKipPrice(_liveSubscription?['amount']);
    final slipUrl = _liveSubscription?['slip_image_url'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFDE68A), width: 2),
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 48, color: Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'ລໍຖ້າແອດມິນກວດສອບການຊຳລະເງິນ (Pending)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'ແອດມິນກຳລັງກວດສອບສະລິບການໂອນເງິນຂອງທ່ານ ໂດຍປົກກະຕິໃຊ້ເວລາ 1-24 ຊົ່ວໂມງ\nທ່ານບໍ່ສາມາດສົ່ງຄຳຂໍໃໝ່ໄດ້ໃນລະຫວ່າງນີ້',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),

          const Text('ຂໍ້ມູນການຊຳລະເງິນທີ່ສົ່ງໄປ:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 10),
          _buildInfoTile(Icons.workspace_premium_rounded, 'ແພັກເກັດ', pkgName),
          const SizedBox(height: 8),
          _buildInfoTile(Icons.payments_rounded, 'จำนวนเงิน', amountFormatted),
          const SizedBox(height: 14),

          if (slipUrl.isNotEmpty) ...[
            const Text('ສະລິບການໂອນເງິນ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => ImageHelper.showPreviewModal(context, path: slipUrl, title: 'ສະລິບການໂອນເງິນ'),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: ImageHelper.buildImage(slipUrl, fit: BoxFit.cover, width: double.infinity, height: 150),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('ກັບສູ່ໜ້າຫຼັກ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- Rejected Subscription View ---
  Widget _buildRejectedSubscriptionCard() {
    final pkgName = _liveSubscription?['package_name'] ?? 'Premiere Package';
    final amountFormatted = _formatKipPrice(_liveSubscription?['amount']);
    final rejectReason = _liveSubscription?['rejected_reason'] ?? 'ສະລິບການໂອນເງິນບໍ່ຊັດເຈນ ຫຼື ຈຳນວນເງິນບໍ່ກົງກັນ';
    final slipUrl = _liveSubscription?['slip_image_url'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              'ການຊຳລະເງິນຖືກປະຕິເສດ (Rejected)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 18),

          // Reason card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFDC2626), size: 20),
                    SizedBox(width: 8),
                    Text('ເຫດຜົນທີ່ຖືກປະຕິເສດ:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                  ],
                ),
                const SizedBox(height: 6),
                Text(rejectReason, style: const TextStyle(fontSize: 13, color: Color(0xFF7F1D1D), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text('ຂໍ້ມູນທີ່ສົ່ງກ່ອນໜ້ານີ້:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildInfoTile(Icons.workspace_premium_rounded, 'ແພັກເກັດ', pkgName),
          const SizedBox(height: 6),
          _buildInfoTile(Icons.payments_rounded, '<ctrl42>ຈຳນວນເງິນ', amountFormatted),
          const SizedBox(height: 12),

          if (slipUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: ImageHelper.buildImage(slipUrl, fit: BoxFit.cover, width: double.infinity, height: 120),
              ),
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _isResubmitMode = true);
              },
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              label: const Text('ເລືອກແພັກເກັດ ແລະ ຊຳລະເງິນໃໝ່ (Re-submit)', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ຍົກລະດັບເປັນສະມາຊິກ Premiere Member',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'ເຂົ້າເຖິງຄັງ e-Book PDF ທຸກເລົ່ມແບບບໍ່ຈຳກັດ ດາວໂຫຼດອອບໄລນ໌ ແລະ ບໍ່ມີໂຄສະນາຄັ້ນ',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCardsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 650;
        return isMobile
            ? Column(
                children: List.generate(_fetchedPackages.length, (index) => _buildPackageCard(index, isMobile: true)),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(_fetchedPackages.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: index == 0 ? 0 : 8,
                        right: index == _fetchedPackages.length - 1 ? 0 : 8,
                      ),
                      child: _buildPackageCard(index, isMobile: false),
                    ),
                  );
                }),
              );
      },
    );
  }

  Widget _buildPackageCard(int index, {required bool isMobile}) {
    final pkg = _fetchedPackages[index];
    final isSelected = _selectedPackageIndex == index;
    final bool isStudentPkg = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;

    final String name = pkg['name'] ?? 'Package';
    final String desc = pkg['description'] ?? '';
    final String formattedPrice = _formatKipPrice(pkg['price']);
    final int days = int.tryParse(pkg['duration_days']?.toString() ?? '30') ?? 30;

    Color primaryColor = isStudentPkg ? const Color(0xFF7C3AED) : (index == 0 ? AppColors.primary : const Color(0xFF0F172A));

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? primaryColor : const Color(0xFFE2E8F0),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected ? primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isStudentPkg) const Icon(Icons.school_rounded, size: 16, color: Colors.amber),
                if (isStudentPkg) const SizedBox(width: 4),
                Text(
                  isStudentPkg ? 'ແພັກເກັດພິເສດນັກຮຽນ (Student Pro)' : (index == 0 ? 'ແພັກເກັດยอดนิยม (Popular)' : 'ແພັກເກັດຄຸ້ມຄ່າ (Best Value)'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Price Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formattedPrice,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: primaryColor),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '/ $days ວັນ',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 16),

                // Features list
                _buildFeatureRow('ເຂົ້າເຖິງຄັງ e-Book PDF ทั่วไป'),
                _buildFeatureRow('ດາວໂຫຼດໄວ້ອ່ານອອບໄລນ໌ได้'),
                if (isStudentPkg) _buildFeatureRow('ສ່ວນຫຼຸດພິເສດสำหรับນັກຮຽນ/ນັກສຶກສາ'),
                if (days >= 365) _buildFeatureRow('ເຂົ້າເຖິງປຶ້ມທຸກເລົ່ມຕະຫຼອດ 365 ວັນ'),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _selectedPackageIndex = index);
                      _onSubscribeClicked(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('ສະໝັກແພັກເກັດນີ້', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('คำถามที่พบบ่อย (FAQ)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 12),
          Text('Q: ทำไมต้องยืนยันตัวตน KYC ก่อนสมัครแพ็กเกจ?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          SizedBox(height: 2),
          Text('A: เพื่อยืนยันสิทธิ์การใช้งานของสมาชิก และป้องกันการละเมิดลิขสิทธิ์หนังสือ e-Book ตามกฎหมาย', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          SizedBox(height: 10),
          Text('Q: แพ็กเกจนักเรียน (Student Special) ใช้เอกสารอะไรบ้าง?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
          SizedBox(height: 2),
          Text('A: สามารถใช้บัตรนักเรียน/นักศึกษา หรือหนังสือรับรองสถานะการศึกษาเพื่อรับส่วนลดพิเศษได้ทันที', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
