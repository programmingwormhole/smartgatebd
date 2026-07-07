import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/auth_controller.dart';

class ApartmentInfoScreen extends StatelessWidget {
  const ApartmentInfoScreen({super.key});

  String _displayValue(String? value, {String fallback = 'N/A'}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return fallback;
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Apartment Info'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<AuthController>(
        builder: (controller) {
          final user = controller.user;
          final apartmentLabel =
              'Apt ${_displayValue(user?.flatNo)}, Block ${_displayValue(user?.blockNo)}';
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryNavy.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home_work,
                        color: Colors.white,
                        size: 48,
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              apartmentLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _displayValue(
                                user?.buildingName,
                                fallback: 'Building Name',
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildInfoCard([
                  _buildInfoRow('Building', _displayValue(user?.buildingName)),
                  const Divider(),
                  _buildInfoRow('Block', _displayValue(user?.blockNo)),
                  const Divider(),
                  _buildInfoRow('Floor', _displayValue(user?.floorName)),
                  const Divider(),
                  _buildInfoRow('Flat', _displayValue(user?.flatNo)),
                  const Divider(),
                  _buildInfoRow(
                    'Role',
                    _displayValue(
                      user?.residentRole?.toUpperCase(),
                      fallback: 'RESIDENT',
                    ),
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Apartment ID',
                    user?.flatId?.toString() ?? 'N/A',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    'Building ID',
                    user?.buildingId?.toString() ?? 'N/A',
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primaryNavy),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This information is assigned by the building administrator. Contact them if you see any errors.',
                          style: TextStyle(
                            color: AppColors.primaryNavy,
                            fontSize: 13,
                          ),
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

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
