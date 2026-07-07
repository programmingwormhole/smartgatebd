import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/service_controller.dart';
import 'book_service_screen.dart';
import '../../core/widgets/shimmer_loader.dart';
import '../../core/utils/date_formatter.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ServiceController>().fetchServices();
      Get.find<ServiceController>().fetchBookings();
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
        title: const Text('Maintenance & Services'),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryNavy,
          tabs: const [
            Tab(text: 'Book Service'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: GetBuilder<ServiceController>(
        builder: (serviceController) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingTab(serviceController),
              _buildHistoryTab(serviceController),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingTab(ServiceController controller) {
    if (controller.isLoading.value && controller.services.isEmpty) {
      return const _ServicesLoadingState();
    }

    if (controller.services.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.fetchServices,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: _ServicesEmptyState(onRetry: controller.fetchServices),
            ),
          ],
        ),
      );
    }

    final List<dynamic> categories = controller.services;

    return RefreshIndicator(
      onRefresh: controller.fetchServices,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What do you need help with?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.85,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final service = categories[index];
                final name = service['name'] as String;
                final serviceId = service['id'];
                final icon = service['icon'] is IconData
                    ? service['icon'] as IconData
                    : _getIconForService(name);
                final color = service['color'] is Color
                    ? service['color'] as Color
                    : _getColorForService(name);

                return InkWell(
                  onTap: serviceId == null
                      ? null
                      : () {
                          Get.to(
                            () => BookServiceScreen(
                              serviceId: serviceId as int,
                              category: name,
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Icon(icon, color: color, size: 32),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(ServiceController controller) {
    if (controller.isLoading.value && controller.bookings.isEmpty) {
      return const ShimmerList();
    }

    if (controller.bookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: controller.fetchBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(
              height: 400,
              child: Center(child: Text('No service requests found')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: controller.fetchBookings,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: controller.bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final booking = controller.bookings[index];

          final status = booking['status'] ?? 'Pending';
          final color = _getStatusColor(status);

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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'REQ-${booking['id']}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booking['description'] ?? 'No description',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _getIconForService(booking['category']),
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${booking['service']['name']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormatter.formatDate(booking['booking_date']),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  if ((booking['admin_comment'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Admin Note: ${booking['admin_comment']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if ((booking['rejection_reason'] ?? '')
                      .toString()
                      .trim()
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Rejection Reason: ${booking['rejection_reason']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.successGreen;
      case 'in progress':
        return AppColors.primaryBlue;
      case 'rejected':
        return AppColors.errorRed;
      default:
        return AppColors.warningOrange;
    }
  }

  IconData _getIconForService(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('plumb')) return Icons.plumbing;
    if (n.contains('elect')) return Icons.electrical_services;
    if (n.contains('clean')) return Icons.cleaning_services;
    if (n.contains('carp')) return Icons.carpenter;
    if (n.contains('laundry')) return Icons.local_laundry_service;
    if (n.contains('pest')) return Icons.pest_control;
    return Icons.build;
  }

  Color _getColorForService(String? name) {
    final n = name?.toLowerCase() ?? '';
    if (n.contains('plumb')) return Colors.blue;
    if (n.contains('elect')) return Colors.orange;
    if (n.contains('clean')) return Colors.teal;
    if (n.contains('carp')) return Colors.brown;
    if (n.contains('laundry')) return Colors.indigo;
    if (n.contains('pest')) return Colors.red;
    return Colors.grey;
  }
}

class _ServicesLoadingState extends StatelessWidget {
  const _ServicesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 14),
          Text(
            'Loading available services...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesEmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _ServicesEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.miscellaneous_services_outlined,
                  color: AppColors.primaryBlue,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No Services Available',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Services have not been configured for your building yet. Please try again shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Refresh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
