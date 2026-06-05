import 'package:intl/intl.dart';

class Formatters {
  /// ₺2.847.350,00 formatı
  static String currency(double value) {
    return NumberFormat.currency(
      locale: 'tr_TR',
      symbol: '₺',
      decimalDigits: 2,
    ).format(value);
  }

  /// Kompakt — ₺2,8 Mn / ₺324,5 B
  static String currencyCompact(double value) {
    final abs = value.abs();
    final sign = value < 0 ? '-' : '';
    final fmt = NumberFormat('0.#', 'tr_TR');

    if (abs >= 1000000) {
      return '$sign₺${fmt.format(abs / 1000000)} Mn';
    }
    if (abs >= 1000) {
      return '$sign₺${fmt.format(abs / 1000)} B';
    }
    return '$sign₺${NumberFormat('#', 'tr_TR').format(abs)}';
  }

  /// 14:32 / Dün 09:24 / 3 gün önce
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    if (diff == 0) return timeStr;
    if (diff == 1) return 'Dün $timeStr';
    if (diff < 7) return '$diff gün önce';
    return DateFormat('d MMM', 'tr_TR').format(date);
  }
}