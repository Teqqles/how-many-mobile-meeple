/// Human-friendly formatting of play dates, shared by the play log UI.
class PlayDateFormat {
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  /// Today / Yesterday / "5 Jan 2026".
  static String absolute(DateTime date) {
    switch (_dayDelta(date)) {
      case 0:
        return 'Today';
      case 1:
        return 'Yesterday';
      default:
        return _full(date);
    }
  }

  /// Like [absolute] but uses "N days ago" for the last week.
  static String relative(DateTime date) {
    final delta = _dayDelta(date);
    if (delta == 0) return 'Today';
    if (delta == 1) return 'Yesterday';
    if (delta < 7) return '$delta days ago';
    return _full(date);
  }

  /// Whole calendar months between [date] and now.
  static int monthsSince(DateTime date) {
    final now = DateTime.now();
    return (now.year - date.year) * 12 + (now.month - date.month);
  }

  static int _dayDelta(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(date.year, date.month, date.day);
    return today.difference(that).inDays;
  }

  static String _full(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';
}
