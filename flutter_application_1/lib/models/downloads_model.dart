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
      title: 'ໜັງສືສັງຄົມ',
      author: 'ດຣ.ຈອນ ວົງວິໄລ',
      category: 'ສັງຄົມ',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/social_cover_1785399683975.jpg',
    ),
    DownloadedBookItem(
      id: 'd2',
      title: 'ໜັງສືວັນນະຄະດີ',
      author: 'ທ່ານ ສຸວັນນີ ສີທອນ',
      category: 'ສິລະປະ',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_cover_1785383995867.jpg',
    ),
  ];
}
