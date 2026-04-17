import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static String dateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }

    try {
      final DateTime dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String yesNo(bool value) {
    return value ? 'Да' : 'Нет';
  }

  static String activeInactive(bool value) {
    return value ? 'Активен' : 'Не активен';
  }

  static String subscriptionStatus(bool value) {
    return value ? 'Активна' : 'Не активна';
  }

  static String fallback(String? value, {String empty = '—'}) {
    if (value == null || value.trim().isEmpty) {
      return empty;
    }
    return value;
  }
}
