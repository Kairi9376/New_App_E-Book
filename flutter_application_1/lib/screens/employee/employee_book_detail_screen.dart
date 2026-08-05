import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import 'edit_book_screen.dart';

class EmployeeBookDetailScreen extends StatefulWidget {
  final BookModel book;

  const EmployeeBookDetailScreen({
    super.key,
    required this.book,
  });

  @override
  State<EmployeeBookDetailScreen> createState() =>
      _EmployeeBookDetailScreenState();
}

class _EmployeeBookDetailScreenState extends State<EmployeeBookDetailScreen> {
  // ใช้ book ที่ได้รับตอนเปิดหน้า
  late BookModel _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  // แปลง bytes เป็น KB / MB (ตัวอย่าง: 15.4 MB)
  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Unknown';
    final kb = bytes / 1024;
    if (kb < 1024) {
      return '${kb.toStringAsFixed(1)} KB';
    }
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(1)} MB';
  }

  // ลบหนังสือด้วย logic เดียวกับ book_management_screen.dart
  Future<void> _deleteBook() async {
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

    final bool success = await ApiService.deleteBook(_book.id);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ລົບປຶ້ມສຳເລັດແລ້ວ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      Navigator.pop(context, true); // กลับไปยังหน้าก่อนหน้า + สัญญาณ refresh
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ລົບປຶ້ມບໍ່ສຳເລັດ!'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // เปิด EditBookScreen — หลังกลับ ถ้า result == true -> pop กลับเอง
  Future<void> _openEditBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditBookScreen(book: _book),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true); // กลับไป Book Management + refresh
    }
  }

  // แสดงรูปโดยใช้ pattern เดิม (Network / Asset / Placeholder)
  Widget _buildImage() {
    final String path = _book.imagePath;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/BookCover.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
        Container(
          color: Colors.black.withOpacity(0.25),
        ),
        const Center(
          child: Icon(Icons.menu_book_rounded, color: Colors.white, size: 48),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String categoryText =
        _book.tags.isNotEmpty ? _book.tags.join(', ') : 'ທົ່ວໄປ';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Book Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== ส่วนที่ 1: Cover =====
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: 160,
                      height: 230,
                      child: _buildImage(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ===== ส่วนที่ 2: Basic Information =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('Basic Information',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow('Title', _book.title),
                      _buildInfoRow('Author', _book.author),
                      _buildInfoRow('Category', categoryText),
                      _buildInfoRow('Language', _book.language),
                      _buildInfoRow(
                          'Pages',
                          _book.pageCount > 0
                              ? '${_book.pageCount} pages'
                              : '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== ส่วนที่ 3: File Information =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.folder_zip_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('File Information',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow(
                        'PDF',
                        _book.pdfUrl != null && _book.pdfUrl!.isNotEmpty
                            ? 'PDF Available'
                            : 'No PDF',
                      ),
                      _buildInfoRow(
                        'PDF URL',
                        _book.pdfUrl ?? '-',
                      ),
                      _buildInfoRow(
                        'File Size',
                        _formatFileSize(_book.fileSizeBytes),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== ส่วนที่ 4: Permission Status =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.tune_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('Permission Status',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          // Free / Paid Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _book.isFree
                                  ? Colors.green.shade50
                                  : Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _book.isFree
                                      ? Icons.check_circle_rounded
                                      : Icons.warning_amber_rounded,
                                  size: 14,
                                  color: _book.isFree
                                      ? Colors.green
                                      : Colors.amber.shade900,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _book.isFree ? 'Free' : 'Paid',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _book.isFree
                                        ? Colors.green
                                        : Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Hidden Badge
                          if (_book.isHidden) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.visibility_off_rounded,
                                      size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Hidden',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          // Deleted Badge
                          if (_book.isDeleted) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.delete_outline_rounded,
                                      size: 14, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Deleted',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== ส่วนที่ 5: Description =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.notes_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('Description',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      Text(
                        (_book.description != null &&
                                _book.description!.isNotEmpty)
                            ? _book.description!
                            : 'No description',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ===== ส่วนที่ 6: Date =====
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_today_rounded,
                              color: AppColors.primary, size: 18),
                          SizedBox(width: 6),
                          Text('Date',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ],
                      ),
                      const Divider(height: 16),
                      _buildInfoRow('Created', _book.createdAt ?? '-'),
                      // BookModel ไม่มี updatedAt field — แสดง '-' ตามกำหนด
                      _buildInfoRow('Updated', '-'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ===== Action Buttons =====
                Row(
                  children: [
                    // Button 1: Edit Book
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openEditBook,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit Book',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Button 2: Delete Book
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _deleteBook,
                        icon:
                            const Icon(Icons.delete_outline_rounded, size: 18),
                        label: const Text('Delete',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
