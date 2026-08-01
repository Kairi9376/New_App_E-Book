class BookModel {
  final String id;
  final String title;
  final String author;
  final double rating;
  final String ratingText;
  final List<String> tags;
  final String imagePath;
  final String? pdfUrl;
  final String? description;
  final bool isPopular;
  final bool isNew;
  final bool isRecommended;
  final bool isBookmarked;
  final bool isFree;
  final int? authorId;
  final List<int> categoryIds;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.authorId,
    this.categoryIds = const [],
    required this.rating,
    this.ratingText = '',
    required this.tags,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.isBookmarked = false,
    this.isFree = true,
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

    return BookModel(
      id: (map['book_id'] ?? map['id'] ?? '').toString(),
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      authorId: parsedAuthorId,
      categoryIds: parsedCategoryIds,
      rating: parsedRating,
      ratingText: map['ratingText'] ?? (parsedRating == 0.0 ? 'New' : parsedRating.toStringAsFixed(1)),
      tags: parsedTags.isEmpty ? ['ທົ່ວໄປ'] : parsedTags,
      imagePath: cover,
      pdfUrl: pdf,
      description: map['description'] ?? '',
      isPopular: map['is_popular'] == 1 || map['is_popular'] == true || map['isPopular'] == true,
      isNew: map['is_new'] == 1 || map['is_new'] == true || map['isNew'] == true,
      isRecommended: map['is_recommended'] == 1 || map['is_recommended'] == true || map['isRecommended'] == true,
      isBookmarked: map['is_bookmarked'] == 1 || map['is_bookmarked'] == true || map['isBookmarked'] == true,
      isFree: map['is_free'] == 1 || map['is_free'] == true || map['isFree'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'rating': rating,
      'ratingText': ratingText,
      'tags': tags,
      'imagePath': imagePath,
      'pdfUrl': pdfUrl,
      'description': description,
      'isPopular': isPopular,
      'isNew': isNew,
      'isRecommended': isRecommended,
      'isBookmarked': isBookmarked,
      'isFree': isFree,
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
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg',
      isPopular: true,
    ),
    BookModel(
      id: '2',
      title: 'High School Science',
      author: 'Nageen Prakashan',
      rating: 3.7,
      ratingText: '3.7',
      tags: ['ວິທະຍາສາດ'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/science_cover_1785383980996.jpg',
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
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
      isNew: true,
    ),
    BookModel(
      id: '4',
      title: 'Advances in Physics',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['ຜະຈົນໄພ'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
      isNew: true,
    ),
    BookModel(
      id: '5',
      title: 'Modern Science & Tech',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['ວິທະຍາສາດ', 'ເຕັກໂນໂລຊີ'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/science_cover_1785383980996.jpg',
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
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg',
      isRecommended: true,
    ),
    BookModel(
      id: '7',
      title: 'Everything you need to ace MATHS',
      author: 'Award Winning teacher',
      rating: 5.0,
      ratingText: '5.0',
      tags: ['ຄະນິດສາດ'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/science_cover_1785383980996.jpg',
      isRecommended: true,
    ),
  ];
}
