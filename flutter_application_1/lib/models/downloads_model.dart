class DownloadedBookItem {
  final String id;
  final int? downloadId;
  final int? bookId;
  final String title;
  final String author;
  final String category;
  final String imagePath;
  final String? pdfUrl;
  final String? downloadedAt;

  DownloadedBookItem({
    required this.id,
    this.downloadId,
    this.bookId,
    required this.title,
    required this.author,
    required this.category,
    required this.imagePath,
    this.pdfUrl,
    this.downloadedAt,
  });

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

    return DownloadedBookItem(
      id: (map['download_id'] ?? map['book_id'] ?? map['id'] ?? '').toString(),
      downloadId: dId,
      bookId: bId,
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      category: map['category_name'] ?? map['category'] ?? 'ທົ່ວໄປ',
      imagePath: cover.isNotEmpty ? cover : 'assets/sample_cover.png',
      pdfUrl: pdf,
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
      'cover_image_url': imagePath,
      'file_pdf_url': pdfUrl,
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
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
    DownloadedBookItem(
      id: '2',
      bookId: 3,
      title: 'Quantum Mechanics',
      author: 'Dr. Elias Thorne',
      category: 'ເຕັກໂນໂລຊີ',
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
  ];
}
