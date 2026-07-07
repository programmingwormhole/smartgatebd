import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../controllers/amenity_controller.dart';
import '../../core/utils/date_formatter.dart';

class BookAmenityScreen extends StatefulWidget {
  final int amenityId;
  final String amenityName;

  const BookAmenityScreen({
    super.key,
    required this.amenityId,
    required this.amenityName,
  });

  @override
  State<BookAmenityScreen> createState() => _BookAmenityScreenState();
}

class _BookAmenityScreenState extends State<BookAmenityScreen> {
  DateTime _selectedDate = DateTime.now();
  int? _selectedSlotIndex;
  final _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchSlots();
    });
  }

  void _fetchSlots() {
    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    Get.find<AmenityController>().fetchSlots(widget.amenityId, dateStr);
    _selectedSlotIndex = null;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _fetchSlots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Book Amenity'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryNavy,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.white),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Booking ${widget.amenityName}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Select Date'),
                    const SizedBox(height: 8),
                    _buildPickerTile(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      Icons.calendar_today,
                      () => _selectDate(context),
                    ),
                    _buildSectionTitle('Available Slots'),
                    const SizedBox(height: 8),
                    GetBuilder<AmenityController>(
                      builder: (controller) {
                        if (controller.isLoading.value &&
                            controller.slots.isEmpty) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (controller.slots.isEmpty) {
                          return const Text('No slots available for this date');
                        }
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 3.5,
                              ),
                          itemCount: controller.slots.length,
                          itemBuilder: (context, index) {
                            final slot = controller.slots[index];
                            final isAvailable = slot['is_available'] ?? false;
                            final isSelected = _selectedSlotIndex == index;

                            return InkWell(
                              onTap: isAvailable
                                  ? () {
                                      setState(() {
                                        _selectedSlotIndex = index;
                                      });
                                    }
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryNavy
                                      : (isAvailable
                                            ? Colors.white
                                            : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryNavy
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${DateFormatter.formatTime(slot['from'])} to ${DateFormatter.formatTime(slot['to'])}',
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isAvailable
                                              ? Colors.black
                                              : Colors.grey),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Reason (Optional)'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Purpose of booking...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: GetBuilder<AmenityController>(
                builder: (provider) {
                  return ElevatedButton(
                    onPressed: provider.isLoading.value
                        ? null
                        : () async {
                            if (_selectedSlotIndex == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a slot'),
                                ),
                              );
                              return;
                            }

                            final slot = provider.slots[_selectedSlotIndex!];

                            final success = await provider.bookAmenity(
                              widget.amenityId,
                              {
                                'booking_date':
                                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                                'from_time': slot['from'],
                                'to_time': slot['to'],
                                'reason': _reasonController.text.trim(),
                              },
                            );

                            if (mounted) {
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking request submitted!'),
                                  ),
                                );
                                Get.back();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to submit booking'),
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Confirm Booking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  );
                },
              ),
            ),
            // AnimatedPadding(
            //   duration: const Duration(milliseconds: 220),
            //   curve: Curves.easeOut,
            //   padding: EdgeInsets.only(bottom: keyboardInset),
            //   child: SafeArea(
            //     top: false,
            //     child: ,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _buildPickerTile(String text, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryNavy),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
