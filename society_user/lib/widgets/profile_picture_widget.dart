import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/colors.dart';
import '../core/constants/api_constants.dart';
import '../controllers/auth_controller.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String? profilePictureUrl;
  final String userName;
  final bool editable;
  final VoidCallback? onPictureUpdated;
  final double radius;

  const ProfilePictureWidget({
    super.key,
    this.profilePictureUrl,
    required this.userName,
    this.editable = false,
    this.onPictureUpdated,
    this.radius = 50,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  late ImagePicker _imagePicker;
  bool _isUploading = false;
  final AuthController _authController = Get.find<AuthController>();

  @override
  void initState() {
    super.initState();
    _imagePicker = ImagePicker();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    return name.split(' ').map((e) => e[0]).join('').toUpperCase().substring(0, 1);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        await _uploadProfilePicture(File(pickedFile.path));
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() => _isUploading = true);

    try {
      final success = await _authController.uploadProfilePicture(imageFile);
      if (success) {
        Get.snackbar(
          'Success',
          'Profile picture updated successfully',
          backgroundColor: Colors.green.withOpacity(0.1),
          colorText: Colors.green,
        );
        widget.onPictureUpdated?.call();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to upload profile picture: $e',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProfilePicture() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Profile Picture'),
        content: const Text('Are you sure you want to remove your profile picture?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Get.back();
              setState(() => _isUploading = true);
              try {
                final success = await _authController.deleteProfilePicture();
                if (success) {
                  Get.snackbar(
                    'Success',
                    'Profile picture removed',
                    backgroundColor: Colors.green.withOpacity(0.1),
                    colorText: Colors.green,
                  );
                  widget.onPictureUpdated?.call();
                }
              } finally {
                setState(() => _isUploading = false);
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(widget.userName);
    final fullImageUrl = ApiConstants.getImageUrl(widget.profilePictureUrl);

    return Stack(
      children: [
        CircleAvatar(
          radius: widget.radius,
          backgroundColor: AppColors.lightBlue.withOpacity(0.5),
          backgroundImage: fullImageUrl.isNotEmpty
              ? NetworkImage(fullImageUrl)
              : null,
          child: fullImageUrl.isEmpty
              ? Text(
                  initials,
                  style: TextStyle(
                    fontSize: widget.radius * 0.8,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                )
              : null,
        ),
        if (widget.editable)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onLongPress: fullImageUrl.isNotEmpty
                  ? _deleteProfilePicture
                  : null,
              onTap: _isUploading ? null : _pickImage,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.primaryNavy,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(
                        fullImageUrl.isNotEmpty
                            ? Icons.edit
                            : Icons.add_a_photo,
                        color: Colors.white,
                        size: 16,
                      ),
              ),
            ),
          ),
      ],
    );
  }
}
