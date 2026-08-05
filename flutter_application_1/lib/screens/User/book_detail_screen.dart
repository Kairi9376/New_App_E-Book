import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/history_model.dart';
import '../../services/api_service.dart';
import '../../utils/image_helper.dart';
import '../../models/kyc_model.dart';
import 'pdf_viewer_screen.dart';
import 'kyc_submission_screen.dart';
import 'membership_package_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_model.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel? book;

  const BookDetailScreen({super.key, this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _isBookmarked = false;
  bool _isLiked = false;
  int _likeCount = 124;
  int _viewCount = 350;

  late String _title;
  late String _author;
  late String _imagePath;
  int _totalPageCount = 120;
  int _lastPageRead = 0;
  int _selectedPageChunk = 0;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _title = widget.book!.title;
      _author = widget.book!.author;
      _imagePath = widget.book!.imagePath;
      _isBookmarked = widget.book!.isBookmarked;
      _isLiked = widget.book!.isLiked;
      _likeCount = widget.book!.likeCount > 0 ? widget.book!.likeCount : 124;
      _viewCount = widget.book!.viewCount > 0 ? widget.book!.viewCount : 350;
      _totalPageCount = widget.book!.pageCount > 0 ? widget.book!.pageCount : 120;
    } else {
      _title = 'The Happiness Effect';
      _author = 'Stephen T. Radentz';
      _imagePath = 'assets/sample_book.pdf';
    }

    _fetchReadingHistory();
  }

  bool get _isMember {
    final user = ApiService.currentUser ?? {};
    final role = user['role'] ?? 'user';
    final email = user['email'] ?? '';
    return role == 'admin' || role == 'employee' || email == 'member@gmail.com';
  }

  void _showMembershipRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFFF59E0B)),
              ),
              const SizedBox(height: 18),
              const Text(
                'ຕ້ອງເປັນສະມາຊິກ Premiere',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'ການດາວໂຫຼດໜັງສືສະຫງວນໄວ້ສຳລັບສະມາຊິກ Premiere Member ເທົ່ານັ້ນ\n\nກະລຸນາຢືນຢັນຕົວຕົນ (KYC) ແລະ ສະໝັກແພັກເກັດສະມາຊິກເພື່ອເຂົ້າເຖິງການດາວໂຫຼດ',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MembershipPackageScreen()),
                    );
                  },
                  icon: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
                  label: const Text('ສະໝັກສະມາຊິກ Premiere', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ໄວ້ທີຫຼັງ', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _fetchReadingHistory() async {
    if (widget.book == null) return;
    try {
      final historyList = await ApiService.getHistory();
      final targetId = widget.book!.id;
      final match = historyList.firstWhere(
        (h) => (h.bookId?.toString() == targetId || h.id == targetId || h.title == _title),
        orElse: () => HistoryBookItem(id: '', title: '', author: '', category: '', progress: 0.0, imagePath: ''),
      );

      if (match.id.isNotEmpty && match.lastPageRead > 0) {
        if (mounted) {
          setState(() {
            _lastPageRead = match.lastPageRead;
            _selectedPageChunk = ((_lastPageRead - 1) ~/ 50).clamp(0, ((_totalPageCount - 1) ~/ 50));
          });
        }
      }
    } catch (_) {}
  }

  Widget _buildImage(String path, {double? width, double? height}) {
    return ImageHelper.buildImage(path, width: width, height: height, fit: BoxFit.cover);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/BookCover.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.amber.shade100),
          ),
          Container(
            color: Colors.black.withOpacity(0.25),
          ),
          const Center(
            child: Icon(Icons.book_rounded, color: Colors.white, size: 48),
          ),
        ],
      ),
    );
  }

  void _openReader({int initialPage = 1}) {
    String pdfUrl = widget.book?.pdfUrl ?? '';
    if (pdfUrl.isEmpty) {
      pdfUrl = 'assets/sample_book.pdf';
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          bookId: widget.book?.id ?? '1',
          pdfUrl: pdfUrl,
          bookTitle: _title,
          author: _author,
          description: widget.book?.description,
          pageCount: _totalPageCount,
          initialPage: initialPage,
        ),
      ),
    ).then((_) => _fetchReadingHistory());
  }

  @override
  Widget build(BuildContext context) {
    final String synopsisFullText = widget.book?.description ??
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
                          // Top Header Actions Row (Back, Heart Like, Bookmark, Share)
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
                                    icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    iconColor: const Color(0xFFEF4444),
                                    onTap: () async {
                                      setState(() {
                                        _isLiked = !_isLiked;
                                        _likeCount += _isLiked ? 1 : -1;
                                      });
                                      if (widget.book != null) {
                                        await ApiService.toggleLike(widget.book!.id);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _buildCircularIconButton(
                                    icon: _isBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    iconColor: AppColors.primary,
                                    onTap: () async {
                                      setState(() {
                                        _isBookmarked = !_isBookmarked;
                                      });
                                      if (widget.book != null) {
                                        await ApiService.toggleBookmark(widget.book!.id);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  _buildCircularIconButton(
                                    icon: Icons.share_outlined,
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('ແບ່ງປັນໜັງສືນີ້ສຳເລັດ')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Large Center Book Cover with Shadow
                          Center(
                            child: GestureDetector(
                              onTap: () => ImageHelper.showPreviewModal(context, path: _imagePath, title: _title),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 160,
                                    height: 230,
                                    child: _buildImage(_imagePath),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Book Details Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),

                          // Book Title
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

                          // Author Name
                          Text(
                            _author,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Info Badges Row (Likes, Readers, Pages)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () async {
                                  setState(() {
                                    _isLiked = !_isLiked;
                                    _likeCount += _isLiked ? 1 : -1;
                                  });
                                  if (widget.book != null) {
                                    await ApiService.toggleLike(widget.book!.id);
                                  }
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: _buildInfoBadge(
                                  icon: _isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                  iconColor: const Color(0xFFEF4444),
                                  text: '$_likeCount ຖືກໃຈ',
                                  bgColor: const Color(0xFFFEF2F2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildInfoBadge(
                                icon: Icons.visibility_rounded,
                                iconColor: const Color(0xFF2563EB),
                                text: '$_viewCount ຜູ້ອ່ານ',
                                bgColor: const Color(0xFFEFF6FF),
                              ),
                              const SizedBox(width: 10),
                              _buildInfoBadge(
                                icon: Icons.auto_stories_rounded,
                                iconColor: AppColors.primary,
                                text: '$_totalPageCount ໜ້າ',
                                bgColor: const Color(0xFFE2EDFF),
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
                                    onPressed: () => _openReader(initialPage: _lastPageRead > 0 ? _lastPageRead : 1),
                                    icon: const Icon(Icons.menu_book_rounded, size: 20),
                                    label: Text(
                                      _lastPageRead > 0 ? 'ອ່ານຕໍ່ (ໜ້າ $_lastPageRead)' : 'ອ່ານເລີຍ',
                                      style: const TextStyle(
                                        fontSize: 14,
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
                                    onPressed: () async {
                                      if (!_isMember) {
                                        _showMembershipRequiredDialog();
                                        return;
                                      }
                                      final bookId = widget.book?.id ?? '1';
                                      final success = await ApiService.recordDownload(bookId);
                                      if (mounted) {
                                        NotificationService.addNotification(
                                          context,
                                          title: '📥 ດາວໂຫຼດໜັງສືສຳເລັດແລ້ວ',
                                          message: 'ບັນທຶກ "${_title}" ເຂົ້າຄັງອອບໄລນ໌ຮຽບຮ້ອຍແລ້ວ',
                                          type: NotificationType.book,
                                          targetId: bookId,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(success
                                                ? 'ດາວໂຫຼດ "$_title" ເຂົ້າຄັງອອບໄລນ໌ສຳເລັດແລ້ວ!'
                                                : 'ບັນທຶກລາຍການດາວໂຫຼດສຳເລັດ'),
                                            backgroundColor: const Color(0xFF10B981),
                                          ),
                                        );
                                      }
                                    },
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

                          // Reading Progress Header Card
                          _buildReadingProgressHeaderCard(),

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
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Table of Contents Section (ສາລະບັນ / ລາຍການໜ້າ PDF)
                          _buildTableOfContentsSection(),


                          const SizedBox(height: 30),
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

  Widget _buildTableOfContentsSection() {
    final int totalChunks = ((_totalPageCount - 1) ~/ 50) + 1;
    final int currentChunk = _selectedPageChunk.clamp(0, totalChunks - 1);
    final int startPage = (currentChunk * 50) + 1;
    final int endPage = ((currentChunk + 1) * 50) > _totalPageCount ? _totalPageCount : ((currentChunk + 1) * 50);
    final int itemsInCurrentChunk = endPage - startPage + 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.format_list_bulleted_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'ສາລະບານ / ລາຍການໜ້າ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: _showDirectJumpDialog,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.near_me_rounded, size: 14, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('ຂ້າມໄປໜ້າ...', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'ທັງໝົດ $_totalPageCount ໜ້າ',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Range Selector Chips (for books > 50 pages)
          if (totalChunks > 1) ...[
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: totalChunks,
                itemBuilder: (context, cIndex) {
                  final cStart = (cIndex * 50) + 1;
                  final cEnd = ((cIndex + 1) * 50) > _totalPageCount ? _totalPageCount : ((cIndex + 1) * 50);
                  final isSelected = cIndex == currentChunk;

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: isSelected,
                      label: Text('ໜ້າ $cStart-$cEnd'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1)),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedPageChunk = cIndex;
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Last Read Highlight Banner
          if (_lastPageRead > 0)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_added_rounded, color: Color(0xFF2563EB), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ອ່ານລ່າສຸດເຖິງ: ໜ້າທີ $_lastPageRead',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                  ),
                  InkWell(
                    onTap: () => _openReader(initialPage: _lastPageRead),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('ອ່ານຕໍ່', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

          // PDF Pages List for Selected Range (startPage .. endPage)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemsInCurrentChunk,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final int pageNum = startPage + index;
              final bool isLastReadPage = pageNum == _lastPageRead;

              return InkWell(
                onTap: () => _openReader(initialPage: pageNum),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isLastReadPage ? const Color(0xFFFEF3C7) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isLastReadPage ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
                      width: isLastReadPage ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isLastReadPage ? const Color(0xFFF59E0B) : const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$pageNum',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isLastReadPage ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'ໜ້າທີ $pageNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isLastReadPage ? FontWeight.bold : FontWeight.w500,
                            color: isLastReadPage ? const Color(0xFFB45309) : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (isLastReadPage)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.push_pin_rounded, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'ອ່ານລ່າສຸດ',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ],
                          ),
                        )
                      else
                        const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDirectJumpDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ຂ້າມໄປໜ້າທີ່ຕ້ອງການ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ກະລຸນາປ້ອນໝາຍເລກໜ້າ (1 ເຖິງ $_totalPageCount):', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'ຕົວຢ່າງ: 45',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              final target = int.tryParse(controller.text.trim());
              if (target != null && target >= 1 && target <= _totalPageCount) {
                Navigator.pop(ctx);
                _openReader(initialPage: target);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ກະລຸນາປ້ອນຕົວເລກລະຫວ່າງ 1 ເຖິງ $_totalPageCount'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ໄປທີ່ໜ້ານີ້'),
          ),
        ],
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
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }

  Widget _buildReadingProgressHeaderCard() {
    if (_lastPageRead <= 0) return const SizedBox.shrink();
    final double percent = (_lastPageRead / (_totalPageCount > 0 ? _totalPageCount : 1)).clamp(0.0, 1.0);
    final int percentInt = (percent * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bookmark_added_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ຄວາມຄືບໜ້າການອ່ານ (Reading Progress)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ອ່ານເຖິງໜ້າທີ $_lastPageRead ຈາກທັງໝົດ $_totalPageCount ໜ້າ',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percentInt%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: const Color(0xFFBFDBFE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
        ],
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
