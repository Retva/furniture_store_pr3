/// Безопасное чтение полей из JSON: отсутствующее поле, null или значение
/// другого типа не роняют разбор, а заменяются значением по умолчанию.
class JsonRead {
  const JsonRead._();

  static int integer(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static String text(Object? value, [String fallback = '']) =>
      value is String ? value : (value == null ? fallback : value.toString());

  static List<int> ids(Object? value) {
    if (value is! List) return const [];
    return value.map((e) => integer(e, -1)).where((e) => e > 0).toList();
  }

  static DateTime? date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  static Map<String, dynamic>? map(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : null;
}
