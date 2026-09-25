import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/academics/presentation/add_course_screen.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/app_gate.dart';
import '../../features/planner/presentation/add_plan_screen.dart';
import '../../features/planner/presentation/timetable_screen.dart';
import '../../features/qa/presentation/ask_question_screen.dart';
import '../../features/qa/presentation/question_detail_screen.dart';
import '../../features/qa/presentation/saved_questions_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

const _publicPaths = {'/login', '/register', '/forgot-password'};

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authServiceProvider);
  final refresh = _AuthRefresh(auth.changes);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = auth.session != null;
      final isPublic = _publicPaths.contains(state.uri.path);
      if (!signedIn && !isPublic) return '/login';
      if (signedIn && isPublic) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const AppGate()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/settings/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/academics/add-course', builder: (_, __) => const AddCourseScreen()),
      GoRoute(path: '/planner/add', builder: (_, __) => const AddPlanScreen()),
      GoRoute(path: '/planner/timetable', builder: (_, __) => const TimetableScreen()),
      GoRoute(path: '/qa/ask', builder: (_, __) => const AskQuestionScreen()),
      GoRoute(path: '/qa/saved', builder: (_, __) => const SavedQuestionsScreen()),
      GoRoute(
        path: '/qa/:id',
        builder: (_, state) => QuestionDetailScreen(questionId: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
