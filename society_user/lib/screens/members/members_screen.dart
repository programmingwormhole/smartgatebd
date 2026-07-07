import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_constants.dart';
import '../../controllers/member_controller.dart';
import '../../core/widgets/shimmer_loader.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryNavy,
          tabs: const [
            Tab(text: 'Member'),
            Tab(text: 'Admin'),
            Tab(text: 'Committee'),
          ],
        ),
      ),
      body: GetBuilder<MemberController>(
        init: MemberController(),
        builder: (controller) {
          if (controller.isLoading.value && controller.members.isEmpty) {
            return const ShimmerList();
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildMembersList(controller.members, 'Member'),
              _buildMembersList(controller.members, 'Admin'),
              _buildMembersList(controller.members, 'Committee'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMembersList(List<dynamic> allMembers, String type) {
    final filteredMembers = allMembers.where((m) {
      final role = m['role']?.toString().toLowerCase() ?? '';
      if (type == 'Admin') return role == 'admin';
      if (type == 'Committee') return role == 'committee';
      return role == 'resident' || role == 'member';
    }).toList();

    if (filteredMembers.isEmpty) {
      return Center(
        child: Text(
          'No $type found',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredMembers.length,
      itemBuilder: (context, index) {
        final member = filteredMembers[index];
        final name = member['user']?['name'] ?? 'Unknown Member';
        final phone = member['user']?['phone'] ?? 'N/A';
        final profilePicture = member['user']?['profile_picture'];
        final flatNumber = member['flat']?['flat_number'] ?? 'N/A';
        final blockName = member['flat']?['floor']?['block']?['name'] ?? 'N/A';
        final buildingName =
            member['flat']?['floor']?['block']?['building']?['name'] ??
            'Not assigned';
        final initials = name.isNotEmpty
            ? name
                  .split(' ')
                  .map((e) => e[0])
                  .join('')
                  .toUpperCase()
                  .substring(0, 1)
            : 'U';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => _showMemberDetails({
              'name': name,
              'phone': phone,
              'flat': flatNumber,
              'block': blockName,
              'building': buildingName,
              'profile_picture': profilePicture,
            }),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                    backgroundImage:
                        profilePicture != null &&
                            profilePicture.toString().isNotEmpty
                        ? NetworkImage(
                            ApiConstants.getImageUrl(profilePicture.toString()),
                          )
                        : null,
                    child:
                        profilePicture == null ||
                            profilePicture.toString().isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Flat: $flatNumber | Block: $blockName',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showMemberDetails(Map<String, dynamic> member) {
    final name = member['name'] ?? 'Unknown';
    final profilePicture = member['profile_picture'];
    final initials = name.isNotEmpty
        ? name
              .split(' ')
              .map((e) => e[0])
              .join('')
              .toUpperCase()
              .substring(0, 1)
        : 'U';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                    backgroundImage:
                        profilePicture != null &&
                            profilePicture.toString().isNotEmpty
                        ? NetworkImage(
                            ApiConstants.getImageUrl(profilePicture.toString()),
                          )
                        : null,
                    child:
                        profilePicture == null ||
                            profilePicture.toString().isEmpty
                        ? Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    member['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    member['phone']!,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.business_outlined,
                        '${member['building']}\nsociety',
                      ),
                      _buildVerticalDivider(),
                      _buildInfoItem(
                        Icons.home_outlined,
                        'Flat no:\n${member['flat']}',
                      ),
                      _buildVerticalDivider(),
                      _buildInfoItem(
                        Icons.domain_outlined,
                        'Block no:\n${member['block']}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _makeCall(member['phone']?.toString()),
                          icon: const Icon(
                            Icons.call,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Call',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      // const SizedBox(width: 12),
                      // Expanded(
                      //   child: ElevatedButton.icon(
                      //     onPressed: () {},
                      //     icon: const Icon(
                      //       Icons.chat_bubble_outline,
                      //       color: Colors.white,
                      //       size: 20,
                      //     ),
                      //     label: const Text(
                      //       'Chat',
                      //       style: TextStyle(color: Colors.white),
                      //     ),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor:
                      //           Colors.green, // Vibrant green from screenshot
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(10),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _makeCall(String? phone) async {
    final trimmed = (phone ?? '').trim();
    if (trimmed.isEmpty || trimmed == 'N/A') {
      Get.snackbar(
        'Unavailable',
        'Phone number not found',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final dialable = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri(scheme: 'tel', path: dialable);

    if (!await launchUrl(uri)) {
      Get.snackbar(
        'Error',
        'Unable to open dialer',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primaryNavy, size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }
}
