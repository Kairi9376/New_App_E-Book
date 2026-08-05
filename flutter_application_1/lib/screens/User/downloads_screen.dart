import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/downloads_model.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../utils/image_helper.dart';
import 'book_detail_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  List<DownloadedBookItem> _downloadList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDownloads();
  }

  Future<void> _fetchDownloads() async {
    setState(() => _isLoading = true);
    final items = await ApiService.getDownloads();
    if (mounted) {
      setState(() {
        _downloadList = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(int index, DownloadedBookItem item) async {
    final deletedId = item.downloadId?.toString() ?? item.id;
    setState(() {
      _downloadList.removeWhere((b) => b.id == item.id);
    });

    await ApiService.deleteDownload(deletedId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ລົບ "${item.title}" ອອກຈາກລາຍການດາວໂຫຼດແລ້ວ'),
          backgroundColor: const Color(0xFFEF4444),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'ເລີກທຳ',
            textColor: Colors.white,
            onPressed: () async {
              if (item.bookId != null) {
                await ApiService.recordDownload(item.bookId.toString());
              }
              _fetchDownloads();
            },
          ),
        ),
      );
    }
  }

  void _openBookDetail(DownloadedBookItem item) {
    final parsedTags = item.category.isNotEmpty
        ? item.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : ['ທົ່ວໄປ'];

    final bookModel = BookModel(
      id: item.bookId?.toString() ?? item.id,
      title: item.title,
      author: item.author,
      pageCount: item.pageCount,
      fileSizeBytes: item.fileSizeBytes,
      rating: item.rating,
      ratingText: item.rating == 0.0 ? 'New' : item.rating.toStringAsFixed(1),
      likeCount: item.likeCount,
      viewCount: item.viewCount,
      tags: parsedTags,
      imagePath: item.imagePath,
      pdfUrl: item.pdfUrl ?? 'assets/sample_book.pdf',
      description: item.description ?? '',
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookDetailScreen(book: bookModel)),
    );
  }

  List<String> get _categories {
    final cats = <String>{'ທັງໝົດ'};
    for (final item in _downloadList) {
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

  List<DownloadedBookItem> get _filteredList {
    final catList = _categories;
    final safeIndex = (_selectedCategoryIndex < catList.length) ? _selectedCategoryIndex : 0;
    final selectedCat = catList[safeIndex];

    return _downloadList.where((book) {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title & Refresh Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.download_for_offline_rounded, color: AppColors.primary, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'ດາວໂຫຼດ (Downloaded Books)',
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
                onPressed: _fetchDownloads,
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
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'ຄົ້ນຫາໃນລາຍການດາວໂຫຼດ...',
                hintStyle: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                icon: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category Chips Bar
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _selectedCategoryIndex == index;
                return ChoiceChip(
                  label: Text(_categories[index]),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  backgroundColor: const Color(0xFFEFF3F8),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategoryIndex = index);
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Downloaded List Items
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : displayList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_download_outlined, size: 64, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 12),
                            const Text(
                              'ບໍ່ມີໄຟລ໌ດາວໂຫຼດໃນເຄື່ອງ',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'ກົດປຸ່ມດາວໂຫຼດ 📥 ໃນໜ້າໜັງສືເພື່ອບັນທຶກໄວ້ອ່ານອອບໄລນ໌',
                              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchDownloads,
                        color: AppColors.primary,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: displayList.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildDownloadCard(displayList[index], index);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadCard(DownloadedBookItem item, int index) {
    final catBadgeList = item.category.isNotEmpty
        ? item.category.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
        : ['ທົ່ວໄປ'];

    return InkWell(
      onTap: () => _openBookDetail(item),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Thumbnail Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(
                item.imagePath,
                width: 85,
                height: 115,
              ),
            ),
            const SizedBox(width: 14),

            // Details & Action Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Delete Icon Button
                      IconButton(
                        onPressed: () => _removeItem(index, item),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFDC2626),
                          size: 20,
                        ),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        tooltip: 'ລົບໄຟລ໌',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Metadata Badges (Categories & File Size & Page Count)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...catBadgeList.map(
                        (catName) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEBF1F7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            catName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      if (item.fileSizeBytes > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sd_storage_outlined, size: 12, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Text(
                                item.formattedFileSize,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.pageCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.pageCount} ໜ້າ',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Read Now Button
                  SizedBox(
                    height: 32,
                    width: 115,
                    child: ElevatedButton.icon(
                      onPressed: () => _openBookDetail(item),
                      icon: const Icon(Icons.menu_book_rounded, size: 14, color: Colors.white),
                      label: const Text(
                        'ອ່ານເລີຍ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

