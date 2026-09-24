const levels = [100, 200, 300, 400, 500, 600];

List<int> graduationYears() {
  final now = DateTime.now().year;
  return [for (var y = now; y <= now + 7; y++) y];
}

/// Splits comma-separated text into unique, trimmed tags (max 30 tags, 30 chars each).
List<String> parseTags(String raw) {
  final seen = <String>{};
  return raw
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty && s.length <= 30)
      .where((s) => seen.add(s.toLowerCase()))
      .take(30)
      .toList();
}

/// Academic session labels like 2025/2026, newest first (sessions start around September).
List<String> sessionLabels() {
  final now = DateTime.now();
  final start = now.month >= 8 ? now.year : now.year - 1;
  return [for (var y = start + 1; y >= start - 5; y--) '$y/${y + 1}'];
}

String currentSessionLabel() {
  final now = DateTime.now();
  final start = now.month >= 8 ? now.year : now.year - 1;
  return '$start/${start + 1}';
}
