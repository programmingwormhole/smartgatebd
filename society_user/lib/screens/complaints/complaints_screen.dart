import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/complaint_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    final complaintController = Get.find<ComplaintController>();
    if (_tabController.index == 0) {
      complaintController.fetchActiveComplaints();
    } else {
      complaintController.fetchResolvedComplaints();
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Fetch complaints on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ComplaintController>().fetchActiveComplaints();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complaints'),
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
            Tab(text: 'Active'),
            Tab(text: 'Resolved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComplaintsList(isActive: true),
          _buildComplaintsList(isActive: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewComplaintDialog(),
        backgroundColor: AppColors.primaryNavy,
        icon: const Icon(Icons.add_comment, color: Colors.white),
        label: const Text(
          'New Complaint',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildComplaintsList({required bool isActive}) {
    return GetBuilder<ComplaintController>(
      builder: (complaintController) {
        final isLoading = isActive
            ? complaintController.isActiveLoading
            : complaintController.isResolvedLoading;

        if (isLoading) {
          return const ShimmerList();
        }

        final complaints = isActive
            ? complaintController.activeComplaints
            : complaintController.resolvedComplaints;

        Future<void> onRefresh() async {
          if (isActive) {
            await complaintController.fetchActiveComplaints();
          } else {
            await complaintController.fetchResolvedComplaints();
          }
        }

        if (complaints.isEmpty) {
          return RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.speaker_notes_off_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isActive
                              ? 'No active complaints'
                              : 'No resolved complaints',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return _buildComplaintCard(
                complaint['title'] ?? 'N/A',
                complaint['category'] ?? 'General',
                complaint['status'] ?? 'Pending',
                complaint['created_at'] != null
                    ? complaint['created_at'].toString().split('T')[0]
                    : 'N/A',
                complaint['description'] ?? '',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildComplaintCard(
    String title,
    String category,
    String status,
    String date,
    String desc,
  ) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = AppColors.successGreen;
        break;
      case 'inprogress':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = AppColors.warningOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                date,
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
              // const Spacer(),
              // TextButton(
              //   onPressed: () {},
              //   style: TextButton.styleFrom(
              //     padding: EdgeInsets.zero,
              //     minimumSize: const Size(0, 0),
              //     tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              //   ),
              //   child: const Text(
              //     'View Details',
              //     style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewComplaintDialog() {
    String? selectedCategory;
    final categories = [
      'Electrical',
      'Plumbing',
      'Security',
      'Common Area',
      'Parking',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'New Complaint',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Category',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((cat) {
                    final isSelected = selectedCategory == cat;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryNavy
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryNavy
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                _buildComplaintInputField(
                  'Title',
                  'Enter a short title',
                  controller: _titleController,
                ),
                const SizedBox(height: 16),
                _buildComplaintInputField(
                  'Description',
                  'Provide details about the issue',
                  controller: _descController,
                  maxLines: 4,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedCategory == null ||
                          _titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields'),
                          ),
                        );
                        return;
                      }

                      final success = await Get.find<ComplaintController>()
                          .addComplaint({
                            'category': selectedCategory,
                            'title': _titleController.text.trim(),
                            'description': _descController.text.trim(),
                          });

                      if (success) {
                        _titleController.clear();
                        _descController.clear();
                        _tabController.animateTo(0);
                        Get.back();
                        Get.snackbar(
                          'Success',
                          'Complaint raised successfully',
                        );
                      } else {
                        Get.snackbar(
                          'Error',
                          'Failed to submit complaint',
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          colorText: Colors.red,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Submit Complaint',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintInputField(
    String label,
    String hint, {
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryNavy),
            ),
          ),
        ),
      ],
    );
  }
}
