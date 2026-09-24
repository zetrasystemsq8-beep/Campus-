import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile.dart';

final profileRepositoryProvider =
    Provider((ref) => ProfileRepository(ref.watch(supabaseClientProvider)));

final profileProvider = FutureProvider<Profile?>((ref) async {
  final uid = ref.watch(currentUserIdProvider);
  if (uid == null) return null;
  return ref.watch(profileRepositoryProvider).fetchMine();
});
