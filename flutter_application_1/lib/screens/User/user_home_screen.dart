import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/kyc_model.dart';
import '../../services/api_service.dart';
import '../../utils/image_helper.dart';
import 'history_screen.dart';
import 'saved_screen.dart';
import 'downloads_screen.dart';
import 'profile_screen.dart';
import 'book_detail_screen.dart';
import 'kyc_submission_screen.dart';
import 'membership_package_screen.dart';
import 'pdf_viewer_screen.dart';
import 'search_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _selectedCategoryIndex = 0;
  int _currentBottomNavIndex = 0;
  String _searchQuery = '';
  List<BookModel> _fetchedBooks = [];
  bool _isLoadingBooks = true;
  KycStatus _kycStatus = KycStatus.notSubmitted;

  List<Map<String, dynamic>> _fetchedCategories = [
    {'category_id': null, 'name': 'ທັງໝົດ'}
  ];

  final Set<String> _bookmarkedIds = {};

  @override
  void initState() {
    super.initState();
    _loadBackendData();
  }

  Future<void> _loadBackendData() async {
    setState(() => _isLoadingBooks = true);

    if (_fetchedCategories.length <= 1) {
      final cats = await ApiService.getCategories();
      if (cats.isNotEmpty) {
        _fetchedCategories = [
          {'category_id': null, 'name': 'ທັງໝົດ'},
          ...cats,
        ];
      }
    }

    String? selectedCatId;
    if (_selectedCategoryIndex > 0 && _selectedCategoryIndex < _fetchedCategories.length) {
      final catItem = _fetchedCategories[_selectedCategoryIndex];
      if (catItem['category_id'] != null) {
        selectedCatId = catItem['category_id'].toString();
      }
    }

    final books = await ApiService.getBooks(
      search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      categoryId: selectedCatId,
    );

    // Fetch live KYC status
    final user = ApiService.currentUser ?? {};
    final rawUserId = user['user_id'] ?? user['id'];
    final int userId = rawUserId != null ? (int.tryParse(rawUserId.toString()) ?? 3) : 3;
    final liveKyc = await ApiService.getUserKycStatus(userId);

    if (mounted) {
      setState(() {
        _fetchedBooks = books;
        _isLoadingBooks = false;
        if (liveKyc != null) {
          _kycStatus = liveKyc.status;
        }
      });
    }
  }

  void _toggleBookmark(String bookId) async {
    setState(() {
      if (_bookmarkedIds.contains(bookId)) {
        _bookmarkedIds.remove(bookId);
      } else {
        _bookmarkedIds.add(bookId);
      }
    });
    await ApiService.toggleBookmark(bookId);
  }

  Widget _buildImage(String path, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    return ImageHelper.buildImage(path, width: width, height: height, fit: fit);
  }

  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.blueGrey.shade100,
      child: const Icon(Icons.book, color: AppColors.primary, size: 32),
    );
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
                '\u0e95\u0ec9\u0ead\u0e87\u0ec0\u0e9b\u0eb1\u0e99\u0eaa\u0eb0\u0ea1\u0eb2\u0e8a\u0eb4\u0e81 Premiere',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                '\u0e81\u0eb2\u0e99\u0e94\u0eb2\u0ea7\u0ec2\u0eab\u0ebc\u0e94\u0edc\u0eb1\u0e87\u0eaa\u0eb7\u0eaa\u0eb0\u0eab\u0e87\u0ea7\u0e99\u0ec4\u0ea7\u0ec9\u0eaa\u0eb3\u0ea5\u0eb1\u0e9a\u0eaa\u0eb0\u0ea1\u0eb2\u0e8a\u0eb4\u0e81 Premiere Member \u0ec0\u0e97\u0ebb\u0ec8\u0eb2\u0e99\u0eb1\u0ec9\u0e99\n\n\u0e81\u0eb0\u0ea5\u0eb8\u0e99\u0eb2\u0ea2\u0eb7\u0e99\u0ea2\u0eb1\u0e99\u0e95\u0ebb\u0ea7\u0e95\u0ebb\u0e99 (KYC) \u0ec1\u0ea5\u0eb0 \u0eaa\u0eb0\u0edd\u0eb1\u0e81\u0ec1\u0e9e\u0eb1\u0e81\u0ec0\u0e81\u0eb1\u0e94\u0eaa\u0eb0\u0ea1\u0eb2\u0e8a\u0eb4\u0e81\u0ec0\u0e9e\u0eb7\u0ec8\u0ead\u0ec0\u0e82\u0ebb\u0ec9\u0eb2\u0ec0\u0e96\u0eb4\u0e87\u0e81\u0eb2\u0e99\u0e94\u0eb2\u0ea7\u0ec2\u0eab\u0ebc\u0e94',
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
                  label: const Text('\u0eaa\u0eb0\u0edd\u0eb1\u0e81\u0eaa\u0eb0\u0ea1\u0eb2\u0e8a\u0eb4\u0e81 Premiere', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  child: const Text('\u0ec4\u0ea7\u0ec9\u0e97\u0eb5\u0eab\u0ebc\u0eb1\u0e87', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _buildBodyContent(),
            ),
            // Bottom Navigation Bar
            _buildBottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    switch (_currentBottomNavIndex) {
      case 1:
        return const HistoryScreen();
      case 2:
        return const SavedScreen();
      case 3:
        return const DownloadsScreen();
      case 4:
        return const ProfileScreen();
      case 0:
      default:
        return RefreshIndicator(
          onRefresh: _loadBackendData,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. User Header Profile Bar
                _buildHeaderBar(),
                const SizedBox(height: 16),

                // 2. Search Bar
                _buildSearchBar(),
                const SizedBox(height: 16),

                // 3. Category Horizontal Chips
                _buildCategoryChips(),
                const SizedBox(height: 16),

                // KYC Identity Banner Prompt
                _buildKycPromptBanner(),
                const SizedBox(height: 20),

                // 4. Section 1: Popular
                _buildSectionHeader('ຍອດນິຍົມ', onSeeAll: () {}),
                const SizedBox(height: 12),
                _buildPopularBooksList(),
                const SizedBox(height: 24),

                // 5. Section 2: New Books
                _buildSectionHeader('ປຶ້ມໃໝ່', onSeeAll: () {}),
                const SizedBox(height: 12),
                _buildNewBooksList(),
                const SizedBox(height: 24),

                // 6. Section 3: Recommended
                _buildSectionHeader('ແນະນຳ', onSeeAll: () {}),
                const SizedBox(height: 12),
                _buildRecommendedBooksList(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
    }
  }

  // --- 1. Header Bar Widget ---
  Widget _buildHeaderBar() {
    final user = ApiService.currentUser ?? {};
    final firstName = user['first_name'] ?? 'ສົມຊາຍ';
    final lastName = user['last_name'] ?? 'ໃຈດີ';
    final role = user['role'] ?? 'user';
    final email = user['email'] ?? '';
    final isPremiere = role == 'admin' || role == 'employee' || email == 'member@gmail.com';

    return Row(
      children: [
        CircleAvatar(
          radius: 23,
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 18),
          ),
        ),
        const SizedBox(width: 12),

        // User Info Name & Badge
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$firstName $lastName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2EDFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isPremiere ? 'Premiere User' : 'General User',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Notification Bell Icon with Dot
        Stack(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKycPromptBanner() {
    // Hide the banner if KYC is already approved or pending
    if (_kycStatus == KycStatus.approved || _kycStatus == KycStatus.pending) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0047AB), Color(0xFF336BBD)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0047AB).withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'ຢືນຢັນຕົວຕົນ (KYC) ເພື່ອສະໝັກແພັກເກັດສະມາຊິກ',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  'ຍື່ນບັດປະຈຳຕົວລໍຖ້າແອດມິນອະນຸມັດເພື່ອອ່ານ PDF ແບບບໍ່ຈຳກັດ',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final user = ApiService.currentUser ?? {};
              final userId = (user['user_id'] ?? 3).toString();
              final userName = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
              final userEmail = user['email'] ?? '';

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => KycSubmissionScreen(
                    currentKyc: KycModel(
                      id: 'kyc_$userId',
                      userId: userId,
                      userName: userName.isNotEmpty ? userName : 'ຜູ້ໃຊ້ງານລະບົບ',
                      userEmail: userEmail,
                      idCardNumber: '',
                      fullName: userName,
                      idCardImagePath: '',
                      selfieImagePath: '',
                      status: KycStatus.notSubmitted,
                      submittedAt: DateTime.now(),
                    ),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 36),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('ຍື່ນ KYC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- 2. Search Bar Widget (Navigates to dedicated SearchScreen) ---
  Widget _buildSearchBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
        child: Row(
          children: const [
            Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 12),
            Text(
              'ຄົ້ນຫາປຶ້ມ ຫຼື ຊື່ຜູ້ແຕ່ງ...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            Spacer(),
            Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 18),
          ],
        ),
      ),
    );
  }

  // --- 3. Category Horizontal Filter ---
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _fetchedCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          final catName = _fetchedCategories[index]['name']?.toString() ?? 'ທັງໝົດ';
          return ChoiceChip(
            label: Text(catName),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: const Color(0xFFEFF3F8),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategoryIndex = index;
              });
              _loadBackendData();
            },
          );
        },
      ),
    );
  }

  // --- Section Title Header ---
  Widget _buildSectionHeader(String title, {required VoidCallback onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'ເບິ່ງທັງໝົດ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. Section 1: Popular Books Horizontal List ---
  Widget _buildPopularBooksList() {
    if (_isLoadingBooks) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final books = _fetchedBooks.where((b) => b.isPopular || b.isFree).toList();
    final displayBooks = books.isNotEmpty ? books : _fetchedBooks;

    if (displayBooks.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('ບໍ່ພົບປຶ້ມຍອດນິຍົມในขณะนี้')),
      );
    }

    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _buildBookCard(displayBooks[index]);
        },
      ),
    );
  }

  // --- 5. Section 2: New Books Vertical List ---
  Widget _buildNewBooksList() {
    if (_isLoadingBooks) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final books = _fetchedBooks.where((b) => b.isNew || b.ratingText == 'New').toList();
    final displayBooks = books.isNotEmpty ? books : _fetchedBooks;

    if (displayBooks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('ບໍ່ພົບປຶ້ມໃໝ່'),
      );
    }

    return Column(
      children: displayBooks.map((book) => _buildNewBookTile(book)).toList(),
    );
  }

  // --- 6. Section 3: Recommended Books Horizontal List ---
  Widget _buildRecommendedBooksList() {
    if (_isLoadingBooks) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final books = _fetchedBooks.where((b) => b.isRecommended || b.rating >= 4.0).toList();
    final displayBooks = books.isNotEmpty ? books : _fetchedBooks;

    if (displayBooks.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text('ບໍ່ພົບປຶ້ມແນະນຳ')),
      );
    }

    return SizedBox(
      height: 290,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayBooks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _buildBookCard(displayBooks[index]);
        },
      ),
    );
  }

  // --- Reusable Book Card Widget (Popular & Recommended) ---
  Widget _buildBookCard(BookModel book) {
    final isBookmarked = _bookmarkedIds.contains(book.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        width: 175,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Cover Image with Floating Bookmark Button
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildImage(book.imagePath, width: 155, height: 135),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: () => _toggleBookmark(book.id),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Title
          Text(
            book.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          // Author
          Text(
            book.author,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),

          // Rating Row
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                book.ratingText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Category Tag Pill
          if (book.tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                book.tags.first,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          const Spacer(),

          // Read Now + Download Action Buttons Row
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'อ่านเลย',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  if (!_isMember) {
                    _showMembershipRequiredDialog();
                    return;
                  }
                  // Proceed with download for members
                  final bookId = book.id;
                  ApiService.recordDownload(bookId).then((success) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? '\u0e94\u0eb2\u0ea7\u0ec2\u0eab\u0ebc\u0e94 "${book.title}" \u0eaa\u0eb3\u0ec0\u0ea5\u0eb1\u0e94!' : '\u0e9a\u0eb1\u0e99\u0e97\u0eb6\u0e81\u0ea5\u0eb2\u0e8d\u0e81\u0eb2\u0e99\u0e94\u0eb2\u0ea7\u0ec2\u0eab\u0ebc\u0e94\u0eaa\u0eb3\u0ec0\u0ea5\u0eb1\u0e94'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  });
                },
                child: Container(
                  height: 32,
                  width: 32,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.file_download_outlined,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildNewBookTile(BookModel book) {
    final isBookmarked = _bookmarkedIds.contains(book.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Book Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildImage(book.imagePath, width: 60, height: 75),
            ),
            const SizedBox(width: 12),

            // Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    book.author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Rating & Tags Row
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        book.ratingText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: book.tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),

            // Bookmark Icon Button
            IconButton(
              onPressed: () => _toggleBookmark(book.id),
              icon: Icon(
                isBookmarked ? Icons.bookmark : Icons.bookmark_border_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Bottom Navigation Bar Widget ---
  Widget _buildBottomNavigationBar() {
    final navItems = [
      {'icon': Icons.home_rounded, 'label': 'ໜ້າຫຼັກ'},
      {'icon': Icons.history_rounded, 'label': 'ປະຫວັດ'},
      {'icon': Icons.bookmark_outline_rounded, 'label': 'ບັນທຶກ'},
      {'icon': Icons.file_download_outlined, 'label': 'ດາວໂຫຼດ'},
      {'icon': Icons.person_outline_rounded, 'label': 'ໂປຣໄຟລ໌'},
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
          final isSelected = _currentBottomNavIndex == index;
          final item = navItems[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _currentBottomNavIndex = index;
              });
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
