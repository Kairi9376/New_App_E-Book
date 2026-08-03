class SavedBookItem {
  final String id;
  final int? bookmarkId;
  final int? bookId;
  final String title;
  final String author;
  final double rating;
  final String category;
  final String imagePath;
  final String? pdfUrl;
  final String? description;
  final bool isBookmarked;

  SavedBookItem({
    required this.id,
    this.bookmarkId,
    this.bookId,
    required this.title,
    required this.author,
    required this.rating,
    required this.category,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.isBookmarked = true,
  });

  factory SavedBookItem.fromMap(Map<String, dynamic> map, {String uploadsBaseUrl = 'http://localhost:5000/uploads'}) {
    double parsedRating = 4.5;
    if (map['rating'] != null) {
      parsedRating = double.tryParse(map['rating'].toString()) ?? 4.5;
    }

    String cover = map['cover_image_url'] ?? map['imagePath'] ?? '';
    if (cover.startsWith('/uploads/') || cover.startsWith('uploads/')) {
      cover = '$uploadsBaseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null && (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$uploadsBaseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    int? bmId = int.tryParse(map['bookmark_id']?.toString() ?? '');
    int? bId = int.tryParse(map['book_id']?.toString() ?? map['id']?.toString() ?? '');

    return SavedBookItem(
      id: (map['bookmark_id'] ?? map['book_id'] ?? map['id'] ?? '').toString(),
      bookmarkId: bmId,
      bookId: bId,
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      rating: parsedRating,
      category: map['category_name'] ?? map['category'] ?? 'ທົ່ວໄປ',
      imagePath: cover.isNotEmpty ? cover : 'assets/sample_cover.png',
      pdfUrl: pdf,
      description: map['description'] ?? '',
      isBookmarked: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookmark_id': bookmarkId ?? id,
      'book_id': bookId,
      'title': title,
      'author': author,
      'rating': rating,
      'category': category,
      'cover_image_url': imagePath,
      'file_pdf_url': pdfUrl,
      'description': description,
    };
  }
}

class MockSavedData {
  static List<SavedBookItem> savedItems = [
    SavedBookItem(
      id: '1',
      bookId: 3,
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      rating: 4.9,
      category: 'ເຕັກໂນໂລຊີ',
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isBookmarked: true,
    ),
    SavedBookItem(
      id: '2',
      bookId: 2,
      title: 'High School Science',
      author: 'Nageen Prakashan',
      rating: 4.8,
      category: 'ວິທະຍາສາດ',
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isBookmarked: true,
    ),
  ];
}
