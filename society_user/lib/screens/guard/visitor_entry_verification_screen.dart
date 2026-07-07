import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/guard_controller.dart';

class VisitorEntryVerificationScreen extends StatefulWidget {
  final Map<String, dynamic> visitorData;

  const VisitorEntryVerificationScreen({
    super.key,
    required this.visitorData,
  });

  @override
  State<VisitorEntryVerificationScreen> createState() =>
      _VisitorEntryVerificationScreenState();
}

class _VisitorEntryVerificationScreenState
    extends State<VisitorEntryVerificationScreen> {
  late TextEditingController _rejectReasonController;
  final GuardController _controller = Get.find<GuardController>();
  bool _isRejecting = false;

  @override
  void initState() {
    super.initState();
    _rejectReasonController = TextEditingController();
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmEntry() async {
    final passCategory = widget.visitorData['pass_category'] as String? ?? 'visitor';
    if (passCategory == 'permanent') {
      final subjectType = widget.visitorData['permanent_type'] as String?;
      final subjectId = widget.visitorData['id'] as int?;
      final entryCode = widget.visitorData['entry_code'] as String?;

      if (subjectType == null || subjectId == null || entryCode == null) {
        Get.snackbar('Error', 'Invalid permanent gatepass data');
        return;
      }

      final success = await _controller.markPermanentEntry(
        subjectType: subjectType,
        subjectId: subjectId,
        entryCode: entryCode,
      );
      if (!mounted) return;
      
      if (success) {
        if (mounted) {
          Get.back();
          Get.snackbar(
            'Success',
            'Entry logged successfully',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
          );
        }
      } else {
        Get.snackbar('Error', _controller.errorMessage.value);
      }
      return;
    }

    final visitorId = widget.visitorData['id'] as int?;
    if (visitorId == null) {
      Get.snackbar('Error', 'Invalid visitor data');
      return;
    }

    final success = await _controller.confirmVisitorEntry(visitorId);
    if (!mounted) return;

    if (success) {
      if (mounted) {
        Get.back();
        Get.snackbar(
          'Success',
          'Visitor entry confirmed',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to confirm visitor entry',
      );
    }
  }

  Future<void> _rejectEntry() async {
    final visitorId = widget.visitorData['id'] as int?;
    if (visitorId == null) {
      Get.snackbar('Error', 'Invalid visitor data');
      return;
    }

    if (_rejectReasonController.text.trim().isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter rejection reason',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
      return;
    }

    final success = await _controller.rejectVisitorEntry(
      visitorId,
      _rejectReasonController.text.trim(),
    );

    if (!mounted) return;
    
    if (success) {
      if (mounted) {
        Get.back();
        Get.snackbar(
          'Success',
          'Visitor entry rejected',
          backgroundColor: Colors.orange.withOpacity(0.1),
          colorText: Colors.orange,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to reject visitor entry',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> _exitVisitor() async {
    final passCategory = widget.visitorData['pass_category'] as String? ?? 'visitor';
    if (passCategory == 'permanent') {
      final subjectType = widget.visitorData['permanent_type'] as String?;
      final subjectId = widget.visitorData['id'] as int?;
      final entryCode = widget.visitorData['entry_code'] as String?;

      if (subjectType == null || subjectId == null || entryCode == null) {
        Get.snackbar('Error', 'Invalid permanent gatepass data');
        return;
      }

      final success = await _controller.markPermanentExit(
        subjectType: subjectType,
        subjectId: subjectId,
        entryCode: entryCode,
      );
      if (!mounted) return;
      
      if (success) {
        if (mounted) {
          Get.back();
          Get.snackbar(
            'Success',
            'Exit logged successfully',
            backgroundColor: Colors.green.withOpacity(0.1),
            colorText: Colors.green,
          );
        }
      } else {
        Get.snackbar('Error', _controller.errorMessage.value);
      }
      return;
    }

    final visitorId = widget.visitorData['id'] as int?;
    if (visitorId == null) {
      Get.snackbar('Error', 'Invalid visitor data');
      return;
    }

    final success = await _controller.markVisitorExit(visitorId);
    if (!mounted) return;

    if (success) {
      if (mounted) {
        Get.back();
        Get.snackbar(
          'Success',
          'Visitor marked as exited',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
      }
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Failed to mark visitor exit',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visitor = widget.visitorData;
    final guestName = visitor['guest_name'] as String? ?? 'Unknown';
    final residentName = visitor['resident_name'] as String? ?? 'Not assigned';
    final residentPhone = visitor['resident_phone'] as String? ?? '-';
    final purpose = visitor['purpose'] as String? ?? 'Not specified';
    final expectedCheckout =
        visitor['expected_checkout_time'] as String? ?? '-';
    final entryCode = visitor['entry_code'] as String? ?? '-';
    final status = visitor['status'] as String? ?? 'pending';
    final passCategory = visitor['pass_category'] as String? ?? 'visitor';
    final gatepassEnabled = visitor['gatepass_enabled'] as bool? ?? true;
    final entryTime = visitor['entry_time'] as String? ?? visitor['created_at'] as String? ?? '-';
    final exitTime = visitor['exit_time'] as String? ?? visitor['updated_at'] as String? ?? '-';
    final visitorType = visitor['type'] as String? ?? 'personal';
    final phone = visitor['phone'] as String? ?? '-';
    final vehicleNo = visitor['vehicle_no'] as String? ?? '-';
    final companyName = visitor['company_name'] as String? ?? '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Verify Gatepass',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visitor Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status == 'resident_rejected') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Rejected by Resident',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reason: ${visitor['reject_reason'] ?? 'Not specified'}',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              guestName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Entry Code: $entryCode',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  _buildInfoRow('Visiting Resident', residentName),
                  const SizedBox(height: 16),
                  _buildInfoRow('Resident Phone', residentPhone),
                  const SizedBox(height: 16),
                  _buildInfoRow('Visit Purpose', purpose),
                  const SizedBox(height: 16),
                  _buildInfoRow('Expected Checkout', expectedCheckout),
                  const SizedBox(height: 16),
                  if (passCategory == 'permanent') ...[
                    _buildInfoRow(
                      'Gatepass Type',
                      (visitor['permanent_type'] ?? '-').toString(),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      'Gatepass Status',
                      gatepassEnabled ? 'Enabled' : 'Disabled',
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Type-based conditional fields
                  ..._buildTypeBasedFields(visitorType, phone, vehicleNo, companyName),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Badge and Action Area (Conditional)
            if (passCategory == 'permanent' && !gatepassEnabled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.block, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This permanent gatepass is disabled by resident.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'exited') ...[
              // Visitor Expired Card with Statistics
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.lock_clock,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'VISITOR EXPIRED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Visit Statistics',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatisticRow(
                      'Entry Time',
                      _formatTime(entryTime),
                      Icons.login,
                      Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildStatisticRow(
                      'Exit Time',
                      _formatTime(exitTime),
                      Icons.logout,
                      Colors.red,
                    ),
                    const SizedBox(height: 12),
                    _buildStatisticRow(
                      'Total Stay Duration',
                      _calculateDuration(entryTime, exitTime),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ],
                ),
              ),
            ] else if (status == 'inside') ...[
              // Visitor Inside - Show Only Exit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                passCategory == 'permanent'
                                    ? 'Member Inside'
                                    : 'Visitor Inside',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Entry time: $entryTime',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _controller.isLoading.value ? null : _exitVisitor,
                    icon: const Icon(Icons.exit_to_app),
                    label: Text(
                      passCategory == 'permanent' ? 'Log Exit' : 'Exit Visitor',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Rejection Reason (if rejecting)
              if (_isRejecting) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Rejection Reason',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _rejectReasonController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Enter reason for rejection...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action Buttons (Allow/Reject)
              Obx(() => Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: passCategory == 'permanent'
                          ? null
                          : (_controller.isLoading.value == true
                          ? null
                          : _cancelRejection),
                      icon: const Icon(Icons.close),
                      label:
                      Text(passCategory == 'permanent' ? 'No Reject' : (_isRejecting ? 'Cancel' : 'Reject Entry')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: _isRejecting == true ? Colors.orange : Colors.red,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _controller.isLoading.value == true
                          ? null
                          : (_isRejecting ? _rejectEntry : _confirmEntry),
                      icon: Icon(_isRejecting ? Icons.delete : Icons.check),
                      label: Text(
                          _isRejecting
                              ? 'Confirm Rejection'
                              : (passCategory == 'permanent' ? 'Log Entry' : 'Allow Entry')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        _isRejecting ? Colors.red : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              )),
            ],
          ],
        ),
      ),
    );
  }

  void _cancelRejection() {
    if (_isRejecting) {
      setState(() {
        _isRejecting = false;
        _rejectReasonController.clear();
      });
    } else {
      setState(() {
        _isRejecting = true;
      });
    }
  }

  String _formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty || timeString == '-') {
      return '-';
    }
    try {
      final dateTime = DateTime.parse(timeString);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} on ${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (e) {
      return timeString;
    }
  }

  String _calculateDuration(String? entryTime, String? exitTime) {
    if (entryTime == null || exitTime == null || entryTime == '-' || exitTime == '-') {
      return '-';
    }
    try {
      final entry = DateTime.parse(entryTime);
      final exit = DateTime.parse(exitTime);
      final duration = exit.difference(entry);

      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      if (hours > 0) {
        return '$hours h $minutes m $seconds s';
      } else if (minutes > 0) {
        return '$minutes m $seconds s';
      } else {
        return '$seconds s';
      }
    } catch (e) {
      return '-';
    }
  }

  Widget _buildStatisticRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTypeBasedFields(
    String type,
    String phone,
    String vehicleNo,
    String companyName,
  ) {
    final List<Widget> fields = [
      _buildInfoRow('Visitor Type', _formatVisitorType(type)),
    ];

    // Add phone for all types except personal
    if (type != 'personal') {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildInfoRow('Phone', phone));
    }

    // Add company name for delivery and cab types
    if (type == 'delivery' || type == 'cab') {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildInfoRow('Company', companyName));
    }

    // Add vehicle number for cab type
    if (type == 'cab') {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildInfoRow('Vehicle Number', vehicleNo));
    }

    // Add vehicle for delivery type
    if (type == 'delivery') {
      fields.add(const SizedBox(height: 16));
      fields.add(_buildInfoRow('Vehicle Number', vehicleNo));
    }

    return fields;
  }

  String _formatVisitorType(String type) {
    final typeMap = {
      'personal': 'Personal Guest',
      'cab': 'Cab Driver',
      'delivery': 'Delivery Partner',
      'service': 'Service Provider',
      'contractor': 'Contractor',
    };
    if (typeMap.containsKey(type)) {
      return typeMap[type]!;
    }
    // Fallback: capitalize first letter
    return type.isEmpty
        ? 'Unknown'
        : type[0].toUpperCase() + type.substring(1).replaceAll('_', ' ');
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
