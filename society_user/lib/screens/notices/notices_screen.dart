import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/notice_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class NoticesScreen extends StatefulWidget {
  const NoticesScreen({super.key});

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<NoticeController>().fetchNotices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notice Board'),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primaryNavy),
            onPressed: () => Get.find<NoticeController>().fetchNotices(),
          ),
        ],
      ),
      body: GetBuilder<NoticeController>(
        builder: (noticeController) {
          if (noticeController.isLoading && noticeController.notices.isEmpty) {
            return const ShimmerList();
          }

          if (noticeController.notices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text('No notices found'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: noticeController.notices.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final notice = noticeController.notices[index];
              final isUrgent =
                  notice['priority']?.toString().toLowerCase() == 'urgent';
              return _buildNoticeCard(
                title: notice['title'] ?? 'Notice',
                date:
                    notice['created_at_human'] ??
                    notice['created_at'] ??
                    'Date N/A',
                description: notice['description'] ?? '',
                isUrgent: isUrgent,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildNoticeCard({
    required String title,
    required String date,
    required String description,
    required bool isUrgent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent
              ? AppColors.errorRed.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isUrgent
                        ? AppColors.errorLight
                        : AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isUrgent ? 'URGENT' : 'GENERAL',
                    style: TextStyle(
                      color: isUrgent
                          ? AppColors.errorRed
                          : AppColors.primaryNavy,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            if (isUrgent) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.errorRed,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Requires immediate attention',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.errorRed.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
