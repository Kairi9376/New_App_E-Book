import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';

class DeletedBooksScreen extends StatefulWidget {
  const DeletedBooksScreen({super.key});

  @override
  State<DeletedBooksScreen> createState() => _DeletedBooksScreenState();
}

class _DeletedBooksScreenState extends State<DeletedBooksScreen> {
  List<BookModel> _deletedBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDeletedBooks();
  }

  Future<void> _fetchDeletedBooks() async {
    setState(() => _isLoading = true);
    final books = await ApiService.getDeletedBooks();
    if (mounted) {
      setState(() {
        _deletedBooks = books;
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreBook(BookModel book) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Restore this book?'),
        content: Text('"${book.title}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final bool success = await ApiService.restoreBook(book.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book restored successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _fetchDeletedBooks();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to restore book'),
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
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/BookCover.jpg',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFE2E8F0)),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.25),
          ),
          const Center(
            child: Icon(Icons.restore_from_trash_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                color: Colors.redAccent.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.restore_from_trash_rounded,
                  color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'Deleted Books',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ຣີເຟຣຊ',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _fetchDeletedBooks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _deletedBooks.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restore_from_trash_rounded,
                          size: 48, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('ບໍ່ມີປຶ້ມທີ່ຖືກລົບ (Deleted Books is empty)',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchDeletedBooks,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _deletedBooks.length,
                    itemBuilder: (context, index) {
                      final book = _deletedBooks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildDeletedBookCard(book),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildDeletedBookCard(BookModel book) {
    final String categoryText =
        book.tags.isNotEmpty ? book.tags.first : 'ທົ່ວໄປ';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
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
                Text(book.title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(book.author,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Category
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
                    // Deleted Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Deleted',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Restore Button (ด้านขวา)
          IconButton(
            icon: const Icon(Icons.restore_rounded,
                color: Colors.green, size: 24),
            tooltip: 'Restore Book',
            onPressed: () => _restoreBook(book),
          ),
        ],
      ),
    );
  }
}
