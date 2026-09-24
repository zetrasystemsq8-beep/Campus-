import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/option.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/academic_repository.dart';

final academicRepositoryProvider =
    Provider((ref) => AcademicRepository(ref.watch(supabaseClientProvider)));

// Reference data is cached for the session to save mobile data.
final universitiesProvider =
    FutureProvider<List<Option>>((ref) => ref.watch(academicRepositoryProvider).universities());

final facultiesProvider = FutureProvider.family<List<Option>, String>(
    (ref, universityId) => ref.watch(academicRepositoryProvider).faculties(universityId));

final departmentsProvider = FutureProvider.family<List<Option>, String>(
    (ref, facultyId) => ref.watch(academicRepositoryProvider).departments(facultyId));

final programmesProvider = FutureProvider.family<List<Option>, String>(
    (ref, departmentId) => ref.watch(academicRepositoryProvider).programmes(departmentId));
