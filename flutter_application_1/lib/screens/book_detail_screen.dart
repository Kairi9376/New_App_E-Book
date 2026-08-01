import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/book_model.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel? book;

  const BookDetailScreen({super.key, this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isBookmarked = false;
  bool _isExpanded = false;

  late String _title;
  late String _author;
  late String _ratingText;
  late String _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _title = widget.book!.title;
      _author = widget.book!.author;
      _ratingText = widget.book!.ratingText;
      _imagePath = widget.book!.imagePath;
      _isBookmarked = widget.book!.isBookmarked;
    } else {
      _title = 'The Happiness Effect';
      _author = 'Stephen T. Radentz';
      _ratingText = '4.9';
      _imagePath =
          '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg';
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
      color: Colors.amber.shade100,
      child: const Icon(Icons.book, color: AppColors.primary, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    const synopsisFullText =
        "In a world where memories can be harvested and sold like currency, Silas Thorne is a simple collector with a dangerous secret. When he discovers a memory that doesn't belong to any living human, he is thrust into a conspiracy that reaches the highest levels of the Neo-Veridian government. \"Echoes of the Void\" is a gripping exploration of identity, loss, and the price of progress in a dystopian future where even our dreams are no longer private property.";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Gradient Area with Floating Actions & Large Cover
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFD6E4FF),
                            Color(0xFFEFF5FF),
                            Colors.white,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top Header Actions Row (Back, Bookmark, Share)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildCircularIconButton(
                                icon: Icons.arrow_back_rounded,
                                onTap: () => Navigator.pop(context),
                              ),
                              Row(
                                children: [
                                  _buildCircularIconButton(
                                    icon: _isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    iconColor: AppColors.primary,
                                    onTap: () {
                                      setState(() {
                                        _isBookmarked = !_isBookmarked;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _buildCircularIconButton(
                                    icon: Icons.share_outlined,
                                    onTap: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Large Centered Book Cover Image
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _buildImage(
                                _imagePath,
                                width: 200,
                                height: 260,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    // Book Info Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          // Title
                          Text(
                            _title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Author
                          Text(
                            _author,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Info Badges Row (Rating, Pages, Language)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildInfoBadge(
                                icon: Icons.star_rounded,
                                iconColor: Colors.amber,
                                text: _ratingText,
                                bgColor: const Color(0xFFFEF9C3),
                              ),
                              const SizedBox(width: 10),
                              _buildInfoBadge(
                                icon: Icons.menu_book_rounded,
                                iconColor: AppColors.primary,
                                text: '342 Pages',
                                bgColor: const Color(0xFFE2EDFF),
                              ),
                              const SizedBox(width: 10),
                              _buildInfoBadge(
                                icon: Icons.language_rounded,
                                iconColor: const Color(0xFF7C3AED),
                                text: 'Laos',
                                bgColor: const Color(0xFFF3E8FF),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Action Buttons Row (Read Now & Download)
                          Row(
                            children: [
                              // Read Now Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                                    label: const Text(
                                      'ອ່ານເລີຍ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Download Button
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(Icons.file_download_outlined, size: 20),
                                    label: const Text(
                                      'ດາວໂຫຼດ',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Synopsis Section
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ເນື້ອເຣື່ອງຫຍໍ້',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            synopsisFullText,
                            maxLines: _isExpanded ? 100 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),

                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Text(
                                    _isExpanded ? 'ຊ່ອນຂໍ້ຄວາມ' : 'ອ່ານເພີ່ມເຕີມ',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _isExpanded
                                        ? Icons.keyboard_arrow_up_rounded
                                        : Icons.keyboard_arrow_down_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar Consistency
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularIconButton({
    required IconData icon,
    Color iconColor = AppColors.textPrimary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required Color iconColor,
    required String text,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'หน้าหลัก'},
      {'icon': Icons.history_rounded, 'label': 'ประวัติ'},
      {'icon': Icons.bookmark_outline_rounded, 'label': 'บันทึก'},
      {'icon': Icons.file_download_outlined, 'label': 'ดาวน์โหลด'},
      {'icon': Icons.person_outline_rounded, 'label': 'โปรไฟล์'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(navItems.length, (index) {
          final isSelected = index == 0;
          final item = navItems[index];

          return GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 8,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE2EDFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 22,
                    color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      item['label'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
