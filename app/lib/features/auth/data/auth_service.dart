import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/errors/app_failure.dart';

/// All authentication calls live here; UI never touches Supabase directly.
class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  Stream<AuthState> get changes => _client.auth.onAuthStateChange;
  Session? get session => _client.auth.currentSession;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run().timeout(const Duration(seconds: 20));
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> signIn({required String email, required String password}) =>
      _guard(() => _client.auth.signInWithPassword(email: email.trim(), password: password));

  /// Returns true when a session was created immediately (email confirmation disabled).
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) =>
      _guard(() async {
        final res = await _client.auth.signUp(
          email: email.trim(),
          password: password,
          data: {'full_name': fullName.trim()},
          emailRedirectTo: Env.authRedirectUrl.isEmpty ? null : Env.authRedirectUrl,
        );
        return res.session != null;
      });

  Future<void> sendPasswordReset(String email) => _guard(
        () => _client.auth.resetPasswordForEmail(
          email.trim(),
          redirectTo: Env.authRedirectUrl.isEmpty ? null : Env.authRedirectUrl,
        ),
      );

  Future<void> signOut() => _guard(_client.auth.signOut);
}
