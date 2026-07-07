import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/amenity_controller.dart';
import 'book_amenity_screen.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/date_formatter.dart';

class AmenitiesScreen extends StatefulWidget {
  const AmenitiesScreen({super.key});

  @override
  State<AmenitiesScreen> createState() => _AmenitiesScreenState();
}

class _AmenitiesScreenState extends State<AmenitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Get.find<AmenityController>();
      controller.fetchAmenities();
      controller.fetchBookings();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Amenities'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryNavy,
          tabs: const [
            Tab(text: 'Available'),
            Tab(text: 'My Bookings'),
          ],
        ),
      ),
      body: GetBuilder<AmenityController>(
        builder: (controller) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableTab(controller),
              _buildBookingsTab(controller),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailableTab(AmenityController controller) {
    if (controller.isLoading.value && controller.amenities.isEmpty) {
      return const ShimmerList();
    }

    if (controller.amenities.isEmpty) {
      return const Center(child: Text('No amenities available'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: controller.amenities.length,
      itemBuilder: (context, index) {
        final amenity = controller.amenities[index];
        final price = amenity['price_per_day'] ?? '0';
        final capacity = amenity['max_capacity'] ?? 'N/A';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAmenityCard(
            context,
            amenity['id'] as int,
            amenity['name'] ?? 'N/A',
            'Price: ৳$price/slot | Capacity: $capacity',
            _getIconForAmenity(amenity['name']),
            _getColorForAmenity(amenity['name']),
            'Available',
            isActionable: true,
            isUnavailable: false,
          ),
        );
      },
    );
  }

  Widget _buildBookingsTab(AmenityController controller) {
    if (controller.isLoading.value && controller.bookings.isEmpty) {
      return const ShimmerList();
    }

    if (controller.bookings.isEmpty) {
      return const Center(child: Text('No bookings found'));
    }

    return RefreshIndicator(
      onRefresh: () async => controller.fetchBookings(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: controller.bookings.length,
        itemBuilder: (context, index) {
          final booking = controller.bookings[index];
          final details = <String>[
            '${DateFormatter.formatDate(booking['booking_date'])} at ${DateFormatter.formatTimeRange(booking['booking_time'])}',
          ];

          final adminComment = (booking['admin_comment'] ?? '').toString().trim();
          final rejectionReason = (booking['rejection_reason'] ?? '')
              .toString()
              .trim();

          if (adminComment.isNotEmpty) {
            details.add('Admin Note: $adminComment');
          }

          if (rejectionReason.isNotEmpty) {
            details.add('Rejection Reason: $rejectionReason');
          }

          final status = (booking['status'] ?? 'pending').toString().toLowerCase();

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    booking['amenity_name'] ?? 'Booking',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      details[0],
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.capitalizeFirst ?? status,
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (adminComment.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.note_alt_outlined, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin Note: $adminComment',
                            style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (rejectionReason.isNotEmpty && status == 'rejected')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.errorRed, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reject Reason: $rejectionReason',
                            style: const TextStyle(color: AppColors.errorRed, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getIconForAmenity(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('pool')) return Icons.pool;
    if (n.contains('gym')) return Icons.fitness_center;
    if (n.contains('hall')) return Icons.celebration;
    if (n.contains('court')) return Icons.sports_tennis;
    return Icons.domain;
  }

  Color _getColorForAmenity(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('pool')) return Colors.blue;
    if (n.contains('gym')) return Colors.orange;
    if (n.contains('hall')) return Colors.purple;
    if (n.contains('court')) return Colors.green;
    return Colors.teal;
  }

  Widget _buildAmenityCard(
    BuildContext context,
    int amenityId,
    String title,
    String time,
    IconData icon,
    Color iconColor,
    String status, {
    bool isActionable = false,
    bool isUnavailable = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                time,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isUnavailable
                    ? AppColors.errorLight
                    : (isActionable
                          ? AppColors.primaryNavy
                          : AppColors.successGreen.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: isUnavailable
                      ? AppColors.errorRed
                      : (isActionable ? Colors.white : AppColors.successGreen),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (isActionable && !isUnavailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade100)),
              ),
              child: TextButton(
                onPressed: () {
                  Get.to(
                    () => BookAmenityScreen(
                      amenityId: amenityId,
                      amenityName: title,
                    ),
                  );
                },
                child: const Text(
                  'Request Booking',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
