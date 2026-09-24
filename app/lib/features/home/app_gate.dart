import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/theme/app_theme.dart';
import '../profile/presentation/onboarding_screen.dart';
import '../profile/presentation/profile_providers.dart';
import 'main_shell.dart';

/// Decides between loading, error/retry, onboarding and the main app.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(profileProvider).when(
          skipLoadingOnReload: true,
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(AppFailure.from(e).message, textAlign: TextAlign.center),
                    const SizedBox(height: Spacing.md),
                    FilledButton(
                      onPressed: () => ref.invalidate(profileProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          data: (p) {
            if (p == null) return const SizedBox.shrink();
            return p.isOnboarded ? const MainShell() : const OnboardingScreen();
          },
        );
  }
}
