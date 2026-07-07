import 'package:flutter/material.dart';
import '../core/constants/colors.dart';
import '../core/constants/api_constants.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? profilePictureUrl;
  final String userName;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;

  const UserAvatarWidget({
    super.key,
    this.profilePictureUrl,
    required this.userName,
    this.radius = 20,
    this.backgroundColor,
    this.textColor,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    return name.split(' ').map((e) => e[0]).join('').toUpperCase().substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(userName);
    final fullImageUrl = ApiConstants.getImageUrl(profilePictureUrl);
    final bgColor = backgroundColor ?? AppColors.lightBlue.withOpacity(0.5);
    final txtColor = textColor ?? AppColors.primaryNavy;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: fullImageUrl.isNotEmpty
          ? NetworkImage(fullImageUrl)
          : null,
      child: fullImageUrl.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.bold,
                color: txtColor,
              ),
            )
          : null,
    );
  }
}
