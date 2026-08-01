import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../services/api_service.dart';
import '../../services/file_picker_helper.dart';

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
  bool _isHidden = false;

  bool _isUploadingPdf = false;
  bool _isUploadingCover = false;
  double _pdfUploadProgress = 0.0;
  String? _pdfFileName;

  // Data from MySQL Database
  List<Map<String, dynamic>> _dbCategories = [];
  List<Map<String, dynamic>> _dbAuthors = [];
  int? _selectedCategoryId;
  int? _selectedAuthorId;
  bool _isLoadingData = true;

  final List<Map<String, String>> _languages = [
    {'code': 'LA', 'name': 'ພາສາລາວ (LA)'},
    {'code': 'TH', 'name': 'ພາສາໄທ (TH)'},
    {'code': 'EN', 'name': 'ພາສາອັງກິດ (EN)'},
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _pagesController = TextEditingController(text: '320');
    _descriptionController = TextEditingController(text: widget.book?.description ?? '');
    _coverUrlController = TextEditingController(text: widget.book?.imagePath ?? '');
    _pdfUrlController = TextEditingController(text: widget.book?.pdfUrl ?? '');

    _selectedLanguage = 'LA';
    _isFree = widget.book?.isFree ?? true;
    _isHidden = false;

    _fetchFormData();
  }

  Future<void> _fetchFormData() async {
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getAuthors(),
      ]);

      final cats = results[0] as List<Map<String, dynamic>>;
      final auths = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _dbCategories = cats;
          _dbAuthors = auths;

          // Set Category default / match
          if (_dbCategories.isNotEmpty) {
            if (widget.book != null) {
              // 1. Try matching by categoryId
              if (widget.book!.categoryIds.isNotEmpty) {
                final targetId = widget.book!.categoryIds.first;
                final matchById = _dbCategories.where((c) => c['category_id'] == targetId);
                if (matchById.isNotEmpty) {
                  _selectedCategoryId = targetId;
                }
              }
              // 2. Fallback to tag name match
              if (_selectedCategoryId == null && widget.book!.tags.isNotEmpty) {
                final bookTag = widget.book!.tags.first;
                final matchByTag = _dbCategories.where((c) => c['name'].toString().contains(bookTag) || bookTag.contains(c['name'].toString()));
                if (matchByTag.isNotEmpty) {
                  _selectedCategoryId = matchByTag.first['category_id'];
                }
              }
              _selectedCategoryId ??= _dbCategories.first['category_id'];
            } else {
              _selectedCategoryId = _dbCategories.first['category_id'];
            }
          }

          // Set Author default / match
          if (_dbAuthors.isNotEmpty) {
            if (widget.book != null) {
              // 1. Try matching by authorId
              if (widget.book!.authorId != null) {
                final matchById = _dbAuthors.where((a) => a['author_id'] == widget.book!.authorId);
                if (matchById.isNotEmpty) {
                  _selectedAuthorId = widget.book!.authorId;
                }
              }
              // 2. Fallback to author name match
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
    });

    final res = await ApiService.uploadFile(
      bytes: fileInfo.bytes,
      filename: fileInfo.name,
      fieldName: 'pdf',
    );

    if (mounted) {
      setState(() {
        _isUploadingPdf = false;
        _pdfUploadProgress = 1.0;
        if (res['success'] == true) {
          _pdfUrlController.text = res['url'] ?? res['path'] ?? 'uploads/pdf/${fileInfo.name}';
        } else {
          _pdfUrlController.text = 'uploads/pdf/${fileInfo.name}';
        }
      });

      final sizeMB = (fileInfo.size / (1024 * 1024)).toStringAsFixed(2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['success'] == true
              ? 'ອັບໂຫຼດ PDF "${fileInfo.name}" (${sizeMB}MB) ສຳເລັດ'
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

  void _onSave() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final title = _titleController.text.trim();
      final description = _descriptionController.text.trim();
      final coverUrl = _coverUrlController.text.trim();
      final pdfUrl = _pdfUrlController.text.trim();

      if (widget.book != null) {
        // Edit existing book
        await ApiService.updateBook(widget.book!.id, {
          'title': title,
          'author_id': _selectedAuthorId,
          'category_id': _selectedCategoryId,
          'category_ids': _selectedCategoryId != null ? [_selectedCategoryId] : [],
          'description': description,
          'language': _selectedLanguage,
          'page_count': int.tryParse(_pagesController.text.trim()) ?? 320,
          'cover_image_url': coverUrl.isNotEmpty ? coverUrl : null,
          'file_pdf_url': pdfUrl.isNotEmpty ? pdfUrl : null,
          'is_free': _isFree,
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
          'page_count': int.tryParse(_pagesController.text.trim()) ?? 320,
          'description': description,
          'cover_image_url': coverUrl.isNotEmpty ? coverUrl : 'assets/sample_cover.png',
          'file_pdf_url': pdfUrl.isNotEmpty ? pdfUrl : 'assets/sample_book.pdf',
          'uploaded_by': adminId,
          'is_free': _isFree,
          'category_ids': _selectedCategoryId != null ? [_selectedCategoryId] : [1],
        });
      }

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading

      // Find author name for the returned model
      String authorName = 'ບໍ່ລະບຸ';
      if (_selectedAuthorId != null) {
        final match = _dbAuthors.where((a) => a['author_id'] == _selectedAuthorId);
        if (match.isNotEmpty) authorName = match.first['name'] ?? '';
      }

      String categoryName = 'ທົ່ວໄປ';
      if (_selectedCategoryId != null) {
        final match = _dbCategories.where((c) => c['category_id'] == _selectedCategoryId);
        if (match.isNotEmpty) categoryName = match.first['name'] ?? '';
      }

      final savedBook = BookModel(
        id: widget.book?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        author: authorName,
        rating: widget.book?.rating ?? 5.0,
        ratingText: widget.book?.ratingText ?? 'New',
        tags: [categoryName],
        imagePath: coverUrl.isNotEmpty ? coverUrl : (widget.book?.imagePath ?? 'assets/sample_cover.png'),
        pdfUrl: pdfUrl.isNotEmpty ? pdfUrl : widget.book?.pdfUrl,
        description: description,
        isFree: _isFree,
      );
      Navigator.pop(context, savedBook);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.book != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 560),
        child: _isLoadingData
            ? SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('ກຳລັງດຶງຂໍ້ມູນໝວດໝູ່ ແລະ ນັກຂຽນ...'),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  isEditing ? 'ແກ້ໄຂຂໍ້ມູນປຶ້ມ (Edit Book)' : 'ເພີ່ມປຶ້ມໃໝ່ (Add Book)',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.ellipsis,
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
                    const Divider(height: 20),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Book Title
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'ຊື່ປຶ້ມ *',
                              hintText: 'ປ້ອນຊື່ປຶ້ມ...',
                              prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                            ),
                            validator: (value) => value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ປຶ້ມ' : null,
                          ),
                          const SizedBox(height: 12),

                          // Author Dropdown (from MySQL DB)
                          DropdownButtonFormField<int>(
                            value: _dbAuthors.any((a) => a['author_id'] == _selectedAuthorId) ? _selectedAuthorId : (_dbAuthors.isNotEmpty ? _dbAuthors.first['author_id'] : null),
                            decoration: const InputDecoration(
                              labelText: 'ນັກຂຽນ (Author - ຈາກຖານຂໍ້ມູນ) *',
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
                          const SizedBox(height: 12),

                          // Category Dropdown (from MySQL DB)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: _dbCategories.any((c) => c['category_id'] == _selectedCategoryId) ? _selectedCategoryId : (_dbCategories.isNotEmpty ? _dbCategories.first['category_id'] : null),
                                  decoration: const InputDecoration(
                                    labelText: 'ໝວດໝູ່ (Category - DB)',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: _dbCategories.map((cat) {
                                    return DropdownMenuItem<int>(
                                      value: cat['category_id'],
                                      child: Text('${cat['name']}', style: const TextStyle(fontSize: 13)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategoryId = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _pagesController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'ຈຳນວນໜ້າ',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Language Selection
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            decoration: const InputDecoration(
                              labelText: 'ພາສາຂອງປຶ້ມ (Language)',
                              prefixIcon: Icon(Icons.language_rounded, color: AppColors.primary),
                            ),
                            items: _languages.map((lang) {
                              return DropdownMenuItem(value: lang['code'], child: Text(lang['name']!));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedLanguage = val);
                            },
                          ),
                          const SizedBox(height: 12),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'ເນື້ອເລື່ອງ / ລາຍລະອຽດ (Description)',
                              hintText: 'ປ້ອນເນື້ອເລື່ອງ...',
                            ),
                          ),
                          const SizedBox(height: 14),

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
                                          const Text('ອັບໂຫຼດໄຟລ໌ PDF', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                          Text(_pdfFileName ?? 'ເລືອກໄຟລ໌ .pdf ຈາກເຄື່ອງ (ສູງສຸດ 100MB)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _isUploadingPdf ? null : _pickPdfFile,
                                      icon: _isUploadingPdf
                                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                          : const Icon(Icons.folder_open_rounded, size: 14),
                                      label: Text(_isUploadingPdf ? 'ກຳລັງອັບໂຫຼດ...' : 'ເລືອກ PDF', style: const TextStyle(fontSize: 11)),
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
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _pdfUrlController,
                            decoration: const InputDecoration(
                              labelText: 'ເສັ້ນທາງໄຟລ໌ PDF (Path/URL)',
                              prefixIcon: Icon(Icons.link_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Cover Image Upload
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: _isUploadingCover
                                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                                      : const Icon(Icons.image_outlined, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text('ອັບໂຫຼດຮູບປົກ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text('ເລືອກ JPG, PNG ຈາກເຄື່ອງ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _isUploadingCover ? null : _pickCoverImage,
                                  icon: const Icon(Icons.photo_library_rounded, size: 14),
                                  label: const Text('ເລືອກຮູບປົກ', style: TextStyle(fontSize: 11)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          TextFormField(
                            controller: _coverUrlController,
                            decoration: const InputDecoration(
                              labelText: 'ເສັ້ນທາງຮູບປົກ (Cover Image Path/URL)',
                              prefixIcon: Icon(Icons.image_search_rounded, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Toggles
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  subtitle: const Text('ເປີດໃຫ້ສະມາຊິກທົ່ວໄປອ່ານໄດ້'),
                                  value: _isFree,
                                  activeColor: Colors.green,
                                  onChanged: (val) => setState(() => _isFree = val),
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  dense: true,
                                  title: const Text('ເຊື່ອງປຶ້ມ (Hide Book)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('ເຊື່ອງປຶ້ມບໍ່ໃຫ້ແສດງໃນໜ້າຫຼັກ'),
                                  value: _isHidden,
                                  activeColor: Colors.redAccent,
                                  onChanged: (val) => setState(() => _isHidden = val),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
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
