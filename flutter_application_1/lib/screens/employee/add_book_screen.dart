import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class EmployeeAddBookScreen extends StatefulWidget {
  const EmployeeAddBookScreen({super.key});

  @override
  State<EmployeeAddBookScreen> createState() => _EmployeeAddBookScreenState();
}

class _EmployeeAddBookScreenState extends State<EmployeeAddBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pagesController = TextEditingController();
  final _priceController = TextEditingController();

  // State Variables
  String _selectedCategory = 'เทคโนโลยี';
  String _accessType = 'Premiere Member'; // 'Free', 'Premiere Member', 'Paid'
  
  // PDF File Upload Mock State
  String? _pdfFileName;
  double? _pdfFileSizeMB;
  bool _isUploadingPdf = false;
  double _pdfUploadProgress = 0.0;

  // Cover Image Upload Mock State
  String? _coverImagePath;
  bool _isUploadingCover = false;

  final List<String> _categories = [
    'เทคโนโลยี',
    'วิทยาศาสตร์',
    'ศิลปะ',
    'สุขภาพ',
    'ชีวิต & การพัฒนาตนเอง',
    'ธุรกิจ & การลงทุน',
    'นิยาย & การผจญภัย',
    'คณิตศาสตร์',
    'ภาษาต่างประเทศ',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _pagesController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // Simulate PDF Selection
  void _pickPdfFile() async {
    setState(() {
      _isUploadingPdf = true;
      _pdfUploadProgress = 0.2;
    });

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() => _pdfUploadProgress = 0.6);

    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _pdfUploadProgress = 1.0;
      _isUploadingPdf = false;
      _pdfFileName = _titleController.text.trim().isNotEmpty
          ? '${_titleController.text.trim().replaceAll(' ', '_')}.pdf'
          : 'flutter_ebook_document.pdf';
      _pdfFileSizeMB = 14.8;
      if (_pagesController.text.isEmpty) {
        _pagesController.text = '248';
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text('แนบไฟล์ PDFสำเร็จ: $_pdfFileName (${_pdfFileSizeMB}MB)')),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Simulate Cover Image Selection
  void _pickCoverImage() async {
    setState(() => _isUploadingCover = true);
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _isUploadingCover = false;
      _coverImagePath = 'assets/sample_cover.png';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เลือกรูปภาพปกเรียบร้อยแล้ว'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSaveBook() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pdfFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาอัปโหลดไฟล์ PDF หนังสือเข้าระบบก่อนทำการบันทึก'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Success Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 56),
            SizedBox(height: 12),
            Text(
              'เพิ่มหนังสือ PDF สำเร็จ!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'หนังสือเรื่อง "${_titleController.text.trim()}" ได้ถูกอัปโหลดและบันทึกเข้าสู่ระบบเรียบร้อยแล้ว',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context, true); // Return to previous screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ตกลง', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'ระบบเพิ่มหนังสือ PDF (พนักงาน)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ดูตัวอย่าง',
            icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.white),
            onPressed: () => _showPreviewModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Banner Header
                  _buildHeaderSection(),
                  const SizedBox(height: 24),

                  // 1. Upload PDF Section (Critical)
                  _buildPdfUploadSection(),
                  const SizedBox(height: 24),

                  // 2. Upload Cover Image Section
                  _buildCoverUploadSection(),
                  const SizedBox(height: 24),

                  const Divider(height: 32),

                  // 3. Book General Info Form
                  const Text(
                    'ข้อมูลทั่วไปของหนังสือ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  // Title Field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อหนังสือ *',
                      hintText: 'เช่น Flutter Web App Masterclass',
                      prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'กรุณากรอกชื่อหนังสือ' : null,
                  ),
                  const SizedBox(height: 16),

                  // Author Field
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้แต่ง / สำนักพิมพ์ *',
                      hintText: 'เช่น ดร. สมชาย วิทยาการ',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'กรุณากรอกชื่อผู้แต่ง' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category & Pages & Access Type
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return isMobile
                          ? Column(
                              children: [
                                _buildCategoryDropdown(),
                                const SizedBox(height: 16),
                                _buildPagesField(),
                                const SizedBox(height: 16),
                                _buildAccessTypeDropdown(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildCategoryDropdown()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildPagesField()),
                                const SizedBox(width: 12),
                                Expanded(child: _buildAccessTypeDropdown()),
                              ],
                            );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description / Synopsis Field
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'เรื่องย่อ / คำอธิบายหนังสือ',
                      hintText: 'กรอกเนื้อหาสรุปย่อของหนังสือเล่มนี้...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _formKey.currentState?.reset();
                            setState(() {
                              _pdfFileName = null;
                              _pdfFileSizeMB = null;
                              _coverImagePath = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('ล้างข้อมูล'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _onSaveBook,
                          icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                          label: const Text('บันทึกหนังสือเข้าสู่ระบบ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ส่วนงานพนักงาน (Staff Portal): เพิ่มหนังสืออิเล็กทรอนิกส์ (E-Book)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                SizedBox(height: 2),
                Text(
                  'รองรับไฟล์รูปแบบ PDF เท่านั้น (ขนาดสูงสุด 100MB ต่อไฟล์) พร้อมรูปปก JPG/PNG',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // PDF File Upload Widget
  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อัปโหลดไฟล์หนังสือ (PDF Document) *',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _pdfFileName != null ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _pdfFileName != null ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _pdfFileName != null ? const Color(0xFF10B981).withOpacity(0.15) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.picture_as_pdf_rounded,
                      color: _pdfFileName != null ? const Color(0xFF10B981) : AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _pdfFileName ?? 'เลือกไฟล์หนังสือ PDF (.pdf)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _pdfFileName != null ? const Color(0xFF065F46) : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pdfFileName != null
                              ? 'ขนาดไฟล์: $_pdfFileSizeMB MB • พร้อมใช้งาน'
                              : 'รองรับไฟล์เอกสาร PDF ทุกชนิด (ไม่เกิน 100MB)',
                          style: TextStyle(
                            fontSize: 12,
                            color: _pdfFileName != null ? const Color(0xFF047857) : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isUploadingPdf ? null : _pickPdfFile,
                    icon: Icon(
                      _pdfFileName != null ? Icons.swap_horiz_rounded : Icons.upload_file_rounded,
                      size: 18,
                    ),
                    label: Text(_pdfFileName != null ? 'เปลี่ยนไฟล์' : 'เลือกไฟล์ PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pdfFileName != null ? const Color(0xFF059669) : AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              if (_isUploadingPdf) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: _pdfUploadProgress,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Cover Image Upload Widget
  Widget _buildCoverUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'อัปโหลดรูปภาพปกหนังสือ (Cover Image)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _coverImagePath != null ? 'เลือกรูปปกเรียบร้อย (sample_cover.png)' : 'อัปโหลดรูปปก (JPG, PNG)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'อัตราส่วนที่แนะนำ 3:4 (เช่น 600x800 px)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isUploadingCover ? null : _pickCoverImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_coverImagePath != null ? 'เปลี่ยนรูป' : 'เลือกรูปปก'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'หมวดหมู่หนังสือ *',
        prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem(
          value: cat,
          child: Text(cat, style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedCategory = val);
      },
    );
  }

  Widget _buildPagesField() {
    return TextFormField(
      controller: _pagesController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'จำนวนหน้า (Pages)',
        hintText: 'เช่น 250',
        prefixIcon: Icon(Icons.auto_stories_outlined, color: AppColors.primary),
      ),
    );
  }

  Widget _buildAccessTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _accessType,
      decoration: const InputDecoration(
        labelText: 'สิทธิ์การเข้าถึงหนังสือ',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
      ),
      items: const [
        DropdownMenuItem(value: 'Free', child: Text('อ่านฟรี (ทุกสมาชิก)')),
        DropdownMenuItem(value: 'Premiere Member', child: Text('เฉพาะสมาชิก Premiere')),
        DropdownMenuItem(value: 'Paid', child: Text('ซื้ออ่านเป็นเล่ม')),
      ],
      onChanged: (val) {
        if (val != null) setState(() => _accessType = val);
      },
    );
  }

  void _showPreviewModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.preview_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('ตัวอย่างมุมมองหนังสือ (Preview)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                _titleController.text.isEmpty ? '(ยังไม่ได้ระบุชื่อหนังสือ)' : _titleController.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                _authorController.text.isEmpty ? 'ผู้แต่ง: (ไม่ระบุ)' : 'ผู้แต่ง: ${_authorController.text}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(label: Text('หมวดหมู่: $_selectedCategory')),
                const SizedBox(width: 8),
                Chip(label: Text('รูปแบบ: PDF (${_pagesController.text} หน้า)')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
