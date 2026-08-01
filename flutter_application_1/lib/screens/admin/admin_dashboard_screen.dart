import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/kyc_model.dart';
import 'admin_book_dialog.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Books, 1: KYC Approval, 2: Users, 3: Master Data & Settings, 4: Analytics
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ທັງໝົດ';
  String _kycFilterStatus = 'ທັງໝົດ'; // ທັງໝົດ, ລໍຖ້າອະນຸມັດ, ອະນຸມັດແລ້ວ, ບໍ່ອະນຸມັດ

  final List<BookModel> _adminBooks = [
    ...MockBookData.popularBooks,
    ...MockBookData.newBooks,
    ...MockBookData.recommendedBooks,
  ];

  final List<KycModel> _kycSubmissions = [...MockKycData.submissions];

  final List<String> _masterCategories = [
    'ເຕັກໂນໂລຊີ',
    'ບໍລິຫານທຸລະກິດ',
    'ວິທະຍາສາດ',
    'ປະຫວັດສາດ',
    'ນວນນິຍາຍ & ວັນນະກຳ',
    'ການພັດທະນາຕົນເອງ',
  ];

  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'u1',
      'name': 'Somchai ໃຈດີ',
      'email': 'user1234@gmail.com',
      'role': 'User',
      'isPremiere': false,
      'status': 'Active',
      'kycStatus': KycStatus.pending,
    },
    {
      'id': 'u2',
      'name': 'ພຣີມ່ຽມ ສະມາຊິກ',
      'email': 'member@gmail.com',
      'role': 'User',
      'isPremiere': true,
      'status': 'Active',
      'kycStatus': KycStatus.approved,
    },
    {
      'id': 'u3',
      'name': 'Somchai Staff',
      'email': 'employee@gmail.com',
      'role': 'Employee',
      'isPremiere': false,
      'status': 'Active',
      'kycStatus': KycStatus.approved,
    },
    {
      'id': 'u4',
      'name': 'Admin Master',
      'email': 'admin@gmail.com',
      'role': 'Admin',
      'isPremiere': true,
      'status': 'Active',
      'kycStatus': KycStatus.approved,
    },
  ];

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

  void _openAddBookDialog() async {
    final newBook = await showDialog<BookModel>(
      context: context,
      builder: (context) => const AdminBookDialog(),
    );
    if (newBook != null) {
      setState(() {
        _adminBooks.insert(0, newBook);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ເພີ່ມປຶ້ມ "${newBook.title}" ສຳເລັດ'),
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
    if (updatedBook != null) {
      setState(() {
        _adminBooks[index] = updatedBook;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ແກ້ໄຂຂໍ້ມູນ "${updatedBook.title}" ຮຽບຮ້ອຍ'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _deleteBook(int index) {
    final deleted = _adminBooks[index];
    setState(() {
      _adminBooks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ລົບປຶ້ມ "${deleted.title}" ແລ້ວ'),
        action: SnackBarAction(
          label: 'ຍົກເລີກ',
          onPressed: () {
            setState(() {
              _adminBooks.insert(index, deleted);
            });
          },
        ),
      ),
    );
  }

  void _approveKyc(KycModel item) {
    setState(() {
      final index = _kycSubmissions.indexWhere((element) => element.id == item.id);
      if (index != -1) {
        _kycSubmissions[index] = item.copyWith(
          status: KycStatus.approved,
          reviewedAt: DateTime.now(),
          rejectReason: null,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ອະນຸມັດການຢືນຢັນຕົວຕົນ (KYC) ຂອງ "${item.userName}" ຮຽບຮ້ອຍແລ້ວ'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  void _showRejectKycDialog(KycModel item) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 26),
            const SizedBox(width: 8),
            Text('ບໍ່ອະນຸມັດ KYC: ${item.userName}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ກະລຸນາລະບຸເຫດຜົນທີ່ບໍ່ຜ່ານການອະນຸມັດ (ຈະສົ່ງໃຫ້ຜູ້ໃຊ້ແກ້ໄຂ):', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'ຕົວຢ່າງ: ຮູບຖ່າຍບັດປະຈຳຕົວບໍ່ຈະແຈ້ງ ຫຼື ເລກບັດບໍ່ກົງກັບເອກະສານ...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim().isEmpty
                  ? 'ຂໍ້ມູນ ຫຼື ຮູບຖ່າຍເອກະສານບໍ່ກົງຕາມຂໍ້ ກຳນົດ ກະລຸນາແນບໃໝ່'
                  : reasonController.text.trim();
              Navigator.pop(ctx);
              setState(() {
                final index = _kycSubmissions.indexWhere((e) => e.id == item.id);
                if (index != -1) {
                  _kycSubmissions[index] = item.copyWith(
                    status: KycStatus.rejected,
                    rejectReason: reason,
                    reviewedAt: DateTime.now(),
                  );
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ປະຕິເສດການຍື່ນ KYC ຂອງ "${item.userName}" ຮຽບຮ້ອຍ'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('ຢືນຢັນບໍ່ອະນຸມັດ'),
          ),
        ],
      ),
    );
  }

  void _showReviewKycModal(KycModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'ກວດສອບເອກະສານຢືນຢັນຕົວຕົນ (KYC Proof)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('ຊື່ຜູ້ໃຊ້ງານ:', item.userName),
                    _buildDetailRow('ອີເມວ:', item.userEmail),
                    _buildDetailRow('ຊື່-ນາມສະກຸນ ບົນບັດ:', item.fullName),
                    _buildDetailRow('ເລກບັດປະຈຳຕົວ 13 ຫຼັກ:', item.idCardNumber),
                    _buildDetailRow('ສະຖານະປັດຈຸບັນ:', item.statusText),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('1. ຮູບຖ່າຍໜ້າບັດປະຈຳຕົວ (Front ID Card):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.credit_card_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('ເອກະສານຮູບພາບບັດປະຈຳຕົວ (${item.idCardNumber})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('ສະຖານະຮູບຖ່າຍ: ຈະແຈ້ງ ແລະ ອ່ານອອກໄດ້ງ່າຍ', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text('2. ຮູບຖ່າຍເຊວຟີຄູ່ກັບບັດປະຈຳຕົວ (Selfie Proof):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.face_retouching_natural_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: 8),
                    Text('ຮູບຖ່າຍເຊວຟີໃບໜ້າຄູ່ບັດປະຈຳຕົວ (${item.userName})', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('ສະຖານະຮູບຖ່າຍ: ໃບໜ້າກົງກັບບັດປະຈຳຕົວ', style: TextStyle(fontSize: 12, color: Color(0xFF047857))),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (item.status == KycStatus.pending) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRejectKycDialog(item);
                        },
                        icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
                        label: const Text('ບໍ່ອະນຸມັດ (Reject)', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveKyc(item);
                        },
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: const Text('ອະນຸມັດຜ່ານ KYC (Approve)', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingKycCount = _kycSubmissions.where((e) => e.status == KycStatus.pending).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Admin Portal & Master Control',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'ຜູ້ດູແລລະບົບ',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'ອອກຈາກລະບົບ',
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMetricSummaryRow(pendingKycCount),
            _buildTabSegmentBar(pendingKycCount),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: _buildTabBodyContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricSummaryRow(int pendingKycCount) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          _buildMetricCard('ປຶ້ມທັງໝົດ', '${_adminBooks.length}', Icons.menu_book_rounded, Colors.blue),
          const SizedBox(width: 8),
          _buildMetricCard('ລໍຖ້າອະນຸມັດ KYC', '$pendingKycCount ລາຍການ', Icons.pending_actions_rounded, Colors.amber),
          const SizedBox(width: 8),
          _buildMetricCard('ຜູ້ໃຊ້ທັງໝົດ', '${_mockUsers.length}', Icons.people_alt_rounded, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSegmentBar(int pendingKycCount) {
    final tabs = [
      {'label': 'ຈັດການປຶ້ມ', 'icon': Icons.book_rounded},
      {'label': 'ອະນຸມັດ KYC', 'icon': Icons.verified_user_rounded, 'badge': pendingKycCount > 0 ? '$pendingKycCount' : null},
      {'label': 'ຈັດການຜູ້ໃຊ້', 'icon': Icons.people_outline_rounded},
      {'label': 'ຂໍ້ມູນພື້ນຖານ', 'icon': Icons.tune_rounded},
      {'label': 'ລາຍງານ & ສະຖິຕິ', 'icon': Icons.bar_chart_rounded},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          final item = tabs[index];
          final badge = item['badge'] as String?;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (badge != null)
                      Positioned(
                        top: -4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabBodyContent() {
    switch (_selectedTab) {
      case 0:
        return _buildBookManagementTab();
      case 1:
        return _buildKycApprovalTab();
      case 2:
        return _buildUserManagementTab();
      case 3:
        return _buildMasterDataSettingsTab();
      case 4:
        return _buildAnalyticsTab();
      default:
        return _buildBookManagementTab();
    }
  }

  Widget _buildBookManagementTab() {
    final filteredBooks = _adminBooks.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'ທັງໝົດ' ||
          (book.tags.isNotEmpty && book.tags.first == _selectedCategoryFilter);
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາປຶ້ມ ຫຼື ຊື່ຜູ້ແຕ່ງ...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openAddBookDialog,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('ເພີ່ມປຶ້ມໃໝ່', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(110, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: filteredBooks.isEmpty
              ? const Center(child: Text('ບໍ່ພົບຂໍ້ມູນປຶ້ມ', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: filteredBooks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _buildAdminBookCard(filteredBooks[index], index),
                ),
        ),
      ],
    );
  }

  Widget _buildAdminBookCard(BookModel book, int index) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(book.imagePath, width: 45, height: 60),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text(book.author, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    book.tags.isNotEmpty ? book.tags.first : 'ທົ່ວໄປ',
                    style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
            onPressed: () => _openEditBookDialog(book, index),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteBook(index),
          ),
        ],
      ),
    );
  }

  Widget _buildKycApprovalTab() {
    final filteredKyc = _kycSubmissions.where((item) {
      if (_kycFilterStatus == 'ລໍຖ້າອະນຸມັດ') return item.status == KycStatus.pending;
      if (_kycFilterStatus == 'ອະນຸມັດແລ້ວ') return item.status == KycStatus.approved;
      if (_kycFilterStatus == 'ບໍ່ອະນຸມັດ') return item.status == KycStatus.rejected;
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['ທັງໝົດ', 'ລໍຖ້າອະນຸມັດ', 'ອະນຸມັດແລ້ວ', 'ບໍ່ອະນຸມັດ'].map((statusLabel) {
              final isSel = _kycFilterStatus == statusLabel;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(statusLabel),
                  selected: isSel,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSel ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) => setState(() => _kycFilterStatus = statusLabel),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),

        Expanded(
          child: filteredKyc.isEmpty
              ? const Center(child: Text('ບໍ່ພົບລາຍການຍື່ນອະນຸມັດ KYC', style: TextStyle(color: AppColors.textSecondary)))
              : ListView.separated(
                  itemCount: filteredKyc.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = filteredKyc[index];
                    return _buildKycSubmissionCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildKycSubmissionCard(KycModel item) {
    Color badgeBg;
    Color badgeText;
    IconData statusIcon;

    switch (item.status) {
      case KycStatus.approved:
        badgeBg = const Color(0xFFECFDF5);
        badgeText = const Color(0xFF065F46);
        statusIcon = Icons.check_circle_rounded;
        break;
      case KycStatus.pending:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFF92400E);
        statusIcon = Icons.pending_actions_rounded;
        break;
      case KycStatus.rejected:
        badgeBg = const Color(0xFFFEF2F2);
        badgeText = const Color(0xFF991B1B);
        statusIcon = Icons.cancel_rounded;
        break;
      case KycStatus.notSubmitted:
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = AppColors.textSecondary;
        statusIcon = Icons.help_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      item.userName.isNotEmpty ? item.userName[0] : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.userName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(item.userEmail, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(statusIcon, size: 14, color: badgeText),
                    const SizedBox(width: 4),
                    Text(item.statusText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeText)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ເລກບັດປະຈຳຕົວ: ${item.idCardNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text('ຍື່ນເມື່ອ: ${item.submittedAt.hour}:${item.submittedAt.minute.toString().padLeft(2, '0')} ນ.', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          if (item.rejectReason != null) ...[
            const SizedBox(height: 6),
            Text('ເຫດຜົນທີ່ບໍ່ອະນຸມັດ: ${item.rejectReason}', style: const TextStyle(fontSize: 11, color: Colors.redAccent)),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showReviewKycModal(item),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                  label: const Text('ເບິ່ງຫຼັກຖານເອກະສານ', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              if (item.status == KycStatus.pending) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveKyc(item),
                    icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                    label: const Text('ອະນຸມັດທັນທີ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ລາຍການຜູ້ໃຊ້ງານທັງໝົດໃນລະບົບ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: _mockUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final user = _mockUsers[index];
              final KycStatus userKyc = user['kycStatus'] as KycStatus;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(user['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(user['email'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: userKyc == KycStatus.approved ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  userKyc == KycStatus.approved ? 'ຜ່ານ KYC ແລ້ວ' : 'ຍັງບໍ່ຜ່ານ KYC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: userKyc == KycStatus.approved ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: user['role'] == 'Admin'
                            ? Colors.purple.shade50
                            : user['role'] == 'Employee'
                                ? Colors.orange.shade50
                                : const Color(0xFFE2EDFF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user['role'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: user['role'] == 'Admin'
                              ? Colors.purple
                              : user['role'] == 'Employee'
                                  ? Colors.orange.shade800
                                  : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMasterDataSettingsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Text('ຈັດການໝວດໝູ່ປຶ້ມ (Master Categories)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                      onPressed: () {
                        final catController = TextEditingController();
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('ເພີ່ມໝວດໝູ່ໃໝ່'),
                            content: TextField(
                              controller: catController,
                              decoration: const InputDecoration(hintText: 'ຊື່ໝວດໝູ່ປຶ້ມ...'),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
                              ElevatedButton(
                                onPressed: () {
                                  if (catController.text.trim().isNotEmpty) {
                                    setState(() => _masterCategories.add(catController.text.trim()));
                                    Navigator.pop(ctx);
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _masterCategories.map((cat) {
                    return Chip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () {
                        setState(() => _masterCategories.remove(cat));
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded, color: Color(0xFFF59E0B), size: 20),
                    const SizedBox(width: 8),
                    const Text('ຕັ້ງຄ່າລາຄາແພັກເກັດສະມາຊິກ (Subscription Pricing)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPriceSettingTile('ແພັກເກັດພຣີມ່ຽມລາຍເດືອນ (Monthly)', '199,000 ກີບ / ເດືອນ'),
                _buildPriceSettingTile('ແພັກເກັດພຣີມ່ຽມລາຍປີ (Yearly)', '1,890,000 ກີບ / ປີ'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ຕັ້ງຄ່າຄວາມປອດໄພ & ນະໂຍບາຍ KYC', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('ບັງຄັບຜ່ານ KYC ກ່ອນສະໝັກສະມາຊິກ (Force KYC)'),
                  subtitle: const Text('ຜູ້ໃຊ້ทุกคนต้องได้รับการอนุมัติบัตรประชาชนก่อนซื้อแพ็กเกจ'),
                  value: true,
                  activeColor: AppColors.primary,
                  onChanged: (val) {},
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text('ໂໝດປັບປຸງລະບົບ (Maintenance Mode)'),
                  subtitle: const Text('ປິດບໍລິການຊົ່ວຄາວເພື່ອອັບເດດລະບົບ'),
                  value: false,
                  activeColor: AppColors.primary,
                  onChanged: (val) {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSettingTile(String title, String currentPrice) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      subtitle: Text(currentPrice, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
      trailing: OutlinedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ເປີດຟອມແກ້ໄຂລາຄາແພັກເກັດ')),
          );
        },
        child: const Text('ແກ້ໄຂລາຄາ', style: TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ລາຍງານສະຖິຕິການໃຊ້ງານລະບົບ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ໝວດໝູ່ປຶ້ມຍອດນິຍົມ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildAnalyticsCategoryItem('ເຕັກໂນໂລຊີ & ຄອມພິວເຕີ', 0.85, '85%'),
                _buildAnalyticsCategoryItem('ບໍລິຫານທຸລະກິດ & ການເງິນ', 0.70, '70%'),
                _buildAnalyticsCategoryItem('ນວນນິຍາຍ & ວັນນະກຳ', 0.60, '60%'),
                _buildAnalyticsCategoryItem('ການພັດທະນາຕົນເອງ', 0.45, '45%'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCategoryItem(String name, double percent, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
