import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/profile.dart';

class ProfileRepository {
  ProfileRepository(this._client);
  final SupabaseClient _client;

  static const _select = '*, university:universities(name), faculty:faculties(name), '
      'department:departments(name), programme:programmes(name)';

  String get _uid => _client.auth.currentUser!.id;

  Future<Profile> fetchMine() => guarded(() async {
        final row = await _client.from('profiles').select(_select).eq('id', _uid).single();
        return Profile.fromMap(row);
      });

  /// Only columns granted to `authenticated` in the database can be changed here.
  Future<void> update(Map<String, dynamic> changes) => guarded(() async {
        await _client.from('profiles').update(changes).eq('id', _uid);
      });
}
