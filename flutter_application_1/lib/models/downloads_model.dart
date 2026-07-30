class DownloadedBookItem {
  final String id;
  final String title;
  final String author;
  final String category;
  final String imagePath;

  DownloadedBookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.imagePath,
  });
}

class MockDownloadsData {
  static List<DownloadedBookItem> downloadedItems = [
    DownloadedBookItem(
      id: 'd1',
      title: 'หนังสือสังคม',
      author: 'ดร.จอน วงวิไล',
      category: 'สังคม',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/social_cover_1785399683975.jpg',
    ),
    DownloadedBookItem(
      id: 'd2',
      title: 'หนังสือวรรณคดี',
      author: 'ท่าน สุวันนิ สิทอม',
      category: 'ศิลปะ',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
    ),
  ];
}
