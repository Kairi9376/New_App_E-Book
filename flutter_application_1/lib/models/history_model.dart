class HistoryBookItem {
  final String id;
  final String title;
  final String author;
  final String category;
  final double progress; // 0.0 to 1.0 (e.g. 0.45 for 45%)
  final String imagePath;

  HistoryBookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.progress,
    required this.imagePath,
  });

  int get progressPercentage => (progress * 100).round();
}

class MockHistoryData {
  static List<HistoryBookItem> historyItems = [
    HistoryBookItem(
      id: 'h1',
      title: 'หนังสือสังคม',
      author: 'ดร.จอน วงวิไล',
      category: 'สังคม',
      progress: 0.45,
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/social_cover_1785399683975.jpg',
    ),
    HistoryBookItem(
      id: 'h2',
      title: 'หนังสือเทคโนโลยี',
      author: 'ท่าน วิว วงไลวัน',
      category: 'เทคโนโลยี',
      progress: 1.0,
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/tech_tablet_cover_1785399703628.jpg',
    ),
    HistoryBookItem(
      id: 'h3',
      title: 'หนังสือวรรณคดี',
      author: 'ท่าน สุวันนิ สิทอม',
      category: 'ศิลปะ',
      progress: 0.20,
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
    ),
  ];
}
