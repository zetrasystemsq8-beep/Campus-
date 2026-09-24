import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/planner_repository.dart';
import '../domain/planner_models.dart';

final plannerRepositoryProvider =
    Provider((ref) => PlannerRepository(ref.watch(supabaseClientProvider)));

final plannerItemsProvider = FutureProvider<List<PlannerItem>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(plannerRepositoryProvider).items();
});

final timetableProvider = FutureProvider<List<TimetableSlot>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(plannerRepositoryProvider).slots();
});
