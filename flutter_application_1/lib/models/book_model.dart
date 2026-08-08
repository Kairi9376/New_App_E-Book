import '../services/api_config.dart';

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
  final int likeCount;
  final int viewCount;
  final bool isLiked;
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
  final bool isFreeDownload;
  final bool isHidden;
  final bool isDeleted;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String? uploaderName;
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
    this.rating = 0.0,
    this.ratingText = '',
    this.likeCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
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
    this.isFreeDownload = false,
    this.isHidden = false,
    this.isDeleted = false,
    this.status = 'approved',
    this.rejectionReason,
    this.uploaderName,
    this.createdAt,
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

  factory BookModel.fromMap(Map<String, dynamic> map, {String? uploadsBaseUrl}) {
    final baseUrl = uploadsBaseUrl ?? ApiConfig.uploadsBaseUrl;
    List<String> parsedTags = [];
    if (map['categories'] != null && map['categories'].toString().isNotEmpty) {
      parsedTags = map['categories']
          .toString()
          .split(', ')
          .where((t) => t.isNotEmpty)
          .toList();
    } else if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      } else if (map['tags'] is String) {
        parsedTags = map['tags'].toString().split(',');
      }
    }

    List<int> parsedCategoryIds = [];
    if (map['category_ids'] != null &&
        map['category_ids'].toString().isNotEmpty) {
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
      cover = '$baseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null &&
        (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$baseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    double parsedRating = 0.0;
    if (map['rating'] != null) {
      parsedRating = double.tryParse(map['rating'].toString()) ?? 0.0;
    }

    int parsedLikes = int.tryParse(map['like_count']?.toString() ?? map['likes']?.toString() ?? map['likeCount']?.toString() ?? '124') ?? 124;
    int parsedViews = int.tryParse(map['view_count']?.toString() ?? map['views']?.toString() ?? map['readers']?.toString() ?? map['viewCount']?.toString() ?? '350') ?? 350;
    bool parsedIsLiked = map['is_liked'] == 1 || map['is_liked'] == true || map['isLiked'] == true;

    int parsedPages = int.tryParse(map['page_count']?.toString() ??
            map['pageCount']?.toString() ??
            '0') ??
        0;
    int parsedSizeBytes = int.tryParse(map['file_size_bytes']?.toString() ??
            map['fileSizeBytes']?.toString() ??
            '0') ??
        0;
    int? parsedUploadedBy = int.tryParse(
        map['uploaded_by']?.toString() ?? map['uploadedBy']?.toString() ?? '');

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
      likeCount: parsedLikes,
      viewCount: parsedViews,
      isLiked: parsedIsLiked,
      tags: parsedTags.isEmpty ? ['ທົ່ວໄປ'] : parsedTags,
      imagePath: cover,
      pdfUrl: pdf,
      description: map['description'] ?? '',
      uploadedBy: parsedUploadedBy,
      isPopular: map['is_popular'] == 1 ||
          map['is_popular'] == true ||
          map['isPopular'] == true,
      isNew:
          map['is_new'] == 1 || map['is_new'] == true || map['isNew'] == true,
      isRecommended: map['is_recommended'] == 1 ||
          map['is_recommended'] == true ||
          map['isRecommended'] == true,
      isBookmarked: map['is_bookmarked'] == 1 ||
          map['is_bookmarked'] == true ||
          map['isBookmarked'] == true,
      isFree: map['is_free'] == 1 ||
          map['is_free'] == true ||
          map['isFree'] == true,
      isFreeDownload: map['is_free_download'] == 1 ||
          map['is_free_download'] == true ||
          map['isFreeDownload'] == true,
      isHidden: map['is_hidden'] == 1 ||
          map['is_hidden'] == true ||
          map['isHidden'] == true,
      isDeleted: map['is_deleted'] == 1 ||
          map['is_deleted'] == true ||
          map['isDeleted'] == true,
      status: map['status']?.toString() ?? 'approved',
      rejectionReason: map['rejection_reason']?.toString(),
      uploaderName: map['uploader_first_name'] != null
          ? '${map['uploader_first_name']} ${map['uploader_last_name'] ?? ''}'.trim()
          : map['uploaderName']?.toString(),
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
      'like_count': likeCount,
      'view_count': viewCount,
      'is_liked': isLiked,
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
      'is_free_download': isFreeDownload ? 1 : 0,
      'is_hidden': isHidden,
      'is_deleted': isDeleted,
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
      likeCount: 1240,
      viewCount: 4500,
      tags: ['ຊີວິດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isPopular: true,
    ),
    BookModel(
      id: '2',
      title: 'High School Science',
      author: 'Nageen Prakashan',
      likeCount: 890,
      viewCount: 3200,
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
      likeCount: 450,
      viewCount: 1800,
      tags: ['ສິລະປະ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isNew: true,
    ),
    BookModel(
      id: '4',
      title: 'Advances in Physics',
      author: 'Dr. Elias Thorne',
      likeCount: 320,
      viewCount: 1200,
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
      likeCount: 2150,
      viewCount: 6800,
      tags: ['ພາສາອັງກິດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isRecommended: true,
    ),
    BookModel(
      id: '7',
      title: 'Everything you need to ace MATHS',
      author: 'Award Winning teacher',
      likeCount: 3400,
      viewCount: 9200,
      tags: ['ຄະນິດສາດ'],
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
      isRecommended: true,
    ),
  ];
}
