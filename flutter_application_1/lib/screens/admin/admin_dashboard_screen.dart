import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import 'admin_book_dialog.dart';
import '../employee/add_book_screen.dart';
import '../login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedTab = 0; // 0: Books, 1: Users, 2: Analytics, 3: Settings
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ทั้งหมด';

  final List<BookModel> _adminBooks = [
    ...MockBookData.popularBooks,
    ...MockBookData.newBooks,
    ...MockBookData.recommendedBooks,
  ];

  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': 'u1',
      'name': 'John Johnny',
      'email': 'john@example.com',
      'role': 'User',
      'isPremiere': true,
      'status': 'Active',
    },
    {
      'id': 'u2',
      'name': 'Somchai Manager',
      'email': 'somchai@ebook.com',
      'role': 'Employee',
      'isPremiere': false,
      'status': 'Active',
    },
    {
      'id': 'u3',
      'name': 'Admin Master',
      'email': 'admin@ebook.com',
      'role': 'Admin',
      'isPremiere': true,
      'status': 'Active',
    },
    {
      'id': 'u4',
      'name': 'Anousone Vong',
      'email': 'anousone@example.com',
      'role': 'User',
      'isPremiere': false,
      'status': 'Active',
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
          content: Text('เพิ่มหนังสือ "${newBook.title}" สำเร็จ'),
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
          content: Text('แก้ไขข้อมูล "${updatedBook.title}" เรียบร้อย'),
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
        content: Text('ลบหนังสือ "${deleted.title}" แล้ว'),
        action: SnackBarAction(
          label: 'เลิกทำ',
          onPressed: () {
            setState(() {
              _adminBooks.insert(index, deleted);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              'Admin Portal',
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
                'ผู้ดูแลระบบ',
                style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            tooltip: 'ออกจากระบบ',
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
            // Top Metric Summary Cards
            _buildMetricSummaryRow(),

            // Tab Navigation Segment Bar
            _buildTabSegmentBar(),

            // Tab View Body
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

  // --- Summary Metric Cards ---
  Widget _buildMetricSummaryRow() {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          _buildMetricCard('หนังสือทั้งหมด', '${_adminBooks.length}', Icons.menu_book_rounded, Colors.blue),
          const SizedBox(width: 10),
          _buildMetricCard('ผู้ใช้ทั้งหมด', '${_mockUsers.length}', Icons.people_alt_rounded, Colors.green),
          const SizedBox(width: 10),
          _buildMetricCard('ดาวน์โหลด', '45.2K', Icons.file_download_rounded, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
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
                Icon(icon, size: 20, color: AppColors.primary),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab Segment Navigation Bar ---
  Widget _buildTabSegmentBar() {
    final tabs = [
      {'label': 'จัดการหนังสือ', 'icon': Icons.book_rounded},
      {'label': 'จัดการผู้ใช้', 'icon': Icons.people_outline_rounded},
      {'label': 'รายงาน & สถิติ', 'icon': Icons.bar_chart_rounded},
      {'label': 'ตั้งค่าระบบ', 'icon': Icons.settings_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          final item = tabs[index];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 18,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
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

  // --- Tab Body Switcher ---
  Widget _buildTabBodyContent() {
    switch (_selectedTab) {
      case 0:
        return _buildBookManagementTab();
      case 1:
        return _buildUserManagementTab();
      case 2:
        return _buildAnalyticsTab();
      case 3:
        return _buildSettingsTab();
      default:
        return _buildBookManagementTab();
    }
  }

  // --- TAB 1: BOOK MANAGEMENT ---
  Widget _buildBookManagementTab() {
    final filteredBooks = _adminBooks.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'ทั้งหมด' ||
          (book.tags.isNotEmpty && book.tags.first == _selectedCategoryFilter);
      return matchesSearch && matchesCategory;
    }).toList();

    return Column(
      children: [
        // Action Bar: Search Input & Add Book Button
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ค้นหาหนังสือ หรือชื่อผู้แต่ง...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _openAddBookDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มหนังสือใหม่', style: TextStyle(fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(120, 42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Book List View
        Expanded(
          child: filteredBooks.isEmpty
              ? const Center(
                  child: Text('ไม่พบข้อมูลหนังสือ', style: TextStyle(color: AppColors.textSecondary)),
                )
              : ListView.separated(
                  itemCount: filteredBooks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final book = filteredBooks[index];
                    return _buildAdminBookCard(book, index);
                  },
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
          // Cover Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(book.imagePath, width: 50, height: 65),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  book.author,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF1F7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.tags.isNotEmpty ? book.tags.first : 'ทั่วไป',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                    Text(
                      book.ratingText,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons: Edit & Delete
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
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

  // --- TAB 2: USER MANAGEMENT ---
  Widget _buildUserManagementTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'รายการผู้ใช้งานในระบบ',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView.separated(
            itemCount: _mockUsers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = _mockUsers[index];
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
                      child: Text(
                        user['name'][0],
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user['email'],
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),

                    // Role Badge
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

  // --- TAB 3: ANALYTICS & REPORTS ---
  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายงานสถิติการใช้งาน',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),

          // Stat Card
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
                const Text(
                  'หมวดหมู่ยอดนิยม',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAnalyticsCategoryItem('วิทยาศาสตร์', 0.85, '85%'),
                _buildAnalyticsCategoryItem('เทคโนโลยี', 0.70, '70%'),
                _buildAnalyticsCategoryItem('ศิลปะ', 0.50, '50%'),
                _buildAnalyticsCategoryItem('สุขภาพ', 0.35, '35%'),
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

  // --- TAB 4: SETTINGS ---
  Widget _buildSettingsTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'การตั้งค่าระบบผู้ดูแล',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('โหมดปรับปรุงระบบ (Maintenance Mode)'),
            subtitle: const Text('ปิดการเข้าใช้งานชั่วคราวสำหรับผู้ใช้ทั่วไป'),
            value: false,
            activeColor: AppColors.primary,
            onChanged: (val) {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.backup_outlined, color: AppColors.primary),
            title: const Text('สำรองข้อมูลระบบ (Backup Data)'),
            subtitle: const Text('ส่งออกไฟล์ข้อมูลหนังสือและสมาชิก'),
            trailing: OutlinedButton(
              onPressed: () {},
              child: const Text('Export'),
            ),
          ),
        ],
      ),
    );
  }
}
