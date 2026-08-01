import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';

class AdminBookDialog extends StatefulWidget {
  final BookModel? book;

  const AdminBookDialog({super.key, this.book});

  @override
  State<AdminBookDialog> createState() => _AdminBookDialogState();
}

class _AdminBookDialogState extends State<AdminBookDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _pagesController;
  late String _selectedCategory;

  final List<String> _categories = [
    'ວິທະຍາສາດ',
    'ສິນລະປະ',
    'ສຸຂະພາບ',
    'ຊີວິດ',
    'ຜະຈົນໄພ',
    'ເຕັກໂນໂລຊີ',
    'ຄະນິດສາດ',
    'English',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.book?.title ?? '');
    _authorController = TextEditingController(text: widget.book?.author ?? '');
    _pagesController = TextEditingController(text: '320');
    _selectedCategory = widget.book?.tags.isNotEmpty == true
        ? widget.book!.tags.first
        : _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _pagesController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final savedBook = BookModel(
        id: widget.book?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        rating: widget.book?.rating ?? 5.0,
        ratingText: widget.book?.ratingText ?? 'New',
        tags: [_selectedCategory],
        imagePath: widget.book?.imagePath ??
            '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg',
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.add_box_rounded,
                        color: AppColors.primary,
                        size: 26,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'ແກ້ໄຂຂໍ້ມູນປຶ້ມ' : 'ເພີ່ມປຶ້ມໃໝ່',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
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
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'ຊື່ປຶ້ມ',
                        hintText: 'ປ້ອນຊື່ປຶ້ມ',
                        prefixIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ປຶ້ມ' : null,
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'ຊື່ຜູ້ແຕ່ງ / ຜູ້ຂຽນ',
                        hintText: 'ປ້ອນຊື່ຜູ້ແຕ່ງ',
                        prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty ? 'ກະລຸນາປ້ອນຊື່ຜູ້ແຕ່ງ' : null,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: _categories.contains(_selectedCategory)
                                ? _selectedCategory
                                : _categories.first,
                            decoration: const InputDecoration(
                              labelText: 'ໝວດໝູ່',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat, style: const TextStyle(fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCategory = val;
                                });
                              }
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
                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
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
                                Text(
                                  'ອັບໂຫຼດໄຟລ໌ປຶ້ມ (PDF) *',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                Text(
                                  'ຮອງຮັບເອກະສານ .pdf (ສູງສຸດ 100MB)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('ເລືອກໄຟລ໌ PDF', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

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
                            child: const Icon(Icons.image_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ອັບໂຫຼດຮູບປົກປຶ້ມ',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'ຮອງຮັບ JPG, PNG (ບໍ່ເກີນ 5MB)',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('ເລືອກຮູບປົກ', style: TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(isEditing ? 'ບັນທຶກການແກ້ໄຂ' : 'ເພີ່ມປຶ້ມ'),
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
