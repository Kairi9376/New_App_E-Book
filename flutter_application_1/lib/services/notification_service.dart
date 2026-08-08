import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/User/notifications_screen.dart';

class NotificationService {
  static final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>([]);

  static bool _isInitialized = false;

  /// Initialize and load notifications
  static Future<void> init() async {
    if (_isInitialized) return;
    final items = await ApiService.getNotifications();
    notificationsNotifier.value = List.from(items);
    _isInitialized = true;
  }

  /// Get total unread notifications count
  static int get unreadCount =>
      notificationsNotifier.value.where((n) => !n.isRead).length;

  /// Refresh notifications list from API
  static Future<void> refresh() async {
    final items = await ApiService.getNotifications();
    notificationsNotifier.value = List.from(items);
  }

  /// Add a new notification and trigger live UI update + top floating toast banner
  static void addNotification(
    BuildContext? context, {
    required String title,
    required String message,
    required NotificationType type,
    String? targetId,
    String? imagePath,
    bool showToast = true,
  }) {
    final newItem = NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      isRead: false,
      createdAt: DateTime.now(),
      targetId: targetId,
      imagePath: imagePath,
    );

    // Update Live ValueNotifier list at the top
    notificationsNotifier.value = [newItem, ...notificationsNotifier.value];

    // Show floating in-app notification banner toast if context is provided
    if (showToast && context != null && context.mounted) {
      _showInAppNotificationBanner(context, newItem);
    }
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String id) async {
    final list = List<NotificationItem>.from(notificationsNotifier.value);
    final idx = list.indexWhere((n) => n.id == id);
    if (idx != -1) {
      list[idx] = list[idx].copyWith(isRead: true);
      notificationsNotifier.value = list;
    }
    await ApiService.markNotificationAsRead(id);
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    final list = notificationsNotifier.value
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notificationsNotifier.value = list;
    await ApiService.markAllNotificationsAsRead();
  }

  /// Delete notification
  static Future<void> deleteNotification(String id) async {
    final list = List<NotificationItem>.from(notificationsNotifier.value);
    list.removeWhere((n) => n.id == id);
    notificationsNotifier.value = list;
    await ApiService.deleteNotification(id);
  }

  /// Show floating top in-app notification banner toast
  static void _showInAppNotificationBanner(
      BuildContext context, NotificationItem item) {
    late OverlayEntry overlayEntry;

    IconData iconData;
    Color iconColor;
    Color bgColor;

    switch (item.type) {
      case NotificationType.kyc:
        iconData = Icons.gpp_good_rounded;
        iconColor = const Color(0xFF10B981);
        bgColor = const Color(0xFFD1FAE5);
        break;
      case NotificationType.subscription:
        iconData = Icons.workspace_premium_rounded;
        iconColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case NotificationType.book:
        iconData = Icons.auto_stories_rounded;
        iconColor = const Color(0xFF6366F1);
        bgColor = const Color(0xFFE0E7FF);
        break;
      case NotificationType.promo:
        iconData = Icons.local_offer_rounded;
        iconColor = const Color(0xFFEC4899);
        bgColor = const Color(0xFFFCE7F3);
        break;
      // # ເຮັດຫຍັງ: ຕັດ default ອອກ ເຫຼືອແຕ່ case NotificationType.system
      // # ຍ້ອນຫຍັງ: switch ນີ້ກວມທຸກຄ່າຂອງ enum ຢູ່ແລ້ວ default ຈຶ່ງເປັນໂຄ້ດຕາຍ
      // #          ແລະ ຍັງກີດຂວາງ analyzer ບໍ່ໃຫ້ເຕືອນຕອນເພີ່ມ NotificationType ໃໝ່
      // #          ແລ້ວລືມມາຈັດການທີ່ນີ້ (ຫຼັງຍົກ SDK ເປັນ 3.10 analyzer ຈຶ່ງເລີ່ມເຕືອນ)
      // # ແກ້ຈາກສ່ວນໃດ: 'case NotificationType.system:' ທີ່ຕິດດ້ວຍ 'default:'
      // # ແກ້ເຮັດຫຍັງ: ພຶດຕິກຳຄືເກົ່າ ແຕ່ຖ້າເພີ່ມ type ໃໝ່ຈະ compile ເຕືອນທັນທີ
      case NotificationType.system:
        iconData = Icons.notifications_active_rounded;
        iconColor = AppColors.primary;
        bgColor = const Color(0xFFEFF6FF);
        break;
    }

    overlayEntry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -40),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: InkWell(
              onTap: () {
                overlayEntry.remove();
                markAsRead(item.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: bgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(iconData, color: iconColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}
