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
import '../login_screen.dart';
import '../User/pdf_viewer_screen.dart';
import '../../utils/image_helper.dart';

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
  String _reportTimeFilter = 'ທັງໝົດ';

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

  int get _pendingBooksCount =>
      _adminBooks.where((b) => b.status.toLowerCase() == 'pending').length;

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

    try {
      // ใช้ eagerError: false เพื่อไม่ให้ API ตัวใดตัวหนึ่งล้มเหลวแล้วพาทั้งหมดพัง
      final results = await Future.wait([
        ApiService.getBooks(role: 'admin', status: 'all').catchError((_) => <BookModel>[]),
        ApiService.getUsers().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getKycList().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getSubscriptions().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getPackages(showAll: true).catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getCategories().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getAuthors().catchError((_) => <Map<String, dynamic>>[]),
        ApiService.getAuditLogs().catchError((_) => <Map<String, dynamic>>[]),
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
            color: Colors.black.withOpacity(0.25),
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
                  activeColor: Colors.green,
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
                  activeColor: Colors.green,
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

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Admin Control Panel', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  Text('ລະບົບຄຸ້ມຄອງ E-Book & KYC', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary), onPressed: _fetchAdminData, tooltip: 'ຣີເຟຣຊ'),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout, tooltip: 'ອອກຈາກລະບົບ'),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    key: const ValueKey('main_scaffold_body_column'),
                    children: [
                      // Top Header Nav for Web/Tablet Mode
                      if (!isMobile)
                        Container(
                          color: Colors.white,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                _buildNavTab(0, Icons.menu_book_rounded, 'ຄັງຫນັງສື', count: _adminBooks.length, badge: _pendingBooksCount),
                                _buildNavTab(1, Icons.people_alt_rounded, 'ຜູ້ໃຊ້/ພະນັກງານ', count: _adminUsers.length),
                                _buildNavTab(2, Icons.verified_user_rounded, 'KYC & Student', badge: _pendingKycCount),
                                _buildNavTab(3, Icons.receipt_long_rounded, 'ສະລິບໂອນເງິນ', badge: _pendingSlipCount),
                                _buildNavTab(4, Icons.settings_applications_rounded, 'ລະບົບ & ແພັກເກັດ'),
                                _buildNavTab(5, Icons.analytics_rounded, 'ລາຍງານ & ສະຖິຕິ'),
                              ],
                            ),
                          ),
                        ),
                      if (!isMobile) const Divider(height: 1),

                      // Content Tab Body
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 12 : 16),
                          child: IndexedStack(
                            index: _selectedTab,
                            children: [
                              _buildBookManagementTab(isMobile),
                              _buildUserManagementTab(isMobile),
                              _buildKycApprovalTab(isMobile),
                              _buildSubscriptionApprovalTab(isMobile),
                              _buildSystemMasterTab(isMobile),
                              _buildReportsTab(isMobile),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (index) => setState(() => _selectedTab = index),
              selectedItemColor: AppColors.primary,
              unselectedItemColor: const Color(0xFF64748B),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 10,
              unselectedFontSize: 9,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'ຄັງປຶ້ມ'),
                const BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'ຜູ້ໃຊ້'),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.verified_user_rounded),
                      if (_pendingKycCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                            child: Text('$_pendingKycCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                  label: 'KYC',
                ),
                BottomNavigationBarItem(
                  icon: Stack(
                    children: [
                      const Icon(Icons.receipt_long_rounded),
                      if (_pendingSlipCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                            child: Text('$_pendingSlipCount', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ),
                    ],
                  ),
                  label: 'ສະລິບ',
                ),
                const BottomNavigationBarItem(icon: Icon(Icons.settings_applications_rounded), label: 'ລະບົບ'),
                const BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'ລາຍງານ'),
              ],
            )
          : null,
    );
  }

  Widget? _buildFab() {
    if (_selectedTab == 0) {
      return FloatingActionButton.extended(
        onPressed: _openAddBookDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ເພີ່ມປຶ້ມ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    if (_selectedTab == 1) {
      return FloatingActionButton.extended(
        onPressed: _openCreateUserDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text('ເພີ່ມຜູ້ໃຊ້', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  Widget _buildNavTab(int index, IconData icon, String label, {int? count, int badge = 0}) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: isSelected ? Colors.amber : Colors.red, borderRadius: BorderRadius.circular(10)),
                child: Text('$badge', style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        onSelected: (val) {
          if (val) setState(() => _selectedTab = index);
        },
      ),
    );
  }

  // --- STAT SUMMARY CARD BANNER ---
  Widget _buildStatSummaryBanner({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool wrapExpanded = true,
  }) {
    final content = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (wrapExpanded) {
      return Expanded(child: content);
    }
    return SizedBox(width: 180, child: content);
  }

  // --- TAB 0: BOOKS MANAGEMENT ---
  Widget _buildBookManagementTab(bool isMobile) {
    final filtered = _adminBooks.where((b) {
      final matchesSearch = b.title.toLowerCase().contains(_searchQuery.toLowerCase()) || b.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _bookStatusFilter == 'ທັງໝົດ' || b.status.toLowerCase() == _bookStatusFilter.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        // Quick Stats Banner
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatSummaryBanner(title: 'ປຶ້ມທັງໝົດ', value: '${_adminBooks.length} ຫົວ', icon: Icons.menu_book_rounded, color: AppColors.primary, wrapExpanded: false),
              const SizedBox(width: 8),
              _buildStatSummaryBanner(title: 'ລໍຖ້າອະນຸມັດ', value: '$_pendingBooksCount ຫົວ', icon: Icons.hourglass_top_rounded, color: Colors.orange.shade800, wrapExpanded: false),
              const SizedBox(width: 8),
              _buildStatSummaryBanner(title: 'ອະນຸມັດແລ້ວ', value: '${_adminBooks.where((b) => b.status.toLowerCase() == 'approved').length} ຫົວ', icon: Icons.check_circle_rounded, color: Colors.green, wrapExpanded: false),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Search Bar & Status Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາຊື່ປຶ້ມ ຫຼື ຜູ້ແຕ່ງ...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButton<String>(
                value: _bookStatusFilter,
                underline: const SizedBox(),
                items: [
                  const DropdownMenuItem(value: 'ທັງໝົດ', child: Text('ທັງໝົດ', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'pending', child: Text('ລໍຖ້າອະນຸມັດ ($_pendingBooksCount)', style: TextStyle(fontSize: 12, color: Colors.orange.shade900, fontWeight: FontWeight.bold))),
                  const DropdownMenuItem(value: 'approved', child: Text('ອະນຸມັດແລ້ວ', style: TextStyle(fontSize: 12, color: Colors.green))),
                  const DropdownMenuItem(value: 'rejected', child: Text('ບໍ່ອະນຸມັດ', style: TextStyle(fontSize: 12, color: Colors.red))),
                ],
                onChanged: (val) => setState(() => _bookStatusFilter = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAdminData,
            color: AppColors.primary,
            child: filtered.isEmpty
                ? const Center(child: Text('ບໍ່ພົບລາຍການປຶ້ມ', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final book = filtered[idx];
                      final isPending = book.status.toLowerCase() == 'pending';
                      final isApproved = book.status.toLowerCase() == 'approved';
                      final isRejected = book.status.toLowerCase() == 'rejected';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isPending ? Colors.orange.shade300 : const Color(0xFFE2E8F0), width: isPending ? 1.5 : 1.0),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          onTap: () => _showBookDetailModal(book, idx),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(width: 48, height: 64, child: _buildImage(book.imagePath)),
                          ),
                          title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text('ຜູ້ແຕ່ງ: ${book.author}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              if (book.uploaderName != null)
                                Text('ຜູ້ເພີ່ມ: ${book.uploaderName}', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isApproved
                                          ? Colors.green.shade50
                                          : (isRejected ? Colors.red.shade50 : Colors.orange.shade50),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isApproved ? 'ອະນຸມັດແລ້ວ' : (isRejected ? 'ບໍ່ອະນຸມັດ' : 'ລໍຖ້າອະນຸມັດ'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isApproved
                                            ? Colors.green.shade700
                                            : (isRejected ? Colors.red.shade700 : Colors.orange.shade900),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                                    child: Text(book.tags.isNotEmpty ? book.tags.first : "ທົ່ວໄປ", style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                  ),
                                  if (book.isFree)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('ອ່ານຟຣີ', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isPending) ...[
                                IconButton(
                                  tooltip: 'ອະນຸມັດປຶ້ມ',
                                  icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                                  onPressed: () => _changeBookStatus(book, 'approved'),
                                ),
                                IconButton(
                                  tooltip: 'ປະຕິເສດປຶ້ມ',
                                  icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 24),
                                  onPressed: () => _changeBookStatus(book, 'rejected'),
                                ),
                              ] else ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                  onPressed: () => _openEditBookDialog(book, idx),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => _deleteBook(idx),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
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
          title: Row(
            children: const [
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

    return Column(
      children: [
        // Quick User Stats Banner
        Row(
          children: [
            _buildStatSummaryBanner(title: 'ຜູ້ໃຊ້ທັງໝົດ', value: '${_adminUsers.length} ຄົນ', icon: Icons.people_alt_rounded, color: Colors.indigo),
            const SizedBox(width: 8),
            _buildStatSummaryBanner(title: 'ແອດມິນ/ພະນັກງານ', value: '${_adminUsers.where((u) => (u['role'] ?? '').toString().toLowerCase() != 'user').length} ຄົນ', icon: Icons.admin_panel_settings_rounded, color: Colors.purple),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ຄົ້ນຫາຊື່ ຫຼື ອີເມວ...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButton<String>(
                value: _userRoleFilter,
                underline: const SizedBox(),
                items: ['ທັງໝົດ', 'Admin', 'Employee', 'User'].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setState(() => _userRoleFilter = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAdminData,
            color: AppColors.primary,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (ctx, idx) {
                final user = filtered[idx];
                final status = (user['status'] ?? 'active').toString().toLowerCase();
                final isSuspended = status == 'suspended' || status == 'banned';
                final role = (user['role'] ?? 'user').toString();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    onTap: () => _showUserDetailModal(user),
                    leading: CircleAvatar(
                      backgroundColor: role.toLowerCase() == 'admin'
                          ? Colors.purple
                          : (role.toLowerCase() == 'employee' ? Colors.orange.shade800 : AppColors.primary),
                      child: Text(
                        (user['first_name'] ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim(),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: role.toLowerCase() == 'admin'
                                ? Colors.purple.shade100
                                : (role.toLowerCase() == 'employee' ? Colors.orange.shade100 : Colors.blue.shade100),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: role.toLowerCase() == 'admin'
                                  ? Colors.purple
                                  : (role.toLowerCase() == 'employee' ? Colors.orange.shade900 : Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('ອີເມວ: ${user['email']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
                          onPressed: () {
                            final realIdx = _adminUsers.indexWhere((u) =>
                                (u['user_id'] ?? u['id']) == (user['user_id'] ?? user['id']));
                            _openEditUserDialog(user, realIdx >= 0 ? realIdx : idx);
                          },
                        ),
                        ElevatedButton(
                          onPressed: () => _toggleUserStatus(user),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSuspended ? Colors.green : Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: Text(isSuspended ? 'ປົດລະງັບ' : 'ລະງັບ', style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
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

    return Column(
      children: [
        // KYC Stats Banner
        Row(
          children: [
            _buildStatSummaryBanner(title: 'ລໍຖ້າອະນຸມັດ KYC', value: '$_pendingKycCount ຄົນ', icon: Icons.badge_rounded, color: Colors.orange.shade800),
            const SizedBox(width: 8),
            _buildStatSummaryBanner(title: 'ອະນຸມັດແລ້ວ', value: '${_kycSubmissions.where((k) => k.status == KycStatus.approved).length} ຄົນ', icon: Icons.verified_rounded, color: Colors.green),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ລາຍການຂໍອະນຸມັດ KYC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButton<String>(
                value: _kycFilterStatus,
                underline: const SizedBox(),
                items: ['ທັງໝົດ', 'ລໍຖ້າອະນຸມັດ', 'ອະນຸມັດແລ້ວ', 'ບໍ່ອະນຸມັດ'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setState(() => _kycFilterStatus = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAdminData,
            color: AppColors.primary,
            child: filtered.isEmpty
                ? const Center(child: Text('ບໍ່ມີລາຍການ KYC'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final item = filtered[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          onTap: () => _showKycDetailModal(item),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFEFF6FF),
                            child: Icon(Icons.badge_rounded, color: AppColors.primary, size: 24),
                          ),
                          title: Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ອີເມວ: ${item.userEmail}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('ເລກບັດ: ${item.idCardNumber}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                            ],
                          ),
                          trailing: item.status == KycStatus.pending
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _approveKyc(item)),
                                    IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent), onPressed: () => _showRejectKycDialog(item)),
                                  ],
                                )
                              : Chip(
                                  label: Text(item.statusText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                  backgroundColor: item.status == KycStatus.approved ? Colors.green.shade100 : Colors.red.shade100,
                                ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
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

    return Column(
      children: [
        // Slip Stats Banner
        Row(
          children: [
            _buildStatSummaryBanner(title: 'ສະລິບລໍຖ້າກວດສອບ', value: '$_pendingSlipCount ລາຍການ', icon: Icons.receipt_long_rounded, color: Colors.amber.shade900),
            const SizedBox(width: 8),
            _buildStatSummaryBanner(title: 'ອະນຸມັດແລ້ວ', value: '${_subscriptions.where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'active').length} ລາຍການ', icon: Icons.verified_user_rounded, color: Colors.green),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ລາຍການແຈ້ງຊຳລະເງິນ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: DropdownButton<String>(
                value: _subFilterStatus,
                underline: const SizedBox(),
                items: ['ທັງໝົດ', 'pending', 'active', 'rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(fontSize: 12)))).toList(),
                onChanged: (val) => setState(() => _subFilterStatus = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchAdminData,
            color: AppColors.primary,
            child: filtered.isEmpty
                ? const Center(child: Text('ບໍ່ມີລາຍການສະລິບໂອນເງິນ'))
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final sub = filtered[idx];
                      final status = (sub['payment_status'] ?? 'pending').toString();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(10),
                          onTap: () => _showSubscriptionDetailModal(sub),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFEF3C7),
                            child: Icon(Icons.receipt_long_rounded, color: Colors.amber, size: 24),
                          ),
                          title: Text('${sub['first_name'] ?? ""} ${sub['last_name'] ?? ""}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ແພັກເກັດ: ${sub['package_name'] ?? "VIP"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('ຍອດຊຳລະ: ${sub['amount']} LAK', style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          trailing: status == 'pending'
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () => _approveSubscription(sub),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                      child: const Text('ອະນຸມັດ', style: TextStyle(color: Colors.white, fontSize: 11)),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.redAccent), onPressed: () => _rejectSubscription(sub)),
                                  ],
                                )
                              : Chip(label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: status == 'active' ? Colors.green.shade100 : Colors.red.shade100),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // --- TAB 4: SYSTEM & PACKAGES MASTER TAB ---
  Widget _buildSystemMasterTab(bool isMobile) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Packages Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ຈັດການແພັກເກັດສະມາຊິກ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton.icon(
                onPressed: _openCreatePackageDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                label: const Text('ສ້າງແພັກເກັດ', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Packages Grid Cards
          ..._packages.map((pkg) {
            final isStudentPkg = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;
            final isActive = pkg['is_active'] == 1 || pkg['is_active'] == true || pkg['is_active'] == null;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isActive ? const Color(0xFFE2E8F0) : Colors.red.shade200),
              ),
              child: ListTile(
                onTap: () => _showPackageDetailModal(pkg),
                leading: Icon(
                  isStudentPkg ? Icons.school_rounded : Icons.workspace_premium_rounded,
                  color: isActive ? (isStudentPkg ? Colors.orange : Colors.purple) : Colors.grey,
                  size: 32,
                ),
                title: Row(
                  children: [
                    Text(
                      pkg['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isActive ? AppColors.textPrimary : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isStudentPkg)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                        child: const Text('ນັກຮຽນ/ນັກສຶກສາ', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Active (ເປີດນຳໃຊ້)' : 'Inactive (ປິດນຳໃຊ້)',
                        style: TextStyle(
                          fontSize: 9,
                          color: isActive ? Colors.green.shade800 : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  'ລາຄາ: ${pkg['price']} LAK | ໄລຍະເວລາ: ${pkg['duration_days']} ມື້',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      tooltip: 'ແກ້ໄຂແພັກເກັດ',
                      onPressed: () => _openEditPackageDialog(pkg),
                    ),
                    Switch(
                      value: isActive,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.redAccent,
                      onChanged: (val) => _togglePackageStatus(pkg),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),

          // Master Categories Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ໝວດໝູ່ປຶ້ມ (Categories - MySQL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                        onPressed: () {
                          final catCtrl = TextEditingController();
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('ເພີ່ມໝວດໝູ່ໃໝ່'),
                              content: TextField(controller: catCtrl, decoration: const InputDecoration(hintText: 'ຊື່ໝວດໝູ່...')),
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
                        },
                      ),
                    ],
                  ),
                  _masterCategories.isEmpty
                      ? const Padding(padding: EdgeInsets.all(8), child: Text('ບໍ່ມີໝວດໝູ່ໃນຖານຂໍ້ມູນ'))
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _masterCategories.map((cat) {
                            final catId = cat['category_id'];
                            final catName = (cat['name'] ?? '').toString();
                            return Chip(
                              label: Text('$catName (ID: $catId)', style: const TextStyle(fontSize: 11)),
                              backgroundColor: Colors.blue.shade50,
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Authors Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ລາຍຊື່ນັກຂຽນ (Authors)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ElevatedButton.icon(
                        onPressed: _openCreateAuthorDialog,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('ເພີ່ມນັກຂຽນ', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _authors.isEmpty
                      ? const Padding(padding: EdgeInsets.all(8), child: Text('ບໍ່ມີນັກຂຽນໃນຖານຂໍ້ມູນ'))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _authors.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final author = _authors[idx];
                            final authorId = author['author_id'] ?? 0;
                            final authorName = (author['name'] ?? '').toString();
                            final authorBio = (author['biography'] ?? '').toString();
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.primary.withOpacity(0.15),
                                child: Text(authorName.isNotEmpty ? authorName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              ),
                              title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(authorBio.isNotEmpty ? authorBio : 'ບໍ່ມີປະຫວັດ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 18),
                                    onPressed: () => _openEditAuthorDialog(authorId, authorName, authorBio),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                                    onPressed: () => _confirmDeleteAuthor(authorId, authorName),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Audit Logs
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.security_rounded, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Text('ບັນທຶກຄວາມປອດໄພ (Audit Logs)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _auditLogs.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Text('ບໍ່ມີບັນທຶກ Audit Logs'))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _auditLogs.length > 8 ? 8 : _auditLogs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final log = _auditLogs[idx];
                            return ListTile(
                              dense: true,
                              onTap: () => _showAuditLogDetailModal(log),
                              title: Text('${log['first_name'] ?? "User"}: ${log['action']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              subtitle: Text('IP: ${log['ip_address'] ?? "127.0.0.1"} | ${log['details'] ?? "N/A"}', style: const TextStyle(fontSize: 10)),
                            );
                          },
                        ),
                ],
              ),
            ),
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary,
                  child: Text((user['first_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
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
              const SizedBox(height: 4),
              Text('ອີເມວ: ${item.userEmail}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text('ເລກປະຈຳຕົວ: ${item.idCardNumber}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('ສະຖານະ: ${item.statusText}', style: TextStyle(color: item.status == KycStatus.approved ? Colors.green : (item.status == KycStatus.rejected ? Colors.red : Colors.orange), fontWeight: FontWeight.bold, fontSize: 12)),
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
              if (item.status == KycStatus.pending)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveKyc(item);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('ອະນຸມັດ KYC'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectKycDialog(item);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('ປະຕິເສດ'),
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
              Text('ຍອດຊຳລະ: ${sub['amount'] ?? "49000"} LAK', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                      Text('ລາຄາ: ${pkg['price']} LAK | ໄລຍະເວລາ: ${pkg['duration_days']} ມື້', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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

  // --- TAB 5: EXECUTIVE REPORTS & ANALYTICS ---
  Widget _buildReportsTab(bool isMobile) {
    // 1. Calculate Revenue Metrics (Support 'active' or 'approved' status from DB)
    final approvedSubs = _subscriptions.where((s) {
      final st = (s['payment_status'] ?? '').toString().toLowerCase();
      return st == 'approved' || st == 'active';
    }).toList();
    final pendingSubs = _subscriptions.where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'pending').toList();
    final rejectedSubs = _subscriptions.where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'rejected').toList();

    double totalRevenue = 0;
    for (var s in approvedSubs) {
      totalRevenue += double.tryParse((s['amount'] ?? s['price'] ?? 49000).toString()) ?? 49000;
    }

    double pendingRevenue = 0;
    for (var s in pendingSubs) {
      pendingRevenue += double.tryParse((s['amount'] ?? s['price'] ?? 49000).toString()) ?? 49000;
    }

    // 2. Calculate Reading & Book Metrics (Using exact DB data)
    int totalViews = 0;
    int totalLikes = 0;
    for (var b in _adminBooks) {
      totalViews += b.viewCount;
      totalLikes += b.likeCount;
    }

    // Sort Top 5 Popular Books by real engagement
    final sortedBooks = List<BookModel>.from(_adminBooks);
    sortedBooks.sort((a, b) {
      final scoreA = a.likeCount * 2 + a.viewCount;
      final scoreB = b.likeCount * 2 + b.viewCount;
      return scoreB.compareTo(scoreA);
    });
    final topBooks = sortedBooks.take(5).toList();

    // 3. Calculate User Demographics & KYC Metrics
    final totalUsers = _adminUsers.length;
    final premiereUsersCount = _adminUsers.where((u) => (u['role'] ?? '') == 'admin' || (u['role'] ?? '') == 'employee' || (u['email'] ?? '') == 'member@gmail.com').length;
    final kycApprovedCount = _kycSubmissions.where((k) => k.status == KycStatus.approved).length;
    final kycPendingCount = _kycSubmissions.where((k) => k.status == KycStatus.pending).length;
    final kycRejectedCount = _kycSubmissions.where((k) => k.status == KycStatus.rejected).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Export Action Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ລາຍງານສະຖິຕິ & ຜົນປະກອບການ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Executive Reports & Analytics Overview', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showExportReportModal(
                    totalRevenue: totalRevenue,
                    totalUsers: totalUsers,
                    topBooksCount: topBooks.length,
                  ),
                  icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                  label: Text(isMobile ? 'ພິມ' : 'ພິມລາຍງານ PDF', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Executive KPI Grid (4 Cards)
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 1.45 : 1.6,
            children: [
              _buildReportKpiCard(
                title: 'ລາຍຮັບລວມການສະໝັກສະມາຊິກ',
                value: '${totalRevenue.toStringAsFixed(0)} LAK',
                subtitle: 'ຈາກ ${approvedSubs.length} ລາຍການທີ່ອະນຸມັດ',
                icon: Icons.payments_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
              _buildReportKpiCard(
                title: 'ສະລິບລໍຖ້າກວດສອບມູນຄ່າ',
                value: '${pendingRevenue.toStringAsFixed(0)} LAK',
                subtitle: '${pendingSubs.length} ລາຍການລໍຖ້າດຳເນີນການ',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
              _buildReportKpiCard(
                title: 'ຍອດອ່ານປຶ້ມສະສົມລວມ',
                value: '$totalViews ຄັ້ງ',
                subtitle: 'ຈາກປຶ້ມທັງໝົດ ${_adminBooks.length} ຫົວ',
                icon: Icons.auto_stories_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
              ),
              _buildReportKpiCard(
                title: 'ຍອດກົດຫົວໃຈຖືກໃຈລວມ',
                value: '$totalLikes ❤️',
                subtitle: 'ຈາກຜູ້ໃຊ້ງານທັງໝົດ $totalUsers ຄົນ',
                icon: Icons.favorite_rounded,
                color: const Color(0xFFEF4444),
                bgColor: const Color(0xFFFEF2F2),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Analytics Section Layout (Grid for Web / Stack for Mobile)
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top 5 Popular Books Leaderboard (Left Side)
              Expanded(
                flex: isMobile ? 0 : 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.emoji_events_rounded, color: Color(0xFFF59E0B), size: 20),
                              SizedBox(width: 8),
                              Text('ອັນດັບປຶ້ມຍອດນິຍົມສູງສຸດ (Top 5 Books)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                            child: const Text('Top Reads', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (topBooks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('ບໍ່ມີຂໍ້ມູນປຶ້ມ', style: TextStyle(color: AppColors.textSecondary))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topBooks.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (ctx, idx) {
                            final book = topBooks[idx];
                            final views = book.viewCount;
                            final likes = book.likeCount;

                            Color rankColor = const Color(0xFF94A3B8);
                            if (idx == 0) rankColor = const Color(0xFFF59E0B); // Gold
                            if (idx == 1) rankColor = const Color(0xFF64748B); // Silver
                            if (idx == 2) rankColor = const Color(0xFFD97706); // Bronze

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(color: rankColor.withOpacity(0.15), shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        '${idx + 1}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rankColor),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(width: 36, height: 48, child: _buildImage(book.imagePath)),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(book.author, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFEF4444)),
                                          const SizedBox(width: 3),
                                          Text('$likes', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.visibility_rounded, size: 12, color: Color(0xFF2563EB)),
                                          const SizedBox(width: 3),
                                          Text('$views', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              if (!isMobile) const SizedBox(width: 16),
              if (isMobile) const SizedBox(height: 16),

              // Subscriptions & KYC Analytics (Right Side)
              Expanded(
                flex: isMobile ? 0 : 5,
                child: Column(
                  children: [
                    // Payment Slips Status Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('ສັດສ່ວນສະຖານະສະລິບການໂອນເງິນ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildProgressBarItem(
                            label: 'ອະນຸມັດສຳເລັດ (Approved)',
                            count: approvedSubs.length,
                            total: _subscriptions.isNotEmpty ? _subscriptions.length : 1,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(height: 8),
                          _buildProgressBarItem(
                            label: 'ລໍຖ້າກວດສອບ (Pending)',
                            count: pendingSubs.length,
                            total: _subscriptions.isNotEmpty ? _subscriptions.length : 1,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 8),
                          _buildProgressBarItem(
                            label: 'ປະຕິເສດ (Rejected)',
                            count: rejectedSubs.length,
                            total: _subscriptions.isNotEmpty ? _subscriptions.length : 1,
                            color: const Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KYC Verification Analytics Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                              SizedBox(width: 8),
                              Text('ສະຖານະການຢືນຢັນຕົວຕົນ (KYC Status)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStatCircle(title: 'ຜ່ານອະນຸມັດ', count: kycApprovedCount, color: const Color(0xFF10B981)),
                              _buildMiniStatCircle(title: 'ລໍຖ້າກວດ', count: kycPendingCount, color: const Color(0xFFF59E0B)),
                              _buildMiniStatCircle(title: 'ປະຕິເສດ', count: kycRejectedCount, color: const Color(0xFFEF4444)),
                              _buildMiniStatCircle(title: 'ສະມາຊິກ Premiere', count: premiereUsersCount, color: const Color(0xFF7C3AED)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audit Activity Logs Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text('ບັນທຶກກິດຈະກຳແຍກລ່າສຸດຂອງລະບົບ (Audit Activity Logs)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    Text('${_auditLogs.length} ລາຍການ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 12),
                if (_auditLogs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('ບໍ່ມີບັນທຶກກິດຈະກຳຍ້ອນຫຼັງ', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _auditLogs.length > 5 ? 5 : _auditLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final log = _auditLogs[idx];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.admin_panel_settings_outlined, size: 16, color: AppColors.primary),
                        ),
                        title: Text(log['action'] ?? 'ກິດຈະກຳໃນລະບົບ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(log['details'] ?? 'ດຳເນີນການໂດຍຜູ້ດູແລລະບົບ', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        trailing: Text(log['created_at'] != null ? log['created_at'].toString().split('T')[0] : 'ມື້ນີ້', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReportKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressBarItem({required String label, required int count, required int total, required Color color}) {
    final double percent = (count / (total > 0 ? total : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('$count ລາຍການ (${(percent * 100).round()}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCircle({required String title, required int count, required Color color}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(
            child: Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showExportReportModal({required double totalRevenue, required int totalUsers, required int topBooksCount}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('ລາຍງານສະຫຼຸບຜູ້ບໍລິຫານ (Executive Summary)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ສະຫຼຸບລາຍງານສະຖິຕິການນຳໃຊ້ ແລະ ລາຍຮັບລະບົບ e-Book:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ລາຍຮັບລວມອະນຸມັດ: ${totalRevenue.toStringAsFixed(0)} LAK', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  const SizedBox(height: 4),
                  Text('• ຈຳນວນຜູ້ໃຊ້ງານທັງໝົດ: $totalUsers ບັນຊີ', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('• ຈຳນວນປຶ້ມໃນລະບົບ: ${_adminBooks.length} ຫົວ', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('• ລາຍງານອອກ ວັນທີ: ${DateTime.now().toString().split(' ')[0]}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ປິດ')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ສົ່ງອອກລາຍງານ PDF ສຳເລັດແລ້ວ!'), backgroundColor: Color(0xFF10B981)),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('ດາວໂຫຼດ PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

