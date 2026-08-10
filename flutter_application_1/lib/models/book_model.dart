import '../services/api_config.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final int? authorId;
  final List<int> categoryIds;
  final String language; // ENUM('LA', 'TH', 'EN', 'JP', 'CN')
  final int pageCount;
  final int fileSizeBytes;
  final double rating;
  final String ratingText;
  final int likeCount;
  final int viewCount;
  final bool isLiked;
  final List<String> tags;
  final String imagePath;
  final String? pdfUrl;
  final String? description;
  final int? uploadedBy;
  final bool isPopular;
  final bool isNew;
  final bool isRecommended;
  final bool isBookmarked;
  final bool isFree;
  final bool isFreeDownload;
  final bool isHidden;
  final bool isDeleted;
  final String status; // 'pending', 'approved', 'rejected'
  final String? rejectionReason;
  final String? uploaderName;
  final String? createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.authorId,
    this.categoryIds = const [],
    this.language = 'LA',
    this.pageCount = 0,
    this.fileSizeBytes = 0,
    this.rating = 0.0,
    this.ratingText = '',
    this.likeCount = 0,
    this.viewCount = 0,
    this.isLiked = false,
    required this.tags,
    required this.imagePath,
    this.pdfUrl,
    this.description,
    this.uploadedBy,
    this.isPopular = false,
    this.isNew = false,
    this.isRecommended = false,
    this.isBookmarked = false,
    this.isFree = true,
    this.isFreeDownload = false,
    this.isHidden = false,
    this.isDeleted = false,
    this.status = 'approved',
    this.rejectionReason,
    this.uploaderName,
    this.createdAt,
  });

  String get formattedLikes {
    if (likeCount >= 1000) {
      return '${(likeCount / 1000).toStringAsFixed(1)}k';
    }
    return likeCount.toString();
  }

  String get formattedViews {
    if (viewCount >= 1000) {
      return '${(viewCount / 1000).toStringAsFixed(1)}k';
    }
    return viewCount.toString();
  }

  factory BookModel.fromMap(Map<String, dynamic> map, {String? uploadsBaseUrl}) {
    final baseUrl = uploadsBaseUrl ?? ApiConfig.uploadsBaseUrl;
    List<String> parsedTags = [];
    if (map['categories'] != null && map['categories'].toString().isNotEmpty) {
      parsedTags = map['categories']
          .toString()
          .split(', ')
          .where((t) => t.isNotEmpty)
          .toList();
    } else if (map['tags'] != null) {
      if (map['tags'] is List) {
        parsedTags = List<String>.from(map['tags']);
      } else if (map['tags'] is String) {
        parsedTags = map['tags'].toString().split(',');
      }
    }

    List<int> parsedCategoryIds = [];
    if (map['category_ids'] != null &&
        map['category_ids'].toString().isNotEmpty) {
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
      cover = '$baseUrl/${cover.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    String? pdf = map['file_pdf_url'] ?? map['pdfUrl'];
    if (pdf != null &&
        (pdf.startsWith('/uploads/') || pdf.startsWith('uploads/'))) {
      pdf = '$baseUrl/${pdf.replaceAll(RegExp(r'^/?uploads/'), '')}';
    }

    double parsedRating = 0.0;
    if (map['rating'] != null) {
      parsedRating = double.tryParse(map['rating'].toString()) ?? 0.0;
    }

    // # ເຮັດຫຍັງ: ປ່ຽນຄ່າເລີ່ມຕົ້ນຂອງ likes/views ຈາກ 124/350 ເປັນ 0
    // # ຍ້ອນຫຍັງ: ເລກ 124 ກັບ 350 ຖືກ hardcode ໄວ້ ປຶ້ມທຸກຫົວທີ່ backend ບໍ່ໄດ້ສົ່ງ
    // #          ຄ່ານີ້ມາຈຶ່ງສະແດງ "124 ຖືກໃຈ / 350 ຜູ້ອ່ານ" ຄືກັນໝົດ ເປັນຕົວເລກປອມ
    // #          ທີ່ຜູ້ໃຊ້ເຂົ້າໃຈວ່າແມ່ນສະຖິຕິຈິງ
    // # ແກ້ຈາກສ່ວນໃດ: fallback '124' ແລະ '350' ໃນ BookModel.fromMap
    // # ແກ້ເຮັດຫຍັງ: 0 ສະທ້ອນຄວາມຈິງວ່າຍັງບໍ່ມີໃຜອ່ານ/ຖືກໃຈ ສ່ວນຄ່າຈິງມາຈາກ
    // #             ຖັນ readers_count/likes_count ໃນຖານຂໍ້ມູນ
    int parsedLikes = int.tryParse(map['likes_count']?.toString() ?? map['like_count']?.toString() ?? map['likes']?.toString() ?? map['likeCount']?.toString() ?? '0') ?? 0;
    int parsedViews = int.tryParse(map['readers_count']?.toString() ?? map['view_count']?.toString() ?? map['views']?.toString() ?? map['readers']?.toString() ?? map['viewCount']?.toString() ?? '0') ?? 0;
    bool parsedIsLiked = map['is_liked'] == 1 || map['is_liked'] == true || map['isLiked'] == true;

    int parsedPages = int.tryParse(map['page_count']?.toString() ??
            map['pageCount']?.toString() ??
            '0') ??
        0;
    int parsedSizeBytes = int.tryParse(map['file_size_bytes']?.toString() ??
            map['fileSizeBytes']?.toString() ??
            '0') ??
        0;
    int? parsedUploadedBy = int.tryParse(
        map['uploaded_by']?.toString() ?? map['uploadedBy']?.toString() ?? '');

    return BookModel(
      id: (map['book_id'] ?? map['id'] ?? '').toString(),
      title: map['title'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'ບໍ່ລະບຸຜູ້ແຕ່ງ',
      authorId: parsedAuthorId,
      categoryIds: parsedCategoryIds,
      language: map['language']?.toString() ?? 'LA',
      pageCount: parsedPages,
      fileSizeBytes: parsedSizeBytes,
      rating: parsedRating,
      ratingText: map['ratingText'] ?? (parsedRating == 0.0 ? 'New' : parsedRating.toStringAsFixed(1)),
      likeCount: parsedLikes,
      viewCount: parsedViews,
      isLiked: parsedIsLiked,
      tags: parsedTags.isEmpty ? ['ທົ່ວໄປ'] : parsedTags,
      imagePath: cover,
      pdfUrl: pdf,
      description: map['description'] ?? '',
      uploadedBy: parsedUploadedBy,
      isPopular: map['is_popular'] == 1 ||
          map['is_popular'] == true ||
          map['isPopular'] == true,
      isNew:
          map['is_new'] == 1 || map['is_new'] == true || map['isNew'] == true,
      isRecommended: map['is_recommended'] == 1 ||
          map['is_recommended'] == true ||
          map['isRecommended'] == true,
      isBookmarked: map['is_bookmarked'] == 1 ||
          map['is_bookmarked'] == true ||
          map['isBookmarked'] == true,
      isFree: map['is_free'] == 1 ||
          map['is_free'] == true ||
          map['isFree'] == true,
      isFreeDownload: map['is_free_download'] == 1 ||
          map['is_free_download'] == true ||
          map['isFreeDownload'] == true,
      isHidden: map['is_hidden'] == 1 ||
          map['is_hidden'] == true ||
          map['isHidden'] == true,
      isDeleted: map['is_deleted'] == 1 ||
          map['is_deleted'] == true ||
          map['isDeleted'] == true,
      status: map['status']?.toString() ?? 'approved',
      rejectionReason: map['rejection_reason']?.toString(),
      uploaderName: map['uploader_first_name'] != null
          ? '${map['uploader_first_name']} ${map['uploader_last_name'] ?? ''}'.trim()
          : map['uploaderName']?.toString(),
      createdAt: map['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'book_id': id,
      'id': id,
      'title': title,
      'author': author,
      'author_id': authorId,
      'category_ids': categoryIds,
      'language': language,
      'page_count': pageCount,
      'file_size_bytes': fileSizeBytes,
      'rating': rating,
      'ratingText': ratingText,
      'like_count': likeCount,
      'view_count': viewCount,
      'is_liked': isLiked,
      'tags': tags,
      'cover_image_url': imagePath,
      'imagePath': imagePath,
      'file_pdf_url': pdfUrl,
      'pdfUrl': pdfUrl,
      'description': description,
      'uploaded_by': uploadedBy,
      'isPopular': isPopular,
      'isNew': isNew,
      'isRecommended': isRecommended,
      'isBookmarked': isBookmarked,
      'is_free': isFree,
      'is_free_download': isFreeDownload ? 1 : 0,
      'is_hidden': isHidden,
      'is_deleted': isDeleted,
      'created_at': createdAt,
    };
  }
}

// # ເຮັດຫຍັງ: ລຶບ class Mock*Data ອອກຈາກໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ເປັນຂໍ້ມູນຕົວຢ່າງທີ່ hardcode ໄວ້ໃນແອັບ ໃຊ້ເປັນ fallback ຕອນ API ລົ້ມ
// #          ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນເນື້ອຫາປອມ ແລະ ປິດບັງບັນຫາຂອງ backend
// # ແກ້ຈາກສ່ວນໃດ: class Mock*Data ທ້າຍໄຟລ໌ ພ້ອມກັບຜູ້ເອີ້ນໃນ api_service.dart
// # ແກ້ເຮັດຫຍັງ: ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ Backend/database.sql ເປັນ seed ຂອງຖານຂໍ້ມູນ
// #             ເຊິ່ງເປັນຂໍ້ມູນຈິງທີ່ແກ້ໄຂ/ລຶບໄດ້ຜ່ານໜ້າ Admin
