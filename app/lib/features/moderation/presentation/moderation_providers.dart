import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/moderation_repository.dart';

final moderationRepositoryProvider =
    Provider((ref) => ModerationRepository(ref.watch(supabaseClientProvider)));
