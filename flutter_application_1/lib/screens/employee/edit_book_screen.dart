import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';

class EditBookScreen extends StatefulWidget {
  final BookModel book;

  const EditBookScreen({
    super.key,
    required this.book,
  });

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers (prefilled from widget.book)
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pagesController;
  late final TextEditingController _pdfUrlController;
  late final TextEditingController _coverUrlController;

  // State Variables
  late String _selectedLanguage;
  late bool _isFree;
  late bool _isFreeDownload;
  late bool _isHidden;

  // File Upload States
  String? _pdfFileName;
  bool _isUploadingPdf = false;
  double _pdfUploadProgress = 0.0;
  int _fileSizeBytes = 0;

  bool _isUploadingCover = false;

  // Data from MySQL Database
  List<Map<String, dynamic>> _dbCategories = [];
  List<Map<String, dynamic>> _dbAuthors = [];
  late Set<int> _selectedCategoryIds;
  int? _selectedAuthorId;
  bool _isLoadingData = true;

  // All 5 Database Languages ENUM('LA', 'TH', 'EN', 'JP', 'CN')
  final List<Map<String, String>> _languages = [
    {'code': 'LA', 'name': '🇱🇦 ພາສາລາວ (Lao - LA)'},
    {'code': 'TH', 'name': '🇹🇭 ພາສາໄທ (Thai - TH)'},
    {'code': 'EN', 'name': '🇬🇧 ພາສາອັງກິດ (English - EN)'},
    {'code': 'JP', 'name': '🇯🇵 ພາສາຢີ່ປຸ່ນ (Japanese - JP)'},
    {'code': 'CN', 'name': '🇨🇳 ພາສາຈີນ (Chinese - CN)'},
  ];

  @override
  void initState() {
    super.initState();

    // Prefill existing book data
    _titleController = TextEditingController(text: widget.book.title);
    _descriptionController =
        TextEditingController(text: widget.book.description ?? '');
    _pagesController = TextEditingController(
        text:
            (widget.book.pageCount > 0 ? widget.book.pageCount : 0).toString());
    _pdfUrlController = TextEditingController(text: widget.book.pdfUrl ?? '');
    _coverUrlController = TextEditingController(text: widget.book.imagePath);

    _selectedLanguage =
        widget.book.language.isEmpty ? 'LA' : widget.book.language;
    _isFree = widget.book.isFree;
    _isFreeDownload = widget.book.isFreeDownload;
    _isHidden = widget.book.isHidden;
    _selectedCategoryIds = Set<int>.from(widget.book.categoryIds);
    _selectedAuthorId = widget.book.authorId;
    _fileSizeBytes = widget.book.fileSizeBytes;
    _pdfFileName =
        (widget.book.pdfUrl != null && widget.book.pdfUrl!.isNotEmpty)
            ? widget.book.pdfUrl!.split('/').last
            : null;

    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getAuthors(),
      ]);

      final cats = results[0];
      final auths = results[1];

      if (mounted) {
        setState(() {
          _dbCategories = cats;
          _dbAuthors = auths;

          // Auto-select current book categories (only IDs that exist in DB)
          if (_selectedCategoryIds.isEmpty && _dbCategories.isNotEmpty) {
            _selectedCategoryIds = {_dbCategories.first['category_id']};
          }

          // Auto-select current book author by ID, fallback match by name
          if (_selectedAuthorId == null &&
              widget.book.author.isNotEmpty &&
              _dbAuthors.isNotEmpty) {
            final matchByName = _dbAuthors.where((a) =>
                a['name'].toString().trim().toLowerCase() ==
                widget.book.author.trim().toLowerCase());
            if (matchByName.isNotEmpty) {
              _selectedAuthorId = matchByName.first['author_id'];
            }
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pagesController.dispose();
    _pdfUrlController.dispose();
    _coverUrlController.dispose();
    super.dispose();
  }

  // Pick PDF File and Auto-detect Page Count (reuse pattern from add_book_screen)
  void _pickPdfFile() async {
    final fileInfo = await FilePickerHelper.pickFile(accept: '.pdf');
    if (fileInfo == null) return;

    setState(() {
      _isUploadingPdf = true;
      _pdfUploadProgress = 0.4;
      _pdfFileName = fileInfo.name;
      _fileSizeBytes = fileInfo.size;
      if (fileInfo.pageCount > 0) {
        _pagesController.text = fileInfo.pageCount.toString();
      }
    });

    final res = await ApiService.uploadFile(
      bytes: fileInfo.bytes,
      filename: fileInfo.name,
      fieldName: 'pdf',
    );

    if (mounted) {
      final sizeMB = (fileInfo.size / (1024 * 1024)).toStringAsFixed(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _pdfUploadProgress = 1.0;
          _isUploadingPdf = false;
          if (res['success'] == true) {
            _pdfUrlController.text =
                res['url'] ?? res['path'] ?? 'uploads/pdfs/${fileInfo.name}';
          } else {
            _pdfUrlController.text = 'uploads/pdfs/${fileInfo.name}';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    res['success'] == true
                        ? 'ອັບໂຫຼດ PDF ໃໝ່ "${fileInfo.name}" (${sizeMB}MB, ${fileInfo.pageCount} ໜ້າ) ສຳເລັດ'
                        : 'ເລືອກ PDF "${fileInfo.name}" ແລ້ວ',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  // Pick Cover Image from User's disk (reuse pattern from add_book_screen)
  void _pickCoverImage() async {
    final fileInfo =
        await FilePickerHelper.pickFile(accept: 'image/*,.jpg,.jpeg,.png');
    if (fileInfo == null) return;

    setState(() => _isUploadingCover = true);

    final res = await ApiService.uploadFile(
      bytes: fileInfo.bytes,
      filename: fileInfo.name,
      fieldName: 'cover',
    );

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _isUploadingCover = false;
          if (res['success'] == true) {
            _coverUrlController.text =
                res['url'] ?? res['path'] ?? 'uploads/covers/${fileInfo.name}';
          } else {
            _coverUrlController.text = 'uploads/covers/${fileInfo.name}';
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ອັບໂຫຼດຮູບປົກໃໝ່ "${fileInfo.name}" ສຳເລັດ'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      });
    }
  }

  void _openQuickAddAuthorModal() {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ເພີ່ມນັກຂຽນໃໝ່ (Quick Add Author)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'ຊື່ນັກຂຽນ *')),
            const SizedBox(height: 8),
            TextField(
                controller: bioCtrl,
                maxLines: 2,
                decoration:
                    const InputDecoration(labelText: 'ປະຫວັດຫຍໍ້ (Biography)')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.createAuthor(name,
                    bio: bioCtrl.text.trim());
                if (mounted && success) {
                  await _fetchFormData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('ເພີ່ມນັກຂຽນ "$name" ສຳເລັດ'),
                        backgroundColor: AppColors.primary),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('ເພີ່ມໃສ່ MySQL'),
          ),
        ],
      ),
    );
  }

  // Save: Update existing book (reuse pattern from add_book_screen._onSaveBook)
  void _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ກະລຸນາເລືອກຢ່າງໜ້ອຍ 1 ໝວດໝູ່'),
            backgroundColor: Colors.deepOrange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final bool success = await ApiService.updateBook(widget.book.id, {
      'title': _titleController.text.trim(),
      'author_id': _selectedAuthorId ?? 1,
      'category_ids': _selectedCategoryIds.toList(),
      'description': _descriptionController.text.trim(),
      'language': _selectedLanguage,
      'page_count':
          int.tryParse(_pagesController.text.trim()) ?? (widget.book.pageCount),
      'cover_image_url': _coverUrlController.text.trim().isNotEmpty
          ? _coverUrlController.text.trim()
          : null,
      'file_pdf_url': _pdfUrlController.text.trim().isNotEmpty
          ? _pdfUrlController.text.trim()
          : null,
      'file_size_bytes': _fileSizeBytes,
      'is_free': _isFree,
      'is_free_download': _isFreeDownload,
      'is_hidden': _isHidden,
    });

    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('ບັນທຶກການແກ້ໄຂ "${_titleController.text.trim()}" ສຳເລັດ!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ບໍ່ສາມາດບັນທຶກການແກ້ໄຂປຶ້ມໄດ້'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildCoverPreview() {
    final String coverUrl = _coverUrlController.text.trim();
    if (coverUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 70,
          height: 95,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/BookCover.jpg', fit: BoxFit.cover),
              Container(color: Colors.black.withOpacity(0.25)),
              const Center(child: Icon(Icons.image_outlined, color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (coverUrl.startsWith('http://') || coverUrl.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          coverUrl,
          width: 70,
          height: 95,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
              width: 70,
              height: 95,
              color: Colors.amber.shade100,
              child: const Icon(Icons.broken_image)),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        coverUrl,
        width: 70,
        height: 95,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
            width: 70,
            height: 95,
            color: Colors.blue.shade100,
            child: const Icon(Icons.book_rounded, color: AppColors.primary)),
      ),
    );
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
          children: const [
            Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              'ແກ້ໄຂປຶ້ມ (Edit Book)',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ],
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 680),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            key: const ValueKey('main_scaffold_body_column'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section 1: Basic Info
                        Row(
                          children: const [
                            Icon(Icons.info_outline_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text('1. ຂໍ້ມູນພື້ນຖານຂອງປຶ້ມ (Basic Information)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'ຊື່ປຶ້ມ (Book Title) *',
                            hintText: 'ປ້ອນຊື່ປຶ້ມ...',
                            prefixIcon: Icon(Icons.book_rounded,
                                color: AppColors.primary),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty
                              ? 'ກະລຸນາປ້ອນຊື່ປຶ້ມ'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Author Dropdown + Quick Add
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _dbAuthors.any((a) =>
                                        a['author_id'] == _selectedAuthorId)
                                    ? _selectedAuthorId
                                    : (_dbAuthors.isNotEmpty
                                        ? _dbAuthors.first['author_id']
                                        : null),
                                decoration: const InputDecoration(
                                  labelText: 'ນັກຂຽນ (Author - MySQL) *',
                                  prefixIcon: Icon(Icons.person_outline_rounded,
                                      color: AppColors.primary),
                                ),
                                items: _dbAuthors.map((a) {
                                  return DropdownMenuItem<int>(
                                    value: a['author_id'],
                                    child: Text(
                                        '${a['name']} (ID: ${a['author_id']})',
                                        style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedAuthorId = val);
                                },
                                validator: (val) =>
                                    val == null ? 'ກະລຸນາເລືອກນັກຂຽນ' : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.person_add_alt_1_rounded,
                                  color: AppColors.primary),
                              tooltip: 'ເພີ່ມນັກຂຽນໃໝ່',
                              onPressed: _openQuickAddAuthorModal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Language & Pages
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                value: _languages.any(
                                        (l) => l['code'] == _selectedLanguage)
                                    ? _selectedLanguage
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'ພາສາ (Language - ENUM)',
                                  prefixIcon: Icon(Icons.language_rounded,
                                      color: AppColors.primary),
                                ),
                                items: _languages.map((lang) {
                                  return DropdownMenuItem(
                                      value: lang['code'],
                                      child: Text(lang['name']!,
                                          style:
                                              const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null)
                                    setState(() => _selectedLanguage = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _pagesController,
                                readOnly: true,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'ຈຳນວນໜ້າ (Auto PDF Pages)',
                                  prefixIcon: Icon(Icons.auto_stories_rounded,
                                      color: AppColors.primary),
                                  filled: true,
                                  fillColor: Color(0xFFF8FAFC),
                                  helperText: 'ອ່ານຈຳນວນໜ້າຈາກ PDF ໂດຍອັດໂນມັດ',
                                  helperStyle: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Section 2: Categories (Multi-select)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.category_rounded,
                                    color: AppColors.primary, size: 18),
                                SizedBox(width: 6),
                                Text(
                                    '2. ໝວດໝູ່ປຶ້ມ (Categories - ເລືອກໄດ້ຫຼາຍໝວດໝູ່)',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                              ],
                            ),
                            Text('${_selectedCategoryIds.length} ໝວດໝູ່',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),

                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: _dbCategories.isEmpty
                              ? const Text('ບໍ່ມີໝວດໝູ່ໃນ MySQL')
                              : Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: _dbCategories.map((cat) {
                                    final catId = cat['category_id'] as int;
                                    final isSelected =
                                        _selectedCategoryIds.contains(catId);
                                    return FilterChip(
                                      selected: isSelected,
                                      label: Text(cat['name'].toString(),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textPrimary)),
                                      selectedColor: AppColors.primary,
                                      checkmarkColor: Colors.white,
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          side: BorderSide(
                                              color: isSelected
                                                  ? AppColors.primary
                                                  : Colors.grey.shade300)),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedCategoryIds.add(catId);
                                          } else if (_selectedCategoryIds
                                                  .length >
                                              1) {
                                            _selectedCategoryIds.remove(catId);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'ເນື້ອເລື່ອງ / ລາຍລະອຽດ (Description)',
                            hintText: 'ປ້ອນເນື້ອເລື່ອງຫຍໍ້...',
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section 3: Files Upload
                        Row(
                          children: const [
                            Icon(Icons.folder_zip_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text('3. ໄຟລ໌ PDF & ຮູບປົກ (PDF & Cover)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // PDF Upload
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color:
                                          AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                            'ອັບໂຫຼດ PDF ໃໝ່ (Replace PDF)',
                                            style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary)),
                                        Text(
                                            _pdfFileName ??
                                                'ບໍ່ໄດ້ປ່ຽນ — ໃຊ້ໄຟລ໌ເດີມ',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        _isUploadingPdf ? null : _pickPdfFile,
                                    icon: _isUploadingPdf
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.folder_open_rounded,
                                            size: 14),
                                    label: Text(
                                        _isUploadingPdf
                                            ? 'ອັບໂຫຼດ...'
                                            : 'ເລືອກ PDF',
                                        style: const TextStyle(fontSize: 11)),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary),
                                  ),
                                ],
                              ),
                              if (_isUploadingPdf) ...[
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                    value: _pdfUploadProgress,
                                    backgroundColor: Colors.white,
                                    color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // PDF Path/URL (existing)
                        TextFormField(
                          controller: _pdfUrlController,
                          decoration: const InputDecoration(
                            labelText: 'ເສັ້ນທາງໄຟລ໌ PDF (Path/URL)',
                            prefixIcon: Icon(Icons.link_rounded,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Cover Upload with Live Preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              _buildCoverPreview(),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('ຮູບປົກ (Cover Live Preview)',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold)),
                                    const Text('ເລືອກ JPG, PNG ໃໝ່ເພື່ອປ່ຽນ',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                    const SizedBox(height: 8),
                                    OutlinedButton.icon(
                                      onPressed: _isUploadingCover
                                          ? null
                                          : _pickCoverImage,
                                      icon: const Icon(
                                          Icons.photo_library_rounded,
                                          size: 14),
                                      label: const Text('ເລືອກຮູບປົກ',
                                          style: TextStyle(fontSize: 11)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Cover URL
                        TextFormField(
                          controller: _coverUrlController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'ເສັ້ນທາງຮູບປົກ (Cover Path/URL)',
                            prefixIcon: Icon(Icons.image_search_rounded,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section 4: Permission
                        Row(
                          children: const [
                            Icon(Icons.tune_rounded,
                                color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text('4. ຕັ້ງຄ່າສິດ (Permission)',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                dense: true,
                                title: const Text('ອ່ານຟຣີ (Free Access)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text(
                                    'ເປີດໃຫ້ສະມາຊິກທົ່ວໄປອ່ານໄດ້ໂດຍບໍ່ຕ້ອງສະໝັກສະມາຊິກ'),
                                value: _isFree,
                                activeColor: Colors.green,
                                onChanged: (val) =>
                                    setState(() => _isFree = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                dense: true,
                                title: const Text('ດາວໂຫຼດຟຣີ (Free PDF Download)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text(
                                    'ເປີດໃຫ້ດາວໂຫຼດຟຣີທຸກຄົນ (ຫາກປິດໄວ້ เฉพาะสมาชิก VIP/Premiere ເທົ່ານັ້ນທີ່ດາວໂຫຼດໄດ້)'),
                                value: _isFreeDownload,
                                activeColor: const Color(0xFF2563EB),
                                onChanged: (val) =>
                                    setState(() => _isFreeDownload = val),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                dense: true,
                                title: const Text('ເຊື່ອງປຶ້ມ (Hide Book)',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: const Text(
                                    'ເຊື່ອງປຶ້ມບໍ່ໃຫ້ສະແດງໃນໜ້າຫຼັກ (is_hidden = TRUE)'),
                                value: _isHidden,
                                activeColor: Colors.redAccent,
                                onChanged: (val) =>
                                    setState(() => _isHidden = val),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _onSave,
                            icon: const Icon(Icons.save_rounded),
                            label: const Text('ບັນທຶກການແກ້ໄຂ (Save Changes)',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
