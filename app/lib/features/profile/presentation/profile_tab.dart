import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../auth/presentation/auth_providers.dart';
import 'profile_providers.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign out')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final details = [
      if (p.programmeName != null) p.programmeName!,
      if (p.departmentName != null && p.programmeName == null) p.departmentName!,
      if (p.level != null) '${p.level} Level',
    ].join(' · ');

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Center(
            child: Semantics(
              label: 'Profile initials ${p.initials}',
              child: CircleAvatar(
                radius: 44,
                backgroundColor: scheme.primaryContainer,
                child: Text(p.initials,
                    style: text.headlineMedium?.copyWith(color: scheme.onPrimaryContainer)),
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Center(child: Text(p.displayName, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700))),
          Center(child: Text('@${p.username}', style: text.bodyMedium)),
          if (p.isVerified)
            const Padding(
              padding: EdgeInsets.only(top: Spacing.sm),
              child: Center(child: Chip(avatar: Icon(Icons.verified, size: 18), label: Text('Verified'))),
            ),
          const SizedBox(height: Spacing.md),
          if (p.universityName != null) Center(child: Text(p.universityName!, style: text.bodyLarge)),
          if (details.isNotEmpty) Center(child: Text(details, style: text.bodyMedium)),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            Text(p.bio!, style: text.bodyLarge),
          ],
          if (p.skills.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text('Skills', style: text.titleSmall),
            const SizedBox(height: Spacing.sm),
            Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [for (final s in p.skills) Chip(label: Text(s))]),
          ],
          if (p.interests.isNotEmpty) ...[
            const SizedBox(height: Spacing.lg),
            Text('Interests', style: text.titleSmall),
            const SizedBox(height: Spacing.sm),
            Wrap(spacing: Spacing.sm, runSpacing: Spacing.sm, children: [for (final s in p.interests) Chip(label: Text(s))]),
          ],
          const SizedBox(height: Spacing.lg),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit profile'),
            onTap: () => context.push('/profile/edit'),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Privacy'),
            onTap: () => context.push('/settings/privacy'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}
