import 'package:intl/intl.dart';

/// Human-friendly formatting helpers used across the app.
class Formatters {
  Formatters._();

  static String date(DateTime t) => DateFormat('d MMM yyyy', 'en_US').format(t);

  static String time(DateTime t) => DateFormat('HH:mm:ss', 'en_US').format(t);

  static String dateTime(DateTime t) =>
      DateFormat('d MMM yyyy · HH:mm:ss', 'en_US').format(t);

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
