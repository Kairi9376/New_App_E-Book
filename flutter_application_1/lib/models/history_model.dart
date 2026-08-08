import '../services/api_config.dart';

class HistoryBookItem {
  final String id;
  final int? historyId;
  final int? bookId;
  final String title;
  final String author;
  final String category;
  final double progress; // 0.0 to 1.0 (e.g. 0.45 for 45%)
  final int lastPageRead;
  final String imagePath;
  final String? pdfUrl;
  final String? description;

  HistoryBookItem({
    required this.id,
    this.historyId,
    this.bookId,
    required this.title,
    required this.author,
    required this.category,
    required this.progress,
    this.lastPageRead = 1,
    required this.imagePath,
    this.pdfUrl,
    this.description,
  });

  int get progressPercentage => (progress * 100).round();

  factory HistoryBookItem.fromMap(Map<String, dynamic> map, {String? uploadsBaseUrl}) {
    final baseUrl = uploadsBaseUrl ?? ApiConfig.uploadsBaseUrl;
    double parsedProgress = 0.0;
    if (map['progress_percent'] != null) {
      parsedProgress = (double.tryParse(map['progress_percent'].toString()) ?? 0.0) / 100.0;
    } else if (map['progress'] != null) {
      parsedProgress = double.tryParse(map['progress'].toString()) ?? 0.0;
    }

    String cover = map['cover_image_url'] ?? map['imagePath'] ?? '';
    if (cover.startsWith('/uploads/') || cover.startsWith('uploads/')) {
      cover = '$baseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null && (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$baseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    int? hId = int.tryParse(map['history_id']?.toString() ?? '');
    int? bId = int.tryParse(map['book_id']?.toString() ?? map['id']?.toString() ?? '');
    int pRead = int.tryParse(map['last_page_read']?.toString() ?? '1') ?? 1;

    return HistoryBookItem(
      id: (map['history_id'] ?? map['book_id'] ?? map['id'] ?? '').toString(),
      historyId: hId,
      bookId: bId,
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      category: map['category_name'] ?? map['category'] ?? 'ທົ່ວໄປ',
      progress: parsedProgress,
      lastPageRead: pRead,
      imagePath: cover.isNotEmpty ? cover : 'assets/sample_cover.png',
      pdfUrl: pdf,
      description: map['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'history_id': historyId ?? id,
      'book_id': bookId,
      'title': title,
      'author': author,
      'category': category,
      'progress_percent': progressPercentage,
      'last_page_read': lastPageRead,
      'cover_image_url': imagePath,
      'file_pdf_url': pdfUrl,
      'description': description,
    };
  }
}

class MockHistoryData {
  static List<HistoryBookItem> historyItems = [
    HistoryBookItem(
      id: '1',
      bookId: 4,
      title: 'ໜັງສືສັງຄົມ',
      author: 'ດຣ.ຈອນ ວົງວິໄລ',
      category: 'ສັງຄົມ',
      progress: 0.45,
      lastPageRead: 81,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
    HistoryBookItem(
      id: '2',
      bookId: 1,
      title: 'The Happiness Effect',
      author: 'Stephen T. Radentz',
      category: 'ເຕັກໂນໂລຊີ',
      progress: 1.0,
      lastPageRead: 240,
      imagePath: 'assets/sample_cover.png',
      pdfUrl: 'assets/sample_book.pdf',
    ),
  ];
}
