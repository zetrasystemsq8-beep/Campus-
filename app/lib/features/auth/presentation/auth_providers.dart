import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_service.dart';

final supabaseClientProvider = Provider<SupabaseClient>((_) => Supabase.instance.client);

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(supabaseClientProvider)));

final authStateProvider =
    StreamProvider<AuthState>((ref) => ref.watch(authServiceProvider).changes);

/// Current user id. Only changes on real sign-in/sign-out, not on token refresh.
final currentUserIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authServiceProvider);
  final streamed = ref.watch(authStateProvider.select((s) => s.valueOrNull?.session?.user.id));
  return streamed ?? auth.session?.user.id;
});
