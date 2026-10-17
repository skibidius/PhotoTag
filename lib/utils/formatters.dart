import 'package:intl/intl.dart';

/// Human-friendly formatting helpers used across the app.
class Formatters {
  Formatters._();

  static String date(DateTime t, String locale) =>
      DateFormat('d MMM yyyy', locale).format(t);

  static String time(DateTime t, String locale) =>
      DateFormat('HH:mm:ss', locale).format(t);

  static String dateTime(DateTime t, String locale) =>
      DateFormat('d MMM yyyy · HH:mm:ss', locale).format(t);

  static String monthYear(DateTime t, String locale) =>
      DateFormat('MMMM yyyy', locale).format(t);

  /// Rounds a heading to the nearest 16-wind cardinal direction.
  static String cardinal(double degrees) {
    const List<String> dirs = <String>[
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final int index = ((degrees % 360) / 22.5).round() % 16;
    return dirs[index];
  }
}
