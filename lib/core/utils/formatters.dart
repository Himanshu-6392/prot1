import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static final _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final _inrFormatDecimal = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compact = NumberFormat.compact(locale: 'en_IN');

  /// ₹25,000
  static String formatINR(num amount) => _inrFormat.format(amount);

  /// ₹25,000.50
  static String formatINRDecimal(num amount) =>
      _inrFormatDecimal.format(amount);

  /// ₹25K or ₹2.5L or ₹1Cr
  static String formatINRCompact(num amount) => '₹${_compact.format(amount)}';

  /// 5.5% per month
  static String formatInterestRate(double rate) =>
      '${rate.toStringAsFixed(1)}% / month';

  /// 3 months or 1 year 3 months
  static String formatTenure(int months) {
    if (months < 12) return '$months month${months > 1 ? 's' : ''}';
    final y = months ~/ 12;
    final m = months % 12;
    if (m == 0) return '$y year${y > 1 ? 's' : ''}';
    return '$y yr ${m} mo';
  }

  /// LTV: 70%
  static String formatLTV(double ratio) => 'LTV: ${ratio.toStringAsFixed(0)}%';

  /// 29 Jun 2026
  static String formatDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  /// 3:45 PM
  static String formatTime(DateTime dt) => DateFormat('h:mm a').format(dt);

  /// 29 Jun
  static String formatShortDate(DateTime dt) => DateFormat('dd MMM').format(dt);

  /// Just now / 5 min ago / Yesterday / 28 Jun
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatShortDate(dt);
  }

  /// Phone: hide middle 5 digits
  static String maskPhone(String phone) {
    if (phone.length < 10) return phone;
    return '${phone.substring(0, 2)}*****${phone.substring(phone.length - 3)}';
  }

  /// Star rating: 4.5
  static String formatRating(double rating) => rating.toStringAsFixed(1);
}
