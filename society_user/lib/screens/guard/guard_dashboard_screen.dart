import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/app_config.dart';
import '../../controllers/guard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/notification_controller.dart';
import '../notifications/notification_screen.dart';
import 'add_walk_in_visitor_screen.dart';
import 'guard_qr_scanner_screen.dart';
import 'visitor_entry_verification_screen.dart';
import 'guard_activity_log_screen.dart';

class GuardDashboardScreen extends StatefulWidget {
  const GuardDashboardScreen({super.key});

  @override
  State<GuardDashboardScreen> createState() => _GuardDashboardScreenState();
}

class _GuardDashboardScreenState extends State<GuardDashboardScreen> {
  late TextEditingController _entryCodeController;
  final GuardController _controller = Get.find<GuardController>();

  @override
  void initState() {
    super.initState();
    _entryCodeController = TextEditingController();
  }

  @override
  void dispose() {
    _entryCodeController.dispose();
    super.dispose();
  }

  Future<void> _verifyEntryCode() async {
    final code = _entryCodeController.text.trim();
    if (code.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter entry code',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
      );
      return;
    }

    final visitor = await _controller.verifyEntryCode(code);

    if (visitor != null) {
      _entryCodeController.clear();
      Get.to(() => VisitorEntryVerificationScreen(visitorData: visitor));
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value.isNotEmpty
            ? _controller.errorMessage.value
            : 'Invalid entry code',
        backgroundColor: Colors.red.withValues(alpha: 0.1),
        colorText: Colors.red,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _scanEntryCode() async {
    final scannedCode = await Get.to<String>(
      () => const GuardQrScannerScreen(),
    );
    if (!mounted || scannedCode == null || scannedCode.trim().isEmpty) {
      return;
    }

    _entryCodeController.text = scannedCode.trim();
    await _verifyEntryCode();
  }

  Future<void> _openWalkInScreen() async {
    final result = await Get.to<Map<String, dynamic>>(
      () => const AddWalkInVisitorScreen(),
    );

    if (!mounted || result == null) return;

    final entryCode =
        (result['gatepass']?['entry_code'] ??
                result['visitor']?['gatepass']?['entry_code'] ??
                '')
            .toString();
    final visitorName = (result['visitor']?['name'] ?? 'Visitor').toString();

    Get.defaultDialog(
      title: 'Visitor Added',
      middleText: entryCode.isNotEmpty
          ? '$visitorName added successfully.\nEntry Code: $entryCode'
          : '$visitorName added successfully.',
      textConfirm: 'OK',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Guard Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppColors.primaryNavy,
        elevation: 0,
        actions: [
          if (AppConfig.showDBNotification)
            GetBuilder<NotificationController>(
              builder: (notificationController) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Get.to(() => const NotificationScreen());
                      },
                    ),
                    if (notificationController.unreadCount > 0)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            notificationController.unreadCount > 99
                                ? '99+'
                                : '${notificationController.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Get.find<AuthController>().logout();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry Code Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.qr_code_2,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verify Visitor Entry',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Enter the entry code from visitor gatepass',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _entryCodeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter entry code (e.g., 123456)',
                      prefixIcon: const Icon(Icons.password),
                      suffixIcon: IconButton(
                        tooltip: 'Scan QR code',
                        onPressed: _scanEntryCode,
                        icon: const Icon(Icons.qr_code_scanner),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primaryBlue,
                          width: 2,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onFieldSubmitted: (_) => _verifyEntryCode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: _controller.isLoading.value
                            ? null
                            : _verifyEntryCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _controller.isLoading.value
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Verify Entry Code',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openWalkInScreen,
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text('Add Walk-in Visitor'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Stats
            Text(
              'Today\'s Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Inside',
                      _controller.insideVisitors.length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      'Pending',
                      _controller.pendingVisitors.length.toString(),
                      Icons.person_add_alt_1,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Get.to(() => const GuardActivityLogScreen()),
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View My Activity Logs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
