import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import 'admin_book_dialog.dart'; // AdminBookFormScreen
import 'admin_user_dialog.dart'; // AdminUserFormScreen
import 'admin_reports_tab.dart'; // AdminReportsTab
import '../login_screen.dart';
import '../User/pdf_viewer_screen.dart';
import '../../utils/image_helper.dart';

// # ເຮັດຫຍັງ: ເພີ່ມຊຸດ design token ຂອງໜ້າ Admin (ສີ, ໄລຍະຫ່າງ, ມົນ, ຕົວອັກສອນ)
// # ຍ້ອນຫຍັງ: ໄຟລ໌ນີ້ເຄີຍ hardcode ສີ (0xFFE2E8F0, Colors.orange.shade800, ...) ແລະ
// #          ຂະໜາດຕົວອັກສອນ 8/10/11/12/13/14/15/16/18 ກະຈາຍທົ່ວ 2300 ບັນທັດ
// #          ເຮັດໃຫ້ສີດຽວກັນມີຫຼາຍເສດ ແລະ ສະຖານະ (ອະນຸມັດ/ລໍຖ້າ/ປະຕິເສດ) ບໍ່ສະໝ່ຳສະເໝີ
// # ແກ້ຈາກສ່ວນໃດ: ຄ່າສີ/ຂະໜາດທີ່ຂຽນຊ້ຳຢູ່ໃນທຸກ tab ຂອງ admin_dashboard_screen.dart
// # ແກ້ເຮັດຫຍັງ: ລວມເປັນຈຸດດຽວ ໃຫ້ສະຖານະມີຄວາມໝາຍທາງສີ (semantic) ແລະ ຕົວອັກສອນ
// #             ມີລຳດັບຊັ້ນຊັດເຈນ ອ່ານພາສາລາວງ່າຍຂຶ້ນ (ບໍ່ໃຊ້ຂະໜາດຕໍ່າກວ່າ 11 ກັບຂໍ້ຄວາມສຳຄັນ)
class _Ds {
  // ---- Surface & structure ----
  static const bg = Color(0xFFF1F5F9);
  static const surface = Colors.white;
  static const sidebar = Color(0xFF0F172A);
  static const sidebarHover = Color(0xFF1E293B);
  static const border = Color(0xFFE2E8F0);
  static const divider = Color(0xFFEEF2F6);

  // ---- Brand ----
  static const primary = AppColors.primary;
  static const primarySoft = Color(0xFFEFF6FF);

  // ---- Semantic (ສະຖານະຕ້ອງໃຊ້ຄູ່ນີ້ສະເໝີ ຫ້າມສຸ່ມສີແດງ/ຂຽວເອງ) ----
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFB91C1C);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF1D4ED8);
  static const infoSoft = Color(0xFFDBEAFE);
  static const neutral = Color(0xFF475569);
  static const neutralSoft = Color(0xFFF1F5F9);

  // ---- Text ----
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF475569);
  static const textMuted = Color(0xFF94A3B8);

  // ---- Spacing / radius ----
  static const s4 = 4.0, s8 = 8.0, s12 = 12.0, s16 = 16.0, s20 = 20.0, s24 = 24.0;
  static const rSm = 8.0, rMd = 12.0, rLg = 16.0;

  // ---- Typography scale ----
  static const pageTitle =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary, height: 1.3);
  static const pageSubtitle =
      TextStyle(fontSize: 13, color: textSecondary, height: 1.4);
  static const sectionTitle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary, height: 1.3);
  static const cardTitle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary, height: 1.35);
  static const body =
      TextStyle(fontSize: 13, color: textSecondary, height: 1.45);
  static const caption =
      TextStyle(fontSize: 12, color: textMuted, height: 1.4);
  static const badge =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w700, height: 1.3);
  static const kpiValue =
      TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, height: 1.1);
  static const kpiLabel =
      TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary, height: 1.3);

  static BoxDecoration card({Color? borderColor, double radius = rLg}) => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? border),
      );
}

// # ເຮັດຫຍັງ: ເພີ່ມ breakpoint 4 ລະດັບ ແທນການກວດ width < 700 ຢ່າງດຽວ
// # ຍ້ອນຫຍັງ: ຂອງເກົ່າມີແຕ່ isMobile/ບໍ່ແມ່ນ ຈຶ່ງບໍ່ມີ layout ສຳລັບ tablet
// #          ໜ້າຈໍກາງຈຶ່ງໄດ້ desktop ທີ່ຖືກບີບ ຫຼື mobile ທີ່ຖືກຍືດ
// # ແກ້ຈາກສ່ວນໃດ: final bool isMobile = MediaQuery.of(context).size.width < 700;
// # ແກ້ເຮັດຫຍັງ: ແຍກ mobile/tablet/desktop/large ໃຫ້ແຕ່ລະຂະໜາດມີ layout ຂອງຕົນ
enum _Bp {
  mobile,
  tablet,
  desktop,
  large;

  static _Bp of(double w) {
    if (w < 720) return _Bp.mobile;
    if (w < 1100) return _Bp.tablet;
    if (w < 1500) return _Bp.desktop;
    return _Bp.large;
  }

  bool get isMobile => this == _Bp.mobile;
  bool get isTablet => this == _Bp.tablet;
  bool get hasSidebar => this == _Bp.desktop || this == _Bp.large;
  bool get hasRail => this == _Bp.tablet;

  /// ຈຳນວນຖັນຂອງ KPI ຕາມພື້ນທີ່ທີ່ມີ
  int get kpiColumns {
    switch (this) {
      case _Bp.mobile:
        return 2;
      case _Bp.tablet:
        return 2;
      case _Bp.desktop:
        return 4;
      case _Bp.large:
        return 4;
    }
  }
}

// # ເຮັດຫຍັງ: ຕັ້ງຊື່ໃຫ້ 6 ໜ້າຂອງ Admin ແທນການອ້າງດ້ວຍເລກ index ດິບ
// # ຍ້ອນຫຍັງ: _selectedTab ໃຊ້ 0..5 ໂດຍມີ comment ອະທິບາຍໄວ້ຢູ່ບັນທັດດຽວ
// #          ການອ່ານໂຄ້ດຕ້ອງນັບ index ເອງທຸກຄັ້ງ ແລະ ງ່າຍທີ່ຈະສະຫຼັບຜິດ
// # ແກ້ຈາກສ່ວນໃດ: int _selectedTab = 0; // 0: Books, 1: Users, ...
// # ແກ້ເຮັດຫຍັງ: ຍັງເກັບ _selectedTab ເປັນ int ຄືເກົ່າ (ບໍ່ກະທົບ state ທີ່ມີຢູ່)
// #             ແຕ່ເພີ່ມ enum ໄວ້ໃຊ້ອ້າງອີງໃນ navigation ແລະ ການຕິດຕາມ error
enum _Section {
  books(0, 'ຄັງໜັງສື', 'ຈັດການ ແລະ ອະນຸມັດປຶ້ມທັງໝົດໃນລະບົບ', Icons.menu_book_rounded),
  users(1, 'ຜູ້ໃຊ້ & ພະນັກງານ', 'ຈັດການບັນຊີ ສິດການນຳໃຊ້ ແລະ ສະຖານະ', Icons.people_alt_rounded),
  kyc(2, 'ຢືນຢັນຕົວຕົນ', 'ກວດສອບ ແລະ ອະນຸມັດເອກະສານ KYC', Icons.verified_user_rounded),
  subscriptions(3, 'ສະລິບໂອນເງິນ', 'ກວດສອບການຊຳລະ ແລະ ອະນຸມັດແພັກເກັດ', Icons.receipt_long_rounded),
  system(4, 'ລະບົບ & ແພັກເກັດ', 'ແພັກເກັດ ໝວດໝູ່ ນັກຂຽນ ແລະ ບັນທຶກລະບົບ', Icons.settings_applications_rounded),
  reports(5, 'ລາຍງານ & ສະຖິຕິ', 'ພາບລວມການໃຊ້ງານ ແລະ ຕົວເລກສະຫຼຸບ', Icons.analytics_rounded);

  const _Section(this.tab, this.title, this.description, this.icon);
  final int tab;
  final String title;
  final String description;
  final IconData icon;

  static _Section from(int i) => values.firstWhere((s) => s.tab == i, orElse: () => _Section.books);
}

/// ປ້າຍສະຖານະທີ່ໃຊ້ຮ່ວມກັນທຸກ tab - ບັງຄັບໃຫ້ສີສະຖານະມາຈາກ _Ds ເທົ່ານັ້ນ
class _StatusChip extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final IconData? icon;

  const _StatusChip({required this.label, required this.fg, required this.bg, this.icon});

  factory _StatusChip.approved(String label) =>
      _StatusChip(label: label, fg: _Ds.success, bg: _Ds.successSoft, icon: Icons.check_circle_rounded);
  factory _StatusChip.pending(String label) =>
      _StatusChip(label: label, fg: _Ds.warning, bg: _Ds.warningSoft, icon: Icons.hourglass_top_rounded);
  factory _StatusChip.rejected(String label) =>
      _StatusChip(label: label, fg: _Ds.danger, bg: _Ds.dangerSoft, icon: Icons.cancel_rounded);
  factory _StatusChip.info(String label) =>
      _StatusChip(label: label, fg: _Ds.info, bg: _Ds.infoSoft);
  factory _StatusChip.neutral(String label) =>
      _StatusChip(label: label, fg: _Ds.neutral, bg: _Ds.neutralSoft);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_Ds.rSm)),
      // # ເຮັດຫຍັງ: ໃສ່ Flexible + ellipsis ໃຫ້ຂໍ້ຄວາມໃນ chip
      // # ຍ້ອນຫຍັງ: chip ຢູ່ໃນ Wrap ຂອງ _listCard ຊຶ່ງຈຳກັດຄວາມກວ້າງຕາມບ່ອນທີ່ຍັງເຫຼືອ
      // #          ຖ້າຊື່ສະຖານະ/ໝວດຍາວ (ຕົວຢ່າງ "ເຕັກໂນໂລຊີ / Computer") Row ຈະລົ້ນ
      // #          ("A RenderFlex overflowed by 23 pixels on the right") - ພົບຕອນ
      // #          ທົດສອບຈິງທີ່ 375px
      // # ແກ້ຈາກສ່ວນໃດ: Row ພາຍໃນ _StatusChip
      // # ແກ້ເຮັດຫຍັງ: ຂໍ້ຄວາມຫຍໍ້ລົງເມື່ອບ່ອນບໍ່ພໍ ແທນທີ່ຈະລົ້ນອອກນອກກ່ອງ
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: fg), const SizedBox(width: 4)],
          Flexible(
            child: Text(
              label,
              style: _Ds.badge.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// ກ່ອງເນື້ອຫາມາດຕະຖານ - ໃຊ້ຫຸ້ມ section ຂອງໜ້າ System Master ແລະ ອື່ນໆ
class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final List<Widget> actions;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.accent,
    this.actions = const [],
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _Ds.card(),
      margin: const EdgeInsets.only(bottom: _Ds.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(_Ds.s16, _Ds.s16, _Ds.s12, _Ds.s12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(_Ds.s8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(_Ds.rMd),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: _Ds.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _Ds.sectionTitle),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(subtitle!, style: _Ds.caption),
                        ),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
          ),
          const Divider(height: 1, color: _Ds.divider),
          Padding(padding: const EdgeInsets.all(_Ds.s12), child: child),
        ],
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Books, 1: Users, 2: KYC, 3: Subscriptions, 4: Packages & Master
  String _searchQuery = '';
  String _userRoleFilter = 'ທັງໝົດ';
  String _kycFilterStatus = 'ທັງໝົດ';
  String _subFilterStatus = 'ທັງໝົດ';

  final List<BookModel> _adminBooks = [];
  final List<Map<String, dynamic>> _adminUsers = [];
  final List<KycModel> _kycSubmissions = [];
  final List<Map<String, dynamic>> _subscriptions = [];
  final List<Map<String, dynamic>> _packages = [];
  final List<Map<String, dynamic>> _authors = [];
  final List<Map<String, dynamic>> _masterCategories = [];
  final List<Map<String, dynamic>> _auditLogs = [];

  String _bookStatusFilter = 'ທັງໝົດ';
  bool _isLoading = true;

  // # ເຮັດຫຍັງ: ເກັບຊື່ສ່ວນທີ່ໂຫຼດລົ້ມເຫຼວຈາກຮອບ fetch ຫຼ້າສຸດ
  // # ຍ້ອນຫຍັງ: ໃຊ້ແຍກ "ຫວ່າງເພາະຍັງບໍ່ມີຂໍ້ມູນ" ອອກຈາກ "ຫວ່າງເພາະໂຫຼດບໍ່ໄດ້"
  // # ແກ້ຈາກສ່ວນໃດ: state ເດີມມີແຕ່ _isLoading ບໍ່ມີສະຖານະ error
  // # ແກ້ເຮັດຫຍັງ: ໃຫ້ UI ສະແດງ Error state ພ້ອມປຸ່ມລອງໃໝ່ ແທນຂໍ້ຄວາມ "ບໍ່ພົບລາຍການ"
  final Set<_Section> _failedSections = {};

  int get _pendingBooksCount =>
      _adminBooks.where((b) => b.status.toLowerCase() == 'pending').length;

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final cleanStr = amount.toString().replaceAll(',', '').trim();
    final number = double.tryParse(cleanStr);
    if (number == null) return cleanStr.isEmpty ? '0' : cleanStr;

    final isInteger = number % 1 == 0;
    final formattedStr = isInteger ? number.toInt().toString() : number.toStringAsFixed(2);
    final parts = formattedStr.split('.');
    
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final withCommas = parts[0].replaceAllMapped(regex, (Match m) => '${m[1]},');
    
    return parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas;
  }

  @override
  void initState() {
    super.initState();
    // ⚡ ห้ามเรียก _fetchAdminData() ตรงๆ ใน initState เพราะ setState() จะโดนเรียก
    // ในช่วง Build Scope แรกที่ยังวาดไม่เสร็จ → ทำให้เกิด "Tried to build dirty widget
    // in the wrong build scope" และ RenderErrorBox บน Flutter Web
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchAdminData();
    });
  }

  Future<void> _fetchAdminData() async {
    if (mounted) setState(() => _isLoading = true);

    // # ເຮັດຫຍັງ: ບັນທຶກວ່າ API ສ່ວນໃດລົ້ມເຫຼວ ໃສ່ _failedSections
    // # ຍ້ອນຫຍັງ: catchError ຄືນລາຍການຫວ່າງ ໜ້າຈໍຈຶ່ງສະແດງ "ບໍ່ພົບລາຍການ" ຄືກັນ
    // #          ທັງກໍລະນີ "ຍັງບໍ່ມີຂໍ້ມູນຈິງ" ແລະ "ໂຫຼດບໍ່ໄດ້" ຜູ້ດູແລຈຶ່ງແຍກບໍ່ອອກ
    // #          ວ່າຄວນເພີ່ມຂໍ້ມູນ ຫຼື ຄວນກົດລອງໃໝ່
    // # ແກ້ຈາກສ່ວນໃດ: catchError((_) => <T>[]) ທັງ 8 ເສັ້ນ ທີ່ກືນ error ງຽບໆ
    // # ແກ້ເຮັດຫຍັງ: ຍັງຄືນລາຍການຫວ່າງຄືເກົ່າ (Future.wait/eagerError:false ບໍ່ປ່ຽນ)
    // #             ແຕ່ຈື່ຊື່ສ່ວນທີ່ລົ້ມໄວ້ ເພື່ອໃຫ້ UI ສະແດງສະຖານະ Error ພ້ອມປຸ່ມລອງໃໝ່
    _failedSections.clear();
    try {
      // ใช้ eagerError: false เพื่อไม่ให้ API ตัวใดตัวหนึ่งล้มเหลวแล้วพาทั้งหมดพัง
      final results = await Future.wait([
        ApiService.getBooks(role: 'admin', status: 'all').catchError((_) {
          _failedSections.add(_Section.books);
          return <BookModel>[];
        }),
        ApiService.getUsers().catchError((_) {
          _failedSections.add(_Section.users);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getKycList().catchError((_) {
          _failedSections.add(_Section.kyc);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getSubscriptions().catchError((_) {
          _failedSections.add(_Section.subscriptions);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getPackages(showAll: true).catchError((_) {
          _failedSections.add(_Section.system);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getCategories().catchError((_) {
          _failedSections.add(_Section.system);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getAuthors().catchError((_) {
          _failedSections.add(_Section.system);
          return <Map<String, dynamic>>[];
        }),
        ApiService.getAuditLogs().catchError((_) {
          _failedSections.add(_Section.system);
          return <Map<String, dynamic>>[];
        }),
      ]);

      final books = results[0] as List<BookModel>;
      final rawUsers = results[1] as List<Map<String, dynamic>>;
      final rawKyc = results[2] as List<Map<String, dynamic>>;
      final rawSubs = results[3] as List<Map<String, dynamic>>;
      final rawPkgs = results[4] as List<Map<String, dynamic>>;
      final rawCats = results[5] as List<Map<String, dynamic>>;
      final rawAuthors = results[6] as List<Map<String, dynamic>>;
      final rawLogs = results[7] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _adminBooks.clear();
          _adminBooks.addAll(books);

          _adminUsers.clear();
          _adminUsers.addAll(rawUsers);

          // ครอบ KYC mapping ด้วย try-catch เพื่อป้องกัน null/format ทำให้เกิด ErrorWidget
          _kycSubmissions.clear();
          if (rawKyc.isNotEmpty) {
            for (final k in rawKyc) {
              try {
                final statusStr = (k['status'] ?? 'pending').toString();
                KycStatus st = KycStatus.pending;
                if (statusStr == 'approved') st = KycStatus.approved;
                if (statusStr == 'rejected') st = KycStatus.rejected;

                final name = '${k['first_name'] ?? ''} ${k['last_name'] ?? ''}'.trim();
                _kycSubmissions.add(KycModel(
                  id: (k['kyc_id'] ?? 1).toString(),
                  userId: (k['user_id'] ?? 1).toString(),
                  userName: name.isNotEmpty ? name : 'ຜູ້ໃຊ້ງານ',
                  userEmail: (k['email'] ?? '').toString(),
                  fullName: name.isNotEmpty ? name : 'ຜູ້ໃຊ້ງານ',
                  idCardNumber: (k['document_number'] ?? 'N/A').toString(),
                  idCardImagePath: (k['document_image_url'] ?? '').toString(),
                  selfieImagePath: (k['selfie_image_url'] ?? '').toString(),
                  submittedAt: k['created_at'] != null ? DateTime.tryParse(k['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
                  status: st,
                  rejectReason: k['rejection_reason']?.toString(),
                ));
              } catch (e) {
                debugPrint('⚠️ KYC row parse error: $e');
              }
            }
          }

          _subscriptions.clear();
          _subscriptions.addAll(rawSubs);

          _packages.clear();
          _packages.addAll(rawPkgs);

          _masterCategories.clear();
          _masterCategories.addAll(rawCats);

          _authors.clear();
          _authors.addAll(rawAuthors);

          _auditLogs.clear();
          _auditLogs.addAll(rawLogs);

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ _fetchAdminData error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _pendingKycCount => _kycSubmissions.where((k) => k.status == KycStatus.pending).length;
  int get _pendingSlipCount => _subscriptions.where((s) => (s['payment_status'] ?? 'pending').toString().toLowerCase() == 'pending').length;

  Widget _buildImage(String path, {double? width, double? height}) {
    String fullPath = path;
    if (path.startsWith('/uploads/') || path.startsWith('uploads/')) {
      fullPath = '${ApiConfig.uploadsBaseUrl}/${path.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    if (fullPath.startsWith('http://') || fullPath.startsWith('https://')) {
      return Image.network(
        fullPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
      );
    }
    if (fullPath.startsWith('assets/')) {
      return Image.asset(
        fullPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(width, height),
      );
    }
    if (!kIsWeb) {
      final file = File(fullPath);
      if (file.existsSync()) {
        return Image.file(file, width: width, height: height, fit: BoxFit.cover);
      }
    }
    return _buildPlaceholder(width, height);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/BookCover.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.25),
          ),
          const Center(
            child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  void _openAddBookDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminBookFormScreen()),
    );
    if (result == true && mounted) {
      _fetchAdminData();
    }
  }

  void _openEditBookDialog(BookModel book, int index) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminBookFormScreen(book: book)),
    );
    if (result == true && mounted) {
      _fetchAdminData();
    }
  }

  void _openCreateUserDialog() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdminUserFormScreen()),
    );
    if (result == true && mounted) {
      _fetchAdminData();
    }
  }

  void _openEditUserDialog(Map<String, dynamic> user, int index) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AdminUserFormScreen(user: user)),
    );
    if (result == true && mounted) {
      _fetchAdminData();
    }
  }

  void _openCreatePackageDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '49000');
    final daysCtrl = TextEditingController(text: '30');
    bool isStudent = false;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ສ້າງແພັກເກັດສະມາຊິກໃໝ່'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ແພັກເກັດ (Package Name)')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ລາຄາ (LAK)')),
                const SizedBox(height: 8),
                TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ໄລຍະເວລາ (ມື້)')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ລາຍລະອຽດແພັກເກັດ')),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('ແພັກເກັດສຳລັບນັກຮຽນ/ນັກສຶກສາ'),
                  value: isStudent,
                  onChanged: (val) => setDialogState(() => isStudent = val),
                ),
                SwitchListTile(
                  title: Text(isActive ? 'ສະຖານະ: ເປີດນຳໃຊ້ (Active)' : 'ສະຖານະ: ປິດນຳໃຊ້ (Inactive)'),
                  value: isActive,
                  activeThumbColor: Colors.green,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final success = await ApiService.createPackage({
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'duration_days': days,
                    'is_for_student': isStudent ? 1 : 0,
                    'is_active': isActive ? 1 : 0,
                  });
                  if (mounted && success) {
                    await _fetchAdminData();
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('ສ້າງແພັກເກັດ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePackageStatus(Map<String, dynamic> pkg) async {
    final pkgId = pkg['package_id'] ?? pkg['id'] ?? 1;
    final bool currentActive = pkg['is_active'] == 1 || pkg['is_active'] == true || pkg['is_active'] == null;
    final bool newActive = !currentActive;

    final success = await ApiService.updatePackageStatus(pkgId, newActive);
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newActive
              ? 'ເປີດນຳໃຊ້ແພັກເກັດ "${pkg['name']}" ຮຽບຮ້ອຍແລ້ວ'
              : 'ປິດນຳໃຊ້ແພັກເກັດ (Inactive) "${pkg['name']}" ຮຽບຮ້ອຍແລ້ວ'),
          backgroundColor: newActive ? Colors.green : Colors.orange.shade800,
        ),
      );
    }
  }

  void _openEditPackageDialog(Map<String, dynamic> pkg) {
    final nameCtrl = TextEditingController(text: pkg['name'] ?? '');
    final descCtrl = TextEditingController(text: pkg['description'] ?? '');
    final priceCtrl = TextEditingController(text: (pkg['price'] ?? 0).toString());
    final daysCtrl = TextEditingController(text: (pkg['duration_days'] ?? 30).toString());
    bool isStudent = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;
    bool isActive = pkg['is_active'] == 1 || pkg['is_active'] == true || pkg['is_active'] == null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ແກ້ໄຂແພັກເກັດ: ${pkg['name']}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ແພັກເກັດ (Package Name)')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ລາຄາ (LAK)')),
                const SizedBox(height: 8),
                TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ໄລຍະເວລາ (ມື້)')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ລາຍລະອຽດແພັກເກັດ')),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('ແພັກເກັດສຳລັບນັກຮຽນ/ນັກສຶກສາ'),
                  value: isStudent,
                  onChanged: (val) => setDialogState(() => isStudent = val),
                ),
                SwitchListTile(
                  title: Text(isActive ? 'ສະຖານະ: ເປີດນຳໃຊ້ (Active)' : 'ສະຖານະ: ປິດນຳໃຊ້ (Inactive)'),
                  subtitle: Text(isActive ? 'ຜູ້ໃຊ້ງານສາມາດເລືອກຊື້ໄດ້' : 'ຢຸດໃຫ້ບໍລິການຊົ່ວຄາວ ບໍ່ສະແດງໃນໜ້າຊື້'),
                  value: isActive,
                  activeThumbColor: Colors.green,
                  onChanged: (val) => setDialogState(() => isActive = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                final days = int.tryParse(daysCtrl.text.trim()) ?? 30;
                final pkgId = pkg['package_id'] ?? pkg['id'] ?? 1;

                if (name.isNotEmpty) {
                  Navigator.pop(ctx);
                  final success = await ApiService.updatePackage(pkgId, {
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'duration_days': days,
                    'is_for_student': isStudent ? 1 : 0,
                    'is_active': isActive ? 1 : 0,
                  });
                  if (mounted && success) {
                    await _fetchAdminData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ອັບເດດແພັກເກັດຮຽບຮ້ອຍແລ້ວ'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('ບັນທຶກການແກ້ໄຂ'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCreateAuthorDialog() {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ເພີ່ມນັກຂຽນໃໝ່'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ນັກຂຽນ')),
            const SizedBox(height: 8),
            TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ປະຫວັດຫຍໍ້ (Biography)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.createAuthor(name, bio: bioCtrl.text.trim());
                if (mounted && success) {
                  await _fetchAdminData();
                }
              }
            },
            child: const Text('ບັນທຶກ'),
          ),
        ],
      ),
    );
  }

  void _deleteBook(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ຢືນຢັນການລົບປຶ້ມ'),
        content: Text('ທ່ານຕ້ອງການລົບ "${_adminBooks[index].title}" ຈາກລະບົບແທ້ບໍ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final String bookIdStr = _adminBooks[index].id;
              final success = await ApiService.deleteBook(bookIdStr);
              if (mounted) {
                if (success) {
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ລົບປຶ້ມສຳເລັດແລ້ວ!'), backgroundColor: Colors.redAccent),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ລົບປຶ້ມບໍ່ສຳເລັດ!'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );
  }

  void _toggleUserStatus(Map<String, dynamic> user) async {
    final status = (user['status'] ?? 'active').toString().toLowerCase();
    final isSuspended = status == 'suspended' || status == 'banned';
    final newStatus = isSuspended ? 'active' : 'suspended';
    final int userIdInt = int.tryParse((user['user_id'] ?? user['id'] ?? 1).toString()) ?? 1;

    final success = await ApiService.updateUserStatus(userIdInt, newStatus);
    if (mounted) {
      if (success) {
        await _fetchAdminData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSuspended ? 'ປົດລະງັບບັນຊີສຳເລັດ' : 'ລະງັບບັນຊີเรียบร้อย'),
            backgroundColor: isSuspended ? Colors.green : Colors.redAccent,
          ),
        );
      }
    }
  }

  void _approveKyc(KycModel item) async {
    final kycId = int.tryParse(item.id) ?? 1;
    final success = await ApiService.updateKycStatus(kycId, 'approved');
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ອະນຸມັດ KYC ຂອງ ${item.userName} ຮຽບຮ້ອຍແລ້ວ'), backgroundColor: Colors.green),
      );
    }
  }

  void _approveSubscription(Map<String, dynamic> sub) async {
    final subId = sub['subscription_id'] ?? sub['id'] ?? 1;
    final success = await ApiService.updateSubscriptionStatus(subId, 'active');
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ອະນຸມັດສະລິບການຊຳລະເງິນຮຽບຮ້ອຍແລ້ວ!'), backgroundColor: Colors.green),
      );
    }
  }

  void _rejectSubscription(Map<String, dynamic> sub) async {
    final subId = sub['subscription_id'] ?? sub['id'] ?? 1;
    final success = await ApiService.updateSubscriptionStatus(subId, 'rejected');
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ປະຕິເສດສະລິບຮຽບຮ້ອຍແລ້ວ'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _openPdfViewer(BookModel book) {
    String pdfUrl = book.pdfUrl ?? '';
    if (pdfUrl.isEmpty) {
      pdfUrl = 'assets/sample_book.pdf';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          bookId: book.id,
          pdfUrl: pdfUrl,
          bookTitle: book.title,
          author: book.author,
          description: book.description,
          pageCount: book.pageCount,
        ),
      ),
    );
  }

  // # ເຮັດຫຍັງ: ເພີ່ມການລ້າງ session ກ່ອນອອກຈາກລະບົບ ແລະ ປ່ຽນປາຍທາງເປັນ StaffLoginScreen
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າພຽງແຕ່ navigate ໂດຍບໍ່ລ້າງ session ເຮັດໃຫ້ບັນຊີ Admin ຍັງຄ້າງ
  // #          ຢູ່ໃນ SharedPreferences ພໍໂຫຼດໜ້າໃໝ່ AppInitializer ຈະກູ້ session ນັ້ນຄືນ
  // #          ແລ້ວພາເຂົ້າ AdminDashboard ອີກ ທັງທີ່ຜູ້ໃຊ້ກົດອອກຈາກລະບົບໄປແລ້ວ
  // # ແກ້ຈາກສ່ວນໃດ: _logout() ເດີມທີ່ມີແຕ່ Navigator.pushAndRemoveUntil ໄປ LoginScreen
  // # ແກ້ເຮັດຫຍັງ: ລ້າງ session ຈິງ ແລ້ວກັບໄປໜ້າ login ຂອງພະນັກງານ (Web)
  void _logout() async {
    await ApiService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const StaffLoginScreen()),
      (route) => false,
    );
  }

  // # ເຮັດຫຍັງ: ຂຽນ build() ໃໝ່ທັງໝົດເປັນໂຄງ Admin Dashboard ມາດຕະຖານ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າເປັນ AppBar ດຳ + ແຖວ ChoiceChip ເລື່ອນຂວາງ + IndexedStack
  // #          ເຊິ່ງບໍ່ມີລຳດັບຊັ້ນ: ບໍ່ຮູ້ວ່າຢູ່ໜ້າໃດ ບໍ່ມີຄຳອະທິບາຍໜ້າ ແລະ ບົນຈໍກວ້າງ
  // #          ເນື້ອຫາຢຽດເຕັມຄວາມກວ້າງຈົນອ່ານຍາກ
  // # ແກ້ຈາກສ່ວນໃດ: build(), _buildNavTab() ແລະ BottomNavigationBar ເດີມ
  // # ແກ້ເຮັດຫຍັງ: desktop = sidebar ຖາວອນ, tablet = rail ໄອຄອນ, mobile = bottom nav
  // #             ພ້ອມ page header (ຫົວຂໍ້ + ຄຳອະທິບາຍ + ປຸ່ມຫຼັກ) ໃນທຸກໜ້າ
  // #             IndexedStack ແລະ ລຳດັບ tab ຄືເກົ່າ ຈຶ່ງບໍ່ກະທົບ state ຫຼື navigation
  @override
  Widget build(BuildContext context) {
    final bp = _Bp.of(MediaQuery.of(context).size.width);
    final section = _Section.from(_selectedTab);

    return Scaffold(
      backgroundColor: _Ds.bg,
      body: SafeArea(
        child: Row(
          children: [
            if (bp.hasSidebar) _buildSidebar(expanded: true),
            if (bp.hasRail) _buildSidebar(expanded: false),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(bp, section),
                  Expanded(
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        _buildBookManagementTab(bp.isMobile),
                        _buildUserManagementTab(bp.isMobile),
                        _buildKycApprovalTab(bp.isMobile),
                        _buildSubscriptionApprovalTab(bp.isMobile),
                        _buildSystemMasterTab(bp.isMobile),
                        _buildReportsSection(bp),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(bp),
      bottomNavigationBar: bp.isMobile ? _buildBottomNav() : null,
    );
  }

  // # ເຮັດຫຍັງ: ຫຸ້ມ AdminReportsTab ໄວ້ໃນ layout ດຽວກັບ tab ອື່ນ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າສົ່ງ isMobile ເຂົ້າໄປໂດຍບໍ່ມີ page header ຄືໜ້າອື່ນ
  // #          ໜ້າລາຍງານຈຶ່ງເບິ່ງຄືຄົນລະລະບົບກັບໜ້າທີ່ເຫຼືອ
  // # ແກ້ຈາກສ່ວນໃດ: AdminReportsTab(...) ທີ່ວາງກົງໆໃນ IndexedStack
  // # ແກ້ເຮັດຫຍັງ: ໃສ່ page header ດຽວກັນ ແລະ ຮັກສາ data contract ເດີມທຸກ parameter
  Widget _buildReportsSection(_Bp bp) {
    return _tabScaffold(
      section: _Section.reports,
      isMobile: bp.isMobile,
      child: AdminReportsTab(
        subscriptions: _subscriptions,
        adminBooks: _adminBooks,
        adminUsers: _adminUsers,
        kycSubmissions: _kycSubmissions,
        auditLogs: _auditLogs,
        isMobile: bp.isMobile,
      ),
    );
  }

  // ---------------------------------------------------------------- SIDEBAR
  // # ເຮັດຫຍັງ: ເພີ່ມ sidebar ຖາວອນ (desktop) ແລະ rail ໄອຄອນ (tablet)
  // # ຍ້ອນຫຍັງ: ChoiceChip ແຖວດຽວເລື່ອນຂວາງເຮັດໃຫ້ເມນູທ້າຍໆ (ລາຍງານ) ຖືກເຊື່ອງ
  // #          ແລະ ບໍ່ເຫັນວ່າລະບົບມີກີ່ສ່ວນ
  // # ແກ້ຈາກສ່ວນໃດ: ແຖວ _buildNavTab ທີ່ຢູ່ໃນ SingleChildScrollView ແນວນອນ
  // # ແກ້ເຮັດຫຍັງ: ເຫັນທຸກເມນູພ້ອມກັນ ມີ badge ຈຳນວນທີ່ຄ້າງ ແລະ ຮູ້ຕຳແໜ່ງປັດຈຸບັນ
  Widget _buildSidebar({required bool expanded}) {
    return Container(
      width: expanded ? 248 : 76,
      color: _Ds.sidebar,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? _Ds.s16 : _Ds.s12, vertical: _Ds.s20),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(_Ds.s8),
                  decoration: BoxDecoration(
                    color: _Ds.primary,
                    borderRadius: BorderRadius.circular(_Ds.rMd),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
                ),
                if (expanded) ...[
                  const SizedBox(width: _Ds.s12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Admin Dashboard',
                            style: TextStyle(
                                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                        Text('ລະບົບຄຸ້ມຄອງ E-Book',
                            style: TextStyle(color: _Ds.textMuted, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: _Ds.sidebarHover),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: _Ds.s12, horizontal: _Ds.s8),
              children: [
                for (final s in _Section.values) _buildSidebarItem(s, expanded),
              ],
            ),
          ),
          const Divider(height: 1, color: _Ds.sidebarHover),
          Padding(
            padding: const EdgeInsets.all(_Ds.s8),
            child: _sidebarAction(
              icon: Icons.logout_rounded,
              label: 'ອອກຈາກລະບົບ',
              expanded: expanded,
              color: const Color(0xFFFCA5A5),
              onTap: _logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(_Section s, bool expanded) {
    final selected = _selectedTab == s.tab;
    final badge = _badgeFor(s);
    final failed = _failedSections.contains(s);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected ? _Ds.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(_Ds.rMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(_Ds.rMd),
          onTap: () => setState(() => _selectedTab = s.tab),
          child: Tooltip(
            message: expanded ? '' : s.title,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: expanded ? _Ds.s12 : 0, vertical: _Ds.s12),
              child: Row(
                mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(s.icon, size: 20, color: selected ? Colors.white : const Color(0xFF94A3B8)),
                  if (expanded) ...[
                    const SizedBox(width: _Ds.s12),
                    Expanded(
                      child: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? Colors.white : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                  if (failed)
                    Icon(Icons.error_outline_rounded,
                        size: 15, color: expanded ? const Color(0xFFFCA5A5) : const Color(0xFFFCA5A5))
                  else if (badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : _Ds.danger,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('$badge',
                          style: _Ds.badge.copyWith(color: selected ? _Ds.primary : Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sidebarAction({
    required IconData icon,
    required String label,
    required bool expanded,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_Ds.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(_Ds.rMd),
        onTap: onTap,
        child: Tooltip(
          message: expanded ? '' : label,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: expanded ? _Ds.s12 : 0, vertical: _Ds.s12),
            child: Row(
              mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 19, color: color),
                if (expanded) ...[
                  const SizedBox(width: _Ds.s12),
                  Text(label,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _badgeFor(_Section s) {
    switch (s) {
      case _Section.books:
        return _pendingBooksCount;
      case _Section.kyc:
        return _pendingKycCount;
      case _Section.subscriptions:
        return _pendingSlipCount;
      default:
        return 0;
    }
  }

  // ---------------------------------------------------------------- TOP BAR
  // # ເຮັດຫຍັງ: ປ່ຽນແຖບເທິງຈາກ AppBar ດຳ 'Enterprise Admin Portal' ເປັນແຖບຂາວບາງ
  // # ຍ້ອນຫຍັງ: ຫົວຂໍ້ຍີ່ຫໍ້ຊ້ຳກັບ sidebar ແລະ ກິນພື້ນທີ່ໂດຍບໍ່ບອກວ່າຢູ່ໜ້າໃດ
  // # ແກ້ຈາກສ່ວນໃດ: AppBar ເດີມທີ່ມີ gradient logo + ຊື່ລະບົບ + ປຸ່ມ refresh/logout
  // # ແກ້ເຮັດຫຍັງ: ແຖບເທິງບອກຊື່ໜ້າປັດຈຸບັນ ແລະ ເກັບ refresh/logout ໄວ້ຄົບ
  // #             ສ່ວນ mobile ຍັງມີປຸ່ມ logout ຢູ່ນີ້ ເພາະບໍ່ມີ sidebar
  Widget _buildTopBar(_Bp bp, _Section section) {
    return Container(
      decoration: const BoxDecoration(
        color: _Ds.surface,
        border: Border(bottom: BorderSide(color: _Ds.border)),
      ),
      padding: EdgeInsets.symmetric(horizontal: bp.isMobile ? _Ds.s16 : _Ds.s24, vertical: _Ds.s12),
      child: Row(
        children: [
          if (bp.isMobile) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _Ds.primary,
                borderRadius: BorderRadius.circular(_Ds.rSm),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: _Ds.s8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bp.isMobile ? section.title : 'Admin Dashboard',
                  style: TextStyle(
                    fontSize: bp.isMobile ? 15 : 16,
                    fontWeight: FontWeight.w700,
                    color: _Ds.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!bp.isMobile)
                  const Text('ພາບລວມ ແລະ ການຈັດການລະບົບ E-Book', style: _Ds.caption),
              ],
            ),
          ),
          if (_failedSections.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: _Ds.s8),
              child: _StatusChip(
                label: bp.isMobile ? '${_failedSections.length}' : 'ໂຫຼດບໍ່ຄົບ ${_failedSections.length} ສ່ວນ',
                fg: _Ds.warning,
                bg: _Ds.warningSoft,
                icon: Icons.warning_amber_rounded,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _Ds.textSecondary),
            onPressed: _fetchAdminData,
            tooltip: 'ຣີເຟຣຊຂໍ້ມູນ',
          ),
          if (bp.isMobile)
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: _Ds.danger),
              onPressed: _logout,
              tooltip: 'ອອກຈາກລະບົບ',
            ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------- BOTTOM NAV
  // # ເຮັດຫຍັງ: ຂຽນ bottom navigation ໃໝ່ໃຫ້ອ່ານງ່າຍຂຶ້ນ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າໃຊ້ font 9-10 ແລະ badge ຂະໜາດ 8 ເຊິ່ງນ້ອຍເກີນສຳລັບພາສາລາວ
  // # ແກ້ຈາກສ່ວນໃດ: BottomNavigationBar ເດີມທີ່ສ້າງ badge ດ້ວຍ Stack ຊ້ຳ 2 ບ່ອນ
  // # ແກ້ເຮັດຫຍັງ: ຂະໜາດຕົວອັກສອນຂຶ້ນເປັນ 11/12, badge ໃຊ້ helper ດຽວກັນ
  // #             ແລະ ຍັງມີຄົບ 6 ໜ້າ ລວມ 'ລາຍງານ' ຈຶ່ງບໍ່ຫາຍໄປຈາກ mobile
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: _Ds.surface,
        border: Border(top: BorderSide(color: _Ds.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (index) => setState(() => _selectedTab = index),
        backgroundColor: _Ds.surface,
        elevation: 0,
        selectedItemColor: _Ds.primary,
        unselectedItemColor: _Ds.textMuted,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        items: [
          for (final s in _Section.values)
            BottomNavigationBarItem(
              icon: _navIconWithBadge(s.icon, _badgeFor(s), _failedSections.contains(s)),
              label: _shortLabel(s),
            ),
        ],
      ),
    );
  }

  String _shortLabel(_Section s) {
    switch (s) {
      case _Section.books:
        return 'ຄັງປຶ້ມ';
      case _Section.users:
        return 'ຜູ້ໃຊ້';
      case _Section.kyc:
        return 'KYC';
      case _Section.subscriptions:
        return 'ສະລິບ';
      case _Section.system:
        return 'ລະບົບ';
      case _Section.reports:
        return 'ລາຍງານ';
    }
  }

  Widget _navIconWithBadge(IconData icon, int badge, bool failed) {
    if (badge <= 0 && !failed) return Icon(icon);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: failed ? _Ds.warning : _Ds.danger,
              borderRadius: BorderRadius.circular(999),
            ),
            constraints: const BoxConstraints(minWidth: 16),
            child: Text(
              failed ? '!' : '$badge',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // # ເຮັດຫຍັງ: ໃຫ້ FAB ຂຶ້ນສະເພາະ mobile ສ່ວນ desktop/tablet ໃຊ້ປຸ່ມໃນ page header
  // # ຍ້ອນຫຍັງ: FAB ລອຍທັບເນື້ອຫາເໝາະກັບໜ້າຈໍນ້ອຍ ແຕ່ບົນ desktop ປຸ່ມຫຼັກ
  // #          ຄວນຢູ່ຄູ່ກັບຫົວຂໍ້ໜ້າຕາມແບບ admin ມາດຕະຖານ
  // # ແກ້ຈາກສ່ວນໃດ: _buildFab() ເດີມທີ່ຄືນ FAB ທຸກຂະໜາດຈໍ
  // # ແກ້ເຮັດຫຍັງ: action ເດີມ (ເພີ່ມປຶ້ມ / ເພີ່ມຜູ້ໃຊ້) ຍັງຢູ່ຄົບທັງສອງທາງ
  Widget? _buildFab(_Bp bp) {
    if (!bp.isMobile) return null;
    if (_selectedTab == _Section.books.tab) {
      return FloatingActionButton.extended(
        onPressed: _openAddBookDialog,
        backgroundColor: _Ds.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ເພີ່ມປຶ້ມ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }
    if (_selectedTab == _Section.users.tab) {
      return FloatingActionButton.extended(
        onPressed: _openCreateUserDialog,
        backgroundColor: _Ds.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('ເພີ່ມຜູ້ໃຊ້',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      );
    }
    return null;
  }

  // ------------------------------------------------- SHARED PAGE STRUCTURE
  // # ເຮັດຫຍັງ: ເພີ່ມໂຄງມາດຕະຖານໃຫ້ທຸກ tab (page header → KPI → toolbar → ເນື້ອຫາ)
  // # ຍ້ອນຫຍັງ: ແຕ່ລະ tab ເດີມສ້າງ layout ເອງ ຈຶ່ງມີໄລຍະຫ່າງ ແລະ ລຳດັບຕ່າງກັນ
  // #          ຜູ້ໃຊ້ຕ້ອງຮຽນຮູ້ໜ້າໃໝ່ທຸກເທື່ອທີ່ສະຫຼັບ tab
  // # ແກ້ຈາກສ່ວນໃດ: Column ດິບໆທີ່ຂຶ້ນຕົ້ນດ້ວຍ SingleChildScrollView ຂອງ KPI ໃນທຸກ tab
  // # ແກ້ເຮັດຫຍັງ: ທຸກໜ້າມີໂຄງດຽວກັນ ຈຳກັດຄວາມກວ້າງສູງສຸດເພື່ອບໍ່ໃຫ້ແຖວຍາວເກີນອ່ານ
  Widget _tabScaffold({
    required _Section section,
    required bool isMobile,
    List<Widget> kpis = const [],
    Widget? toolbar,
    Widget? headerAction,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
              isMobile ? _Ds.s16 : _Ds.s24, _Ds.s20, isMobile ? _Ds.s16 : _Ds.s24, _Ds.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.title, style: _Ds.pageTitle),
                        const SizedBox(height: 2),
                        Text(section.description, style: _Ds.pageSubtitle),
                      ],
                    ),
                  ),
                  if (headerAction != null && !isMobile) headerAction,
                ],
              ),
              if (kpis.isNotEmpty) ...[
                const SizedBox(height: _Ds.s16),
                _kpiGrid(kpis, isMobile),
              ],
              if (toolbar != null) ...[
                const SizedBox(height: _Ds.s12),
                toolbar,
              ],
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                isMobile ? _Ds.s16 : _Ds.s24, 0, isMobile ? _Ds.s16 : _Ds.s24, _Ds.s16),
            child: child,
          ),
        ),
      ],
    );
  }

  /// KPI ຈັດເປັນຕາຕະລາງຕາມພື້ນທີ່ - desktop 4 ຖັນ, tablet/mobile 2 ຖັນ
  Widget _kpiGrid(List<Widget> kpis, bool isMobile) {
    return LayoutBuilder(
      builder: (context, c) {
        final bp = _Bp.of(MediaQuery.of(context).size.width);
        final cols = bp.kpiColumns;
        const gap = _Ds.s12;
        final width = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final k in kpis) SizedBox(width: width > 0 ? width : c.maxWidth, child: k),
          ],
        );
      },
    );
  }

  // # ເຮັດຫຍັງ: ຂຽນ KPI card ໃໝ່ແທນ _buildStatSummaryBanner ເດີມ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າໃຊ້ຫົວຂໍ້ font 10 ແລະ ຄ່າ font 15 ຢູ່ໃນກ່ອງກວ້າງ 180
  // #          ຕົວເລກຈຶ່ງບໍ່ເດັ່ນ ແລະ ຕ້ອງເລື່ອນຂວາງເບິ່ງ
  // # ແກ້ຈາກສ່ວນໃດ: _buildStatSummaryBanner({title, value, icon, color, wrapExpanded})
  // # ແກ້ເຮັດຫຍັງ: ຕົວເລກເປັນ 26 ເດັ່ນຊັດ ມີ label 12 ແລະ ສະຖານະ "ຕ້ອງກວດ"
  // #             ເມື່ອມີລາຍການຄ້າງ ໃຊ້ຂໍ້ມູນຈິງທັງໝົດ ບໍ່ມີການສ້າງຕົວເລກປອມ
  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
    String? hint,
    bool attention = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(_Ds.s16),
      decoration: _Ds.card(borderColor: attention ? _Ds.warning.withValues(alpha: 0.45) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(_Ds.s8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(_Ds.rMd),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const Spacer(),
              if (attention)
                const _StatusChip(
                    label: 'ຕ້ອງກວດ', fg: _Ds.warning, bg: _Ds.warningSoft),
            ],
          ),
          const SizedBox(height: _Ds.s12),
          Text(value, style: _Ds.kpiValue, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: _Ds.kpiLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint, style: _Ds.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }

  // # ເຮັດຫຍັງ: ລວມຊ່ອງຄົ້ນຫາ ຕົວກອງ ແລະ ປຸ່ມຣີເຟຣຊ ເປັນແຖບດຽວ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າວາງ TextField ກັບ DropdownButton ຢູ່ໃນ Row ເປົ່າ
  // #          ເບິ່ງຄືສອງອົງປະກອບທີ່ບໍ່ກ່ຽວກັນ ແລະ ບົນ mobile ຈະແອອັດ
  // # ແກ້ຈາກສ່ວນໃດ: Row[Expanded(TextField), Container(DropdownButton)] ໃນແຕ່ລະ tab
  // # ແກ້ເຮັດຫຍັງ: ເປັນ toolbar ດຽວ ບົນ mobile ຈະຊ້ອນເປັນ 2 ແຖວອັດຕະໂນມັດ
  Widget _toolbar({
    required String hint,
    required ValueChanged<String> onSearch,
    List<Widget> filters = const [],
    bool isMobile = false,
  }) {
    final search = TextField(
      onChanged: onSearch,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: _Ds.textMuted),
        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _Ds.textMuted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: _Ds.s12),
        filled: true,
        fillColor: _Ds.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Ds.rMd),
          borderSide: const BorderSide(color: _Ds.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Ds.rMd),
          borderSide: const BorderSide(color: _Ds.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Ds.rMd),
          borderSide: const BorderSide(color: _Ds.primary, width: 1.5),
        ),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          search,
          if (filters.isNotEmpty) ...[
            const SizedBox(height: _Ds.s8),
            Row(children: [for (final f in filters) Expanded(child: f)]),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: search),
        for (final f in filters) ...[const SizedBox(width: _Ds.s8), f],
      ],
    );
  }

  /// ກ່ອງເລືອກຕົວກອງ - ໜ້າຕາດຽວກັນທຸກ tab
  Widget _filterBox({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    IconData icon = Icons.filter_list_rounded,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: _Ds.s12),
      decoration: _Ds.card(radius: _Ds.rMd),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: _Ds.textMuted),
          const SizedBox(width: _Ds.s8),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(fontSize: 13, color: _Ds.textPrimary),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // # ເຮັດຫຍັງ: ແຍກສະຖານະ Loading / Empty / Error ອອກຈາກກັນ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າ API ລົ້ມ → catchError → ລາຍການຫວ່າງ → ຂໍ້ຄວາມ "ບໍ່ພົບລາຍການ"
  // #          ຜູ້ດູແລຈຶ່ງເຂົ້າໃຈວ່າລະບົບບໍ່ມີຂໍ້ມູນ ທັງທີ່ຄວາມຈິງແມ່ນຕິດຕໍ່ backend ບໍ່ໄດ້
  // # ແກ້ຈາກສ່ວນໃດ: Center(child: Text('ບໍ່ພົບລາຍການ...')) ທີ່ໃຊ້ຊ້ຳທຸກ tab
  // # ແກ້ເຮັດຫຍັງ: Error ມີໄອຄອນເຕືອນ + ປຸ່ມລອງໃໝ່ ສ່ວນ Empty ບອກວິທີເລີ່ມຕົ້ນ
  Widget _stateView({
    required _Section section,
    required bool isEmpty,
    required String emptyTitle,
    required String emptyHint,
    required IconData emptyIcon,
    required Widget child,
  }) {
    if (_isLoading) return _skeletonList();

    if (_failedSections.contains(section)) {
      return _errorState(section);
    }

    if (isEmpty) {
      return _emptyState(emptyTitle, emptyHint, emptyIcon);
    }
    return child;
  }

  Widget _emptyState(String title, String hint, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Ds.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_Ds.s20),
              decoration: const BoxDecoration(color: _Ds.neutralSoft, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: _Ds.textMuted),
            ),
            const SizedBox(height: _Ds.s16),
            Text(title, style: _Ds.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: _Ds.s4),
            Text(hint, style: _Ds.body, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _errorState(_Section section) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_Ds.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(_Ds.s20),
              decoration: const BoxDecoration(color: _Ds.dangerSoft, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_off_rounded, size: 32, color: _Ds.danger),
            ),
            const SizedBox(height: _Ds.s16),
            const Text('ໂຫຼດຂໍ້ມູນບໍ່ສຳເລັດ', style: _Ds.sectionTitle, textAlign: TextAlign.center),
            const SizedBox(height: _Ds.s4),
            Text('ຕິດຕໍ່ server ບໍ່ໄດ້ ຫຼື ບໍ່ມີສິດເຂົ້າເຖິງສ່ວນ "${section.title}"\nກະລຸນາກວດການເຊື່ອມຕໍ່ແລ້ວລອງໃໝ່',
                style: _Ds.body, textAlign: TextAlign.center),
            const SizedBox(height: _Ds.s16),
            FilledButton.icon(
              onPressed: _fetchAdminData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('ລອງໃໝ່'),
              style: FilledButton.styleFrom(backgroundColor: _Ds.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// Skeleton ແທນ CircularProgressIndicator ກາງຈໍ - ບອກຮູບຮ່າງເນື້ອຫາທີ່ກຳລັງມາ
  Widget _skeletonList() {
    return ListView.builder(
      itemCount: 6,
      padding: EdgeInsets.zero,
      itemBuilder: (_, __) => Container(
        height: 84,
        margin: const EdgeInsets.only(bottom: _Ds.s12),
        decoration: _Ds.card(),
        padding: const EdgeInsets.all(_Ds.s12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 60,
              decoration: BoxDecoration(
                  color: _Ds.neutralSoft, borderRadius: BorderRadius.circular(_Ds.rSm)),
            ),
            const SizedBox(width: _Ds.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 12, width: 180, color: _Ds.neutralSoft),
                  const SizedBox(height: _Ds.s8),
                  Container(height: 10, width: 120, color: _Ds.divider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ປຸ່ມຫຼັກຂອງໜ້າ (desktop) - ແທນ FAB ທີ່ລອຍທັບເນື້ອຫາ
  Widget _primaryAction(String label, IconData icon, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: _Ds.primary,
        padding: const EdgeInsets.symmetric(horizontal: _Ds.s16, vertical: _Ds.s16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ds.rMd)),
      ),
    );
  }

  // --- TAB 0: BOOKS MANAGEMENT ---
  Widget _buildBookManagementTab(bool isMobile) {
    final filtered = _adminBooks.where((b) {
      final matchesSearch = b.title.toLowerCase().contains(_searchQuery.toLowerCase()) || b.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _bookStatusFilter == 'ທັງໝົດ' || b.status.toLowerCase() == _bookStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    // # ເຮັດຫຍັງ: ຂຽນໜ້າຄັງໜັງສືໃໝ່ດ້ວຍໂຄງ page header → KPI → toolbar → ລາຍການ
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າເປັນ KPI ເລື່ອນຂວາງ + ListTile ຂາວຄືກັນໝົດ ຈຶ່ງແຍກບໍ່ອອກວ່າ
    // #          ປຶ້ມໃດລໍຖ້າອະນຸມັດ ແລະ ປຸ່ມ action ເປັນໄອຄອນລ້ວນທີ່ບໍ່ບອກຄວາມໝາຍ
    // # ແກ້ຈາກສ່ວນໃດ: Column[SingleChildScrollView(KPI), Row(search+dropdown), ListView]
    // # ແກ້ເຮັດຫຍັງ: KPI ເປັນຕາຕະລາງ, ລາຍການທີ່ລໍຖ້າມີແຖບສີເຫຼືອງດ້ານຊ້າຍ,
    // #             ປຸ່ມອະນຸມັດ/ປະຕິເສດເປັນປຸ່ມມີຂໍ້ຄວາມ - action ເດີມຄົບທຸກອັນ
    final approvedCount = _adminBooks.where((b) => b.status.toLowerCase() == 'approved').length;

    return _tabScaffold(
      section: _Section.books,
      isMobile: isMobile,
      headerAction: _primaryAction('ເພີ່ມປຶ້ມ', Icons.add_rounded, _openAddBookDialog),
      kpis: [
        _kpiCard(
          label: 'ປຶ້ມທັງໝົດ',
          value: '${_adminBooks.length}',
          icon: Icons.menu_book_rounded,
          accent: _Ds.primary,
          hint: 'ຫົວໃນລະບົບ',
        ),
        _kpiCard(
          label: 'ລໍຖ້າອະນຸມັດ',
          value: '$_pendingBooksCount',
          icon: Icons.hourglass_top_rounded,
          accent: _Ds.warning,
          hint: 'ຕ້ອງກວດສອບ',
          attention: _pendingBooksCount > 0,
        ),
        _kpiCard(
          label: 'ອະນຸມັດແລ້ວ',
          value: '$approvedCount',
          icon: Icons.check_circle_rounded,
          accent: _Ds.success,
          hint: 'ເຜີຍແຜ່ຢູ່',
        ),
        _kpiCard(
          label: 'ບໍ່ອະນຸມັດ',
          value: '${_adminBooks.where((b) => b.status.toLowerCase() == 'rejected').length}',
          icon: Icons.cancel_rounded,
          accent: _Ds.danger,
          hint: 'ຖືກປະຕິເສດ',
        ),
      ],
      toolbar: _toolbar(
        hint: 'ຄົ້ນຫາຊື່ປຶ້ມ ຫຼື ຜູ້ແຕ່ງ...',
        isMobile: isMobile,
        onSearch: (val) => setState(() => _searchQuery = val),
        filters: [
          _filterBox(
            value: _bookStatusFilter,
            onChanged: (val) => setState(() => _bookStatusFilter = val!),
            items: [
              const DropdownMenuItem(value: 'ທັງໝົດ', child: Text('ທຸກສະຖານະ')),
              DropdownMenuItem(value: 'pending', child: Text('ລໍຖ້າອະນຸມັດ ($_pendingBooksCount)')),
              const DropdownMenuItem(value: 'approved', child: Text('ອະນຸມັດແລ້ວ')),
              const DropdownMenuItem(value: 'rejected', child: Text('ບໍ່ອະນຸມັດ')),
            ],
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _fetchAdminData,
        color: _Ds.primary,
        child: _stateView(
          section: _Section.books,
          isEmpty: filtered.isEmpty,
          emptyTitle: 'ບໍ່ພົບລາຍການປຶ້ມ',
          emptyHint: _adminBooks.isEmpty
              ? 'ຍັງບໍ່ມີປຶ້ມໃນລະບົບ ກົດ "ເພີ່ມປຶ້ມ" ເພື່ອເລີ່ມຕົ້ນ'
              : 'ບໍ່ມີປຶ້ມທີ່ຕົງກັບຄຳຄົ້ນຫາ ຫຼື ຕົວກອງທີ່ເລືອກ',
          emptyIcon: Icons.menu_book_rounded,
          child: ListView.builder(
            itemCount: filtered.length,
            padding: EdgeInsets.zero,
            itemBuilder: (ctx, idx) {
              final book = filtered[idx];
              final status = book.status.toLowerCase();
              final isPending = status == 'pending';

              return _listCard(
                accent: isPending
                    ? _Ds.warning
                    : (status == 'rejected' ? _Ds.danger : _Ds.success),
                highlight: isPending,
                onTap: () => _showBookDetailModal(book, idx),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(_Ds.rSm),
                  child: SizedBox(width: 46, height: 62, child: _buildImage(book.imagePath)),
                ),
                title: book.title,
                subtitle: 'ຜູ້ແຕ່ງ: ${book.author}'
                    '${book.uploaderName != null ? '  •  ຜູ້ເພີ່ມ: ${book.uploaderName}' : ''}',
                chips: [
                  if (status == 'approved') _StatusChip.approved('ອະນຸມັດແລ້ວ'),
                  if (status == 'rejected') _StatusChip.rejected('ບໍ່ອະນຸມັດ'),
                  if (isPending) _StatusChip.pending('ລໍຖ້າອະນຸມັດ'),
                  _StatusChip.info(book.tags.isNotEmpty ? book.tags.first : 'ທົ່ວໄປ'),
                  if (book.isFree) _StatusChip.neutral('ອ່ານຟຣີ'),
                ],
                actions: isPending
                    ? [
                        _rowAction('ອະນຸມັດ', Icons.check_rounded, _Ds.success,
                            () => _changeBookStatus(book, 'approved')),
                        _rowAction('ປະຕິເສດ', Icons.close_rounded, _Ds.danger,
                            () => _changeBookStatus(book, 'rejected')),
                      ]
                    : [
                        _iconAction('ແກ້ໄຂ', Icons.edit_outlined, _Ds.info,
                            () => _openEditBookDialog(book, idx)),
                        _iconAction('ລຶບ', Icons.delete_outline_rounded, _Ds.danger,
                            () => _deleteBook(idx)),
                      ],
              );
            },
          ),
        ),
      ),
    );
  }

  // # ເຮັດຫຍັງ: ເພີ່ມ list card ມາດຕະຖານທີ່ໃຊ້ຮ່ວມກັນທຸກ tab
  // # ຍ້ອນຫຍັງ: ແຕ່ລະ tab ເດີມສ້າງ Container + ListTile ເອງ ດ້ວຍ radius 14 ແລະ
  // #          ຂອບ 0xFFE2E8F0 ຄືກັນໝົດ ຈຶ່ງບໍ່ມີລຳດັບຄວາມສຳຄັນ
  // # ແກ້ຈາກສ່ວນໃດ: Container(margin/decoration) + ListTile ທີ່ຂຽນຊ້ຳໃນ 4 tab
  // # ແກ້ເຮັດຫຍັງ: ມີແຖບສີດ້ານຊ້າຍບອກສະຖານະ ແລະ ເນັ້ນລາຍການທີ່ຕ້ອງດຳເນີນການ
  Widget _listCard({
    required Color accent,
    required String title,
    String? subtitle,
    Widget? leading,
    List<Widget> chips = const [],
    List<Widget> actions = const [],
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    // # ເຮັດຫຍັງ: ວາງແຖບສີດ້ານຊ້າຍເປັນ Positioned ໃນ Stack ແທນ BorderSide ດ້ານດຽວ
    // # ຍ້ອນຫຍັງ: ສອງທາງກ່ອນໜ້ານີ້ພັງທັງຄູ່ - IntrinsicHeight + Container(width:4)
    // #          ວັດຄວາມສູງລ່ວງໜ້າ ແຕ່ Wrap ຕັດແຖວຕ່າງກັນຕອນ layout ຈິງ ຈຶ່ງເກີນ
    // #          1px ທີ່ 375px; ສ່ວນ Border(left: accent, ອື່ນ: _Ds.border) ມີສີບໍ່
    // #          ຄືກັນທຸກດ້ານ ຊຶ່ງ Flutter ບໍ່ອະນຸຍາດຄູ່ກັບ borderRadius ("A
    // #          borderRadius can only be given on borders with uniform colors")
    // #          ເຮັດໃຫ້ card ບໍ່ paint ເລີຍ - ເຫັນເປັນກ່ອງຂາວຫວ່າງໃນ console
    // # ແກ້ຈາກສ່ວນໃດ: BoxDecoration.border ຂອງ card ນີ້
    // # ແກ້ເຮັດຫຍັງ: ຂອບເປັນສີດຽວທັງໝົດຈຶ່ງໃຊ້ radius ໄດ້ ແລະ ແຖບສີມາຈາກ Positioned
    // #             ທີ່ຢືດຕາມ Stack ຈຶ່ງບໍ່ບັງຄັບຄວາມສູງ - ບໍ່ overflow ແລະ paint ປົກກະຕິ
    return Container(
      margin: const EdgeInsets.only(bottom: _Ds.s12),
      decoration: BoxDecoration(
        color: _Ds.surface,
        borderRadius: BorderRadius.circular(_Ds.rLg),
        border: Border.all(
          color: highlight ? accent.withValues(alpha: 0.45) : _Ds.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                // # ເຮັດຫຍັງ: ເພີ່ມ padding ຊ້າຍ 4 ໃຫ້ພໍດີກັບຄວາມກວ້າງແຖບສີ
                // # ຍ້ອນຫຍັງ: ແຖບສີເປັນ Positioned ຈຶ່ງລອຍທັບເນື້ອຫາຖ້າບໍ່ເຜື່ອບ່ອນ
                padding: const EdgeInsets.fromLTRB(_Ds.s12 + 4, _Ds.s12, _Ds.s12, _Ds.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (leading != null) ...[leading, const SizedBox(width: _Ds.s12)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: _Ds.cardTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(subtitle,
                                style: _Ds.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          if (chips.isNotEmpty) ...[
                            const SizedBox(height: _Ds.s8),
                            Wrap(spacing: _Ds.s4, runSpacing: _Ds.s4, children: chips),
                          ],
                        ],
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(width: _Ds.s8),
                      Wrap(
                        spacing: _Ds.s4,
                        runSpacing: _Ds.s4,
                        alignment: WrapAlignment.end,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // # ເຮັດຫຍັງ: ແຖບສະຖານະດ້ານຊ້າຍ ຢືດເຕັມຄວາມສູງ card
          // # ຍ້ອນຫຍັງ: IgnorePointer ເພື່ອບໍ່ໃຫ້ບັງ InkWell ຂອງ card
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 4,
            child: IgnorePointer(child: ColoredBox(color: accent)),
          ),
        ],
      ),
    );
  }

  /// ປຸ່ມ action ທີ່ມີຂໍ້ຄວາມ - ໃຊ້ກັບການຕັດສິນໃຈສຳຄັນ (ອະນຸມັດ/ປະຕິເສດ)
  Widget _rowAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.08),
        padding: const EdgeInsets.symmetric(horizontal: _Ds.s12, vertical: _Ds.s8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ds.rSm)),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// ປຸ່ມ action ແບບໄອຄອນ - ໃຊ້ກັບການກະທຳຮອງ (ແກ້ໄຂ/ລຶບ/ເບິ່ງ)
  Widget _iconAction(String tooltip, IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 19),
        color: color,
        style: IconButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.07),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_Ds.rSm)),
          minimumSize: const Size(36, 36),
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Future<void> _changeBookStatus(BookModel book, String status) async {
    String? reason;
    if (status == 'rejected') {
      final textController = TextEditingController();
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('ປະຕິເສດການອະນຸມັດປຶ້ມ'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ກະລຸນາລະບຸເຫດຜົນທີ່ບໍ່ຜ່ານການອະນຸມັດສຳລັບປຶ້ມ "${book.title}":'),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'ເຊັ່ນ: ເອກະສານ PDF ບໍ່ຊັດເຈນ / ເນື້ອຫາບໍ່ກົງຕາມເກນ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ຢືນຢັນປະຕິເສດ', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      reason = textController.text.trim();
    }

    final success = await ApiService.updateBookStatus(book.id, status, rejectionReason: reason);
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'approved'
              ? 'ອະນຸມັດປຶ້ມ "${book.title}" ຮຽບຮ້ອຍແລ້ວ'
              : 'ປະຕິເສດປຶ້ມ "${book.title}" ຮຽບຮ້ອຍແລ້ວ'),
          backgroundColor: status == 'approved' ? Colors.green : Colors.redAccent,
        ),
      );
    }
  }

  // --- TAB 1: USER MANAGEMENT ---
  Widget _buildUserManagementTab(bool isMobile) {
    final filtered = _adminUsers.where((u) {
      final role = (u['role'] ?? '').toString();
      final matchesRole = _userRoleFilter == 'ທັງໝົດ' || role.toLowerCase() == _userRoleFilter.toLowerCase();
      final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''} ${u['email'] ?? ''}'.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    // # ເຮັດຫຍັງ: ຂຽນໜ້າຜູ້ໃຊ້ໃໝ່ໃຫ້ແຍກຂໍ້ມູນຊັດ (avatar / ຊື່ / ອີເມວ / role / ສະຖານະ)
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າເອົາ role ໄປໃສ່ຫຼັງຊື່ດ້ວຍ font 9 ແລະ ບໍ່ສະແດງສະຖານະບັນຊີເລີຍ
    // #          ຜູ້ດູແລຈຶ່ງບໍ່ຮູ້ວ່າໃຜຖືກລະງັບ ຈົນກວ່າຈະສັງເກດສີປຸ່ມດ້ານຂວາ
    // # ແກ້ຈາກສ່ວນໃດ: Column[Row(KPI 2 ອັນ), Row(search+dropdown), ListView(ListTile)]
    // # ແກ້ເຮັດຫຍັງ: ເພີ່ມ KPI ສະຖານະບັນຊີ, ສະແດງ role ແລະ ສະຖານະເປັນ chip ມາດຕະຖານ
    // #             ແລະ ຮັກສາ action ເດີມ (ແກ້ໄຂ / ລະງັບ / ປົດລະງັບ / ເບິ່ງລາຍລະອຽດ)
    final staffCount =
        _adminUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() != 'user').length;
    final suspendedCount = _adminUsers.where((u) {
      final s = (u['status'] ?? 'active').toString().toLowerCase();
      return s == 'suspended' || s == 'banned';
    }).length;

    return _tabScaffold(
      section: _Section.users,
      isMobile: isMobile,
      headerAction:
          _primaryAction('ເພີ່ມຜູ້ໃຊ້', Icons.person_add_alt_1_rounded, _openCreateUserDialog),
      kpis: [
        _kpiCard(
          label: 'ຜູ້ໃຊ້ທັງໝົດ',
          value: '${_adminUsers.length}',
          icon: Icons.people_alt_rounded,
          accent: _Ds.primary,
          hint: 'ບັນຊີໃນລະບົບ',
        ),
        _kpiCard(
          label: 'ແອດມິນ & ພະນັກງານ',
          value: '$staffCount',
          icon: Icons.admin_panel_settings_rounded,
          accent: _Ds.info,
          hint: 'ມີສິດຈັດການ',
        ),
        _kpiCard(
          label: 'ຜູ້ໃຊ້ທົ່ວໄປ',
          value: '${_adminUsers.length - staffCount}',
          icon: Icons.person_outline_rounded,
          accent: _Ds.success,
          hint: 'ບັນຊີລູກຄ້າ',
        ),
        _kpiCard(
          label: 'ຖືກລະງັບ',
          value: '$suspendedCount',
          icon: Icons.block_rounded,
          accent: _Ds.danger,
          hint: 'ເຂົ້າໃຊ້ບໍ່ໄດ້',
          attention: suspendedCount > 0,
        ),
      ],
      toolbar: _toolbar(
        hint: 'ຄົ້ນຫາຊື່ ຫຼື ອີເມວ...',
        isMobile: isMobile,
        onSearch: (val) => setState(() => _searchQuery = val),
        filters: [
          _filterBox(
            value: _userRoleFilter,
            icon: Icons.badge_outlined,
            onChanged: (val) => setState(() => _userRoleFilter = val!),
            items: ['ທັງໝົດ', 'Admin', 'Employee', 'User']
                .map((r) => DropdownMenuItem(
                    value: r, child: Text(r == 'ທັງໝົດ' ? 'ທຸກສິດ' : r)))
                .toList(),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _fetchAdminData,
        color: _Ds.primary,
        child: _stateView(
          section: _Section.users,
          isEmpty: filtered.isEmpty,
          emptyTitle: 'ບໍ່ພົບຜູ້ໃຊ້',
          emptyHint: _adminUsers.isEmpty
              ? 'ຍັງບໍ່ມີບັນຊີໃນລະບົບ ກົດ "ເພີ່ມຜູ້ໃຊ້" ເພື່ອສ້າງບັນຊີທຳອິດ'
              : 'ບໍ່ມີບັນຊີທີ່ຕົງກັບຄຳຄົ້ນຫາ ຫຼື ສິດທີ່ເລືອກ',
          emptyIcon: Icons.people_alt_rounded,
          child: ListView.builder(
            itemCount: filtered.length,
            padding: EdgeInsets.zero,
            itemBuilder: (ctx, idx) {
              final user = filtered[idx];
              final status = (user['status'] ?? 'active').toString().toLowerCase();
              final isSuspended = status == 'suspended' || status == 'banned';
              final role = (user['role'] ?? 'user').toString();
              final roleLower = role.toLowerCase();
              final roleColor = roleLower == 'admin'
                  ? _Ds.info
                  : (roleLower == 'employee' ? _Ds.warning : _Ds.neutral);

              return _listCard(
                accent: isSuspended ? _Ds.danger : _Ds.success,
                highlight: isSuspended,
                onTap: () => _showUserDetailModal(user),
                leading: ImageHelper.buildAvatar(
                  (user['profile_image_url'] ??
                          user['profile_image'] ??
                          user['avatar_url'] ??
                          user['avatar'])
                      ?.toString(),
                  firstName: (user['first_name'] ?? 'U').toString(),
                  size: 44,
                  backgroundColor: roleColor,
                ),
                title: '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                subtitle: '${user['email'] ?? ''}',
                chips: [
                  _StatusChip(
                      label: role.toUpperCase(),
                      fg: roleColor,
                      bg: roleColor.withValues(alpha: 0.10)),
                  if (isSuspended)
                    _StatusChip.rejected(status == 'banned' ? 'ຖືກແບນ' : 'ຖືກລະງັບ')
                  else
                    _StatusChip.approved('ໃຊ້ງານປົກກະຕິ'),
                ],
                actions: [
                  _iconAction('ແກ້ໄຂ', Icons.edit_outlined, _Ds.info, () {
                    final realIdx = _adminUsers.indexWhere(
                        (u) => (u['user_id'] ?? u['id']) == (user['user_id'] ?? user['id']));
                    _openEditUserDialog(user, realIdx >= 0 ? realIdx : idx);
                  }),
                  _rowAction(
                    isSuspended ? 'ປົດລະງັບ' : 'ລະງັບ',
                    isSuspended ? Icons.lock_open_rounded : Icons.block_rounded,
                    isSuspended ? _Ds.success : _Ds.danger,
                    () => _toggleUserStatus(user),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TAB 2: KYC APPROVAL ---
  Widget _buildKycApprovalTab(bool isMobile) {
    final filtered = _kycSubmissions.where((k) {
      if (_kycFilterStatus == 'ລໍຖ້າອະນຸມັດ') return k.status == KycStatus.pending;
      if (_kycFilterStatus == 'ອະນຸມັດແລ້ວ') return k.status == KycStatus.approved;
      if (_kycFilterStatus == 'ບໍ່ອະນຸມັດ') return k.status == KycStatus.rejected;
      return true;
    }).toList();

    // # ເຮັດຫຍັງ: ຂຽນໜ້າ KYC ໃໝ່ໃຫ້ລາຍການທີ່ລໍຖ້າມີຄວາມສຳຄັນທາງສາຍຕາສູງສຸດ
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າທຸກແຖວໜ້າຕາຄືກັນ ແລະ ຂໍ້ມູນ 4 ແຖວອັດກັນດ້ວຍ emoji + font 11
    // #          ເຊິ່ງເປັນຂໍ້ມູນເອກະສານທີ່ຕ້ອງອ່ານໃຫ້ຊັດກ່ອນຕັດສິນໃຈອະນຸມັດ
    // # ແກ້ຈາກສ່ວນໃດ: Column[Row(KPI), Row(ຫົວຂໍ້+dropdown), ListView(ListTile 4 ແຖວ)]
    // # ແກ້ເຮັດຫຍັງ: ລາຍການລໍຖ້າມີແຖບສີເຫຼືອງ ແລະ ຂຶ້ນກ່ອນ, ຂໍ້ມູນເອກະສານເປັນ chip
    // #             ປຸ່ມອະນຸມັດ/ປະຕິເສດເປັນປຸ່ມມີຂໍ້ຄວາມ - action ເດີມຄົບ
    final approvedKyc = _kycSubmissions.where((k) => k.status == KycStatus.approved).length;
    final rejectedKyc = _kycSubmissions.where((k) => k.status == KycStatus.rejected).length;

    // ລໍຖ້າອະນຸມັດຂຶ້ນກ່ອນສະເໝີ - ຜູ້ດູແລເຫັນສິ່ງທີ່ຕ້ອງເຮັດທັນທີ
    final sorted = [...filtered]..sort((a, b) {
        int rank(KycStatus s) => s == KycStatus.pending ? 0 : 1;
        return rank(a.status).compareTo(rank(b.status));
      });

    return _tabScaffold(
      section: _Section.kyc,
      isMobile: isMobile,
      kpis: [
        _kpiCard(
          label: 'ລໍຖ້າອະນຸມັດ',
          value: '$_pendingKycCount',
          icon: Icons.pending_actions_rounded,
          accent: _Ds.warning,
          hint: 'ຕ້ອງກວດເອກະສານ',
          attention: _pendingKycCount > 0,
        ),
        _kpiCard(
          label: 'ອະນຸມັດແລ້ວ',
          value: '$approvedKyc',
          icon: Icons.verified_rounded,
          accent: _Ds.success,
          hint: 'ຜ່ານການກວດສອບ',
        ),
        _kpiCard(
          label: 'ບໍ່ອະນຸມັດ',
          value: '$rejectedKyc',
          icon: Icons.gpp_bad_rounded,
          accent: _Ds.danger,
          hint: 'ຖືກປະຕິເສດ',
        ),
        _kpiCard(
          label: 'ຄຳຮ້ອງທັງໝົດ',
          value: '${_kycSubmissions.length}',
          icon: Icons.folder_shared_rounded,
          accent: _Ds.primary,
          hint: 'ທຸກສະຖານະ',
        ),
      ],
      toolbar: _toolbar(
        hint: 'ຄົ້ນຫາຊື່ ຫຼື ອີເມວຜູ້ຍື່ນ...',
        isMobile: isMobile,
        onSearch: (val) => setState(() => _searchQuery = val),
        filters: [
          _filterBox(
            value: _kycFilterStatus,
            onChanged: (val) => setState(() => _kycFilterStatus = val!),
            items: ['ທັງໝົດ', 'ລໍຖ້າອະນຸມັດ', 'ອະນຸມັດແລ້ວ', 'ບໍ່ອະນຸມັດ']
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s == 'ທັງໝົດ' ? 'ທຸກສະຖານະ' : s)))
                .toList(),
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _fetchAdminData,
        color: _Ds.primary,
        child: _stateView(
          section: _Section.kyc,
          isEmpty: sorted.isEmpty,
          emptyTitle: 'ບໍ່ມີລາຍການ KYC',
          emptyHint: _kycSubmissions.isEmpty
              ? 'ຍັງບໍ່ມີຜູ້ໃຊ້ຍື່ນເອກະສານຢືນຢັນຕົວຕົນເຂົ້າມາ'
              : 'ບໍ່ມີຄຳຮ້ອງທີ່ຕົງກັບຕົວກອງທີ່ເລືອກ',
          emptyIcon: Icons.verified_user_rounded,
          child: ListView.builder(
            itemCount: sorted.length,
            padding: EdgeInsets.zero,
            itemBuilder: (ctx, idx) {
              final item = sorted[idx];
              final isPending = item.status == KycStatus.pending;
              final displayName = item.fullName.isNotEmpty ? item.fullName : item.userName;

              return _listCard(
                accent: isPending
                    ? _Ds.warning
                    : (item.status == KycStatus.rejected ? _Ds.danger : _Ds.success),
                highlight: isPending,
                onTap: () => _showKycDetailModal(item),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: isPending ? _Ds.warningSoft : _Ds.primarySoft,
                  child: Icon(Icons.badge_rounded,
                      color: isPending ? _Ds.warning : _Ds.primary, size: 22),
                ),
                title: displayName,
                subtitle: '${item.userEmail}\n'
                    'ເລກເອກະສານ: ${item.idCardNumber}  •  ${item.documentType}',
                chips: [
                  if (item.status == KycStatus.approved) _StatusChip.approved(item.statusText),
                  if (item.status == KycStatus.rejected) _StatusChip.rejected(item.statusText),
                  if (isPending) _StatusChip.pending(item.statusText),
                  _StatusChip.neutral(item.genderText),
                  if (item.dateOfBirth.isNotEmpty) _StatusChip.neutral('ເກີດ ${item.dateOfBirth}'),
                ],
                actions: [
                  _iconAction('ເບິ່ງເອກະສານ', Icons.visibility_outlined, _Ds.info,
                      () => _showKycDetailModal(item)),
                  if (item.status != KycStatus.approved)
                    _rowAction('ອະນຸມັດ', Icons.check_rounded, _Ds.success,
                        () => _approveKyc(item)),
                  if (item.status != KycStatus.rejected)
                    _rowAction('ປະຕິເສດ', Icons.close_rounded, _Ds.danger,
                        () => _showRejectKycDialog(item)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showRejectKycDialog(KycModel item) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('ປະຕິເສດ KYC: ${item.userName}'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'ລະບຸເຫດຜົນທີ່ບໍ່ອະນຸມັດ...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final kycId = int.tryParse(item.id) ?? 1;
              await ApiService.updateKycStatus(kycId, 'rejected', rejectionReason: reasonCtrl.text.trim());
              await _fetchAdminData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ຢືນຢັນປະຕິເສດ'),
          ),
        ],
      ),
    );
  }



  // --- TAB 3: SUBSCRIPTION SLIP APPROVAL ---
  Widget _buildSubscriptionApprovalTab(bool isMobile) {
    final filtered = _subscriptions.where((s) {
      final st = (s['payment_status'] ?? 'pending').toString().toLowerCase();
      if (_subFilterStatus == 'pending') return st == 'pending';
      if (_subFilterStatus == 'active') return st == 'active';
      if (_subFilterStatus == 'rejected') return st == 'rejected';
      return true;
    }).toList();

    // # ເຮັດຫຍັງ: ຂຽນໜ້າສະລິບໂອນເງິນໃໝ່ໃຫ້ຄົບ 6 ຢ່າງ (ຜູ້ໃຊ້/ແພັກເກັດ/ຍອດ/ວັນທີ/ສະຖານະ/action)
    // # ຍ້ອນຫຍັງ: ຂອງເກົ່າສະແດງແຕ່ຊື່ ແພັກເກັດ ແລະ ຍອດ - ບໍ່ມີວັນທີແຈ້ງຊຳລະ
    // #          ຜູ້ດູແລຈຶ່ງບໍ່ຮູ້ວ່າລາຍການໃດຄ້າງດົນແລ້ວ ແລະ ຄວນຈັດການກ່ອນ
    // # ແກ້ຈາກສ່ວນໃດ: Column[Row(KPI), Row(ຫົວຂໍ້+dropdown), ListView(ListTile)]
    // # ແກ້ເຮັດຫຍັງ: ເພີ່ມວັນທີ ແລະ ຍອດລວມທີ່ອະນຸມັດແລ້ວ ພ້ອມຈັດລາຍການລໍຖ້າຂຶ້ນກ່ອນ
    // #             ໃຊ້ _formatCurrency ເດີມ ບໍ່ປ່ຽນການຄິດໄລ່
    final activeSubs = _subscriptions
        .where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'active')
        .toList();
    final rejectedSubs = _subscriptions
        .where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'rejected')
        .length;
    final totalApproved = activeSubs.fold<double>(
        0, (sum, s) => sum + (double.tryParse((s['amount'] ?? '0').toString()) ?? 0));

    final sorted = [...filtered]..sort((a, b) {
        int rank(Map<String, dynamic> s) =>
            (s['payment_status'] ?? 'pending').toString().toLowerCase() == 'pending' ? 0 : 1;
        return rank(a).compareTo(rank(b));
      });

    return _tabScaffold(
      section: _Section.subscriptions,
      isMobile: isMobile,
      kpis: [
        _kpiCard(
          label: 'ລໍຖ້າກວດສອບ',
          value: '$_pendingSlipCount',
          icon: Icons.receipt_long_rounded,
          accent: _Ds.warning,
          hint: 'ສະລິບຄ້າງ',
          attention: _pendingSlipCount > 0,
        ),
        _kpiCard(
          label: 'ອະນຸມັດແລ້ວ',
          value: '${activeSubs.length}',
          icon: Icons.verified_user_rounded,
          accent: _Ds.success,
          hint: 'ສະມາຊິກໃຊ້ງານຢູ່',
        ),
        _kpiCard(
          label: 'ບໍ່ອະນຸມັດ',
          value: '$rejectedSubs',
          icon: Icons.money_off_rounded,
          accent: _Ds.danger,
          hint: 'ຖືກປະຕິເສດ',
        ),
        _kpiCard(
          label: 'ຍອດທີ່ອະນຸມັດ',
          value: _formatCurrency(totalApproved),
          icon: Icons.payments_rounded,
          accent: _Ds.primary,
          hint: 'LAK ລວມ',
        ),
      ],
      toolbar: _toolbar(
        hint: 'ຄົ້ນຫາຊື່ຜູ້ໂອນ ຫຼື ແພັກເກັດ...',
        isMobile: isMobile,
        onSearch: (val) => setState(() => _searchQuery = val),
        filters: [
          _filterBox(
            value: _subFilterStatus,
            onChanged: (val) => setState(() => _subFilterStatus = val!),
            items: const [
              DropdownMenuItem(value: 'ທັງໝົດ', child: Text('ທຸກສະຖານະ')),
              DropdownMenuItem(value: 'pending', child: Text('ລໍຖ້າກວດສອບ')),
              DropdownMenuItem(value: 'active', child: Text('ອະນຸມັດແລ້ວ')),
              DropdownMenuItem(value: 'rejected', child: Text('ບໍ່ອະນຸມັດ')),
            ],
          ),
        ],
      ),
      child: RefreshIndicator(
        onRefresh: _fetchAdminData,
        color: _Ds.primary,
        child: _stateView(
          section: _Section.subscriptions,
          isEmpty: sorted.isEmpty,
          emptyTitle: 'ບໍ່ມີລາຍການສະລິບໂອນເງິນ',
          emptyHint: _subscriptions.isEmpty
              ? 'ຍັງບໍ່ມີຜູ້ໃຊ້ແຈ້ງຊຳລະຄ່າແພັກເກັດເຂົ້າມາ'
              : 'ບໍ່ມີລາຍການທີ່ຕົງກັບຕົວກອງທີ່ເລືອກ',
          emptyIcon: Icons.receipt_long_rounded,
          child: ListView.builder(
            itemCount: sorted.length,
            padding: EdgeInsets.zero,
            itemBuilder: (ctx, idx) {
              final sub = sorted[idx];
              final status = (sub['payment_status'] ?? 'pending').toString().toLowerCase();
              final isPending = status == 'pending';
              final created = (sub['created_at'] ?? '').toString();
              final dateText = created.length >= 10 ? created.substring(0, 10) : '-';
              final name = '${sub['first_name'] ?? ""} ${sub['last_name'] ?? ""}'.trim();

              return _listCard(
                accent: isPending
                    ? _Ds.warning
                    : (status == 'active' ? _Ds.success : _Ds.danger),
                highlight: isPending,
                onTap: () => _showSubscriptionDetailModal(sub),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: isPending ? _Ds.warningSoft : _Ds.primarySoft,
                  child: Icon(Icons.receipt_long_rounded,
                      color: isPending ? _Ds.warning : _Ds.primary, size: 22),
                ),
                title: name.isNotEmpty ? name : 'ບໍ່ລະບຸຊື່ຜູ້ໂອນ',
                subtitle: 'ແພັກເກັດ: ${sub['package_name'] ?? "-"}  •  ແຈ້ງເມື່ອ $dateText',
                chips: [
                  _StatusChip(
                    label: '${_formatCurrency(sub['amount'])} LAK',
                    fg: _Ds.primary,
                    bg: _Ds.primarySoft,
                    icon: Icons.payments_rounded,
                  ),
                  if (status == 'active') _StatusChip.approved('ອະນຸມັດແລ້ວ'),
                  if (status == 'rejected') _StatusChip.rejected('ບໍ່ອະນຸມັດ'),
                  if (isPending) _StatusChip.pending('ລໍຖ້າກວດສອບ'),
                ],
                actions: [
                  _iconAction('ເບິ່ງສະລິບ', Icons.visibility_outlined, _Ds.info,
                      () => _showSubscriptionDetailModal(sub)),
                  if (isPending) ...[
                    _rowAction('ອະນຸມັດ', Icons.check_rounded, _Ds.success,
                        () => _approveSubscription(sub)),
                    _rowAction('ປະຕິເສດ', Icons.close_rounded, _Ds.danger,
                        () => _rejectSubscription(sub)),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TAB 4: SYSTEM & PACKAGES MASTER TAB ---
  // # ເຮັດຫຍັງ: ຂຽນໜ້າລະບົບໃໝ່ໂດຍແຍກເປັນ 4 ໝວດຊັດເຈນດ້ວຍ _SectionCard
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າເປັນ SingleChildScrollView ຍາວອັນດຽວ ທີ່ເອົາແພັກເກັດ ໝວດໝູ່
  // #          ນັກຂຽນ ແລະ audit log ຕໍ່ກັນລົງມາ ຈົນເບິ່ງຄືລາຍການດຽວຂະໜາດໃຫຍ່
  // #          ແລະ ຫົວຂໍ້ແຕ່ລະໝວດໃຊ້ຄົນລະຮູບແບບ (Text ລ້ວນ / Card / Row)
  // # ແກ້ຈາກສ່ວນໃດ: Column[Row(ຫົວຂໍ້+ປຸ່ມ), ..._packages.map, Card, Card, Card]
  // # ແກ້ເຮັດຫຍັງ: ທຸກໝວດໃຊ້ _SectionCard ດຽວກັນ (ໄອຄອນ + ຫົວຂໍ້ + ຄຳອະທິບາຍ + ປຸ່ມ)
  // #             ພ້ອມ KPI ສະຫຼຸບຂ້າງເທິງ - CRUD ເດີມຂອງທຸກໝວດຢູ່ຄົບ
  Widget _buildSystemMasterTab(bool isMobile) {
    final activePkgs = _packages
        .where((p) => p['is_active'] == 1 || p['is_active'] == true || p['is_active'] == null)
        .length;

    return _tabScaffold(
      section: _Section.system,
      isMobile: isMobile,
      kpis: [
        _kpiCard(
          label: 'ແພັກເກັດທັງໝົດ',
          value: '${_packages.length}',
          icon: Icons.workspace_premium_rounded,
          accent: _Ds.primary,
          hint: '$activePkgs ເປີດນຳໃຊ້',
        ),
        _kpiCard(
          label: 'ໝວດໝູ່ປຶ້ມ',
          value: '${_masterCategories.length}',
          icon: Icons.category_rounded,
          accent: _Ds.info,
          hint: 'ໃນຖານຂໍ້ມູນ',
        ),
        _kpiCard(
          label: 'ນັກຂຽນ',
          value: '${_authors.length}',
          icon: Icons.person_pin_rounded,
          accent: _Ds.success,
          hint: 'ລົງທະບຽນແລ້ວ',
        ),
        _kpiCard(
          label: 'ບັນທຶກລະບົບ',
          value: '${_auditLogs.length}',
          icon: Icons.security_rounded,
          accent: _Ds.neutral,
          hint: 'ເຫດການທີ່ບັນທຶກ',
        ),
      ],
      child: _stateView(
        section: _Section.system,
        isEmpty: false,
        emptyTitle: '',
        emptyHint: '',
        emptyIcon: Icons.settings_applications_rounded,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ---------------------------------------------------- PACKAGES
            _SectionCard(
              title: 'ແພັກເກັດສະມາຊິກ',
              subtitle: 'ກຳນົດລາຄາ ໄລຍະເວລາ ແລະ ການເປີດ/ປິດນຳໃຊ້',
              icon: Icons.workspace_premium_rounded,
              accent: _Ds.primary,
              actions: [
                _rowAction('ສ້າງແພັກເກັດ', Icons.add_rounded, _Ds.primary,
                    _openCreatePackageDialog),
              ],
              child: _packages.isEmpty
                  ? _inlineEmpty('ຍັງບໍ່ມີແພັກເກັດ ກົດ "ສ້າງແພັກເກັດ" ເພື່ອເລີ່ມຕົ້ນ')
                  : Column(
                      children: _packages.map((pkg) {
                        final isStudentPkg =
                            pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;
                        final isActive = pkg['is_active'] == 1 ||
                            pkg['is_active'] == true ||
                            pkg['is_active'] == null;

                        return _listCard(
                          accent: isActive ? _Ds.success : _Ds.neutral,
                          onTap: () => _showPackageDetailModal(pkg),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                isActive ? _Ds.primarySoft : _Ds.neutralSoft,
                            child: Icon(
                              isStudentPkg
                                  ? Icons.school_rounded
                                  : Icons.workspace_premium_rounded,
                              color: isActive ? _Ds.primary : _Ds.textMuted,
                              size: 22,
                            ),
                          ),
                          title: (pkg['name'] ?? '').toString(),
                          subtitle:
                              '${_formatCurrency(pkg['price'])} LAK  •  ${pkg['duration_days']} ມື້',
                          chips: [
                            if (isActive)
                              _StatusChip.approved('ເປີດນຳໃຊ້')
                            else
                              _StatusChip.neutral('ປິດນຳໃຊ້'),
                            if (isStudentPkg) _StatusChip.info('ນັກຮຽນ/ນັກສຶກສາ'),
                          ],
                          actions: [
                            _iconAction('ແກ້ໄຂແພັກເກັດ', Icons.edit_outlined, _Ds.info,
                                () => _openEditPackageDialog(pkg)),
                            Switch(
                              value: isActive,
                              activeThumbColor: _Ds.success,
                              inactiveThumbColor: _Ds.textMuted,
                              onChanged: (val) => _togglePackageStatus(pkg),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
            ),

            // -------------------------------------------------- CATEGORIES
            _SectionCard(
              title: 'ໝວດໝູ່ປຶ້ມ',
              subtitle: 'ໃຊ້ຈັດກຸ່ມປຶ້ມໃນໜ້າຄົ້ນຫາຂອງຜູ້ໃຊ້',
              icon: Icons.category_rounded,
              accent: _Ds.info,
              actions: [
                _rowAction('ເພີ່ມໝວດໝູ່', Icons.add_rounded, _Ds.info, _openCreateCategoryDialog),
              ],
              child: _masterCategories.isEmpty
                  ? _inlineEmpty('ບໍ່ມີໝວດໝູ່ໃນຖານຂໍ້ມູນ')
                  : Wrap(
                      spacing: _Ds.s8,
                      runSpacing: _Ds.s8,
                      children: _masterCategories.map((cat) {
                        return _StatusChip.info((cat['name'] ?? '').toString());
                      }).toList(),
                    ),
            ),

            // ----------------------------------------------------- AUTHORS
            _SectionCard(
              title: 'ນັກຂຽນ',
              subtitle: 'ຂໍ້ມູນຜູ້ແຕ່ງທີ່ຜູກກັບປຶ້ມໃນຄັງ',
              icon: Icons.person_pin_rounded,
              accent: _Ds.success,
              actions: [
                _rowAction('ເພີ່ມນັກຂຽນ', Icons.person_add_alt_rounded, _Ds.success,
                    _openCreateAuthorDialog),
              ],
              child: _authors.isEmpty
                  ? _inlineEmpty('ບໍ່ມີນັກຂຽນໃນຖານຂໍ້ມູນ')
                  : Column(
                      children: _authors.map((author) {
                        final authorId = author['author_id'] ?? 0;
                        final authorName = (author['name'] ?? '').toString();
                        final authorBio = (author['biography'] ?? '').toString();
                        return _listCard(
                          accent: _Ds.success,
                          title: authorName,
                          subtitle: authorBio.isNotEmpty ? authorBio : 'ບໍ່ມີປະຫວັດ',
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: _Ds.successSoft,
                            child: Text(
                              authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, color: _Ds.success),
                            ),
                          ),
                          actions: [
                            _iconAction('ແກ້ໄຂ', Icons.edit_outlined, _Ds.info,
                                () => _openEditAuthorDialog(authorId, authorName, authorBio)),
                            _iconAction('ລຶບ', Icons.delete_outline_rounded, _Ds.danger,
                                () => _confirmDeleteAuthor(authorId, authorName)),
                          ],
                        );
                      }).toList(),
                    ),
            ),

            // -------------------------------------------------- AUDIT LOGS
            _SectionCard(
              title: 'ບັນທຶກຄວາມປອດໄພ',
              subtitle: 'ເຫດການສຳຄັນທີ່ເກີດຂຶ້ນໃນລະບົບ (ຫຼ້າສຸດ 8 ລາຍການ)',
              icon: Icons.security_rounded,
              accent: _Ds.neutral,
              child: _auditLogs.isEmpty
                  ? _inlineEmpty('ບໍ່ມີບັນທຶກ Audit Logs')
                  // # ເຮັດຫຍັງ: ຫຸ້ມ ListTile ດ້ວຍ Material ໂປ່ງໃສ
                  // # ຍ້ອນຫຍັງ: ListTile paint ພື້ນຫຼັງ+ink ໃສ່ Material ໃກ້ສຸດ ແຕ່
                  // #          _SectionCard ເປັນ Container ທີ່ມີສີພື້ນຄັ່ນຢູ່ ຈຶ່ງບັງ ink
                  // #          ໄວ້ ("ListTile background color or ink splashes may be
                  // #          invisible" ໃນ console) - ກົດແລ້ວບໍ່ເຫັນ feedback
                  // # ແກ້ຈາກສ່ວນໃດ: Column ຂອງ audit logs ໃນ _SectionCard ນີ້
                  // # ແກ້ເຮັດຫຍັງ: ມີ Material ຂອງໂຕເອງ ຈຶ່ງເຫັນ ink ຕອນກົດ ຕາມທີ່
                  // #             Flutter ແນະນຳ ແລະ ບໍ່ມີ error ອອກ console ອີກ
                  : Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          for (final log in _auditLogs.take(8))
                            ListTile(
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: _Ds.s8, vertical: 2),
                              onTap: () => _showAuditLogDetailModal(log),
                              leading: const Icon(Icons.history_rounded,
                                  size: 18, color: _Ds.textMuted),
                              title: Text(
                                '${log['first_name'] ?? "User"}: ${log['action']}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: _Ds.textPrimary),
                              ),
                              subtitle: Text(
                                'IP ${log['ip_address'] ?? "127.0.0.1"}  •  ${log['details'] ?? "N/A"}',
                                style: _Ds.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded,
                                  size: 18, color: _Ds.textMuted),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// ຂໍ້ຄວາມຫວ່າງພາຍໃນ section - ນ້ອຍກວ່າ _emptyState ທີ່ໃຊ້ເຕັມໜ້າ
  Widget _inlineEmpty(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _Ds.s16),
      child: Center(child: Text(text, style: _Ds.body, textAlign: TextAlign.center)),
    );
  }

  // # ເຮັດຫຍັງ: ແຍກ dialog ເພີ່ມໝວດໝູ່ອອກມາເປັນ method ຂອງຕົນເອງ
  // # ຍ້ອນຫຍັງ: ຂອງເກົ່າຝັງ showDialog ໄວ້ໃນ onPressed ຂອງ IconButton ກາງ build tree
  // #          ເຮັດໃຫ້ build method ຍາວ ແລະ ອ່ານໂຄງ UI ຍາກ
  // # ແກ້ຈາກສ່ວນໃດ: onPressed ຂອງ IconButton(Icons.add_circle_outline_rounded)
  // # ແກ້ເຮັດຫຍັງ: ຕັກກະການສ້າງໝວດໝູ່ (ApiService.createCategory) ຄືເກົ່າທຸກຢ່າງ
  void _openCreateCategoryDialog() {
    final catCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ເພີ່ມໝວດໝູ່ໃໝ່'),
        content: TextField(
          controller: catCtrl,
          decoration: const InputDecoration(hintText: 'ຊື່ໝວດໝູ່...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              final catName = catCtrl.text.trim();
              if (catName.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.createCategory(catName);
                if (mounted && success) {
                  await _fetchAdminData();
                }
              }
            },
            child: const Text('ບັນທຶກ'),
          ),
        ],
      ),
    );
  }


  void _showBookDetailModal(BookModel book, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(width: 70, height: 95, child: _buildImage(book.imagePath)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('ນັກຂຽນ: ${book.author}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('ລາຍລະອຽດປຶ້ມ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(book.description ?? 'ບໍ່ມີເນື້ອເລື່ອງ', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _openPdfViewer(book);
                },
                icon: const Icon(Icons.menu_book_rounded, size: 18, color: Colors.white),
                label: const Text('ເປີດອ່ານປຶ້ມ (PDF Reader)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailModal(Map<String, dynamic> user) {
    final status = (user['status'] ?? 'active').toString().toLowerCase();
    final isSuspended = status == 'suspended' || status == 'banned';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ImageHelper.buildAvatar(
                  (user['profile_image_url'] ?? user['profile_image'] ?? user['avatar_url'] ?? user['avatar'])?.toString(),
                  firstName: (user['first_name'] ?? 'U').toString(),
                  size: 48,
                  backgroundColor: AppColors.primary,
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${user['first_name'] ?? ""} ${user['last_name'] ?? ""}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text('ສິດການນຳໃຊ້: ${(user['role'] ?? "user").toString().toUpperCase()}'),
            const SizedBox(height: 4),
            Text('ສະຖານະບັນຊີ: ${isSuspended ? "ລະງັບການນຳໃຊ້" : "ປົກກະຕິ (Active)"}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final index = _adminUsers.indexWhere((u) =>
                          (u['user_id'] ?? u['id']) == (user['user_id'] ?? user['id']));
                      _openEditUserDialog(user, index >= 0 ? index : 0);
                    },
                    icon: const Icon(Icons.edit_note_rounded, size: 20),
                    label: const Text('ແກ້ໄຂຂໍ້ມູນ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _toggleUserStatus(user);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.redAccent),
                    child: Text(isSuspended ? 'ປົດລະງັບ' : 'ລະງັບບັນຊີ'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showKycDetailModal(KycModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ລາຍລະອຽດເອກະສານ KYC (${item.userName})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('👤 ຂໍ້ມູນສ່ວນບຸກຄົນ (Personal Details):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text('• ຊື່ ແລະ ນາມສະກຸນ: ${item.fullName.isNotEmpty ? item.fullName : item.userName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text('• ເພດ: ${item.genderText}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    Text('• ວັນເດືອນປີເກີດ: ${item.dateOfBirth.isNotEmpty ? item.dateOfBirth : "ບໍ່ລະບຸ"}', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                    Text('• ເລກເອກະສານ (${item.documentType}): ${item.idCardNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                    Text('• ອີເມວ: ${item.userEmail}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    if (item.isStudent && item.schoolName != null && item.schoolName!.isNotEmpty)
                      Text('• ໂຮງຮຽນ/ມະຫາວິທະຍາໄລ: ${item.schoolName}', style: const TextStyle(fontSize: 12, color: Colors.purple, fontWeight: FontWeight.bold)),
                    Text('• ສະຖານະ: ${item.statusText}', style: TextStyle(color: item.status == KycStatus.approved ? Colors.green : (item.status == KycStatus.rejected ? Colors.red : Colors.orange), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(height: 20),
              
              const Text('1. ຮູບຖ່າຍບັດປະຈຳຕົວ / Passport (ແຕະເພື່ອຂະຫຍາຍເບິ່ງຮູບໃຫຍ່):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (item.idCardImagePath.isNotEmpty) {
                    ImageHelper.showPreviewModal(
                      context,
                      path: item.idCardImagePath,
                      title: 'ຮູບບັດປະຈຳຕົວ - ${item.userName}',
                    );
                  }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _buildImage(item.idCardImagePath, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.zoom_in_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('2. ຮູບຖ່າຍຄູ່ກັບເອກະສານ (Selfie) (ແຕະເພື່ອຂະຫຍາຍເບິ່ງຮູບໃຫຍ່):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (item.selfieImagePath.isNotEmpty) {
                    ImageHelper.showPreviewModal(
                      context,
                      path: item.selfieImagePath,
                      title: 'ຮູບຖ່າຍ Selfie - ${item.userName}',
                    );
                  }
                },
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: _buildImage(item.selfieImagePath, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.zoom_in_rounded, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (item.status != KycStatus.approved)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveKyc(item);
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        label: const Text('ອະນຸມັດ KYC'),
                      ),
                    ),
                  if (item.status != KycStatus.approved && item.status != KycStatus.rejected)
                    const SizedBox(width: 10),
                  if (item.status != KycStatus.rejected)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectKycDialog(item);
                        },
                        icon: const Icon(Icons.cancel_rounded, size: 18),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                        label: Text(item.status == KycStatus.approved ? 'ຍົກເລີກ / ປະຕິເສດ KYC ນີ້' : 'ປະຕິເສດ'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscriptionDetailModal(Map<String, dynamic> sub) {
    final status = (sub['payment_status'] ?? 'pending').toString();
    final String slipUrl = (sub['slip_url'] ?? sub['slip_image_url'] ?? sub['payment_slip_url'] ?? sub['slip'] ?? '').toString();
    final String userName = '${sub['first_name'] ?? ""} ${sub['last_name'] ?? ""}'.trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ລາຍລະອຽດສະລິບການໂອນເງິນ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 4),
              Text('ຜູ້ແຈ້ງຊຳລະ: ${userName.isNotEmpty ? userName : "ຜູ້ໃຊ້ງານ"} (${sub['email'] ?? ""})'),
              Text('ແພັກເກັດ: ${sub['package_name'] ?? "VIP Package"}'),
              Text('ຍອດຊຳລະ: ${_formatCurrency(sub['amount'] ?? 49000)} LAK', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Divider(height: 20),
              const Text('ຮູບພາບສະລິບໂອນເງິນ (ແຕະເພື່ອຂະຫຍາຍເບິ່ງຮູບໃຫຍ່):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (slipUrl.isNotEmpty) {
                    ImageHelper.showPreviewModal(
                      context,
                      path: slipUrl,
                      title: 'ສະລິບການໂອນເງິນ - $userName',
                    );
                  }
                },
                child: Container(
                  height: 260,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _buildImage(slipUrl, width: double.infinity, height: double.infinity),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.zoom_in_rounded, size: 20, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (status == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveSubscription(sub);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('ອະນຸມັດການຊຳລະເງິນ'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectSubscription(sub);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('ປະຕິເສດສະລິບ'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPackageDetailModal(Map<String, dynamic> pkg) {
    final isStudentPkg = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;
    final isActive = pkg['is_active'] == 1 || pkg['is_active'] == true || pkg['is_active'] == null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isStudentPkg ? Icons.school_rounded : Icons.workspace_premium_rounded,
                  color: isActive ? (isStudentPkg ? Colors.orange : Colors.purple) : Colors.grey,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('ລາຄາ: ${_formatCurrency(pkg['price'])} LAK | ໄລຍະເວລາ: ${pkg['duration_days']} ມື້', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: isActive ? Colors.green.shade900 : Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Text('ລາຍລະອຽດ: ${pkg['description'] ?? "ເຂົ້າເຖິງ e-Book ທັງໝົດ"}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEditPackageDialog(pkg);
                    },
                    icon: const Icon(Icons.edit_rounded, size: 18),
                    label: const Text('ແກ້ໄຂແພັກເກັດ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _togglePackageStatus(pkg);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.redAccent : Colors.green,
                    ),
                    icon: Icon(isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, size: 18),
                    label: Text(isActive ? 'ປິດນຳໃຊ້ (Inactive)' : 'ເປີດນຳໃຊ້ (Active)'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAuditLogDetailModal(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ລາຍລະອຽດບັນທຶກຄວາມປອດໄພ (Audit Log)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Divider(height: 20),
            Text('ຜູ້ເຮັດລາຍການ: ${log['first_name'] ?? ""} (${log['email'] ?? ""})'),
            Text('ຄຳສັ່ງ: ${log['action'] ?? ""}'),
            Text('IP Address: ${log['ip_address'] ?? "127.0.0.1"}'),
            Text('ລາຍລະອຽດ: ${log['details'] ?? "ບໍ່ມີ"}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ປິດໜ້າຕ່າງ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditAuthorDialog(int authorId, String currentName, String currentBio) {
    final nameCtrl = TextEditingController(text: currentName);
    final bioCtrl = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ແກ້ໄຂນັກຂຽນ: $currentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ນັກຂຽນ')),
            const SizedBox(height: 8),
            TextField(controller: bioCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'ປະຫວັດຫຍໍ້ (Biography)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.updateAuthor(authorId, name, bio: bioCtrl.text.trim());
                if (mounted && success) {
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ແກ້ໄຂນັກຂຽນ "$name" ຮຽບຮ້ອຍແລ້ວ'), backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            child: const Text('ບັນທຶກ'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAuthor(int authorId, String authorName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ຢືນຢັນການລົບບັກຂຽນ'),
        content: Text('ທ່ານຕ້ອງການລົບບັກຂຽນ "$authorName" ແທ້ບໍ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteAuthor(authorId);
              if (mounted && success) {
                await _fetchAdminData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('ລົບບັກຂຽນ "$authorName" ຮຽບຮ້ອຍແລ້ວ'), backgroundColor: AppColors.primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ຢືນຢັນລົບ'),
          ),
        ],
      ),
    );
  }
}

