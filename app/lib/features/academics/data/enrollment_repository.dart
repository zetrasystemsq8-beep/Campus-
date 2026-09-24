import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/course.dart';
import '../domain/enrollment.dart';
import '../domain/grading.dart';

class EnrollmentRepository {
  EnrollmentRepository(this._client);
  final SupabaseClient _client;

  static const _enrollSelect = '*, course:courses(code, title, credit_units, level)';

  Future<List<Course>> searchCourses({String? departmentId, String query = ''}) =>
      guarded(() async {
        var q = _client
            .from('courses')
            .select('id, code, title, credit_units, level, department:departments(name)');
        if (departmentId != null) q = q.eq('department_id', departmentId);
        // Strip characters that would break PostgREST filter syntax.
        final term = query.replaceAll(RegExp(r'[,()%*\\]'), ' ').trim();
        if (term.isNotEmpty) q = q.or('code.ilike.%$term%,title.ilike.%$term%');
        final rows = await q.order('code').limit(40);
        return [for (final r in rows) Course.fromMap(r)];
      });

  Future<List<Enrollment>> enrollments() => guarded(() async {
        final rows = await _client
            .from('enrollments')
            .select(_enrollSelect)
            .order('session_label', ascending: false)
            .order('semester_number', ascending: false);
        return [for (final r in rows) Enrollment.fromMap(r)];
      });

  Future<void> enroll({
    required String courseId,
    required String sessionLabel,
    required int semester,
  }) =>
      guarded(() async {
        await _client.from('enrollments').insert({
          'course_id': courseId,
          'session_label': sessionLabel,
          'semester_number': semester,
        });
      });

  Future<void> setScore(String id, double? score) => guarded(() async {
        await _client.from('enrollments').update({'score': score}).eq('id', id);
      });

  Future<void> remove(String id) => guarded(() async {
        await _client.from('enrollments').delete().eq('id', id);
      });

  /// Programme scheme if set, otherwise the platform default scheme.
  Future<GradingScheme> gradingScheme(String? programmeId) => guarded(() async {
        if (programmeId != null) {
          final row = await _client
              .from('programmes')
              .select('grading_scheme:grading_schemes(*)')
              .eq('id', programmeId)
              .maybeSingle();
          final m = row?['grading_scheme'] as Map<String, dynamic>?;
          if (m != null) return GradingScheme.fromMap(m);
        }
        final row = await _client
            .from('grading_schemes')
            .select()
            .eq('is_default', true)
            .isFilter('university_id', null)
            .limit(1)
            .maybeSingle();
        if (row == null) throw const AppFailure('No grading scale is configured yet.');
        return GradingScheme.fromMap(row);
      });
}
