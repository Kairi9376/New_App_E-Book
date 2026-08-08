import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import 'add_book_screen.dart';
import 'book_management_screen.dart';
import 'author_management_screen.dart';
import 'category_management_screen.dart';
import '../login_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  int _totalBooks = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    final books = await ApiService.getBooks(status: 'all', role: 'employee');
    if (mounted) {
      setState(() {
        _totalBooks = books.length;
      });
    }
  }

  void _openAddBookScreen() {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const EmployeeAddBookScreen()),
      );

      if (result == true && mounted) {
        _fetchDashboardStats();
      }
    });
  }

  void _openBookManagement() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookManagementScreen()),
    ).then((_) {
      if (mounted) _fetchDashboardStats();
    });
  }

  void _openAuthorManagement() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AuthorManagementScreen()),
    );
  }

  void _openCategoryManagement() {
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
            const SizedBox(width: 8),
            const Text('ອອກຈາກລະບົບ'),
          ],
        ),
        content:
            const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບພະນັກງານ (Staff Portal) ແທ້ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          // # ເຮັດຫຍັງ: ເພີ່ມການລ້າງ session ກ່ອນອອກ ແລະ ປ່ຽນປາຍທາງເປັນ StaffLoginScreen
          // # ຍ້ອນຫຍັງ: ບັນຫາດຽວກັນກັບ Admin - ຂອງເກົ່າ navigate ຢ່າງດຽວ session ພະນັກງານ
          // #          ຈຶ່ງຄ້າງຢູ່ໃນເຄື່ອງ ແລ້ວຖືກກູ້ຄືນຕອນເປີດໃໝ່
          // # ແກ້ຈາກສ່ວນໃດ: ປຸ່ມຢືນຢັນອອກຈາກລະບົບໃນ dialog ທີ່ push ໄປ LoginScreen
          // # ແກ້ເຮັດຫຍັງ: ລ້າງ session ຈິງ ແລ້ວກັບໄປໜ້າ login ຂອງພະນັກງານ (Web)
          ElevatedButton(
            onPressed: () async {
              await ApiService.clearSession();
              if (!context.mounted) return;
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const StaffLoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ອອກຈາກລະບົບ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.badge_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Employee Portal',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Staff / ພະນັກງານ',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ອອກຈາກລະບົບ',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _onLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(),
              const SizedBox(height: 20),
              _buildResponsiveStats(),
              const SizedBox(height: 24),
              _buildAddBookBanner(),
              const SizedBox(height: 16),
              _buildManageBooksBanner(),
              const SizedBox(height: 16),
              _buildManageAuthorsBanner(),
              const SizedBox(height: 16),
              _buildManageCategoriesBanner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ສະບາຍດີພະນັກງານ (Staff Portal) 👋',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  'ຈັດການຄັງປຶ້ມ e-Book ເພີ່ມໄຟລ໌ PDF ແລະ ດູແລຄວາມຮຽບຮ້ອຍຂອງລະບົບ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade300),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            children: [
              _buildSingleStatCard('ປຶ້ມທັງໝົດ', '$_totalBooks',
                  Icons.menu_book_rounded, const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _buildSingleStatCard('ໄຟລ໌ PDF ພ້ອມອ່ານ', '$_totalBooks',
                  Icons.picture_as_pdf_rounded, const Color(0xFF10B981)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
                child: _buildSingleStatCard('ປຶ້ມທັງໝົດ', '$_totalBooks',
                    Icons.menu_book_rounded, const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSingleStatCard('ໄຟລ໌ PDF ພ້ອມອ່ານ', '$_totalBooks',
                    Icons.picture_as_pdf_rounded, const Color(0xFF10B981))),
          ],
        );
      },
    );
  }

  Widget _buildSingleStatCard(
      String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBookBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 550;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF6EE7B7)),
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.picture_as_pdf_rounded,
                              color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ເພີ່ມປຶ້ມໃໝ່ເຂົ້າຄັງ (ໄຟລ໌ PDF)',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openAddBookScreen,
                        icon: const Icon(Icons.add_rounded,
                            color: Colors.white, size: 20),
                        label: const Text('ເພີ່ມປຶ້ມ PDF',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded,
                          color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ເພີ່ມປຶ້ມໃໝ່ເຂົ້າຄັງ (ໄຟລ໌ PDF)',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ອັບໂຫຼດໄຟລ໌ PDF ຕັ້ງຄ່າຮູບປົກ ແລະ ລາຍລະອຽດຂອງປຶ້ມ',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openAddBookScreen,
                      icon: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 20),
                      label: const Text('ເພີ່ມປຶ້ມ PDF',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildManageCategoriesBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: InkWell(
        onTap: _openCategoryManagement,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.category_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Category Management (ຈັດການໝວດໝູ່)',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ຈັດການໝວດໝູ່ປຶ້ມ ເພີ່ມ ແກ້ໄຂ ລົບ',
                    style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFFF59E0B), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildManageAuthorsBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: InkWell(
        onTap: _openAuthorManagement,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Author Management (ຈັດການນັກຂຽນ)',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ຈັດການລາຍຊື່ນັກຂຽນ ເພີ່ມ ແກ້ໄຂ ລົບ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF10B981), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildManageBooksBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: InkWell(
        onTap: _openBookManagement,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book Management (ຈັດການປຶ້ມ)',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'ຈັດການລາຍການປຶ້ມທັງໝົດ ຄົ້ນຫາ ແລະ ເບິ່ງຂໍ້ມູນ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Color(0xFF3B82F6), size: 16),
          ],
        ),
      ),
    );
  }
}
