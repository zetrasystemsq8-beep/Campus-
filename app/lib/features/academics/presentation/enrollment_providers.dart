import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import '../data/enrollment_repository.dart';
import '../domain/enrollment.dart';
import '../domain/grading.dart';

final enrollmentRepositoryProvider =
    Provider((ref) => EnrollmentRepository(ref.watch(supabaseClientProvider)));

// Watching the user id makes per-user data reload on account switch.
final enrollmentsProvider = FutureProvider<List<Enrollment>>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(enrollmentRepositoryProvider).enrollments();
});

final gradingSchemeProvider = FutureProvider<GradingScheme>((ref) {
  final programmeId = ref.watch(profileProvider.select((p) => p.valueOrNull?.programmeId));
  return ref.watch(enrollmentRepositoryProvider).gradingScheme(programmeId);
});

final academicSummaryProvider = FutureProvider<AcademicSummary>((ref) async {
  final enrollments = await ref.watch(enrollmentsProvider.future);
  final scheme = await ref.watch(gradingSchemeProvider.future);
  return summarise(enrollments, scheme);
});
