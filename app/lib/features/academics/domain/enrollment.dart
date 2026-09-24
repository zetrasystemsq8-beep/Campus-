class Enrollment {
  const Enrollment({
    required this.id,
    required this.courseId,
    required this.code,
    required this.title,
    required this.units,
    required this.level,
    required this.sessionLabel,
    required this.semester,
    this.score,
  });

  final String id;
  final String courseId;
  final String code;
  final String title;
  final int units;
  final int level;
  final String sessionLabel;
  final int semester;
  final double? score;

  /// Sortable key: later attempts compare greater.
  String get order => '$sessionLabel-$semester';

  factory Enrollment.fromMap(Map<String, dynamic> m) {
    final c = m['course'] as Map<String, dynamic>;
    return Enrollment(
      id: m['id'] as String,
      courseId: m['course_id'] as String,
      code: c['code'] as String,
      title: c['title'] as String,
      units: c['credit_units'] as int,
      level: c['level'] as int,
      sessionLabel: m['session_label'] as String,
      semester: m['semester_number'] as int,
      score: (m['score'] as num?)?.toDouble(),
    );
  }
}
