import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/navigation_controller.dart';
import 'controllers/visitor_controller.dart';
import 'controllers/complaint_controller.dart';
import 'controllers/emergency_controller.dart';
import 'controllers/family_controller.dart';
import 'controllers/daily_help_controller.dart';
import 'controllers/vehicle_controller.dart';
import 'controllers/amenity_controller.dart';
import 'controllers/bill_controller.dart';
import 'controllers/service_controller.dart';
import 'controllers/notice_controller.dart';
import 'controllers/pet_controller.dart';
import 'controllers/notification_controller.dart';
import 'controllers/guard_controller.dart';
import 'screens/splash_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force to portrait mode on mobile only
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Initialize Core Services
  Get.put(AuthController(), permanent: true);
  Get.put(NotificationController(), permanent: true);
  Get.lazyPut(() => NavigationController(), fenix: true);
  Get.lazyPut(() => VisitorController(), fenix: true);
  Get.lazyPut(() => ComplaintController(), fenix: true);
  Get.lazyPut(() => EmergencyController(), fenix: true);
  Get.lazyPut(() => FamilyController(), fenix: true);
  Get.lazyPut(() => DailyHelpController(), fenix: true);
  Get.lazyPut(() => VehicleController(), fenix: true);
  Get.lazyPut(() => AmenityController(), fenix: true);
  Get.lazyPut(() => BillController(), fenix: true);
  Get.lazyPut(() => ServiceController(), fenix: true);
  Get.lazyPut(() => NoticeController(), fenix: true);
  Get.lazyPut(() => PetController(), fenix: true);
  Get.lazyPut(() => GuardController(), fenix: true);

  runApp(const SocietyUserApp());
}

class SocietyUserApp extends StatelessWidget {
  const SocietyUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Dalan (দালান)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
