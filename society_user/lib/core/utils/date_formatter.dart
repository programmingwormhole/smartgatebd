import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateTimeString).toLocal();
      return DateFormat('dd MMM yyyy \'at\' hh:mm a').format(dt);
    } catch (e) {
      return dateTimeString;
    }
  }

  static String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (e) {
      return dateString;
    }
  }

  static String formatTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return '';
    try {
      // Assuming timeString is HH:mm or HH:mm:ss
      if (timeString.contains(':')) {
        final parts = timeString.split(':');
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          int.parse(parts[0]),
          int.parse(parts[1]),
        );
        return DateFormat('hh:mm a').format(dt).replaceAll(' ', '');
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  static String formatTimeRange(String? range) {
    if (range == null || range.isEmpty) return 'N/A';
    if (!range.contains(' - ')) return range;
    try {
      final parts = range.split(' - ');
      return '${formatTime(parts[0])} to ${formatTime(parts[1])}';
    } catch (e) {
      return range;
    }
  }
}
