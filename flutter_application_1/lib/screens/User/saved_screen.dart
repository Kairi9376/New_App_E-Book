import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/saved_model.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../utils/image_helper.dart';
import 'book_detail_screen.dart';

class MouseTouchScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  List<SavedBookItem> _savedList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchSavedBooks();
  }

  Future<void> _fetchSavedBooks() async {
    setState(() => _isLoading = true);
    final books = await ApiService.getSavedBooks();
    if (mounted) {
      setState(() {
        _savedList = books;
        _isLoading = false;
      });
    }
  }

  void _toggleBookmark(SavedBookItem item, int index) async {
    setState(() {
      _savedList.removeWhere((b) => b.id == item.id);
    });
    await ApiService.toggleBookmark(item.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ລົບ "${item.title}" ອອກຈາກລາຍການບັນທຶກແລ້ວ'),
          backgroundColor: const Color(0xFFEF4444),
          action: SnackBarAction(
            label: 'ເລີກທຳ',
            textColor: Colors.white,
            onPressed: () async {
              await ApiService.toggleBookmark(item.id);
              _fetchSavedBooks();
            },
          ),
        ),
      );
    }
  }

  void _openBookDetail(SavedBookItem item) {
    final parsedTags = item.category.isNotEmpty
        ? item.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : ['ທົ່ວໄປ'];

    final bookModel = BookModel(
      id: item.bookId?.toString() ?? item.id,
      title: item.title,
      author: item.author,
      rating: item.rating,
      ratingText: item.rating == 0.0 ? 'New' : item.rating.toStringAsFixed(1),
      tags: parsedTags,
      imagePath: item.imagePath,
      pdfUrl: item.pdfUrl ?? 'assets/sample_book.pdf',
      likeCount: item.likeCount,
      viewCount: item.viewCount,
      description: item.description ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: bookModel)),
    );
  }

  List<String> get _categories {
    final cats = <String>{'ທັງໝົດ'};
    for (final item in _savedList) {
      if (item.category.isNotEmpty) {
        final parts = item.category.split(',');
        for (var p in parts) {
          final trimmed = p.trim();
          if (trimmed.isNotEmpty) cats.add(trimmed);
        }
      }
    }
    return cats.toList();
  }

  List<SavedBookItem> get _filteredList {
    final catList = _categories;
    final safeIndex = (_selectedCategoryIndex < catList.length) ? _selectedCategoryIndex : 0;
    final selectedCat = catList[safeIndex];

    return _savedList.where((book) {
      final matchesSearch = _searchQuery.isEmpty ||
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = safeIndex == 0 ||
          book.category.toLowerCase().contains(selectedCat.toLowerCase());

      return matchesSearch && matchesCategory;
    }).toList();
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    return ImageHelper.buildImage(path, width: width, height: height, fit: BoxFit.cover);
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _filteredList;
    final categoriesList = _categories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'ບັນທຶກ (Saved Books)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: _fetchSavedBooks,
                tooltip: 'ຣີເຟຣຊ',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'ຄົ້ນຫາໃນລາຍການບັນທຶກ...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                icon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips Bar (Scrollable for Desktop & Web & Mobile)
          SizedBox(
            height: 34,
            child: ScrollConfiguration(
              behavior: MouseTouchScrollBehavior(),
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: categoriesList.length,
                itemBuilder: (context, idx) {
                  final isSelected = _selectedCategoryIndex == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text(categoriesList[idx]),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: const Color(0xFFF1F5F9),
                      side: BorderSide.none,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryIndex = idx);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Saved Grid Items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayList.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 64, color: Color(0xFFCBD5E1)),
                            SizedBox(height: 12),
                            Text(
                              'ບໍ່ມີປຶ້ມທີ່ບັນທຶກໄວ້',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'ກົດໄອຄອນຄັ້ນໜ້າ 📌 ໃນໜ້າໜັງສືເພື່ອບັນທຶກໄວ້ອ່ານພາຍຫຼັງ',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchSavedBooks,
                        color: AppColors.primary,
                        child: GridView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.55,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                          ),
                          itemBuilder: (context, index) {
                            return _buildSavedCard(displayList[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedCard(SavedBookItem item, int index) {
    final catBadgeList = item.category.isNotEmpty
        ? item.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : ['ທົ່ວໄປ'];

    return InkWell(
      onTap: () => _openBookDetail(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image Container with Bookmark Icon Badge
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF8FAFC),
                      child: _buildImage(item.imagePath),
                    ),
                  ),

                  // Floating Top Right Bookmark Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _toggleBookmark(item, index),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bookmark_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Category Badges
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: catBadgeList.map(
                (catName) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2EDFF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    catName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ).toList(),
            ),
            const SizedBox(height: 6),

            // Title
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),

            // Author & Heart Likes Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, size: 12, color: Color(0xFFEF4444)),
                    const SizedBox(width: 2),
                    Text(
                      item.formattedLikes,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Quick Read Button
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton.icon(
                onPressed: () => _openBookDetail(item),
                icon: const Icon(Icons.menu_book_rounded, size: 12, color: Colors.white),
                label: const Text('ອ່ານເລີຍ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

