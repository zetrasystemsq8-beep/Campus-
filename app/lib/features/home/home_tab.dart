import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../profile/presentation/profile_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Semantics(header: true, child: Text('Hi, ${p.firstName}', style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700))),
          const SizedBox(height: Spacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.universityName ?? '', style: text.titleMedium),
                  const SizedBox(height: Spacing.xs),
                  if (p.facultyName != null) Text(p.facultyName!),
                  if (p.departmentName != null) Text(p.departmentName!),
                  if (p.level != null) Text('${p.level} Level'
                      '${p.graduationYear != null ? ' · Graduating ${p.graduationYear}' : ''}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
