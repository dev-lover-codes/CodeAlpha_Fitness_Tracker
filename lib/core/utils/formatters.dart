import 'package:intl/intl.dart';

class Formatters {
  /// Formats duration in seconds to a human-readable string (e.g. 1h 24m or 45m 12s)
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '0s';
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }

  /// Formats DateTime to a human-readable date string (e.g. Wednesday, Jul 8)
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('EEE, MMM d, y').format(date);
  }

  /// Formats volume double to 1 decimal place if needed
  static String formatVolume(double volume) {
    if (volume == volume.toInt()) {
      return '${NumberFormat('#,###').format(volume.toInt())} kg';
    }
    return '${NumberFormat('#,##0.0').format(volume)} kg';
  }
}
