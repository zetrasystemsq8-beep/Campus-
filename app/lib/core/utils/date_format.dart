const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String formatDate(DateTime d) =>
    '${weekdayNames[d.weekday - 1].substring(0, 3)} ${d.day} ${_months[d.month - 1]}';

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatHm(d.hour, d.minute)}';

/// '09:00:00' -> '09:00'
String trimSeconds(String t) => t.length >= 5 ? t.substring(0, 5) : t;

/// Compact relative time: "just now", "5m", "3h", "2d", else a date.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return formatDate(t);
}
