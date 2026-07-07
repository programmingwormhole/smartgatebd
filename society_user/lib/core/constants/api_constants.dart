class ApiConstants {
  // Change this to your local machine IP when testing on an actual device,
  // or use 10.0.2.2 for Android Emulator.
  // For iOS Simulator, localhost or 127.0.0.1 works.
  static const bool isDev = false;
  static const bool showLog = true;
  static const String appUrl = isDev
      ? 'http://127.0.0.1:8000'
      : 'https://smartgatebd.com';
  static const String baseUrl = '$appUrl/api/v1';
  static const String baseAppUrl = baseUrl;

  static const String loginConfig = '/auth/config';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';

  // Buildings & Config
  static const String buildings = '/buildings';

  // Residents
  static const String residents = '/residents';

  // Family & Daily Help
  static const String family = '/family';
  static const String dailyHelp = '/daily-help';

  // Visitor Management
  static const String visitors = '/visitors';
  static const String visitorGatepass = '/visitors/{id}/gatepass';

  // Bills & Payments
  static const String bills = '/bills';
  static const String payBill = '/bills/{id}/pay';

  // Amenities
  static const String amenities = '/amenities';
  static const String bookAmenity = '/amenities/{id}/book';
  static const String amenityBookings = '/amenities/bookings';

  // Services
  static const String services = '/services';
  static const String bookService = '/service/{id}/book';
  static const String serviceBookings = '/service-bookings';

  // Complaints
  static const String complaints = '/complaints';

  // Emergency Alerts
  static const String emergency = '/emergency';
  static const String emergencySos = '/emergency/sos';

  // FCM Tokens
  static const String fcmTokens = '/fcm-tokens';

  // Vehicles
  static const String vehicles = '/vehicles';

  // User
  static const String user = '/user';

  // Helper method to construct full image URL
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // If already a full URL, return as is
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }

    // If relative path, prepend baseAppUrl
    if (imagePath.startsWith('/')) {
      return '$baseAppUrl$imagePath';
    }

    // Otherwise, prepend baseAppUrl with /
    return '$baseAppUrl/$imagePath';
  }
}
