import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/qa_repository.dart';
import '../domain/qa_models.dart';

final qaRepositoryProvider = Provider((ref) => QaRepository(ref.watch(supabaseClientProvider)));

final questionDetailProvider = FutureProvider.autoDispose.family<QuestionDetail, String>((ref, id) {
  ref.watch(currentUserIdProvider);
  return ref.watch(qaRepositoryProvider).detail(id);
});

final savedQuestionsProvider = FutureProvider.autoDispose<List<Question>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(qaRepositoryProvider).saved();
});
