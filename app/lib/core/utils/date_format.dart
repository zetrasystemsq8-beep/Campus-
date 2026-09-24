const weekdayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatHm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

String formatDate(DateTime d) =>
    '${weekdayNames[d.weekday - 1].substring(0, 3)} ${d.day} ${_months[d.month - 1]}';

String formatDateTime(DateTime d) => '${formatDate(d)}, ${formatHm(d.hour, d.minute)}';

/// '09:00:00' -> '09:00'
String trimSeconds(String t) => t.length >= 5 ? t.substring(0, 5) : t;
