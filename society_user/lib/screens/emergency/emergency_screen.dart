import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/emergency_controller.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Fetch contacts on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<EmergencyController>().fetchSupportContacts();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<EmergencyController>(
        builder: (provider) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SOS Section
                _buildSOSSection(provider),

                // const SizedBox(height: 32),

                // const Text(
                //   'Society Support',
                //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                // ),
                // const SizedBox(height: 16),
                // provider.isLoading
                //     ? const Center(child: CircularProgressIndicator())
                //     : provider.supportContacts.isEmpty
                //     ? _buildEmptyContacts()
                //     : GridView.builder(
                //         shrinkWrap: true,
                //         physics: const NeverScrollableScrollPhysics(),
                //         gridDelegate:
                //             const SliverGridDelegateWithFixedCrossAxisCount(
                //               crossAxisCount: 2,
                //               mainAxisSpacing: 12,
                //               crossAxisSpacing: 12,
                //               childAspectRatio: 1.4,
                //             ),
                //         itemCount: provider.supportContacts.length,
                //         itemBuilder: (context, index) {
                //           final contact = provider.supportContacts[index];
                //           return _buildSupportCard(
                //             contact['name'] ?? 'Support',
                //             contact['phone'] ?? 'N/A',
                //             _getIconForCategory(contact['category']),
                //             _getColorForCategory(contact['category']),
                //           );
                //         },
                //       ),
                const SizedBox(height: 32),
                const Text(
                  'Public Authorities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPublicContact(
                  'Police Station',
                  '999',
                  Icons.local_police,
                  Colors.blueGrey,
                ),
                const SizedBox(height: 12),
                _buildPublicContact(
                  'Fire Brigade',
                  '199',
                  Icons.fire_truck,
                  Colors.deepOrange,
                ),
                const SizedBox(height: 12),
                _buildPublicContact(
                  'Ambulance',
                  '102',
                  Icons.medical_services,
                  Colors.red,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getIconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'security':
        return Icons.security;
      case 'admin':
        return Icons.admin_panel_settings;
      case 'electrician':
        return Icons.bolt;
      case 'plumber':
        return Icons.water_drop;
      default:
        return Icons.contact_support;
    }
  }

  Color _getColorForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'security':
        return Colors.indigo;
      case 'admin':
        return Colors.blue;
      case 'electrician':
        return Colors.orange;
      case 'plumber':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }

  Widget _buildEmptyContacts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: Text('No society contacts available')),
    );
  }

  Widget _buildSOSSection(EmergencyController provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _rippleController,
                builder: (context, child) {
                  return Container(
                    width: 120 + (40 * _rippleController.value),
                    height: 120 + (40 * _rippleController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withValues(
                        alpha: 0.2 * (1 - _rippleController.value),
                      ),
                    ),
                  );
                },
              ),
              GestureDetector(
                onLongPress: () => _showSOSOptions(provider),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Long Press SOS for 3s',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Immediately alerts all on-duty guards',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(
    String title,
    String phone,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                phone,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Icon(Icons.call, size: 16, color: AppColors.successGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicContact(
    String name,
    String number,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.call, color: AppColors.successGreen, size: 20),
        ],
      ),
    );
  }

  void _showSOSOptions(EmergencyController provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        final alertTypes = [
          {
            'label': 'Fire Alert',
            'icon': Icons.local_fire_department,
            'color': Colors.orange,
          },
          {
            'label': 'Stuck in Lift',
            'icon': Icons.elevator,
            'color': Colors.blue,
          },
          {
            'label': 'Medical Emergency',
            'icon': Icons.medical_services,
            'color': Colors.red,
          },
          {
            'label': 'Security Threat',
            'icon': Icons.security,
            'color': Colors.indigo,
          },
          {'label': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
        ];

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Emergency Type',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Immediately alerts all on-duty guards with your location',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: alertTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final type = alertTypes[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        _sendSOSAlert(provider, type['label'] as String);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (type['color'] as Color).withValues(
                            alpha: 0.05,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (type['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: type['color'] as Color,
                            ),
                            const SizedBox(width: 16),
                            Text(
                              type['label'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendSOSAlert(EmergencyController provider, String type) async {
    final success = await provider.triggerSos(
      type,
      'Emergency: $type triggered by user.',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '$type Triggered! Guards notified.'
                : 'Failed to trigger SOS alert.',
          ),
          backgroundColor: success ? Colors.red : Colors.grey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
