import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/book_model.dart';
import '../../models/kyc_model.dart';

class AdminReportsTab extends StatelessWidget {
  final List<Map<String, dynamic>> subscriptions;
  final List<BookModel> adminBooks;
  final List<Map<String, dynamic>> adminUsers;
  final List<KycModel> kycSubmissions;
  final List<Map<String, dynamic>> auditLogs;
  final bool isMobile;

  const AdminReportsTab({
    super.key,
    required this.subscriptions,
    required this.adminBooks,
    required this.adminUsers,
    required this.kycSubmissions,
    required this.auditLogs,
    required this.isMobile,
  });

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0';
    final cleanStr = amount.toString().replaceAll(',', '').trim();
    final number = double.tryParse(cleanStr);
    if (number == null) return cleanStr.isEmpty ? '0' : cleanStr;

    final isInteger = number % 1 == 0;
    final formattedStr = isInteger ? number.toInt().toString() : number.toStringAsFixed(2);
    final parts = formattedStr.split('.');
    
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    final withCommas = parts[0].replaceAllMapped(regex, (Match m) => '${m[1]},');
    
    return parts.length > 1 ? '$withCommas.${parts[1]}' : withCommas;
  }

  @override
  Widget build(BuildContext context) {
    // 1. Calculate Revenue Metrics
    final approvedSubs = subscriptions.where((s) {
      final st = (s['payment_status'] ?? '').toString().toLowerCase();
      return st == 'approved' || st == 'active';
    }).toList();
    final pendingSubs = subscriptions.where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'pending').toList();
    final rejectedSubs = subscriptions.where((s) => (s['payment_status'] ?? '').toString().toLowerCase() == 'rejected').toList();

    double totalRevenue = 0;
    for (var s in approvedSubs) {
      totalRevenue += double.tryParse((s['amount'] ?? s['price'] ?? 49000).toString()) ?? 49000;
    }

    double pendingRevenue = 0;
    for (var s in pendingSubs) {
      pendingRevenue += double.tryParse((s['amount'] ?? s['price'] ?? 49000).toString()) ?? 49000;
    }

    // 2. Calculate Reading & Book Engagement Metrics
    int totalViews = 0;
    int totalLikes = 0;
    for (var b in adminBooks) {
      totalViews += b.viewCount;
      totalLikes += b.likeCount;
    }

    // Sort Top 5 Popular Books by real engagement
    final sortedBooks = List<BookModel>.from(adminBooks);
    sortedBooks.sort((a, b) {
      final scoreA = a.likeCount * 2 + a.viewCount;
      final scoreB = b.likeCount * 2 + b.viewCount;
      return scoreB.compareTo(scoreA);
    });
    final topBooks = sortedBooks.take(5).toList();

    // 3. Calculate User Demographics & KYC Metrics
    final totalUsers = adminUsers.length;
    final premiereUsersCount = adminUsers.where((u) => (u['role'] ?? '') == 'admin' || (u['role'] ?? '') == 'employee' || (u['email'] ?? '') == 'member@gmail.com').length;
    final kycApprovedCount = kycSubmissions.where((k) => k.status == KycStatus.approved).length;
    final kycPendingCount = kycSubmissions.where((k) => k.status == KycStatus.pending).length;
    final kycRejectedCount = kycSubmissions.where((k) => k.status == KycStatus.rejected).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter & Export Action Toolbar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.analytics_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('ລາຍງານສະຖິຕິ & ຜົນປະກອບການ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        Text('Executive Reports & Analytics Overview', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showExportReportModal(
                    context: context,
                    totalRevenue: totalRevenue,
                    totalUsers: totalUsers,
                    topBooksCount: topBooks.length,
                  ),
                  icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                  label: Text(isMobile ? 'ພິມ' : 'ພິມລາຍງານ PDF', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Executive KPI Grid (4 Cards)
          GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 1.45 : 1.6,
            children: [
              _buildReportKpiCard(
                title: 'ລາຍຮັບລວມການສະໝັກສະມາຊິກ',
                value: '${_formatCurrency(totalRevenue)} LAK',
                subtitle: 'ຈາກ ${approvedSubs.length} ລາຍການທີ່ອະນຸມັດ',
                icon: Icons.payments_rounded,
                color: const Color(0xFF10B981),
                bgColor: const Color(0xFFECFDF5),
              ),
              _buildReportKpiCard(
                title: 'ສະລິບລໍຖ້າກວດສອບມູນຄ່າ',
                value: '${_formatCurrency(pendingRevenue)} LAK',
                subtitle: '${pendingSubs.length} ລາຍການລໍຖ້າດຳເນີນການ',
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFFF59E0B),
                bgColor: const Color(0xFFFFFBEB),
              ),
              _buildReportKpiCard(
                title: 'ຜູ້ໃຊ້ງານລະບົບທັງໝົດ',
                value: '$totalUsers ຄົນ',
                subtitle: 'Premiere Member: $premiereUsersCount ຄົນ',
                icon: Icons.people_alt_rounded,
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
              ),
              _buildReportKpiCard(
                title: 'ยอดเข้าชมหนังสือรวม',
                value: '$totalViews ຄັ້ງ',
                subtitle: 'ยอดกดไลก์รวม: $totalLikes ครั้ง',
                icon: Icons.auto_graph_rounded,
                color: const Color(0xFF8B5CF6),
                bgColor: const Color(0xFFF5F3FF),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Charts & Analytics Grid
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Panel: Subscription Status Breakdowns
              Expanded(
                flex: isMobile ? 0 : 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text('ສະຖິຕິການອະນຸມັດສະລິບໂອນເງິນ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          Text('ລວມ ${subscriptions.length} ລາຍການ', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildProgressBarItem(label: 'ອະນຸມັດແລ້ວ (Approved)', count: approvedSubs.length, total: subscriptions.length, color: const Color(0xFF10B981)),
                      const SizedBox(height: 12),
                      _buildProgressBarItem(label: 'ລໍຖ້າກວດສອບ (Pending)', count: pendingSubs.length, total: subscriptions.length, color: const Color(0xFFF59E0B)),
                      const SizedBox(height: 12),
                      _buildProgressBarItem(label: 'ປະຕິເສດ/ບໍ່ຖືກຕ້ອງ (Rejected)', count: rejectedSubs.length, total: subscriptions.length, color: const Color(0xFFEF4444)),
                    ],
                  ),
                ),
              ),
              if (!isMobile) const SizedBox(width: 16),
              if (isMobile) const SizedBox(height: 16),

              // Right Panel: Top 5 Books Engagement Ranking & KYC Status
              Expanded(
                flex: isMobile ? 0 : 6,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.military_tech_rounded, color: Color(0xFFD97706), size: 20),
                                  SizedBox(width: 8),
                                  Text('Top 5 ປຶ້ມທີ່ມียອດອ່ານ & ໄລ້ສູງສຸດ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: topBooks.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (ctx, idx) {
                              final book = topBooks[idx];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: idx == 0 ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                  child: Text('${idx + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: idx == 0 ? const Color(0xFFD97706) : AppColors.textPrimary)),
                                ),
                                title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                subtitle: Text(book.author, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.remove_red_eye_rounded, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 2),
                                    Text('${book.viewCount}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.thumb_up_rounded, size: 12, color: AppColors.primary),
                                    const SizedBox(width: 2),
                                    Text('${book.likeCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // KYC Demographics Summary Mini Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                              SizedBox(width: 8),
                              Text('ສະຖານະການຢືນຢັນຕົວຕົນ (KYC Status)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildMiniStatCircle(title: 'ຜ່ານອະນຸມັດ', count: kycApprovedCount, color: const Color(0xFF10B981)),
                              _buildMiniStatCircle(title: 'ລໍຖ້າກວດ', count: kycPendingCount, color: const Color(0xFFF59E0B)),
                              _buildMiniStatCircle(title: 'ປະຕິເສດ', count: kycRejectedCount, color: const Color(0xFFEF4444)),
                              _buildMiniStatCircle(title: 'ສະມາຊິກ Premiere', count: premiereUsersCount, color: const Color(0xFF7C3AED)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Audit Activity Logs Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.history_toggle_off_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('ປະຫວັດກິດຈະກຳໃນລະບົບ (System Audit Logs)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            Text('ບັນທຶກການເພີ່ມ, ແກ້ໄຂ, ລົບ, ອະນຸມັດ ແລະ ປະຕິເສດ ຂອງແອດມິນ ແລະ ພະນັກງານ', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${auditLogs.length} ລາຍການ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (auditLogs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: const [
                        Icon(Icons.rule_folder_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('ບໍ່ມີບັນທຶກກິດຈະກຳຍ້ອນຫຼັງ', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                        Text('ເມື່ອແອດມິນ ຫຼື ພະນັກງານ ເຮັດກິດຈະກຳໃນລະບົບ ຂໍ້ມູນຈະສະແດງຢູ່ບ່ອນນີ້', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: auditLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 16, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, idx) {
                      final log = auditLogs[idx];
                      final String action = (log['action'] ?? 'ກິດຈະກຳໃນລະບົບ').toString();
                      final String details = (log['details'] ?? '').toString();
                      final String userFullName = (log['user_full_name'] ?? log['user_name'] ?? 'Admin/Staff').toString();
                      final String userRole = (log['user_role'] ?? 'admin').toString();
                      final String createdAtRaw = (log['created_at'] ?? '').toString();

                      String formattedDate = 'ມື້ນີ້';
                      if (createdAtRaw.isNotEmpty) {
                        final parts = createdAtRaw.split('T');
                        if (parts.length >= 2) {
                          final datePart = parts[0];
                          final timePart = parts[1].split('.')[0];
                          formattedDate = '$datePart $timePart';
                        } else {
                          formattedDate = createdAtRaw;
                        }
                      }

                      Color actionColor = AppColors.primary;
                      IconData actionIcon = Icons.info_outline_rounded;

                      if (action.contains('ເພີ່ມ') || action.contains('ອະນຸມັດ') || action.contains('ສ້າງ')) {
                        actionColor = const Color(0xFF10B981);
                        actionIcon = Icons.add_circle_outline_rounded;
                      } else if (action.contains('ແກ້ໄຂ') || action.contains('ຈັດການ')) {
                        actionColor = const Color(0xFFF59E0B);
                        actionIcon = Icons.edit_note_rounded;
                      } else if (action.contains('ລົບ') || action.contains('ປະຕິເສດ') || action.contains('ລະງັບ')) {
                        actionColor = const Color(0xFFEF4444);
                        actionIcon = Icons.remove_circle_outline_rounded;
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: actionColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(actionIcon, size: 18, color: actionColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: actionColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        action,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: actionColor),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        userRole.toUpperCase(),
                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(details.isNotEmpty ? details : 'ບໍ່ມີລາຍລະອຽດເພີ່ມເຕີມ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                                const SizedBox(height: 2),
                                Text('ດຳເນີນການໂດຍ: $userFullName', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReportKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildProgressBarItem({required String label, required int count, required int total, required Color color}) {
    final double percent = (count / (total > 0 ? total : 1)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            Text('$count ລາຍການ (${(percent * 100).round()}%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCircle({required String title, required int count, required Color color}) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Center(
            child: Text('$count', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  void _showExportReportModal({
    required BuildContext context,
    required double totalRevenue,
    required int totalUsers,
    required int topBooksCount,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.print_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 8),
            Text('ລາຍງານສະຫຼຸບຜູ້ບໍລິຫານ (Executive Summary)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ສະຫຼຸບລາຍງານສະຖິຕິການນຳໃຊ້ ແລະ ລາຍຮັບລະບົບ e-Book:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ລາຍຮັບລວມອະນຸມັດ: ${_formatCurrency(totalRevenue)} LAK', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  const SizedBox(height: 4),
                  Text('• ຈຳນວນຜູ້ໃຊ້ງານທັງໝົດ: $totalUsers ບັນຊີ', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('• ຈຳນວນປຶ້ມໃນລະບົບ: ${adminBooks.length} ຫົວ', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('• ລາຍງານອອກ ວັນທີ: ${DateTime.now().toString().split(' ')[0]}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ປິດ')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ສົ່ງອອກລາຍງານ PDF ສຳເລັດແລ້ວ!'), backgroundColor: Color(0xFF10B981)),
              );
            },
            icon: const Icon(Icons.download_rounded, size: 16),
            label: const Text('ດາວໂຫຼດ PDF'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
