class DownloadedBookItem {
  final String id;
  final int? downloadId;
  final int? bookId;
  final String title;
  final String author;
  final String category;
  final int pageCount;
  final int fileSizeBytes;
  final int likeCount;
  final int viewCount;
  final double rating;
  final String imagePath;
  final String? pdfUrl;
  final String? description;
  final String? downloadedAt;

  DownloadedBookItem({
    required this.id,
    this.downloadId,
    this.bookId,
    required this.title,
    required this.author,
    required this.category,
    this.pageCount = 0,
    this.fileSizeBytes = 0,
    this.likeCount = 0,
    this.viewCount = 0,
    this.rating = 0.0,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.downloadedAt,
  });

  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '0.0 MB';
    final mb = fileSizeBytes / (1024 * 1024);
    if (mb < 0.1) {
      final kb = fileSizeBytes / 1024;
      return '${kb.toStringAsFixed(0)} KB';
    }
    return '${mb.toStringAsFixed(1)} MB';
  }

  factory DownloadedBookItem.fromMap(Map<String, dynamic> map, {String uploadsBaseUrl = 'http://localhost:5000/uploads'}) {
    String cover = map['cover_image_url'] ?? map['imagePath'] ?? '';
    if (cover.startsWith('/uploads/') || cover.startsWith('uploads/')) {
      cover = '$uploadsBaseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null && (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$uploadsBaseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    int? dId = int.tryParse(map['download_id']?.toString() ?? '');
    int? bId = int.tryParse(map['book_id']?.toString() ?? map['id']?.toString() ?? '');
    int pCount = int.tryParse(map['page_count']?.toString() ?? map['pageCount']?.toString() ?? '0') ?? 0;
    int fSize = int.tryParse(map['file_size_bytes']?.toString() ?? map['fileSizeBytes']?.toString() ?? '0') ?? 0;
    int likes = int.tryParse(map['likes_count']?.toString() ?? map['like_count']?.toString() ?? map['likes']?.toString() ?? map['likeCount']?.toString() ?? '0') ?? 0;
    int views = int.tryParse(map['readers_count']?.toString() ?? map['view_count']?.toString() ?? map['views']?.toString() ?? map['readers']?.toString() ?? map['viewCount']?.toString() ?? '0') ?? 0;
    double parsedRating = double.tryParse(map['rating']?.toString() ?? '0.0') ?? 0.0;

    return DownloadedBookItem(
      id: (map['download_id'] ?? map['book_id'] ?? map['id'] ?? '').toString(),
      downloadId: dId,
      bookId: bId,
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      category: (map['category_name'] ?? map['category'] ?? map['categories'] ?? 'ທົ່ວໄປ').toString(),
      pageCount: pCount,
      fileSizeBytes: fSize,
      likeCount: likes,
      viewCount: views,
      rating: parsedRating,
      imagePath: cover.isNotEmpty ? cover : 'assets/sample_cover.png',
      pdfUrl: pdf,
      description: map['description'] ?? '',
      downloadedAt: map['downloaded_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'download_id': downloadId ?? id,
      'book_id': bookId,
      'title': title,
      'author': author,
      'category': category,
      'page_count': pageCount,
      'file_size_bytes': fileSizeBytes,
      'likes_count': likeCount,
      'readers_count': viewCount,
      'rating': rating,
      'cover_image_url': imagePath,
      'file_pdf_url': pdfUrl,
      'description': description,
      'downloaded_at': downloadedAt,
    };
  }
}

class MockDownloadsData {
  static List<DownloadedBookItem> downloadedItems = [
    DownloadedBookItem(
      id: '1',
      downloadId: 1,
      bookId: 4,
      title: 'ປຶ້ມສັງຄົມສຶກສາ',
      author: 'ດຣ.ຈອນ ວົງວິໄລ',
      category: 'ສັງຄົມ',
      pageCount: 180,
      fileSizeBytes: 12000000,
      likeCount: 95,
      viewCount: 210,
      rating: 4.8,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
    DownloadedBookItem(
      id: '2',
      downloadId: 2,
      bookId: 3,
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      category: 'ເຕັກໂນໂລຊີ, ວິທະຍາສາດ',
      pageCount: 450,
      fileSizeBytes: 38000000,
      likeCount: 19,
      viewCount: 64,
      rating: 4.9,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
  ];
}

