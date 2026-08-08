import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/kyc_model.dart';
import '../../theme/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import 'book_detail_screen.dart';
import 'kyc_submission_screen.dart';
import 'membership_package_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  int _selectedFilterIndex = 0;

  final List<String> _filterCategories = [
    'ທັງໝົດ',
    'ລະບົບ & KYC',
    'ແພັກເກັດ',
    'ປຶ້ມໃໝ່'
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    await NotificationService.refresh();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ອ່ານການແຈ້ງເຕືອນທັງໝົດແລ້ວ'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    await NotificationService.deleteNotification(id);
  }

  void _onNotificationTap(NotificationItem item) {
    if (!item.isRead) {
      NotificationService.markAsRead(item.id);
      if (mounted) setState(() {});
    }

    // Navigation based on notification type
    switch (item.type) {
      case NotificationType.kyc:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KycSubmissionScreen(
              currentKyc: KycModel.empty(),
            ),
          ),
        );
        break;

      case NotificationType.subscription:
      case NotificationType.promo:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MembershipPackageScreen()),
        );
        break;

      case NotificationType.book:
        if (item.targetId != null) {
          // Open detail for specific book or fallback to library
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookDetailScreen()),
          );
        } else {
          Navigator.pop(context);
        }
        break;

      // # ເຮັດຫຍັງ: ຕັດ default ອອກ ເຫຼືອແຕ່ case NotificationType.system
      // # ຍ້ອນຫຍັງ: switch ນີ້ກວມທຸກຄ່າຂອງ enum ຢູ່ແລ້ວ default ຈຶ່ງເປັນໂຄ້ດຕາຍ
      // #          ແລະ ຍັງກີດຂວາງ analyzer ບໍ່ໃຫ້ເຕືອນຕອນເພີ່ມ NotificationType ໃໝ່
      // #          ແລ້ວລືມມາຈັດການທີ່ນີ້ (ຫຼັງຍົກ SDK ເປັນ 3.10 analyzer ຈຶ່ງເລີ່ມເຕືອນ)
      // # ແກ້ຈາກສ່ວນໃດ: 'case NotificationType.system:' ທີ່ຕິດດ້ວຍ 'default:'
      // # ແກ້ເຮັດຫຍັງ: ພຶດຕິກຳຄືເກົ່າ ແຕ່ຖ້າເພີ່ມ type ໃໝ່ຈະ compile ເຕືອນທັນທີ
      case NotificationType.system:
        Navigator.pop(context);
        break;
    }
  }

  List<NotificationItem> _getFilteredList(List<NotificationItem> all) {
    if (_selectedFilterIndex == 0) return all;
    if (_selectedFilterIndex == 1) {
      return all
          .where((n) =>
              n.type == NotificationType.system ||
              n.type == NotificationType.kyc)
          .toList();
    }
    if (_selectedFilterIndex == 2) {
      return all
          .where((n) =>
              n.type == NotificationType.subscription ||
              n.type == NotificationType.promo)
          .toList();
    }
    if (_selectedFilterIndex == 3) {
      return all.where((n) => n.type == NotificationType.book).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<NotificationItem>>(
      valueListenable: NotificationService.notificationsNotifier,
      builder: (context, allItems, _) {
        final filteredList = _getFilteredList(allItems);
        final unreadCount = allItems.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                const Text(
                  'ການແຈ້ງເຕືອນ (Notifications)',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount ໃໝ່',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all_rounded,
                      size: 16, color: AppColors.primary),
                  label: const Text('ອ່ານທັງໝົດ',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
            ],
          ),
          body: Column(
            children: [
              // Filter Chips Row
              Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterCategories.length,
                    itemBuilder: (context, idx) {
                      final isSelected = _selectedFilterIndex == idx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          selected: isSelected,
                          label: Text(_filterCategories[idx]),
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          selectedColor: AppColors.primary,
                          backgroundColor: const Color(0xFFF1F5F9),
                          side: BorderSide.none,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedFilterIndex = idx);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Main List Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.primary))
                    : filteredList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.notifications_off_outlined,
                                    size: 64, color: Color(0xFFCBD5E1)),
                                SizedBox(height: 12),
                                Text(
                                  'ບໍ່ມີການແຈ້ງເຕືອນໃນຂະນະນີ້',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchNotifications,
                            color: AppColors.primary,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = filteredList[index];
                                return _buildNotificationCard(item);
                              },
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
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

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteNotification(item.id),
      child: InkWell(
        onTap: () => _onNotificationTap(item),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFF0F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE2E8F0)
                  : AppColors.primary.withOpacity(0.3),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(item.isRead ? 0.02 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification Type Avatar Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: iconColor, size: 22),
              ),
              const SizedBox(width: 12),

              // Title & Message Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: item.isRead
                            ? AppColors.textSecondary
                            : const Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.timeAgo,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
