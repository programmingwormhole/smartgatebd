import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/member_service.dart';

class MemberController extends GetxController {
  final MemberService _memberService = MemberService();

  final RxList<dynamic> members = <dynamic>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    isLoading.value = true;
    update();
    try {
      members.value = await _memberService.getMembers();
    } catch (e) {
      debugPrint('Error fetching members: $e');
    } finally {
      isLoading.value = false;
      update();
    }
  }
}
