import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/colors.dart';
import '../../../controllers/amenity_controller.dart';

class CreateEditAmenityScreen extends StatefulWidget {
  final Map<String, dynamic>? amenity;

  const CreateEditAmenityScreen({super.key, this.amenity});

  @override
  State<CreateEditAmenityScreen> createState() =>
      _CreateEditAmenityScreenState();
}

class _CreateEditAmenityScreenState extends State<CreateEditAmenityScreen> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController capacityController;
  late TextEditingController openTimeController;
  late TextEditingController closeTimeController;
  late TextEditingController slotDurationController;
  int _slotDurationMinutes = 60;

  final AmenityController _amenityController = Get.find<AmenityController>();
  bool isLoading = false;

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final raw = value.trim();
    final parts = raw.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _normalizeTime(String? value) {
    final parsed = _parseTime(value);
    if (parsed == null) return '';
    return _formatTimeOfDay(parsed);
  }

  String _formatDurationLabel(int totalMinutes) {
    final safeMinutes = totalMinutes < 0 ? 0 : totalMinutes;
    final hours = safeMinutes ~/ 60;
    final minutes = safeMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }

    if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }

    return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
  }

  Future<void> _pickDuration() async {
    Duration selectedDuration = Duration(minutes: _slotDurationMinutes);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: 340,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const Text(
                          'Select Slot Duration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final minutes = selectedDuration.inMinutes;
                            setState(() {
                              _slotDurationMinutes = minutes <= 0 ? 1 : minutes;
                              slotDurationController.text =
                                  _formatDurationLabel(_slotDurationMinutes);
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hm,
                      initialTimerDuration: selectedDuration,
                      onTimerDurationChanged: (duration) {
                        setModalState(() {
                          selectedDuration = duration;
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickTime(TextEditingController controller) async {
    final initialTime = _parseTime(controller.text) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select time',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppColors.primaryBlue),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked != null) {
      controller.text = _formatTimeOfDay(picked);
    }
  }

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.amenity?['name']);
    priceController = TextEditingController(
      text: widget.amenity?['price_per_day']?.toString(),
    );
    capacityController = TextEditingController(
      text: widget.amenity?['max_capacity']?.toString(),
    );
    openTimeController = TextEditingController(
      text: _normalizeTime(widget.amenity?['open_time']?.toString()),
    );
    closeTimeController = TextEditingController(
      text: _normalizeTime(widget.amenity?['close_time']?.toString()),
    );
    final initialSlotDuration =
        int.tryParse(
          widget.amenity?['slot_duration_minutes']?.toString() ?? '',
        ) ??
        60;
    _slotDurationMinutes = initialSlotDuration > 0 ? initialSlotDuration : 60;
    slotDurationController = TextEditingController(
      text: _formatDurationLabel(_slotDurationMinutes),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    priceController.dispose();
    capacityController.dispose();
    openTimeController.dispose();
    closeTimeController.dispose();
    slotDurationController.dispose();
    super.dispose();
  }

  Future<void> _saveAmenity() async {
    if (nameController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Name is required',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    final data = {
      'name': nameController.text,
      'price_per_day': double.tryParse(priceController.text) ?? 0,
      'max_capacity': int.tryParse(capacityController.text) ?? 1,
      'open_time': openTimeController.text.isEmpty
          ? null
          : openTimeController.text,
      'close_time': closeTimeController.text.isEmpty
          ? null
          : closeTimeController.text,
      'slot_duration_minutes': _slotDurationMinutes,
    };

    bool success;
    if (widget.amenity == null) {
      success = await _amenityController.createAmenity(data);
    } else {
      success = await _amenityController.updateAmenity(
        widget.amenity!['id'],
        data,
      );
    }

    setState(() {
      isLoading = false;
    });

    if (success) {
      Get.back();
      Get.snackbar(
        'Success',
        widget.amenity == null
            ? 'Amenity created successfully'
            : 'Amenity updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Error',
        'Failed to save amenity',
        backgroundColor: AppColors.errorRed,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.amenity == null ? 'Add Amenity' : 'Edit Amenity',
          style: const TextStyle(
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
            _buildTextField(
              'Amenity Name',
              nameController,
              'Enter amenity name',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Price per Slot',
              priceController,
              'Enter price',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Max Capacity',
              capacityController,
              'Enter capacity',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Open Time (HH:mm)',
              openTimeController,
              '08:00',
              readOnly: true,
              suffixIcon: const Icon(Icons.access_time),
              onTap: () => _pickTime(openTimeController),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Close Time (HH:mm)',
              closeTimeController,
              '22:00',
              readOnly: true,
              suffixIcon: const Icon(Icons.access_time),
              onTap: () => _pickTime(closeTimeController),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              'Slot Duration',
              slotDurationController,
              'Select duration',
              readOnly: true,
              suffixIcon: const Icon(Icons.timer_outlined),
              onTap: _pickDuration,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveAmenity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'Save Amenity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
