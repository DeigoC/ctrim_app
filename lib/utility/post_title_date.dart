import 'package:intl/intl.dart';

/// English ordinal suffix for a day of month (e.g. 1st, 2nd, 3rd, 4th).
String dayWithOrdinal(int day) {
  if (day >= 11 && day <= 13) return '${day}th';
  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}

/// Date portion used in post titles, e.g. "26th Jul".
String formatPostTitleDate(DateTime date) =>
    '${dayWithOrdinal(date.day)} ${DateFormat('MMM').format(date)}';

/// Full post title with template name and date, e.g. "Sunday Service (26th Jul)".
String formatPostTitle(String templateTitle, DateTime date) =>
    '$templateTitle (${formatPostTitleDate(date)})';

/// Richer date label for bulk-create previews, e.g. "Sun 26th Jul".
String formatPostTitlePreviewDate(DateTime date) =>
    '${DateFormat('EEE').format(date)} ${formatPostTitleDate(date)}';
