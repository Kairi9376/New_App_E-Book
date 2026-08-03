class BookModel {
  final String id;
  final String title;
  final String author;
  final int? authorId;
  final List<int> categoryIds;
  final String language; // ENUM('LA', 'TH', 'EN', 'JP', 'CN')
  final int pageCount;
  final int fileSizeBytes;
  final double rating;
  final String ratingText;
  final List<String> tags;
  final String imagePath;
  final String? pdfUrl;
  final String? description;
  final int? uploadedBy;
  final bool isPopular;
  final bool isNew;
  final bool isRecommended;
  final bool isBookmarked;
  final bool isFree;
  final bool isHidden;
  final String? createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.authorId,
    this.categoryIds = const [],
    this.language = 'LA',
    this.pageCount = 0,
    this.fileSizeBytes = 0,
    required this.rating,
    this.ratingText = '',
    required this.tags,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.uploadedBy,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.isBookmarked = false,
    this.isFree = true,
    this.isHidden = false,
    this.createdAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, {String uploadsBaseUrl = 'http://localhost:5000/uploads'}) {
    List<String> parsedTags = [];
    if (map['categories'] != null && map['categories'].toString().isNotEmpty) {
      parsedTags = map['categories'].toString().split(', ').where((t) => t.isNotEmpty).toList();
    } else if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      } else if (map['tags'] is String) {
        parsedTags = map['tags'].toString().split(',');
      }
    }

    List<int> parsedCategoryIds = [];
    if (map['category_ids'] != null && map['category_ids'].toString().isNotEmpty) {
      parsedCategoryIds = map['category_ids']
          .toString()
          .split(',')
          .map((id) => int.tryParse(id.trim()))
          .whereType<int>()
          .toList();
    }

    int? parsedAuthorId;
    if (map['author_id'] != null) {
      parsedAuthorId = int.tryParse(map['author_id'].toString());
    }

    String cover = map['cover_image_url'] ?? map['imagePath'] ?? '';
    if (cover.startsWith('/uploads/') || cover.startsWith('uploads/')) {
      cover = '$uploadsBaseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null && (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$uploadsBaseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    double parsedRating = 4.5;
    if (map['rating'] != null) {
      parsedRating = double.tryParse(map['rating'].toString()) ?? 4.5;
    }

    int parsedPages = int.tryParse(map['page_count']?.toString() ?? map['pageCount']?.toString() ?? '0') ?? 0;
    int parsedSizeBytes = int.tryParse(map['file_size_bytes']?.toString() ?? map['fileSizeBytes']?.toString() ?? '0') ?? 0;
    int? parsedUploadedBy = int.tryParse(map['uploaded_by']?.toString() ?? map['uploadedBy']?.toString() ?? '');

    return BookModel(
      id: (map['book_id'] ?? map['id'] ?? '').toString(),
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      authorId: parsedAuthorId,
      categoryIds: parsedCategoryIds,
      language: map['language']?.toString() ?? 'LA',
      pageCount: parsedPages,
      fileSizeBytes: parsedSizeBytes,
      rating: parsedRating,
      ratingText: map['ratingText'] ?? (parsedRating == 0.0 ? 'New' : parsedRating.toStringAsFixed(1)),
      tags: parsedTags.isEmpty ? ['ທົ່ວໄປ'] : parsedTags,
      imagePath: cover,
      pdfUrl: pdf,
      description: map['description'] ?? '',
      uploadedBy: parsedUploadedBy,
      isPopular: map['is_popular'] == 1 || map['is_popular'] == true || map['isPopular'] == true,
      isNew: map['is_new'] == 1 || map['is_new'] == true || map['isNew'] == true,
      isRecommended: map['is_recommended'] == 1 || map['is_recommended'] == true || map['isRecommended'] == true,
      isBookmarked: map['is_bookmarked'] == 1 || map['is_bookmarked'] == true || map['isBookmarked'] == true,
      isFree: map['is_free'] == 1 || map['is_free'] == true || map['isFree'] == true,
      isHidden: map['is_hidden'] == 1 || map['is_hidden'] == true || map['isHidden'] == true,
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': id,
      'id': id,
      'title': title,
      'author': author,
      'author_id': authorId,
      'category_ids': categoryIds,
      'language': language,
      'page_count': pageCount,
      'file_size_bytes': fileSizeBytes,
      'rating': rating,
      'ratingText': ratingText,
      'tags': tags,
      'cover_image_url': imagePath,
      'imagePath': imagePath,
      'file_pdf_url': pdfUrl,
      'pdfUrl': pdfUrl,
      'description': description,
      'uploaded_by': uploadedBy,
      'isPopular': isPopular,
      'isNew': isNew,
      'isRecommended': isRecommended,
      'isBookmarked': isBookmarked,
      'is_free': isFree,
      'is_hidden': isHidden,
      'created_at': createdAt,
    };
  }
}

class MockBookData {
  static List<BookModel> popularBooks = [
    BookModel(
      id: '1',
      title: 'The Happiness Effect',
      author: 'Stephen T. Radentz',
      rating: 4.9,
      ratingText: '4.9',
      tags: ['ຊີວິດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isPopular: true,
    ),
    BookModel(
      id: '2',
      title: 'High School Science',
      author: 'Nageen Prakashan',
      rating: 3.7,
      ratingText: '3.7',
      tags: ['ວິທະຍາສາດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isPopular: true,
    ),
  ];

  static List<BookModel> newBooks = [
    BookModel(
      id: '3',
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['ສິລະປະ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isNew: true,
    ),
    BookModel(
      id: '4',
      title: 'Advances in Physics',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['ຜະຈົນໄພ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isNew: true,
    ),
  ];

  static List<BookModel> recommendedBooks = [
    BookModel(
      id: '6',
      title: 'Learning English Book 3',
      author: 'English Teacher',
      rating: 4.9,
      ratingText: '4.9',
      tags: ['ພາສາອັງກິດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isRecommended: true,
    ),
    BookModel(
      id: '7',
      title: 'Everything you need to ace MATHS',
      author: 'Award Winning teacher',
      rating: 5.0,
      ratingText: '5.0',
      tags: ['ຄະນິດສາດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isRecommended: true,
    ),
  ];
}
