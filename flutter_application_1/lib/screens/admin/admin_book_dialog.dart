import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminBookDialog extends StatefulWidget {
  final BookModel? book;

  const AdminBookDialog({super.key, this.book});

  @override
  State<AdminBookDialog> createState() => _AdminBookDialogState();
}

class _AdminBookDialogState extends State<AdminBookDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _pagesController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverUrlController;
  late TextEditingController _pdfUrlController;

  String _selectedLanguage = 'LA';
  bool _isFree = true;
  bool _isFreeDownload = false;
  bool _isHidden = false;

  bool _isUploadingPdf = false;
  bool _isUploadingCover = false;
  double _pdfUploadProgress = 0.0;
  String? _pdfFileName;
  int _fileSizeBytes = 0;

  // Data from MySQL Database
  List<Map<String, dynamic>> _dbCategories = [];
  List<Map<String, dynamic>> _dbAuthors = [];
  Set<int> _selectedCategoryIds = {};
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
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _pagesController = TextEditingController(text: (widget.book?.pageCount ?? 0).toString());
    _descriptionController = TextEditingController(text: widget.book?.description ?? '');
    _coverUrlController = TextEditingController(text: widget.book?.imagePath ?? '');
    _pdfUrlController = TextEditingController(text: widget.book?.pdfUrl ?? '');

    _selectedLanguage = widget.book?.language ?? 'LA';
    _isFree = widget.book?.isFree ?? true;
    _isFreeDownload = widget.book?.isFreeDownload ?? false;
    _isHidden = widget.book?.isHidden ?? false;

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

          // Set Multi-Category selection matching DB
          if (_dbCategories.isNotEmpty) {
            if (widget.book != null && widget.book!.categoryIds.isNotEmpty) {
              _selectedCategoryIds = Set<int>.from(widget.book!.categoryIds);
            } else if (_dbCategories.isNotEmpty) {
              _selectedCategoryIds = {_dbCategories.first['category_id']};
            }
          }

          // Set Author default / match
          if (_dbAuthors.isNotEmpty) {
            if (widget.book != null) {
              if (widget.book!.authorId != null) {
                final matchById = _dbAuthors.where((a) => a['author_id'] == widget.book!.authorId);
                if (matchById.isNotEmpty) {
                  _selectedAuthorId = widget.book!.authorId;
                }
              }
              if (_selectedAuthorId == null) {
                final bookAuthor = widget.book!.author;
                final matchByName = _dbAuthors.where((a) => a['name'].toString().trim().toLowerCase() == bookAuthor.trim().toLowerCase());
                if (matchByName.isNotEmpty) {
                  _selectedAuthorId = matchByName.first['author_id'];
                }
              }
              _selectedAuthorId ??= _dbAuthors.first['author_id'];
            } else {
              _selectedAuthorId = _dbAuthors.first['author_id'];
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
    _pagesController.dispose();
    _descriptionController.dispose();
    _coverUrlController.dispose();
    _pdfUrlController.dispose();
    super.dispose();
  }

  /// Opens native File Explorer to select real PDF from user's hard drive
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
      setState(() {
        _isUploadingPdf = false;
        _pdfUploadProgress = 1.0;
        if (res['success'] == true) {
          _pdfUrlController.text = res['url'] ?? res['path'] ?? 'uploads/pdfs/${fileInfo.name}';
        } else {
          _pdfUrlController.text = 'uploads/pdfs/${fileInfo.name}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? 'ອັບໂຫຼດ PDF "${fileInfo.name}" (${sizeMB}MB, ${fileInfo.pageCount} ໜ້າ) ສຳເລັດ'
              : 'ເລືອກ PDF "${fileInfo.name}" ແລ້ວ'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Opens native File Explorer to select real Cover Image from user's hard drive
  void _pickCoverImage() async {
    final fileInfo = await FilePickerHelper.pickFile(accept: 'image/*,.jpg,.jpeg,.png');
    if (fileInfo == null) return;

    setState(() => _isUploadingCover = true);

    final res = await ApiService.uploadFile(
      bytes: fileInfo.bytes,
      filename: fileInfo.name,
      fieldName: 'cover',
    );

    if (mounted) {
      setState(() {
        _isUploadingCover = false;
        if (res['success'] == true) {
          _coverUrlController.text = res['url'] ?? res['path'] ?? 'uploads/covers/${fileInfo.name}';
        } else {
          _coverUrlController.text = 'uploads/covers/${fileInfo.name}';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? 'ອັບໂຫຼດຮູບປົກ "${fileInfo.name}" ສຳເລັດ'
              : 'ເລືອກຮູບປົກ "${fileInfo.name}" ແລ້ວ'),
          backgroundColor: Colors.green,
        ),
      );
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
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ຊື່ນັກຂຽນ *')),
            const SizedBox(height: 8),
            TextField(controller: bioCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'ປະຫວັດຫຍໍ້ (Biography)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ຍົກເລີກ')),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await ApiService.createAuthor(name, bio: bioCtrl.text.trim());
                if (mounted && success) {
                  await _fetchFormData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ເພີ່ມນັກຂຽນ "$name" ສຳເລັດ'), backgroundColor: AppColors.primary),
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

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ກະລຸນາເລືອກຢ່າງໜ້ອຍ 1 ໝວດໝູ່'), backgroundColor: Colors.deepOrange),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final coverUrl = _coverUrlController.text.trim();
      final pdfUrl = _pdfUrlController.text.trim();
      final categoryIdsList = _selectedCategoryIds.toList();

      if (widget.book != null) {
        // Edit existing book
        await ApiService.updateBook(widget.book!.id, {
          'title': title,
          'author_id': _selectedAuthorId,
          'category_ids': categoryIdsList,
          'category_id': categoryIdsList.first,
          'description': description,
          'language': _selectedLanguage,
          'page_count': int.tryParse(_pagesController.text.trim()) ?? (widget.book?.pageCount ?? 0),
          'file_size_bytes': _fileSizeBytes,
          'cover_image_url': coverUrl.isNotEmpty ? coverUrl : null,
          'file_pdf_url': pdfUrl.isNotEmpty ? pdfUrl : null,
          'is_free': _isFree,
          'is_free_download': _isFreeDownload,
          'is_hidden': _isHidden,
        });
      } else {
        // Create new book
        final currentUser = ApiService.currentUser ?? {};
        final adminId = currentUser['user_id'] ?? 1;

        await ApiService.createBook({
          'title': title,
          'author_id': _selectedAuthorId ?? 1,
          'language': _selectedLanguage,
          'page_count': int.tryParse(_pagesController.text.trim()) ?? 0,
          'file_size_bytes': _fileSizeBytes,
          'description': description,
          'cover_image_url': coverUrl.isNotEmpty ? coverUrl : 'assets/sample_cover.png',
          'file_pdf_url': pdfUrl.isNotEmpty ? pdfUrl : 'assets/sample_book.pdf',
          'uploaded_by': adminId,
          'is_free': _isFree,
          'is_free_download': _isFreeDownload,
          'category_ids': categoryIdsList,
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      // Find author name for model
      String authorName = 'ບໍ່ລະບຸ';
      if (_selectedAuthorId != null) {
        final match = _dbAuthors.where((a) => a['author_id'] == _selectedAuthorId);
        if (match.isNotEmpty) authorName = match.first['name'] ?? '';
      }

      final savedBook = BookModel(
        id: widget.book?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        author: authorName,
        authorId: _selectedAuthorId,
        categoryIds: categoryIdsList,
        rating: widget.book?.rating ?? 5.0,
        ratingText: widget.book?.ratingText ?? 'New',
        imagePath: coverUrl.isNotEmpty ? coverUrl : 'assets/sample_cover.png',
        pdfUrl: pdfUrl.isNotEmpty ? pdfUrl : 'assets/sample_book.pdf',
        tags: _dbCategories.where((c) => _selectedCategoryIds.contains(c['category_id'])).map((c) => c['name'].toString()).toList(),
        description: description,
        isFree: _isFree,
        isFreeDownload: _isFreeDownload,
        isHidden: _isHidden,
      );

      Navigator.pop(context, savedBook);
    }
  }

  Widget _buildCoverPreview(String coverUrl) {
    if (coverUrl.isEmpty) {
      return Container(
        width: 70,
        height: 95,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: Colors.grey),
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
          errorBuilder: (_, __, ___) => Container(width: 70, height: 95, color: Colors.amber.shade100, child: const Icon(Icons.broken_image)),
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
        errorBuilder: (_, __, ___) => Container(width: 70, height: 95, color: Colors.blue.shade100, child: const Icon(Icons.book_rounded, color: AppColors.primary)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: _isLoadingData
            ? SizedBox(
                height: 220,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(color: AppColors.primary),
                      SizedBox(height: 14),
                      Text('ກຳລັງດຶງຂໍ້ມູນໝວດໝູ່ ແລະ ນັກຂຽນຈາກ MySQL...', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isEditing ? 'ແກ້ໄຂຂໍ້ມູນປຶ້ມ (Edit Book)' : 'ເພີ່ມປຶ້ມໃໝ່ເຂົ້າ MySQL (Add Book)',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Text(
                                      'ກໍານົດລາຍລະອຽດ, ໝວດໝູ່, ນັກຂຽນ ແລະ ໄຟລ໌ PDF',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SECTION 1: BASIC INFORMATION
                          Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text('1. ຂໍ້ມູນພື້ນຖານຂອງປຶ້ມ (Basic Information)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'ຊື່ປຶ້ມ (Book Title) *',
                              hintText: 'ປ້ອນຊື່ປຶ້ມ...',
                              prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ປຶ້ມ' : null,
                          ),
                          const SizedBox(height: 12),

                          // Author Dropdown + Quick Add Button
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _dbAuthors.any((a) => a['author_id'] == _selectedAuthorId) ? _selectedAuthorId : (_dbAuthors.isNotEmpty ? _dbAuthors.first['author_id'] : null),
                                  decoration: const InputDecoration(
                                    labelText: 'ນັກຂຽນ (Author - MySQL) *',
                                    prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                                  ),
                                  items: _dbAuthors.map((a) {
                                    return DropdownMenuItem<int>(
                                      value: a['author_id'],
                                      child: Text('${a['name']} (ID: ${a['author_id']})', style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedAuthorId = val);
                                  },
                                  validator: (val) => val == null ? 'ກະລຸນາເລືອກນັກຂຽນ' : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primary),
                                tooltip: 'ເພີ່ມນັກຂຽນໃໝ່',
                                onPressed: _openQuickAddAuthorModal,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Language Selection & Page Count Row
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedLanguage,
                                  decoration: const InputDecoration(
                                    labelText: 'ພາສາ (Language - ENUM)',
                                    prefixIcon: Icon(Icons.language_rounded, color: AppColors.primary),
                                  ),
                                  items: _languages.map((lang) {
                                    return DropdownMenuItem(value: lang['code'], child: Text(lang['name']!, style: const TextStyle(fontSize: 12)));
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedLanguage = val);
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
                                    prefixIcon: Icon(Icons.auto_stories_rounded, color: AppColors.primary),
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

                          // SECTION 2: CATEGORY SELECTION (Multi-Select FilterChips)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.category_rounded, color: AppColors.primary, size: 18),
                                  SizedBox(width: 6),
                                  Text('2. ໝວດໝູ່ປຶ້ມ (Categories - ເລືອກໄດ້หลายໝວດໝູ່)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                ],
                              ),
                              Text('${_selectedCategoryIds.length} ໝວດໝູ່', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
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
                                      final isSelected = _selectedCategoryIds.contains(catId);
                                      return FilterChip(
                                        selected: isSelected,
                                        label: Text(cat['name'].toString(), style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : AppColors.textPrimary)),
                                        selectedColor: AppColors.primary,
                                        checkmarkColor: Colors.white,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300)),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedCategoryIds.add(catId);
                                            } else if (_selectedCategoryIds.length > 1) {
                                              _selectedCategoryIds.remove(catId);
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 16),

                          // Synopsis Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'ເນື້ອເລື່ອງ / ລາຍລະອຽດ (Description)',
                              hintText: 'ປ້ອນເນື້ອເລື່ອງหຍໍ້...',
                            ),
                          ),
                          const SizedBox(height: 16),

                          // SECTION 3: FILES & MEDIA (PDF & COVER)
                          Row(
                            children: const [
                              Icon(Icons.folder_zip_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text('3. ໄຟລ໌ PDF & ຮູບປົກ (PDF Document & Cover)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // PDF Upload Box
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
                                        color: AppColors.primary.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ອັບໂຫຼດໄຟລ໌ PDF ຈາກເຄື່ອງ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          Text(_pdfFileName ?? 'ເລືອກໄຟລ໌ .pdf ຈາກ Disk (Auto count pages)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingPdf ? null : _pickPdfFile,
                                      icon: _isUploadingPdf
                                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.folder_open_rounded, size: 14),
                                      label: Text(_isUploadingPdf ? 'ອັບໂຫຼດ...' : 'ເລືອກ PDF', style: const TextStyle(fontSize: 11)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_isUploadingPdf) ...[
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(value: _pdfUploadProgress, backgroundColor: Colors.white, color: AppColors.primary),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _pdfUrlController,
                            decoration: const InputDecoration(
                              labelText: 'ເສັ້ນທາງໄຟລ໌ PDF (Path/URL)',
                              prefixIcon: Icon(Icons.link_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Cover Upload Box with Live Preview
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                _buildCoverPreview(_coverUrlController.text.trim()),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ຮູບປົກ (Cover Image Live Preview)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      const Text('ເລືອກ JPG, PNG ຈາກເຄື່ອງ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: _isUploadingCover ? null : _pickCoverImage,
                                        icon: const Icon(Icons.photo_library_rounded, size: 14),
                                        label: const Text('ເລືອກຮູບປົກ', style: TextStyle(fontSize: 11)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _coverUrlController,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'ເສັ້ນທາງຮູບປົກ (Cover Image Path/URL)',
                              prefixIcon: Icon(Icons.image_search_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // SECTION 4: PERMISSIONS & VISIBILITY
                          Row(
                            children: const [
                              Icon(Icons.tune_rounded, color: AppColors.primary, size: 18),
                              SizedBox(width: 6),
                              Text('4. ຕັ້ງຄ່າສิทธิ์ & ການສະແດງຜົນ (Permissions & Visibility)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  dense: true,
                                  title: const Text('ອ່ານຟຣີ (Free Access)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('ເປີດໃຫ້ສະມາຊິກທົ່ວໄປອ່ານໄດ້ໂດຍບໍ່ຕ້ອງສະໝັກສະມາຊິກ'),
                                  value: _isFree,
                                  activeColor: Colors.green,
                                  onChanged: (val) => setState(() => _isFree = val),
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  dense: true,
                                  title: const Text('ດາວໂຫຼດຟຣີ (Free PDF Download)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('ເປີດໃຫ້ດາວໂຫຼດຟຣີທຸກຄົນ (ຫາກປິດໄວ້ เฉพาะสมาชิก VIP/Premiere ເທົ່ານັ້ນທີ່ດາວໂຫຼດໄດ້)'),
                                  value: _isFreeDownload,
                                  activeColor: const Color(0xFF2563EB),
                                  onChanged: (val) => setState(() => _isFreeDownload = val),
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  dense: true,
                                  title: const Text('ເຊື່ອງປຶ້ມ (Hide Book)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('ເຊື່ອງປຶ້ມບໍ່ໃຫ້ສະແດງໃນໜ້າຫຼັກ (is_hidden = TRUE)'),
                                  value: _isHidden,
                                  activeColor: Colors.redAccent,
                                  onChanged: (val) => setState(() => _isHidden = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Save & Cancel Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 46),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('ຍົກເລີກ'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _onSave,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 46),
                                    backgroundColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(isEditing ? 'ບັນທຶກການແກ້ໄຂ' : 'ເພີ່ມປຶ້ມໃສ່ MySQL'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
