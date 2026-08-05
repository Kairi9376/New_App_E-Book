import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';
import 'employee_book_detail_screen.dart';
import 'deleted_books_screen.dart';
import 'author_management_screen.dart';
import 'category_management_screen.dart';

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  String _searchQuery = '';
  String _selectedCategoryFilter = 'ທັງໝົດ';

  List<BookModel> _employeeBooks = [];
  bool _isLoading = true;

  // Categories จาก Database (ApiService.getCategories())
  List<dynamic> _categories = [];
  bool _isLoadingCategories = false;

  // Track book IDs ที่กำลัง toggle hidden (กันกดซ้ำ)
  final Set<String> _togglingBookIds = {};

  @override
  void initState() {
    super.initState();
    _fetchBooks();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    final cats = await ApiService.getCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchBooks() async {
    setState(() => _isLoading = true);
    final books = await ApiService.getBooks(status: 'all', role: 'employee');
    if (mounted) {
      setState(() {
        _employeeBooks = books;
        _isLoading = false;
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
        _fetchBooks();
      }
    });
  }

  Future<void> _openEditBook(BookModel book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookScreen(book: book),
      ),
    );

    if (result == true && mounted) {
      _fetchBooks();
    }
  }

  Future<void> _openBookDetail(BookModel book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeBookDetailScreen(book: book),
      ),
    );

    if (result == true && mounted) {
      _fetchBooks();
    }
  }

  void _openDeletedBooks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DeletedBooksScreen()),
    ).then((_) {
      if (mounted) {
        _fetchBooks();
        _fetchCategories();
      }
    });
  }

  // Quick Toggle Hidden / Visible (ใช้ ApiService.updateBook เดิม)
  Future<void> _toggleHidden(BookModel book, bool value) async {
    // value = สถานะใหม่ของ Switch (ON = Visible, OFF = Hidden)
    // ต้องส่ง is_hidden = !value (ON → false, OFF → true)
    if (_togglingBookIds.contains(book.id)) return; // กันกดซ้ำ

    setState(() => _togglingBookIds.add(book.id));

    final bool success = await ApiService.updateBook(book.id, {
      'is_hidden': !value,
    });

    if (!mounted) return;
    setState(() => _togglingBookIds.remove(book.id));

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book visibility updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update book visibility.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      // Switch กลับเป็นค่าก่อนหน้า (ไม่ต้อง setState เพราะ _fetchBooks ไม่ถูกเรียก
      // แต่ UI ยังแสดงค่าเดิมจาก book.isHidden — ถูกต้องแล้ว)
    }
  }

  Future<void> _deleteBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Book?'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bool success = await ApiService.deleteBook(book.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ລົບປຶ້ມສຳເລັດແລ້ວ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _fetchBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ລົບປຶ້ມບໍ່ສຳເລັດ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(width, height));
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(width, height));
    }
    if (!kIsWeb) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file,
            width: width, height: height, fit: BoxFit.cover);
      }
    }
    return _buildPlaceholder(width, height);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE2E8F0),
      child: const Icon(Icons.picture_as_pdf_rounded,
          color: AppColors.primary, size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _employeeBooks.where((book) {
      final matchesSearch =
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategoryFilter == 'ທັງໝົດ' ||
          book.categoryIds
              .contains(int.tryParse(_selectedCategoryFilter) ?? -1);
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book_rounded,
                  color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Book Management',
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
                'ຈັດການປຶ້ມ',
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
            tooltip: 'Author Management',
            icon: const Icon(Icons.person_rounded, color: Colors.blueAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AuthorManagementScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Category Management',
            icon: const Icon(Icons.category_rounded, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const CategoryManagementScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Deleted Books',
            icon: const Icon(Icons.restore_from_trash, color: Colors.redAccent),
            onPressed: _openDeletedBooks,
          ),
          IconButton(
            tooltip: 'ຣີເຟຣຊ',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // --- Search Bar ---
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ຄົ້ນຫາຊື່ປຶ້ມ ຫຼື ຊື່ຜູ້ແຕ່ງ...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          size: 20, color: AppColors.primary),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),

                // --- Category Filter (จาก Database) ---
                SizedBox(
                  height: 40,
                  child: _isLoadingCategories
                      ? const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          ),
                        )
                      : ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            // ตัวเลือก "ທັງໝົດ" (ทั้งหมด)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: const Text('ທັງໝົດ'),
                                selected: _selectedCategoryFilter == 'ທັງໝົດ',
                                selectedColor: const Color(0xFF0F172A),
                                labelStyle: TextStyle(
                                  color: _selectedCategoryFilter == 'ທັງໝົດ'
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight:
                                      _selectedCategoryFilter == 'ທັງໝົດ'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() =>
                                        _selectedCategoryFilter = 'ທັງໝົດ');
                                  }
                                },
                              ),
                            ),
                            // Categories จาก Database
                            ..._categories.map((cat) {
                              final catId =
                                  (cat['category_id'] ?? 0).toString();
                              final catName = (cat['name'] ?? '').toString();
                              final isSelected =
                                  _selectedCategoryFilter == catId;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(catName),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0F172A),
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() =>
                                          _selectedCategoryFilter = catId);
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                ),
                const SizedBox(height: 8),

                // --- Book List ---
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchBooks,
                    color: AppColors.primary,
                    child: filteredBooks.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 80),
                              const Icon(Icons.search_off_rounded,
                                  size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 8),
                              const Center(
                                child: Text('ບໍ່ພົບຂໍ້ມູນປຶ້ມທີ່ຄົ້ນຫາ',
                                    style: TextStyle(
                                        color: AppColors.textSecondary)),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildEmployeeBookCard(book),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBookScreen,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('ເພີ່ມປຶ້ມ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmployeeBookCard(BookModel book) {
    final String categoryText =
        book.tags.isNotEmpty ? book.tags.first : 'ທົ່ວໄປ';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => _openBookDetail(book),
        borderRadius: BorderRadius.circular(12),
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
                  Text(book.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(book.author,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Category Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          categoryText,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Free/Paid Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: book.isFree
                              ? Colors.green.shade50
                              : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.isFree ? 'ອ່ານຟຣີ' : 'ຈ່າຍເງິນ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: book.isFree
                                ? Colors.green
                                : Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // PDF Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded,
                                size: 12, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('PDF',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Approval Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: book.status.toLowerCase() == 'approved'
                              ? Colors.green.shade50
                              : (book.status.toLowerCase() == 'rejected'
                                  ? Colors.red.shade50
                                  : Colors.orange.shade50),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          book.status.toLowerCase() == 'approved'
                              ? 'ອະນຸມັດແລ້ວ'
                              : (book.status.toLowerCase() == 'rejected'
                                  ? 'ບໍ່ອະນຸມັດ'
                                  : 'ລໍຖ້າອະນຸມັດ'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: book.status.toLowerCase() == 'approved'
                                ? Colors.green.shade700
                                : (book.status.toLowerCase() == 'rejected'
                                    ? Colors.red.shade700
                                    : Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (book.status.toLowerCase() == 'rejected' &&
                      book.rejectionReason != null &&
                      book.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'ເຫດຜົນທີ່ບໍ່ອະນຸມັດ: ${book.rejectionReason}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.red.shade800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Quick Toggle Hidden / Visible
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  book.isHidden ? 'Hidden' : 'Visible',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: book.isHidden ? Colors.redAccent : Colors.green,
                  ),
                ),
                Switch(
                  value: !book.isHidden, // ON = Visible, OFF = Hidden
                  activeColor: Colors.green,
                  onChanged: _togglingBookIds.contains(book.id)
                      ? null // ปิดการกดระหว่าง loading
                      : (val) => _toggleHidden(book, val),
                ),
              ],
            ),
            // Action Buttons (ด้านขวาของ card: Edit + Delete)
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  color: Colors.blueAccent, size: 20),
              tooltip: 'Edit Book',
              onPressed: () => _openEditBook(book),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: Colors.redAccent, size: 20),
              tooltip: 'Delete Book',
              onPressed: () => _deleteBook(book),
            ),
          ],
        ),
      ),
    );
  }
}
