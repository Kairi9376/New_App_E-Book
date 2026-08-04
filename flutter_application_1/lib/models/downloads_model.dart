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
    this.pageCount = 120,
    this.fileSizeBytes = 0,
    this.likeCount = 0,
    this.viewCount = 0,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.downloadedAt,
  });

  String get formattedFileSize {
    if (fileSizeBytes <= 0) return '2.5 MB';
    final mb = fileSizeBytes / (1024 * 1024);
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
    int pCount = int.tryParse(map['page_count']?.toString() ?? map['pageCount']?.toString() ?? '') ?? 120;
    int fSize = int.tryParse(map['file_size_bytes']?.toString() ?? map['fileSizeBytes']?.toString() ?? '') ?? 0;
    int likes = int.tryParse(map['likes_count']?.toString() ?? map['like_count']?.toString() ?? '150') ?? 150;
    int views = int.tryParse(map['readers_count']?.toString() ?? map['view_count']?.toString() ?? '420') ?? 420;

    return DownloadedBookItem(
      id: (map['download_id'] ?? map['book_id'] ?? map['id'] ?? '').toString(),
      downloadId: dId,
      bookId: bId,
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      category: (map['category_name'] ?? map['category'] ?? map['categories'] ?? 'ທົ່ວໄປ').toString(),
      pageCount: pCount > 0 ? pCount : 120,
      fileSizeBytes: fSize,
      likeCount: likes,
      viewCount: views,
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
      bookId: 4,
      title: 'ໜັງສືສັງຄົມ',
      author: 'ດຣ.ຈອນ ວົງວິໄລ',
      category: 'ສັງຄົມ',
      pageCount: 120,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
    DownloadedBookItem(
      id: '2',
      bookId: 3,
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      category: 'ເຕັກໂນໂລຊີ',
      pageCount: 150,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
  ];
}
