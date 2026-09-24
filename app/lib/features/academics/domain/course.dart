class Course {
  const Course({
    required this.id,
    required this.code,
    required this.title,
    required this.units,
    required this.level,
    this.departmentName,
  });

  final String id;
  final String code;
  final String title;
  final int units;
  final int level;
  final String? departmentName;

  factory Course.fromMap(Map<String, dynamic> m) => Course(
        id: m['id'] as String,
        code: m['code'] as String,
        title: m['title'] as String,
        units: m['credit_units'] as int,
        level: m['level'] as int,
        departmentName: (m['department'] as Map<String, dynamic>?)?['name'] as String?,
      );
}
