import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/models/option.dart';

/// Read access to the university structure (reference data).
class AcademicRepository {
  AcademicRepository(this._client);
  final SupabaseClient _client;

  Future<List<Option>> _options(String table, {String? filterColumn, String? filterValue}) =>
      guarded(() async {
        var query = _client.from(table).select('id, name');
        if (filterColumn != null && filterValue != null) {
          query = query.eq(filterColumn, filterValue);
        }
        final rows = await query.order('name');
        return [for (final r in rows) Option.fromMap(r)];
      });

  Future<List<Option>> universities() => _options('universities');
  Future<List<Option>> faculties(String universityId) =>
      _options('faculties', filterColumn: 'university_id', filterValue: universityId);
  Future<List<Option>> departments(String facultyId) =>
      _options('departments', filterColumn: 'faculty_id', filterValue: facultyId);
  Future<List<Option>> programmes(String departmentId) =>
      _options('programmes', filterColumn: 'department_id', filterValue: departmentId);
}
