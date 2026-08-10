enum NotificationType { system, subscription, kyc, book, promo }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final String? targetId; // bookId, packageId, kycId
  final String? imagePath;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.targetId,
    this.imagePath,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'ເມື່ອສັກຄູ່';
    if (diff.inMinutes < 60) return '${diff.inMinutes} ນາທີທີ່ແລ້ວ';
    if (diff.inHours < 24) return '${diff.inHours} ຊົ່ວໂມງທີ່ແລ້ວ';
    if (diff.inDays < 7) return '${diff.inDays} ມື້ທີ່ແລ້ວ';
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    return '$day/$month/${createdAt.year}';
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    NotificationType nType = NotificationType.system;
    final typeStr = (map['type'] ?? '').toString().toLowerCase();
    if (typeStr == 'subscription' || typeStr == 'sub') {
      nType = NotificationType.subscription;
    } else if (typeStr == 'kyc') {
      nType = NotificationType.kyc;
    } else if (typeStr == 'book' || typeStr == 'release') {
      nType = NotificationType.book;
    } else if (typeStr == 'promo' || typeStr == 'discount') {
      nType = NotificationType.promo;
    }

    return NotificationItem(
      id: map['notification_id']?.toString() ??
          map['id']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: map['title'] ?? 'ການແຈ້ງເຕືອນ',
      message: map['message'] ?? '',
      type: nType,
      isRead: map['is_read'] == 1 || map['is_read'] == true || map['isRead'] == true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      targetId: map['target_id']?.toString() ?? map['book_id']?.toString(),
      imagePath: map['image_path'] ?? map['cover_image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'target_id': targetId,
      'image_path': imagePath,
    };
  }

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      targetId: targetId,
      imagePath: imagePath,
    );
  }
}

// # ເຮັດຫຍັງ: ລຶບ class Mock*Data ອອກຈາກໄຟລ໌ນີ້
// # ຍ້ອນຫຍັງ: ເປັນຂໍ້ມູນຕົວຢ່າງທີ່ hardcode ໄວ້ໃນແອັບ ໃຊ້ເປັນ fallback ຕອນ API ລົ້ມ
// #          ເຮັດໃຫ້ຜູ້ໃຊ້ເຫັນເນື້ອຫາປອມ ແລະ ປິດບັງບັນຫາຂອງ backend
// # ແກ້ຈາກສ່ວນໃດ: class Mock*Data ທ້າຍໄຟລ໌ ພ້ອມກັບຜູ້ເອີ້ນໃນ api_service.dart
// # ແກ້ເຮັດຫຍັງ: ຂໍ້ມູນຕົວຢ່າງຍ້າຍໄປຢູ່ Backend/database.sql ເປັນ seed ຂອງຖານຂໍ້ມູນ
// #             ເຊິ່ງເປັນຂໍ້ມູນຈິງທີ່ແກ້ໄຂ/ລຶບໄດ້ຜ່ານໜ້າ Admin
