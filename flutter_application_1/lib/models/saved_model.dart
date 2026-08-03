class SavedBookItem {
  final String id;
  final String title;
  final String author;
  final double rating;
  final String category;
  final String imagePath;
  final bool isBookmarked;

  SavedBookItem({
    required this.id,
    required this.title,
    required this.author,
    required this.rating,
    required this.category,
    required this.imagePath,
    this.isBookmarked = true,
  });
}

class MockSavedData {
  static List<SavedBookItem> savedItems = [
    SavedBookItem(
      id: 's1',
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      rating: 4.9,
      category: 'ເຕັກໂນໂລຊີ',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/quantum_phone_cover_1785401330580.jpg',
      isBookmarked: true,
    ),
    SavedBookItem(
      id: 's2',
      title: 'Neural Networks',
      author: 'Dr. Elias Thorne',
      rating: 4.9,
      category: 'ວິທະຍາສາດ',
      imagePath: '/Users/intern/.gemini/antigravity/brain/c8a3c47e-e27f-493b-ba56-c3f80ddc659c/neural_network_cover_1785401352299.jpg',
      isBookmarked: true,
    ),
  ];
}
