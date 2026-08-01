import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

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
  String _selectedCategory = 'ເຕັກໂນໂລຊີ';
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
    'ເຕັກໂນໂລຊີ',
    'ວິທະຍາສາດ',
    'ສິນລະປະ',
    'ສຸຂະພາບ',
    'ຊີວິດ & ການພັດທະນາຕົນເອງ',
    'ທຸລະກິດ & ການລົງທຶນ',
    'ນວນນິຍາຍ & ຜະຈົນໄພ',
    'ຄະນິດສາດ',
    'ພາສາຕ່າງປະເທດ',
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
              Expanded(child: Text('ແນບໄຟລ໌ PDF ສຳເລັດ: $_pdfFileName (${_pdfFileSizeMB}MB)')),
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
          content: Text('ອັບໂຫຼດຮູບປົກສຳເລັດ (sample_cover.png)'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSaveBook() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pdfFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ກະລຸນາແນບໄຟລ໌ PDF ຂອງປຶ້ມກ່ອນບັນທຶກ'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final currentUser = ApiService.currentUser ?? {};
    final userId = currentUser['user_id'] ?? 2; // Default to Staff/Employee ID

    final response = await ApiService.createBook({
      'title': _titleController.text.trim(),
      'author_id': 1, // Default author ID
      'language': 'LA',
      'page_count': int.tryParse(_pagesController.text.trim()) ?? 100,
      'description': _descriptionController.text.trim(),
      'cover_image_url': _coverImagePath ?? 'assets/sample_cover.png',
      'file_pdf_url': _pdfFileName ?? 'assets/sample_book.pdf',
      'uploaded_by': userId,
      'is_free': _accessType == 'Free',
      'category_ids': [1]
    });

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading dialog

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ບັນທຶກປຶ້ມ PDF "${_titleController.text.trim()}" ເຂົ້າລະບົບສຳເລັດ!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message'] ?? 'ບໍ່ສາມາດບັນທຶກປຶ້ມໄດ້'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            const Text(
              'ລະບົບເພີ່ມປຶ້ມ PDF (ພະນັກງານ)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'ເບິ່ງຕົວຢ່າງ',
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
                  _buildHeaderSection(),
                  const SizedBox(height: 24),

                  _buildPdfUploadSection(),
                  const SizedBox(height: 24),

                  _buildCoverUploadSection(),
                  const SizedBox(height: 24),

                  const Divider(height: 32),

                  const Text(
                    'ຂໍ້ມູນທົ່ວໄປຂອງປຶ້ມ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'ຊື່ປຶ້ມ *',
                      hintText: 'ເຊັ່ນ: Flutter Web App Masterclass',
                      prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ປຶ້ມ' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(
                      labelText: 'ຊື່ຜູ້ແຕ່ງ / ໂຮງພິມ *',
                      hintText: 'ເຊັ່ນ: ດຣ. ສົມໄຊ ວິທະຍາການ',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ຜູ້ແຕ່ງ' : null,
                  ),
                  const SizedBox(height: 16),

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

                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'ເນື້ອເຣື່ອງຫຍໍ້ / ຄຳອະທິບາຍປຶ້ມ',
                      hintText: 'ປ້ອນເນື້ອຫາສະຫຼຸບຫຍໍ້ຂອງປຶ້ມເລີ່ມນີ້...',
                      alignLabelWithHint: true,
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(Icons.description_outlined, color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

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
                          label: const Text('ລ້າງຂໍ້ມູນ'),
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
                          label: const Text('ບັນທຶກປຶ້ມເຂົ້າສູ່ລະບົບ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                const Text(
                  'ສ່ວນງານພະນັກງານ (Staff Portal): ເພີ່ມປຶ້ມອິດເລັກໂທຣນິກ (E-Book)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'ຮອງຮັບໄຟລ໌ຮູບແບບ PDF ເທົ່ານັ້ນ (ຂະໜາດສູງສຸດ 100MB ຕໍ່ໄຟລ໌) ພ້ອມຮູບປົກ JPG/PNG',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ອັບໂຫຼດໄຟລ໌ປຶ້ມ (PDF Document) *',
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
                          _pdfFileName ?? 'ເລືອກໄຟລ໌ປຶ້ມ PDF (.pdf)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _pdfFileName != null ? const Color(0xFF065F46) : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _pdfFileName != null
                              ? 'ຂະໜາດໄຟລ໌: $_pdfFileSizeMB MB • ພ້ອມໃຊ້ງານ'
                              : 'ຮອງຮັບໄຟລ໌ເອກະສານ PDF ທຸກຊະນິດ (ບໍ່ເກີນ 100MB)',
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
                    label: Text(_pdfFileName != null ? 'ປ່ຽນໄຟລ໌' : 'ເລືອກໄຟລ໌ PDF'),
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

  Widget _buildCoverUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ອັບໂຫຼດຮູບພາບປົກປຶ້ມ (Cover Image)',
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
                      _coverImagePath != null ? 'ເລືອກຮູບປົກຮຽບຮ້ອຍ (sample_cover.png)' : 'ອັບໂຫຼດຮູບປົກ (JPG, PNG)',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ອັດຕາສ່ວນທີ່ແນະນຳ 3:4 (ເຊັ່ນ 600x800 px)',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _isUploadingCover ? null : _pickCoverImage,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(_coverImagePath != null ? 'ປ່ຽນຮູບ' : 'ເລືອກຮູບປົກ'),
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
        labelText: 'ໝວດໝູ່ປຶ້ມ *',
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
        labelText: 'ຈຳນວນໜ້າ (Pages)',
        hintText: 'ເຊັ່ນ 250',
        prefixIcon: Icon(Icons.auto_stories_outlined, color: AppColors.primary),
      ),
    );
  }

  Widget _buildAccessTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _accessType,
      decoration: const InputDecoration(
        labelText: 'ສິດການເຂົ້າເຖິງປຶ້ມ',
        prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.primary),
      ),
      items: const [
        DropdownMenuItem(value: 'Free', child: Text('ອ່ານຟຣີ (ທຸກສະມາຊິກ)')),
        DropdownMenuItem(value: 'Premiere Member', child: Text('ສະເພາະສະມາຊິກ Premiere')),
        DropdownMenuItem(value: 'Paid', child: Text('ຊື້ອ່ານເປັນເລີ່ມ')),
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
                    const Icon(Icons.preview_rounded, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('ຕົວຢ່າງມຸມມອງປຶ້ມ (Preview)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                _titleController.text.isEmpty ? '(ຍັງບໍ່ໄດ້ລະບຸຊື່ປຶ້ມ)' : _titleController.text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Center(
              child: Text(
                _authorController.text.isEmpty ? 'ຜູ້ແຕ່ງ: (ບໍ່ລະບຸ)' : 'ຜູ້ແຕ່ງ: ${_authorController.text}',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Chip(label: Text('ໝວດໝູ່: $_selectedCategory')),
                const SizedBox(width: 8),
                Chip(label: Text('ຮູບແບບ: PDF (${_pagesController.text} ໜ້າ)')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
