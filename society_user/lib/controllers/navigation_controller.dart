import 'package:get/get.dart';

class NavigationController extends GetxController {
  int _selectedIndex = 0;
  int _adminRequestsInitialTabIndex = 0;

  int get selectedIndex => _selectedIndex;
  int get adminRequestsInitialTabIndex => _adminRequestsInitialTabIndex;

  void setIndex(int index) {
    _selectedIndex = index;
    update();
  }

  void openAdminRequests({int initialTabIndex = 0}) {
    _adminRequestsInitialTabIndex = initialTabIndex;
    _selectedIndex = 3;
    update();
  }
}
