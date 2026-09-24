import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/planner_models.dart';

class PlannerRepository {
  PlannerRepository(this._client);
  final SupabaseClient _client;

  /// Items due within the last 30 days or later.
  Future<List<PlannerItem>> items() => guarded(() async {
        final since = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
        final rows = await _client
            .from('planner_items')
            .select()
            .gte('due_at', since)
            .order('due_at')
            .limit(200);
        return [for (final r in rows) PlannerItem.fromMap(r)];
      });

  Future<void> addItem({
    required PlannerKind kind,
    required String title,
    required DateTime dueAt,
    String? location,
    String? notes,
  }) =>
      guarded(() async {
        await _client.from('planner_items').insert({
          'kind': kind.name,
          'title': title,
          'due_at': dueAt.toUtc().toIso8601String(),
          'location': location,
          'notes': notes,
        });
      });

  Future<void> setDone(String id, bool done) => guarded(() async {
        await _client.from('planner_items').update({'is_done': done}).eq('id', id);
      });

  Future<void> deleteItem(String id) => guarded(() async {
        await _client.from('planner_items').delete().eq('id', id);
      });

  Future<List<TimetableSlot>> slots() => guarded(() async {
        final rows = await _client
            .from('timetable_slots')
            .select()
            .order('weekday')
            .order('starts_at');
        return [for (final r in rows) TimetableSlot.fromMap(r)];
      });

  Future<void> addSlot({
    required String title,
    required int weekday,
    required String startsAt,
    required String endsAt,
    String? venue,
  }) =>
      guarded(() async {
        await _client.from('timetable_slots').insert({
          'title': title,
          'weekday': weekday,
          'starts_at': startsAt,
          'ends_at': endsAt,
          'venue': venue,
        });
      });

  Future<void> deleteSlot(String id) => guarded(() async {
        await _client.from('timetable_slots').delete().eq('id', id);
      });
}
