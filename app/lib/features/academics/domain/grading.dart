import 'enrollment.dart';

class GradeBand {
  const GradeBand({required this.letter, required this.min, required this.points});
  final String letter;
  final double min;
  final double points;
  bool get isFail => points == 0;
}

/// A university-configurable grading scale (loaded from the database, never hard-coded).
class GradingScheme {
  GradingScheme({required this.name, required this.maxPoints, required List<GradeBand> bands})
      : bands = ([...bands]..sort((a, b) => b.min.compareTo(a.min)));

  final String name;
  final double maxPoints;
  final List<GradeBand> bands; // highest threshold first

  factory GradingScheme.fromMap(Map<String, dynamic> m) => GradingScheme(
        name: m['name'] as String,
        maxPoints: (m['max_points'] as num).toDouble(),
        bands: [
          for (final g in (m['grades'] as List))
            GradeBand(
              letter: g['letter'] as String,
              min: (g['min'] as num).toDouble(),
              points: (g['points'] as num).toDouble(),
            ),
        ],
      );

  GradeBand bandFor(double score) {
    for (final b in bands) {
      if (score >= b.min) return b;
    }
    return bands.last;
  }
}

class Gpa {
  const Gpa(this.value, this.units);
  final double value;
  final int units;
}

class SemesterResult {
  const SemesterResult(this.sessionLabel, this.semester, this.gpa);
  final String sessionLabel;
  final int semester;
  final Gpa gpa;
}

class AcademicSummary {
  const AcademicSummary({this.cgpa, required this.semesters, required this.carryovers});
  final Gpa? cgpa;
  final List<SemesterResult> semesters;
  final List<Enrollment> carryovers;
}

/// Unit-weighted GPA over scored enrollments; null when nothing is scored.
Gpa? computeGpa(Iterable<Enrollment> items, GradingScheme scheme) {
  var points = 0.0;
  var units = 0;
  for (final e in items) {
    final s = e.score;
    if (s == null || e.units == 0) continue;
    points += scheme.bandFor(s).points * e.units;
    units += e.units;
  }
  return units == 0 ? null : Gpa(points / units, units);
}

/// Semester GPAs count every attempt in that semester. CGPA and carryovers use only the
/// latest scored attempt of each course, so a passed retake replaces the earlier failure.
AcademicSummary summarise(List<Enrollment> all, GradingScheme scheme) {
  final scored = all.where((e) => e.score != null).toList();

  final latest = <String, Enrollment>{};
  for (final e in scored) {
    final cur = latest[e.courseId];
    if (cur == null || e.order.compareTo(cur.order) > 0) latest[e.courseId] = e;
  }

  final bySemester = <String, List<Enrollment>>{};
  for (final e in scored) {
    bySemester.putIfAbsent(e.order, () => []).add(e);
  }
  final semesters = <SemesterResult>[];
  for (final key in bySemester.keys.toList()..sort()) {
    final group = bySemester[key]!;
    final gpa = computeGpa(group, scheme);
    if (gpa != null) semesters.add(SemesterResult(group.first.sessionLabel, group.first.semester, gpa));
  }

  return AcademicSummary(
    cgpa: computeGpa(latest.values, scheme),
    semesters: semesters,
    carryovers: [
      for (final e in latest.values)
        if (scheme.bandFor(e.score!).isFail) e,
    ],
  );
}
