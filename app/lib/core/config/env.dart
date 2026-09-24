/// Build-time configuration supplied via --dart-define / --dart-define-from-file.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const authRedirectUrl = String.fromEnvironment('AUTH_REDIRECT_URL');

  static void assertConfigured() {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY. '
        'Run with --dart-define-from-file=.env (see .env.example).',
      );
    }
  }
}
