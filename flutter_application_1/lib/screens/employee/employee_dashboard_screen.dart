import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import 'add_book_screen.dart';
import '../login_screen.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ທັງໝົດ';

  final List<BookModel> _employeeBooks = List.from(MockBookData.popularBooks);

  final List<String> _categories = [
    'ທັງໝົດ',
    'ເຕັກໂນໂລຊີ',
    'ວິທະຍາສາດ',
    'ສິນລະປະ',
    'ສຸຂະພາບ',
    'ຊີວິດ',
    'ຜະຈົນໄພ',
  ];

  void _openAddBookScreen() {
    FocusScope.of(context).unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const EmployeeAddBookScreen()),
      );

      if (result == true && mounted) {
        setState(() {
          _employeeBooks.insert(
            0,
            BookModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: 'ຄູ່ມືການພັດທະນາ Flutter Web E-Book (PDF)',
              author: 'ທີມງານຝ່າຍລະບົບ (Staff)',
              rating: 5.0,
              ratingText: 'New',
              tags: ['ເຕັກໂນໂລຊີ'],
              imagePath: 'assets/sample_cover.png',
            ),
          );
        });
      }
    });
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
        content: const Text('ທ່ານຕ້ອງການອອກຈາກລະບົບພະນັກງານ (Staff Portal) ແທ້ບໍ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ຍົກເລີກ', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ອອກຈາກລະບົບ'),
          ),
        ],
      ),
    );
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
      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _employeeBooks.where((book) {
      final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'ທັງໝົດ' ||
          (book.tags.isNotEmpty && book.tags.first == _selectedCategoryFilter);
      return matchesSearch && matchesCategory;
    }).toList();

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
              child: const Icon(Icons.badge_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Employee Portal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
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
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ຄັງປຶ້ມໃນລະບົບ (E-Book Catalog)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    'ທັງໝົດ ${filteredBooks.length} ເລີ່ມ',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 44,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ຄົ້ນຫາຊື່ປຶ້ມ ຫຼື ຊື່ຜູ້ແຕ່ງ...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.primary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                ),
              ),
              const SizedBox(height: 12),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        selectedColor: const Color(0xFF0F172A),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategoryFilter = cat);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              filteredBooks.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(36),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          const Text('ບໍ່ພົບຂໍ້ມູນປຶ້ມທີ່ຄົ້ນຫາ', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredBooks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final book = filteredBooks[index];
                        return _buildEmployeeBookCard(book, index);
                      },
                    ),
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
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
              _buildSingleStatCard('ປຶ້ມທັງໝົດ', '${_employeeBooks.length}', Icons.menu_book_rounded, const Color(0xFF3B82F6)),
              const SizedBox(height: 10),
              _buildSingleStatCard('ໄຟລ໌ PDF ພ້ອມອ່ານ', '${_employeeBooks.length}', Icons.picture_as_pdf_rounded, const Color(0xFF10B981)),
              const SizedBox(height: 10),
              _buildSingleStatCard('ລາຍການອັບເດດມື້ນີ້', '2', Icons.update_rounded, const Color(0xFFF59E0B)),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: _buildSingleStatCard('ປຶ້ມທັງໝົດ', '${_employeeBooks.length}', Icons.menu_book_rounded, const Color(0xFF3B82F6))),
            const SizedBox(width: 12),
            Expanded(child: _buildSingleStatCard('ໄຟລ໌ PDF ພ້ອມອ່ານ', '${_employeeBooks.length}', Icons.picture_as_pdf_rounded, const Color(0xFF10B981))),
            const SizedBox(width: 12),
            Expanded(child: _buildSingleStatCard('ລາຍການອັບເດດມື້ນີ້', '2', Icons.update_rounded, const Color(0xFFF59E0B))),
          ],
        );
      },
    );
  }

  Widget _buildSingleStatCard(String title, String count, IconData icon, Color color) {
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
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
                          child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'ເພີ່ມປຶ້ມໃໝ່ເຂົ້າຄັງ (ໄຟລ໌ PDF)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openAddBookScreen,
                        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        label: const Text('ເພີ່ມປຶ້ມ PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ເພີ່ມປຶ້ມໃໝ່ເຂົ້າຄັງ (ໄຟລ໌ PDF)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'ອັບໂຫຼດໄຟລ໌ PDF ຕັ້ງຄ່າຮູບປົກ ແລະ ລາຍລະອຽດຂອງປຶ້ມ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _openAddBookScreen,
                      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                      label: const Text('ເພີ່ມປຶ້ມ PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildEmployeeBookCard(BookModel book, int index) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildImage(book.imagePath, width: 55, height: 75),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(book.author, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.picture_as_pdf_rounded, size: 12, color: Color(0xFF059669)),
                          const SizedBox(width: 4),
                          const Text('PDF ພ້ອມອ່ານ', style: TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
