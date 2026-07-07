import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/admin_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../widgets/user_avatar_widget.dart';
import 'edit_resident_screen.dart';

class ResidentDetailScreen extends StatefulWidget {
  const ResidentDetailScreen({super.key, required this.resident});

  final Map<String, dynamic> resident;

  @override
  State<ResidentDetailScreen> createState() => _ResidentDetailScreenState();
}

class _ResidentDetailScreenState extends State<ResidentDetailScreen> {
  late Map<String, dynamic> _resident;
  bool _isLoadingDetails = false;
  List<dynamic> _residentBills = [];
  List<dynamic> _residentFamilyMembers = [];
  List<dynamic> _residentVehicles = [];

  @override
  void initState() {
    super.initState();
    _resident = Map<String, dynamic>.from(widget.resident);
    _loadResidentDetails();
  }

  Map<String, dynamic> get _user => _resident['user'] ?? {};
  Map<String, dynamic> get _flat => _resident['flat'] ?? {};

  String get _role =>
      (_resident['role'] ?? 'Resident').toString().capitalizeFirst ??
      'Resident';

  int? get _residentId {
    final id = _resident['id'];
    if (id is int) return id;
    if (id is String) return int.tryParse(id);
    return null;
  }

  int? get _flatId {
    final fromFlat = _flat['id'];
    if (fromFlat is int) return fromFlat;
    if (fromFlat is String) {
      final parsed = int.tryParse(fromFlat);
      if (parsed != null) return parsed;
    }

    final fromResident = _resident['flat_id'];
    if (fromResident is int) return fromResident;
    if (fromResident is String) return int.tryParse(fromResident);
    return null;
  }

  Future<void> _loadResidentDetails() async {
    final residentId = _residentId;
    final flatId = _flatId;
    if (residentId == null && flatId == null) return;

    setState(() => _isLoadingDetails = true);

    try {
      final adminService = Get.find<AdminController>().adminService;

      final billsFuture = flatId != null
          ? adminService.getFlatBills(flatId)
          : Future.value(<dynamic>[]);
      final familyFuture = residentId != null
          ? adminService.getResidentFamilyMembers(residentId)
          : Future.value(<dynamic>[]);
      final vehicleFuture = residentId != null
          ? adminService.getResidentVehicles(residentId)
          : Future.value(<dynamic>[]);

      final results = await Future.wait([
        billsFuture,
        familyFuture,
        vehicleFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _residentBills = List<dynamic>.from(results[0]);
        _residentFamilyMembers = List<dynamic>.from(results[1]);
        _residentVehicles = List<dynamic>.from(results[2]);
      });
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Error',
        'Failed to load full resident details',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  int get _pendingBillsCount {
    return _residentBills.where((bill) {
      final status = (bill['status'] ?? '').toString().toLowerCase();
      return status != 'paid';
    }).length;
  }

  int get _paidBillsCount {
    return _residentBills.where((bill) {
      final status = (bill['status'] ?? '').toString().toLowerCase();
      return status == 'paid';
    }).length;
  }

  List<dynamic> get _pendingBills {
    return _residentBills.where((bill) {
      final status = (bill['status'] ?? '').toString().toLowerCase();
      return status != 'paid';
    }).toList();
  }

  List<dynamic> get _paidBills {
    return _residentBills.where((bill) {
      final status = (bill['status'] ?? '').toString().toLowerCase();
      return status == 'paid';
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Resident Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadResidentDetails,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () {
              Get.to(() => EditResidentScreen(resident: _resident));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(),
            const SizedBox(height: 12),
            _statChips(),
            if (_isLoadingDetails)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            const SizedBox(height: 12),
            _infoSection('Contact', [
              _infoRow(Icons.phone, 'Phone', _user['phone'] ?? 'N/A'),
              _infoRow(
                Icons.email_outlined,
                'Email',
                _user['email'] ?? 'Not provided',
              ),
            ]),
            _infoSection('Address', [
              _infoRow(
                Icons.home_outlined,
                'Flat',
                _flat['flat_number'] ?? 'N/A',
              ),
              _infoRow(
                Icons.business_outlined,
                'Block',
                _flat['floor']?['block']?['name'] ??
                    _flat['block']?['name'] ??
                    _resident['block']?['name'] ??
                    'N/A',
              ),
              _infoRow(
                Icons.layers_outlined,
                'Floor',
                _flat['floor']?['floor_number'] ??
                    _resident['floor']?['floor_number'] ??
                    'N/A',
              ),
            ]),
            _infoSection('Account', [
              _infoRow(Icons.verified_user_outlined, 'Role', _role),
              _infoRow(
                Icons.badge_outlined,
                'Status',
                (_resident['status'] ?? 'Active').toString().capitalizeFirst ??
                    'Active',
              ),
            ]),
            const SizedBox(height: 8),
            _actionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppColors.primaryBlue, AppColors.primaryNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          UserAvatarWidget(
            radius: 28,
            userName: (_user['name'] ?? 'Resident').toString(),
            profilePictureUrl: _user['profile_picture']?.toString(),
            backgroundColor: Colors.white.withOpacity(0.15),
            textColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _pill(
                      label: _role,
                      color: Colors.white.withOpacity(0.2),
                      textColor: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      label: 'Flat ${_flat['flat_number'] ?? 'N/A'}',
                      color: Colors.white.withOpacity(0.15),
                      textColor: Colors.white,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _toggleCommittee(),
            icon: Icon(
              _role.toLowerCase() == 'committee'
                  ? Icons.workspace_premium_outlined
                  : Icons.group_outlined,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChips() {
    final dues = _pendingBillsCount;
    final paid = _paidBillsCount;
    final vehicles = _residentVehicles.length;
    final members = _residentFamilyMembers.length;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _statCard(
          'Pending Bills',
          '$dues',
          Icons.receipt_long,
          Colors.orange.shade100,
          Colors.orange.shade800,
          onTap: () => _openBills(title: 'Pending Bills', bills: _pendingBills),
        ),
        _statCard(
          'Paid Bills',
          '$paid',
          Icons.verified_outlined,
          Colors.green.shade100,
          Colors.green.shade800,
          onTap: () => _openBills(title: 'Paid Bills', bills: _paidBills),
        ),
        _statCard(
          'Family',
          '$members',
          Icons.family_restroom_outlined,
          Colors.blue.shade100,
          Colors.blue.shade800,
          onTap: () => _openFamilyMembers(),
        ),
        _statCard(
          'Vehicles',
          '$vehicles',
          Icons.directions_car_outlined,
          Colors.purple.shade100,
          Colors.purple.shade800,
          onTap: () => _openVehicles(),
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color bg,
    Color fg, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: (Get.width - 52) / 2,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: fg.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () =>
                Get.to(() => EditResidentScreen(resident: _resident)),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit Resident'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _deleteResident(context),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text('Remove', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _toggleCommittee() async {
    final adminCtrl = Get.find<AdminController>();
    final id = _resident['id'];
    if (id == null) return;

    final currentRole = _role.toLowerCase();
    final newRole = currentRole == 'committee' ? 'resident' : 'committee';
    final success = await adminCtrl.toggleCommitteeStatus(id, newRole);
    if (success) {
      Get.snackbar(
        'Updated',
        'Role changed to ${newRole.capitalizeFirst}',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _deleteResident(BuildContext context) async {
    final adminCtrl = Get.find<AdminController>();
    final id = _resident['id'];
    if (id == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Resident'),
        content: const Text('Are you sure you want to remove this resident?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await adminCtrl.deleteResident(id);
    if (success) {
      Get.back();
      Get.snackbar(
        'Removed',
        'Resident removed',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  void _openBills({required String title, required List<dynamic> bills}) {
    final residentName = (_user['name'] ?? 'Resident').toString();
    Get.to(
      () => _ResidentBillsScreen(
        title: '$title - $residentName',
        bills: bills,
        allowMarkAsPaid: title.toLowerCase().contains('pending'),
        onMarkAsPaid: _markBillAsPaid,
      ),
    );
  }

  Future<bool> _markBillAsPaid(int billId, {String? note}) async {
    final success = await Get.find<AdminController>().markBillAsPaid(
      billId,
      note: note,
    );

    if (success) {
      await _loadResidentDetails();
    }

    return success;
  }

  void _openFamilyMembers() {
    final residentName = (_user['name'] ?? 'Resident').toString();
    Get.to(
      () => _ResidentFamilyMembersScreen(
        title: 'Family - $residentName',
        members: _residentFamilyMembers,
      ),
    );
  }

  void _openVehicles() {
    final residentName = (_user['name'] ?? 'Resident').toString();
    Get.to(
      () => _ResidentVehiclesScreen(
        title: 'Vehicles - $residentName',
        vehicles: _residentVehicles,
      ),
    );
  }
}

class _ResidentBillsScreen extends StatefulWidget {
  const _ResidentBillsScreen({
    required this.title,
    required this.bills,
    required this.allowMarkAsPaid,
    required this.onMarkAsPaid,
  });

  final String title;
  final List<dynamic> bills;
  final bool allowMarkAsPaid;
  final Future<bool> Function(int billId, {String? note}) onMarkAsPaid;

  @override
  State<_ResidentBillsScreen> createState() => _ResidentBillsScreenState();
}

class _ResidentBillsScreenState extends State<_ResidentBillsScreen> {
  late List<dynamic> _bills;

  @override
  void initState() {
    super.initState();
    _bills = List<dynamic>.from(widget.bills);
  }

  Future<void> _showMarkPaidDialog(Map<String, dynamic> bill) async {
    final noteController = TextEditingController();

    await Get.dialog(
      AlertDialog(
        title: const Text('Mark Bill as Paid'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional comment or note',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final billIdValue = bill['id'];
              final billId = billIdValue is int
                  ? billIdValue
                  : int.tryParse(billIdValue.toString());

              if (billId == null) return;

              final success = await widget.onMarkAsPaid(
                billId,
                note: noteController.text.trim(),
              );

              if (success) {
                setState(() {
                  bill['status'] = 'paid';
                });
                Get.back();
                Get.snackbar(
                  'Success',
                  'Bill marked as paid',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  'Failed to mark bill as paid',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title), backgroundColor: Colors.white),
      body: _bills.isEmpty
          ? const Center(child: Text('No bills found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bills.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bill = _bills[index] as Map<String, dynamic>;
                final status = (bill['status'] ?? 'unpaid')
                    .toString()
                    .toUpperCase();
                final amount = bill['amount']?.toString() ?? '0';
                final monthYear = bill['month_year']?.toString() ?? 'N/A';
                final isPaid = status == 'PAID';

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: Column(
                      children: [
                        ListTile(
                          title: Text(
                            '${bill['type']?.toString().capitalizeFirst ?? 'Bill'} - $monthYear',
                          ),
                          subtitle: Text('Amount: ৳$amount'),
                          trailing: Text(
                            status,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPaid ? Colors.green : Colors.orange,
                            ),
                          ),
                        ),
                        if (widget.allowMarkAsPaid && !isPaid)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _showMarkPaidDialog(bill),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Mark as Paid'),
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
}

class _ResidentFamilyMembersScreen extends StatelessWidget {
  const _ResidentFamilyMembersScreen({
    required this.title,
    required this.members,
  });

  final String title;
  final List<dynamic> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white),
      body: members.isEmpty
          ? const Center(child: Text('No family members found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final member = members[index] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(member['name']?.toString() ?? 'Unknown'),
                    subtitle: Text(
                      '${member['relation'] ?? 'Member'}${(member['phone'] ?? '').toString().isNotEmpty ? ' • ${member['phone']}' : ''}',
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ResidentVehiclesScreen extends StatelessWidget {
  const _ResidentVehiclesScreen({required this.title, required this.vehicles});

  final String title;
  final List<dynamic> vehicles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.white),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles found'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index] as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text(vehicle['model']?.toString() ?? 'Vehicle'),
                    subtitle: Text(
                      '${vehicle['plate_number'] ?? 'N/A'}${(vehicle['color'] ?? '').toString().isNotEmpty ? ' • ${vehicle['color']}' : ''}',
                    ),
                    trailing: Text(vehicle['type']?.toString() ?? ''),
                  ),
                );
              },
            ),
    );
  }
}
