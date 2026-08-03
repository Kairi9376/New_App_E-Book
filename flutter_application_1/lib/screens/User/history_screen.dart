import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/history_model.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../utils/image_helper.dart';
import 'book_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryBookItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getHistory();
    if (mounted) {
      setState(() {
        _historyItems = list;
        _isLoading = false;
      });
    }
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    return ImageHelper.buildImage(path, width: width, height: height, fit: BoxFit.cover);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.book_rounded, color: AppColors.primary, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ປະຫວັດການອ່ານ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onPressed: _fetchHistory,
                tooltip: 'ຣີເຟຣຊ',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // History List Cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyItems.isEmpty
                    ? const Center(
                        child: Text(
                          'ບໍ່ມີປະຫວັດການອ່ານ',
                          style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        color: AppColors.primary,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _historyItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            return _buildHistoryCard(_historyItems[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(HistoryBookItem item) {
    return InkWell(
      onTap: () {
        final bookModel = BookModel(
          id: item.bookId?.toString() ?? item.id,
          title: item.title,
          author: item.author,
          rating: 4.8,
          ratingText: '4.8',
          tags: item.category.isNotEmpty ? [item.category] : ['ທັງໝົດ'],
          imagePath: item.imagePath,
          pdfUrl: item.pdfUrl ?? 'assets/sample_book.pdf',
          description: item.description,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookDetailScreen(book: bookModel),
          ),
        ).then((_) => _fetchHistory());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Book Thumbnail Container
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: _buildImage(
                item.imagePath,
                width: 90,
                height: 110,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Right Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Author
                Text(
                  item.author,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Category Tag Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF1F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Percentage Text
                Text(
                  'ອ່ານແລ້ວ ${item.progressPercentage}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    minHeight: 5,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
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
