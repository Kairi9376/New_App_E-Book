import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../services/api_config.dart';
import 'admin_book_dialog.dart';
import '../login_screen.dart';
import '../pdf_viewer_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Books, 1: Users, 2: KYC, 3: Subscriptions, 4: Packages, 5: Logs & Master
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

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  Future<void> _fetchAdminData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        ApiService.getBooks(),
        ApiService.getUsers(),
        ApiService.getKycList(),
        ApiService.getSubscriptions(),
        ApiService.getPackages(),
        ApiService.getCategories(),
        ApiService.getAuthors(),
        ApiService.getAuditLogs(),
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

          _kycSubmissions.clear();
          if (rawKyc.isNotEmpty) {
            _kycSubmissions.addAll(rawKyc.map((k) {
              final statusStr = (k['status'] ?? 'pending').toString();
              KycStatus st = KycStatus.pending;
              if (statusStr == 'approved') st = KycStatus.approved;
              if (statusStr == 'rejected') st = KycStatus.rejected;

              final name = '${k['first_name'] ?? ''} ${k['last_name'] ?? ''}'.trim();
              return KycModel(
                id: (k['kyc_id'] ?? 1).toString(),
                userId: (k['user_id'] ?? 1).toString(),
                userName: name.isNotEmpty ? name : 'ผู้ใช้งาน',
                userEmail: k['email'] ?? '',
                fullName: name.isNotEmpty ? name : 'ผู้ใช้งาน',
                idCardNumber: k['document_number'] ?? 'N/A',
                idCardImagePath: k['document_image_url'] ?? '',
                selfieImagePath: k['selfie_image_url'] ?? '',
                submittedAt: k['created_at'] != null ? DateTime.tryParse(k['created_at']) ?? DateTime.now() : DateTime.now(),
                status: st,
                rejectReason: k['rejection_reason'],
              );
            }));
          } else {
            _kycSubmissions.addAll(MockKycData.submissions);
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
      if (mounted) setState(() => _isLoading = false);
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
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 24),
    );
  }

  // --- Handlers ---
  void _openAddBookDialog() async {
    final newBook = await showDialog<BookModel>(
      context: context,
      builder: (context) => const AdminBookDialog(),
    );
    if (newBook != null && mounted) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ເພີ່ມປຶ້ມ "${newBook.title}" ເຂົ້າຖານຂໍ້ມູນ MySQL ສຳເລັດ'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _openEditBookDialog(BookModel book, int index) async {
    final updatedBook = await showDialog<BookModel>(
      context: context,
      builder: (context) => AdminBookDialog(book: book),
    );
    if (updatedBook != null && mounted) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ແກ້ໄຂຂໍ້ມູນ "${updatedBook.title}" ໃນຖານຂໍ້ມູນ MySQL ຮຽບຮ້ອຍ'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _deleteBook(int index) async {
    final deleted = _adminBooks[index];
    setState(() => _adminBooks.removeAt(index));

    final success = await ApiService.deleteBook(deleted.id);

    if (mounted) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'ລົບປຶ້ມ "${deleted.title}" ຈາກຖານຂໍ້ມູນ MySQL ແລ້ວ' : 'ລົບປຶ້ມ "${deleted.title}" ແລ້ວ'),
        ),
      );
    }
  }

  void _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = int.tryParse(user['user_id']?.toString() ?? user['id']?.toString() ?? '1') ?? 1;
    final currentStatus = (user['status'] ?? 'active').toString().toLowerCase();
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';
    final reasonController = TextEditingController();

    if (currentStatus == 'active') {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('ระงับการใช้งานบัญชี (Suspend Account)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('คุณต้องการระงับบัญชี "${user['email']}" ใช่หรือไม่?'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'เหตุผลการระงับการใช้งาน',
                  hintText: 'เช่น ละเมิดข้อตกลงการใช้งาน...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final success = await ApiService.updateUserStatus(userId, newStatus, reason: reasonController.text.trim());
                if (mounted && success) {
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ระงับบัญชี "${user['email']}" ใน MySQL เรียบร้อย')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text('ยืนยันระงับบัญชี'),
            ),
          ],
        ),
      );
    } else {
      final success = await ApiService.updateUserStatus(userId, 'active');
      if (mounted && success) {
        await _fetchAdminData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ปลดระงับบัญชี "${user['email']}" เรียบร้อย'), backgroundColor: Colors.green),
        );
      }
    }
  }

  void _approveKyc(KycModel item) async {
    final kycId = int.tryParse(item.id) ?? 1;
    await ApiService.updateKycStatus(kycId, 'approved', reviewedBy: 1);

    if (mounted) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ອະນຸມັດ KYC ຂອງ "${item.userName}" เรียบร้อย'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  void _approveSubscription(Map<String, dynamic> sub) async {
    final subId = sub['subscription_id'] ?? 1;
    final success = await ApiService.updateSubscriptionStatus(subId, 'active');
    if (mounted && success) {
      await _fetchAdminData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อนุมัติสลิปโอนเงินสำเร็จ! เปิดใช้งานแพ็กเกจสมาชิกเรียบร้อย'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  void _rejectSubscription(Map<String, dynamic> sub) async {
    final subId = sub['subscription_id'] ?? 1;
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ปฏิเสธสลิปการโอนเงิน'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'ระบุเหตุผลการปฏิเสธ (เช่น ยอดเงินไม่ตรง)...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.updateSubscriptionStatus(subId, 'rejected', reason: reasonController.text.trim());
              if (mounted && success) {
                await _fetchAdminData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ปฏิเสธรายการโอนเงินเรียบร้อย'), backgroundColor: Colors.redAccent),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ยืนยันปฏิเสธ'),
          ),
        ],
      ),
    );
  }

  void _openCreatePackageDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController(text: '30');
    bool isStudent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('เพิ่มแพ็กเกจสมาชิกใหม่ (Create Package)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อแพ็กเกจ')),
                const SizedBox(height: 8),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'รายละเอียด')),
                const SizedBox(height: 8),
                TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ราคา (LAK / กีบ)')),
                const SizedBox(height: 8),
                TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ระยะเวลา (วัน)')),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('แพ็กเกจพิเศษสำหรับนักเรียน (Student Pro)'),
                  value: isStudent,
                  onChanged: (val) => setDlgState(() => isStudent = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0;
                final duration = int.tryParse(durationCtrl.text.trim()) ?? 30;

                if (name.isNotEmpty && price > 0) {
                  Navigator.pop(ctx);
                  final success = await ApiService.createPackage({
                    'name': name,
                    'description': descCtrl.text.trim(),
                    'price': price,
                    'duration_days': duration,
                    'is_for_student': isStudent
                  });

                  if (mounted && success) {
                    await _fetchAdminData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('สร้างแพ็กเกจ "$name" ลง MySQL สำเร็จ'), backgroundColor: AppColors.primary),
                    );
                  }
                }
              },
              child: const Text('บันทึกแพ็กเกจ'),
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
        title: const Text('เพิ่มรายชื่อนักเขียนใหม่ (Add Author)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อนักเขียน')),
            const SizedBox(height: 8),
            TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ประวัติย่อ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.createAuthor(name, bio: bioCtrl.text.trim());
                if (mounted && success) {
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('เพิ่มนักเขียน "$name" เรียบร้อย'), backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // --- DETAIL INSPECTOR MODALS FOR ALL DATA ITEMS ---

  void _openPdfViewer(BookModel book) {
    String pdfUrl = book.pdfUrl ?? '';
    if (pdfUrl.isEmpty || pdfUrl == 'assets/sample_book.pdf') {
      pdfUrl = '${ApiConfig.uploadsBaseUrl}/sample_book.pdf';
    } else if (!pdfUrl.startsWith('http://') && !pdfUrl.startsWith('https://')) {
      if (pdfUrl.startsWith('uploads/') || pdfUrl.startsWith('/uploads/')) {
        pdfUrl = '${ApiConfig.uploadsBaseUrl}/${pdfUrl.replaceAll(RegExp(r'^/?uploads/'), '')}';
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          pdfUrl: pdfUrl,
          bookTitle: book.title,
          author: book.author,
          description: book.description,
        ),
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
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: book.tags.map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            const Text('ເນື້ອເລື່ອງ / ລາຍລະອຽດ:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 4),
            Text(book.description ?? 'ບໍ່ມີເນື້ອເລື່ອງ', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      book.pdfUrl != null && book.pdfUrl!.isNotEmpty ? book.pdfUrl! : 'ບໍ່ໄດ້ແນບໄຟລ໌ PDF',
                      style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // PDF Reader Button
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
                  backgroundColor: const Color(0xFF6366F1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openEditBookDialog(book, index);
                    },
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('ແກ້ໄຂປຶ້ມ'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteBook(index);
                    },
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('ລົບປຶ້ມ', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
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
                  radius: 28,
                  backgroundColor: user['role'] == 'Admin' ? Colors.purple : AppColors.primary,
                  child: Text((user['first_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(user['email'] ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Text('สิทธิ์การใช้งาน: ${user['role']}'),
            const SizedBox(height: 6),
            Text('สถานะบัญชี: ${isSuspended ? "ระงับการใช้งาน (Suspended)" : "ปกติ (Active)"}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _toggleUserStatus(user);
                },
                style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.redAccent),
                child: Text(isSuspended ? 'ปลดระงับบัญชี' : 'ระงับการใช้งานบัญชี'),
              ),
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
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('รายละเอียดคำขอยืนยันตัวตน (KYC Details)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('ชื่อผู้ใช้: ${item.userName} (${item.userEmail})'),
              Text('เลขบัตรประจำตัว: ${item.idCardNumber}'),
              Text('สถานะปัจจุบัน: ${item.statusText}'),
              const Divider(height: 20),
              const Text('รูปถ่ายบัตรประจำตัว / พาสปอร์ต / บัตรนักเรียน:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(height: 180, width: double.infinity, child: _buildImage(item.idCardImagePath)),
              ),
              const SizedBox(height: 16),
              const Text('รูปถ่ายคู่กับเอกสาร (Selfie Preview):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(height: 180, width: double.infinity, child: _buildImage(item.selfieImagePath)),
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
                        child: const Text('อนุมัติ KYC'),
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
                        child: const Text('ปฏิเสธ'),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('รายละเอียดสลิปโอนเงิน (Payment Slip Inspector)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('ผู้แจ้งชำระ: ${sub['first_name'] ?? ""} ${sub['last_name'] ?? ""} (${sub['email'] ?? ""})'),
              Text('แพ็กเกจสมาชิก: ${sub['package_name'] ?? "VIP Package"}'),
              Text('ยอดชำระ: ${sub['amount']} LAK'),
              Text('สถานะการชำระเงิน: ${status.toUpperCase()}'),
              const Divider(height: 20),
              const Text('รูปภาพสลิปโอนเงิน:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(height: 250, width: double.infinity, child: _buildImage(sub['slip_image_url'] ?? '')),
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
                        child: const Text('อนุมัติการชำระเงิน'),
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
                        child: const Text('ปฏิเสธสลิป'),
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
                Icon(isStudentPkg ? Icons.school_rounded : Icons.workspace_premium_rounded, color: isStudentPkg ? Colors.orange : Colors.purple, size: 36),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pkg['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('ราคา: ${pkg['price']} LAK | ระยะเวลา: ${pkg['duration_days']} วัน', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Text('รายละเอียดแพ็กเกจ: ${pkg['description'] ?? "เข้าถึง e-Book ทั้งหมด"}'),
            const SizedBox(height: 8),
            Text('ประเภทแพ็กเกจ: ${isStudentPkg ? "แพ็กเกจราคาพิเศษสำหรับนักเรียน/นักศึกษา" : "แพ็กเกจบุคคลทั่วไป"}'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ปิดหน้าต่าง'),
              ),
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
            Row(
              children: const [
                Icon(Icons.security_rounded, color: Colors.indigo, size: 28),
                SizedBox(width: 10),
                Text('รายละเอียดบันทึกความปลอดภัย (Audit Log)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20),
            Text('ผู้ทำรายการ: ${log['first_name'] ?? ""} (${log['email'] ?? ""})'),
            Text('สิทธิ์ผู้ทำรายการ: ${log['role'] ?? ""}'),
            Text('คำสั่งที่ดำเนินการ: ${log['action'] ?? ""}'),
            Text('IP Address: ${log['ip_address'] ?? "127.0.0.1"}'),
            Text('เวลาที่ทำรายการ: ${log['created_at'] ?? "N/A"}'),
            const SizedBox(height: 10),
            Text('รายละเอียดเพิ่มเติม: ${log['details'] ?? "ไม่มี"}', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ปิดหน้าต่าง'),
              ),
            ),
          ],
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('ระบบผู้ดูแลระบบ (Admin Master Control)', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                Text('ความปลอดภัย การเงิน และสิทธิ์การใช้งานระบบ', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.primary), onPressed: _fetchAdminData, tooltip: 'รีเฟรชข้อมูล'),
          IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout, tooltip: 'ออกจากระบบ'),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Nav Bar
                Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        _buildNavTab(0, Icons.menu_book_rounded, 'คลังหนังสือ'),
                        _buildNavTab(1, Icons.people_alt_rounded, 'จัดการผู้ใช้/พนักงาน'),
                        _buildNavTab(2, Icons.verified_user_rounded, 'อนุมัติ KYC & นักเรียน'),
                        _buildNavTab(3, Icons.receipt_long_rounded, 'อนุมัติสลิปโอนเงิน'),
                        _buildNavTab(4, Icons.card_membership_rounded, 'แพ็กเกจสมาชิก'),
                        _buildNavTab(5, Icons.security_rounded, 'ระบบ & Logs'),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),

                // Content Tab Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IndexedStack(
                      index: _selectedTab,
                      children: [
                        _buildBookManagementTab(),
                        _buildUserManagementTab(),
                        _buildKycApprovalTab(),
                        _buildSubscriptionApprovalTab(),
                        _buildPackagesTab(),
                        _buildMasterDataAndLogsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavTab(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : AppColors.textSecondary),
        label: Text(label),
        selected: isSelected,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 13),
        onSelected: (val) {
          if (val) setState(() => _selectedTab = index);
        },
      ),
    );
  }

  // --- TAB 0: BOOKS MANAGEMENT ---
  Widget _buildBookManagementTab() {
    final filtered = _adminBooks.where((b) {
      final matchesSearch = b.title.toLowerCase().contains(_searchQuery.toLowerCase()) || b.author.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ค้นหาหนังสือ หรือชื่อผู้แต่ง...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _openAddBookDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('เพิ่มหนังสือใหม่', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('ไม่พบรายการหนังสือ'))
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final book = filtered[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _showBookDetailModal(book, idx),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: SizedBox(width: 45, height: 60, child: _buildImage(book.imagePath)),
                        ),
                        title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('ผู้แต่ง: ${book.author} | หมวดหมู่: ${book.tags.isNotEmpty ? book.tags.first : "ทั่วไป"}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _openEditBookDialog(book, idx)),
                            IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteBook(idx)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 1: USER MANAGEMENT ---
  Widget _buildUserManagementTab() {
    final filtered = _adminUsers.where((u) {
      final role = (u['role'] ?? '').toString();
      final matchesRole = _userRoleFilter == 'ທັງໝົດ' || role.toLowerCase() == _userRoleFilter.toLowerCase();
      final name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''} ${u['email'] ?? ''}'.toLowerCase();
      final matchesSearch = name.contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'ค้นหาชื่อ หรืออีเมลผู้ใช้งาน...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _userRoleFilter,
              items: ['ທັງໝົດ', 'Admin', 'Employee', 'User'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
              onChanged: (val) => setState(() => _userRoleFilter = val!),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (ctx, idx) {
              final user = filtered[idx];
              final status = (user['status'] ?? 'active').toString().toLowerCase();
              final isSuspended = status == 'suspended' || status == 'banned';
              final role = (user['role'] ?? 'user').toString();

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _showUserDetailModal(user),
                  leading: CircleAvatar(
                    backgroundColor: role == 'admin' ? Colors.purple : (role == 'employee' ? Colors.orange : AppColors.primary),
                    child: Text((user['first_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(
                    children: [
                      Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: role == 'admin' ? Colors.purple.shade100 : Colors.blue.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.purple : Colors.blue)),
                      ),
                    ],
                  ),
                  subtitle: Text('อีเมล: ${user['email']} | สถานะ: ${isSuspended ? "ระงับการใช้งาน" : "ปกติ"}'),
                  trailing: ElevatedButton(
                    onPressed: () => _toggleUserStatus(user),
                    style: ElevatedButton.styleFrom(backgroundColor: isSuspended ? Colors.green : Colors.redAccent),
                    child: Text(isSuspended ? 'ปลดระงับ' : 'ระงับบัญชี', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: KYC APPROVAL ---
  Widget _buildKycApprovalTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รายการขออนุมัติตัวตน (KYC & Student Verifications)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<String>(
              value: _kycFilterStatus,
              items: ['ທັງໝົດ', 'ລໍຖ້າອະນຸມັດ', 'ອະນຸມັດແລ້ວ', 'ບໍ່ອະນຸມັດ'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _kycFilterStatus = val!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _kycSubmissions.isEmpty
              ? const Center(child: Text('ไม่มีรายการ KYC'))
              : ListView.builder(
                  itemCount: _kycSubmissions.length,
                  itemBuilder: (ctx, idx) {
                    final item = _kycSubmissions[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _showKycDetailModal(item),
                        leading: const Icon(Icons.badge_rounded, color: AppColors.primary, size: 36),
                        title: Text('${item.userName} (${item.userEmail})', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('เลขบัตร: ${item.idCardNumber} | สถานะ: ${item.statusText}'),
                        trailing: item.status == KycStatus.pending
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.check_circle_rounded, color: Colors.green), onPressed: () => _approveKyc(item)),
                                  IconButton(icon: const Icon(Icons.cancel_rounded, color: Colors.redAccent), onPressed: () => _showRejectKycDialog(item)),
                                ],
                              )
                            : Chip(label: Text(item.statusText), backgroundColor: item.status == KycStatus.approved ? Colors.green.shade100 : Colors.red.shade100),
                      ),
                    );
                  },
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
        title: Text('ปฏิเสธ KYC: ${item.userName}'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(hintText: 'ระบุเหตุผลที่ไม่อนุมัติ...')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final kycId = int.tryParse(item.id) ?? 1;
              await ApiService.updateKycStatus(kycId, 'rejected', rejectionReason: reasonCtrl.text.trim());
              await _fetchAdminData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ยืนยันปฏิเสธ'),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: SUBSCRIPTION SLIP APPROVAL ---
  Widget _buildSubscriptionApprovalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('รายการแจ้งชำระเงินค่าสมัครสมาชิก (Slip Verification)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            DropdownButton<String>(
              value: _subFilterStatus,
              items: ['ທັງໝົດ', 'pending', 'active', 'rejected'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => _subFilterStatus = val!),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _subscriptions.isEmpty
              ? const Center(child: Text('ไม่มีรายการสลิปการโอนเงิน'))
              : ListView.builder(
                  itemCount: _subscriptions.length,
                  itemBuilder: (ctx, idx) {
                    final sub = _subscriptions[idx];
                    final status = (sub['payment_status'] ?? 'pending').toString();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _showSubscriptionDetailModal(sub),
                        leading: const Icon(Icons.receipt_long_rounded, color: AppColors.primary, size: 36),
                        title: Text('ผู้ใช้: ${sub['first_name'] ?? ""} ${sub['last_name'] ?? ""} (${sub['email'] ?? ""})'),
                        subtitle: Text('แพ็กเกจ: ${sub['package_name'] ?? "VIP"} | ยอดชำระ: ${sub['amount']} LAK | สถานะ: ${status.toUpperCase()}'),
                        trailing: status == 'pending'
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _approveSubscription(sub),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: const Text('อนุมัติสลิป', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(icon: const Icon(Icons.close_rounded, color: Colors.redAccent), onPressed: () => _rejectSubscription(sub)),
                                ],
                              )
                            : Chip(label: Text(status.toUpperCase()), backgroundColor: status == 'active' ? Colors.green.shade100 : Colors.red.shade100),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 4: PACKAGES MANAGEMENT ---
  Widget _buildPackagesTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('จัดการแพ็กเกจสมาชิก (Subscription Packages)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ElevatedButton.icon(
              onPressed: _openCreatePackageDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('สร้างแพ็กเกจใหม่', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _packages.length,
            itemBuilder: (ctx, idx) {
              final pkg = _packages[idx];
              final isStudentPkg = pkg['is_for_student'] == 1 || pkg['is_for_student'] == true;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _showPackageDetailModal(pkg),
                  leading: Icon(isStudentPkg ? Icons.school_rounded : Icons.workspace_premium_rounded, color: isStudentPkg ? Colors.orange : Colors.purple, size: 36),
                  title: Row(
                    children: [
                      Text(pkg['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (isStudentPkg)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(6)),
                          child: const Text('นักเรียน/นักศึกษา', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle: Text('${pkg['description'] ?? ''}\nราคา: ${pkg['price']} LAK | ระยะเวลา: ${pkg['duration_days']} วัน'),
                  isThreeLine: true,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 5: MASTER DATA & LOGS ---
  Widget _buildMasterDataAndLogsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categories Section (from DB: categories table)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ໝວດໝູ່ປຶ້ມ (Master Categories - MySQL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
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
                              label: Text('$catName (ID: $catId)', style: const TextStyle(fontSize: 12)),
                              backgroundColor: Colors.blue.shade50,
                            );
                          }).toList(),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Authors Section (full CRUD: edit + delete)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ລາຍຊື່ນັກຂຽນ (Authors - MySQL)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ElevatedButton.icon(
                        onPressed: _openCreateAuthorDialog,
                        icon: const Icon(Icons.person_add_rounded, size: 16),
                        label: const Text('ເພີ່ມນັກຂຽນ', style: TextStyle(fontSize: 12)),
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
                              title: Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(authorBio.isNotEmpty ? authorBio : 'ບໍ່ມີປະຫວັດ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent, size: 20),
                                    onPressed: () => _openEditAuthorDialog(authorId, authorName, authorBio),
                                    tooltip: 'ແກ້ໄຂນັກຂຽນ',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => _confirmDeleteAuthor(authorId, authorName),
                                    tooltip: 'ລົບນັກຂຽນ',
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
          const SizedBox(height: 12),

          // Security Audit Logs Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.security_rounded, color: Colors.indigo, size: 20),
                      SizedBox(width: 8),
                      Text('ປະຫວັດການເຮັດວຽກ (Security Audit Logs)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _auditLogs.isEmpty
                      ? const Padding(padding: EdgeInsets.all(16), child: Text('ບໍ່ມີບັນທຶກ Audit Logs'))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _auditLogs.length > 10 ? 10 : _auditLogs.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final log = _auditLogs[idx];
                            return ListTile(
                              dense: true,
                              onTap: () => _showAuditLogDetailModal(log),
                              title: Text('${log['first_name'] ?? "User"} (${log['role'] ?? ""}): ${log['action']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('IP: ${log['ip_address'] ?? "127.0.0.1"} | ລາຍລະອຽດ: ${log['details'] ?? "N/A"}'),
                              trailing: Text(log['created_at'] != null ? log['created_at'].toString().split('T')[0] : '', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                if (mounted) {
                  if (success) {
                    await _fetchAdminData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('ແກ້ໄຂນັກຂຽນ "$name" ສຳເລັດ'), backgroundColor: AppColors.primary),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ແກ້ໄຂນັກຂຽນບໍ່ສຳເລັດ'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              }
            },
            child: const Text('ບັນທຶກການແກ້ໄຂ'),
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
        title: const Text('ຢືນຢັນການລົບນັກຂຽນ'),
        content: Text('ທ່ານຕ້ອງການລົບນັກຂຽນ "$authorName" ຈາກຖານຂໍ້ມູນ MySQL ແທ້ບໍ?\n\nໝາຍເຫດ: ປຶ້ມທີ່ເຊື່ອມໂຍງກັບນັກຂຽນນີ້ຈະຖືກປ່ຽນເປັນ "ບໍ່ລະບຸ"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ApiService.deleteAuthor(authorId);
              if (mounted) {
                if (success) {
                  await _fetchAdminData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ລົບນັກຂຽນ "$authorName" ສຳເລັດ'), backgroundColor: AppColors.primary),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ລົບນັກຂຽນບໍ່ສຳເລັດ (ອາດມີປຶ້ມເຊື່ອມໂຍງຢູ່)'), backgroundColor: Colors.redAccent),
                  );
                }
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




