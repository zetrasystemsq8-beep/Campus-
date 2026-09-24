import 'package:campus_app/features/academics/domain/enrollment.dart';
import 'package:campus_app/features/academics/domain/grading.dart';
import 'package:flutter_test/flutter_test.dart';

final scheme = GradingScheme(name: 'test', maxPoints: 5, bands: const [
  GradeBand(letter: 'F', min: 0, points: 0),
  GradeBand(letter: 'C', min: 50, points: 3),
  GradeBand(letter: 'B', min: 60, points: 4),
  GradeBand(letter: 'A', min: 70, points: 5),
]);

Enrollment enr(String course, String session, int sem, int units, double? score) => Enrollment(
      id: '$course$session$sem',
      courseId: course,
      code: course,
      title: course,
      units: units,
      level: 100,
      sessionLabel: session,
      semester: sem,
      score: score,
    );

void main() {
  test('bandFor picks the highest matching threshold', () {
    expect(scheme.bandFor(72).letter, 'A');
    expect(scheme.bandFor(60).letter, 'B');
    expect(scheme.bandFor(10).letter, 'F');
  });

  test('GPA is unit-weighted and ignores unscored courses', () {
    final gpa = computeGpa([
      enr('A1', '2025/2026', 1, 3, 75),
      enr('B1', '2025/2026', 1, 2, 55),
      enr('C1', '2025/2026', 1, 4, null),
    ], scheme)!;
    expect(gpa.value, closeTo(4.2, 0.001));
    expect(gpa.units, 5);
  });

  test('a passed retake replaces the earlier failure in CGPA', () {
    final s = summarise([
      enr('CSC101', '2024/2025', 1, 3, 30),
      enr('CSC101', '2025/2026', 1, 3, 65),
      enr('MTH101', '2024/2025', 1, 3, 70),
    ], scheme);
    expect(s.cgpa!.value, closeTo(4.5, 0.001));
    expect(s.carryovers, isEmpty);
  });

  test('a failed course with no retake is a carryover', () {
    final s = summarise([enr('CSC101', '2025/2026', 1, 3, 20)], scheme);
    expect(s.carryovers.map((e) => e.code), ['CSC101']);
    expect(s.cgpa!.value, 0);
  });

  test('no scores gives no GPA', () {
    expect(summarise([enr('CSC101', '2025/2026', 1, 3, null)], scheme).cgpa, isNull);
  });
}
