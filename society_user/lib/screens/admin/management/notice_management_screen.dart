import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/notice_controller.dart';
import '../../../core/constants/colors.dart';
import '../../../services/admin_service.dart';
import '../../../services/notice_service.dart';
import '../../../widgets/responsive_web_container.dart';

class NoticeManagementScreen extends StatefulWidget {
  const NoticeManagementScreen({super.key});

  @override
  State<NoticeManagementScreen> createState() => _NoticeManagementScreenState();
}

class _NoticeManagementScreenState extends State<NoticeManagementScreen> {
  final NoticeController _noticeController = Get.find<NoticeController>();
  final AuthController _authController = Get.find<AuthController>();
  final NoticeService _noticeService = NoticeService();
  final AdminService _adminService = AdminService();

  bool _isSuperadmin = false;
  bool _isCreatingNotice = false;
  bool _isUpdatingNotice = false;
  int? _deletingNoticeId;
  List<Map<String, dynamic>> _buildings = [];
  int? _selectedBuildingId;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _bootstrap);
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _bootstrap() async {
    final user = _authController.user;
    _isSuperadmin = user?.role.toLowerCase() == 'superadmin';

    if (_isSuperadmin) {
      try {
        final buildings = await _adminService.getAllBuildings();
        _buildings = buildings
            .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
            .toList();

        final preferred = _noticeController.activeBuildingId ?? user?.buildingId;
        _selectedBuildingId = preferred ?? (_buildings.isNotEmpty ? _toInt(_buildings.first['id']) : null);
      } catch (e) {
        debugPrint('Error loading buildings for notice management: $e');
      }
    } else {
      _selectedBuildingId = user?.buildingId;
    }

    if (_selectedBuildingId != null) {
      _noticeController.setActiveBuildingId(_selectedBuildingId);
      await _noticeController.fetchNotices(buildingId: _selectedBuildingId);
    }

    if (mounted) setState(() {});
  }

  String _buildingName(int? id) {
    if (id == null) return 'Select building';
    final building = _buildings.firstWhere(
      (e) => _toInt(e['id']) == id,
      orElse: () => {},
    );
    return (building['name'] ?? 'Building').toString();
  }

  Future<void> _openCreateNoticeDialog() async {
    if (_selectedBuildingId == null) {
      Get.snackbar(
        'Building Required',
        'Please select a building first.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final payload = await Get.dialog<Map<String, String>>(
      const _NoticeEditorDialog(title: 'Create Notice', submitLabel: 'Create'),
    );

    if (payload == null || payload.isEmpty) return;

    setState(() => _isCreatingNotice = true);
    try {
      final success = await _noticeService.createNotice(
        _selectedBuildingId!,
        {
          'title': payload['title'] ?? '',
          'content': payload['content'] ?? '',
          'created_by_admin_id': _authController.user?.id,
        },
      );

      if (!mounted) return;

      if (success) {
        await _noticeController.fetchNotices(buildingId: _selectedBuildingId);
        if (!mounted) return;
        Get.snackbar(
          'Success',
          'Notice created successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',
          'Could not create notice.',
          backgroundColor: AppColors.errorRed,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingNotice = false);
    }
  }

  Future<void> _openEditNoticeDialog(Map<String, dynamic> notice) async {
    final noticeId = _toInt(notice['id']);
    if (noticeId == null) return;

    final payload = await Get.dialog<Map<String, String>>(
      _NoticeEditorDialog(
        title: 'Edit Notice',
        submitLabel: 'Update',
        initialTitle: (notice['title'] ?? '').toString(),
        initialContent: (notice['content'] ?? notice['description'] ?? '').toString(),
      ),
    );

    if (payload == null || payload.isEmpty) return;

    setState(() => _isUpdatingNotice = true);
    try {
      final success = await _noticeService.updateNotice(noticeId, {
        'title': payload['title'] ?? '',
        'content': payload['content'] ?? '',
      });

      if (!mounted) return;

      if (success) {
        await _noticeController.fetchNotices(buildingId: _selectedBuildingId);
        if (!mounted) return;
        Get.snackbar(
          'Success',
          'Notice updated successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',
          'Could not update notice.',
          backgroundColor: AppColors.errorRed,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdatingNotice = false);
    }
  }

  Future<void> _deleteNotice(Map<String, dynamic> notice) async {
    final noticeId = _toInt(notice['id']);
    if (noticeId == null) return;

    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete Notice'),
        content: const Text('Are you sure you want to delete this notice?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() => _deletingNoticeId = noticeId);
    try {
      final success = await _noticeService.deleteNotice(noticeId);
      if (!mounted) return;

      if (success) {
        await _noticeController.fetchNotices(buildingId: _selectedBuildingId);
        if (!mounted) return;
        Get.snackbar(
          'Success',
          'Notice deleted successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Failed',
          'Could not delete notice.',
          backgroundColor: AppColors.errorRed,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) setState(() => _deletingNoticeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notice Management',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryNavy,
        actions: [
          IconButton(
            onPressed: () => _noticeController.fetchNotices(buildingId: _selectedBuildingId),
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
          IconButton(
            onPressed: (_isCreatingNotice || _isUpdatingNotice || _deletingNoticeId != null)
                ? null
                : _openCreateNoticeDialog,
            icon: (_isCreatingNotice || _isUpdatingNotice)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: ResponsiveWebContainer(
        maxWidth: 800,
        child: Column(
          children: [
            if (_isSuperadmin)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DropdownButtonFormField<int>(
                initialValue: _selectedBuildingId,
                decoration: const InputDecoration(
                  labelText: 'Building',
                  border: OutlineInputBorder(),
                ),
                items: _buildings
                    .map(
                      (b) => DropdownMenuItem<int>(
                        value: _toInt(b['id']),
                        child: Text((b['name'] ?? 'Building').toString()),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() => _selectedBuildingId = value);
                  _noticeController.setActiveBuildingId(value);
                  await _noticeController.fetchNotices(buildingId: value);
                },
              ),
            ),
          Expanded(
            child: GetBuilder<NoticeController>(
              builder: (controller) {
                if (controller.isLoading && controller.notices.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_selectedBuildingId == null) {
                  return const Center(
                    child: Text('No building selected or assigned.'),
                  );
                }

                if (controller.notices.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'No notices for ${_buildingName(_selectedBuildingId)}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openCreateNoticeDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Notice'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: controller.notices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final notice = controller.notices[index] as Map<String, dynamic>;
                    final title = (notice['title'] ?? 'Notice').toString();
                    final content = (notice['content'] ?? notice['description'] ?? '').toString();
                    final date =
                        (notice['created_at_human'] ?? notice['created_at'] ?? '').toString();

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, color: AppColors.primaryBlue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _openEditNoticeDialog(notice);
                                  } else if (value == 'delete') {
                                    _deleteNotice(notice);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 18, color: AppColors.errorRed),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: AppColors.errorRed)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(content, style: TextStyle(color: Colors.grey.shade700, height: 1.35)),
                          if (_deletingNoticeId == _toInt(notice['id'])) ...[
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(minHeight: 2),
                          ],
                          if (date.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              date,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _NoticeEditorDialog extends StatefulWidget {
  final String title;
  final String submitLabel;
  final String? initialTitle;
  final String? initialContent;

  const _NoticeEditorDialog({
    required this.title,
    required this.submitLabel,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<_NoticeEditorDialog> createState() => _NoticeEditorDialogState();
}

class _NoticeEditorDialogState extends State<_NoticeEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      setState(() {
        _error = 'Title and content are required.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    Get.back(result: {
      'title': title,
      'content': content,
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Get.back(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.submitLabel, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
