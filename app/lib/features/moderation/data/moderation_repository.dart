import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';

/// User-facing trust tools: reporting content and blocking users.
class ModerationRepository {
  ModerationRepository(this._client);
  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// [targetType] must match the `report_target` enum (user, question, answer, ...).
  Future<void> report({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) =>
      guarded(() async {
        try {
          await _client.from('reports').insert({
            'reporter_id': _uid,
            'target_type': targetType,
            'target_id': targetId,
            'reason': reason,
            'details': details,
          });
        } on PostgrestException catch (e) {
          if (e.code == '23505') throw const AppFailure('You have already reported this.');
          rethrow;
        }
      });

  Future<void> blockUser(String userId) => guarded(() async {
        try {
          await _client.from('user_blocks').insert({'blocker_id': _uid, 'blocked_id': userId});
        } on PostgrestException catch (e) {
          if (e.code == '23505') return; // already blocked
          rethrow;
        }
      });
}
