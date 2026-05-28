import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  // Pakistan Standard Time offset
  static const _pktOffset = Duration(hours: 5);

  /// Format date as "25 Jan 2025"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date as "25 Jan"
  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  /// Format as "25 Jan 2025, 10:30 AM"
  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(date);
  }

  /// Format as "10:30 AM"
  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  /// Relative time: "Just now", "5 min ago", "2 hours ago", "Yesterday"
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(date);
  }

  /// Parse ISO date string
  static DateTime parse(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Get greeting based on time of day (PKT)
  static String getGreeting() {
    final hour = DateTime.now().toUtc().add(_pktOffset).hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Days overdue (negative if not yet due)
  static int daysOverdue(DateTime dueDate) {
    return DateTime.now().difference(dueDate).inDays;
  }
}
