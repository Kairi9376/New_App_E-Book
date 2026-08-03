import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
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
  bool _isLoadingPackages = true;

  @override
  void initState() {
    super.initState();
    _loadBackendPackages();
  }

  Future<void> _loadBackendPackages() async {
    setState(() => _isLoadingPackages = true);
    final packages = await ApiService.getPackages();
    if (mounted) {
      setState(() {
        _fetchedPackages = packages;
        _isLoadingPackages = false;
      });
    }
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

  void _onSubscribe(int index) {
    if (widget.kycStatus != KycStatus.approved) {
      _showKycRequiredDialog();
      return;
    }

    if (index < 0 || index >= _fetchedPackages.length) return;
    final pkg = _fetchedPackages[index];

    final String pkgName = pkg['name'] ?? 'Package';
    final String pkgPriceFormatted = _formatKipPrice(pkg['price']);
    final int durationDays = int.tryParse(pkg['duration_days']?.toString() ?? '30') ?? 30;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 8),
            Text('ຢືນຢັນສະໝັກແພັກເກັດ'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ທ່ານກຳລັງເລືອກສະໝັກ: $pkgName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            Text('ລາຄາ: $pkgPriceFormatted / $durationDays ວັນ', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
                  Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 18),
                  SizedBox(width: 6),
                  Text('ກວດສອບ KYC ອະນຸມັດແລ້ວ', style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.bold)),
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
                  content: Text('ສະໝັກ $pkgName ($pkgPriceFormatted) ສຳເລັດຮຽບຮ້ອຍແລ້ວ!'),
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

                if (_isLoadingPackages)
                  const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                else
                  _buildPackageCardsGrid(),
                
                const SizedBox(height: 32),
                _buildFaqSection(),
              ],
            ),
          ),
        ),
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
                      _onSubscribe(index);
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
