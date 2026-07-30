class BookModel {
  final String id;
  final String title;
  final String author;
  final double rating;
  final String ratingText;
  final List<String> tags;
  final String imagePath;
  final bool isPopular;
  final bool isNew;
  final bool isRecommended;
  final bool isBookmarked;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    this.ratingText = '',
    required this.tags,
    required this.imagePath,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.isBookmarked = false,
  });
}

class MockBookData {
  static List<BookModel> popularBooks = [
    BookModel(
      id: '1',
      title: 'The Happiness Effect',
      author: 'Stephen T. Radentz',
      rating: 4.9,
      ratingText: '4.9',
      tags: ['ชีวิต'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg',
      isPopular: true,
    ),
    BookModel(
      id: '2',
      title: 'High School Science',
      author: 'Nageen Prakashan',
      rating: 3.7,
      ratingText: '3.7',
      tags: ['วิทยาศาสตร์'],
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
      tags: ['ศิลปะ'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
      isNew: true,
    ),
    BookModel(
      id: '4',
      title: 'Advances in Physics',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['ผจญภัย'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
      isNew: true,
    ),
    BookModel(
      id: '5',
      title: 'Modern Science & Tech',
      author: 'Dr. Elias Thorne',
      rating: 0.0,
      ratingText: 'New',
      tags: ['วิทยาศาสตร์', 'เทคโนโลยี'],
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
      tags: ['English'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/happiness_cover_1785383965921.jpg',
      isRecommended: true,
    ),
    BookModel(
      id: '7',
      title: 'Everything you need to ace MATHS',
      author: 'Award Winning teacher',
      rating: 5.0,
      ratingText: '5.0',
      tags: ['คณิตศาสตร์'],
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/science_cover_1785383980996.jpg',
      isRecommended: true,
    ),
  ];
}
