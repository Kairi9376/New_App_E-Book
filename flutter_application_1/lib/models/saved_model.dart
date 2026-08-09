import '../services/api_config.dart';

class SavedBookItem {
  final String id;
  final int? bookmarkId;
  final int? bookId;
  final String title;
  final String author;
  final double rating;
  final int likeCount;
  final int viewCount;
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
    this.rating = 0.0,
    this.likeCount = 0,
    this.viewCount = 0,
    required this.category,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.isBookmarked = true,
  });

  String get formattedLikes {
    if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}k';
    }
    return likeCount.toString();
  }

  String get formattedViews {
    if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}k';
    }
    return viewCount.toString();
  }

  factory SavedBookItem.fromMap(Map<String, dynamic> map, {String? uploadsBaseUrl}) {
    final baseUrl = uploadsBaseUrl ?? ApiConfig.uploadsBaseUrl;
    double parsedRating = 0.0;
    if (map['rating'] != null) {
      parsedRating = double.tryParse(map['rating'].toString()) ?? 0.0;
    }

    int parsedLikes = int.tryParse(map['likes_count']?.toString() ?? map['like_count']?.toString() ?? map['likes']?.toString() ?? map['likeCount']?.toString() ?? '0') ?? 0;
    int parsedViews = int.tryParse(map['readers_count']?.toString() ?? map['view_count']?.toString() ?? map['views']?.toString() ?? map['readers']?.toString() ?? map['viewCount']?.toString() ?? '0') ?? 0;

    String cover = map['cover_image_url'] ?? map['imagePath'] ?? '';
    if (cover.startsWith('/uploads/') || cover.startsWith('uploads/')) {
      cover = '$baseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null && (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$baseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
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
      likeCount: parsedLikes,
      viewCount: parsedViews,
      category: (map['category_name'] ?? map['category'] ?? map['categories'] ?? 'ທົ່ວໄປ').toString(),
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
      'like_count': likeCount,
      'view_count': viewCount,
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
      likeCount: 450,
      viewCount: 1800,
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
      likeCount: 890,
      viewCount: 3200,
      category: 'ວິທະຍາສາດ',
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isBookmarked: true,
    ),
  ];
}
