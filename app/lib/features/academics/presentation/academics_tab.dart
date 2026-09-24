import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/enrollment.dart';
import '../domain/grading.dart';
import 'enrollment_providers.dart';
import 'score_sheet.dart';

class AcademicsTab extends ConsumerWidget {
  const AcademicsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enrollments = ref.watch(enrollmentsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Academics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/academics/add-course'),
        icon: const Icon(Icons.add),
        label: const Text('Add course'),
      ),
      body: enrollments.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(enrollmentsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.school_outlined,
              title: 'No courses yet',
              message: 'Add the courses you are taking, then enter your scores to see your GPA and CGPA.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(enrollmentsProvider);
              await ref.read(enrollmentsProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, 96),
              children: [
                const _SummaryCard(),
                ..._groups(context, ref, items),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _groups(BuildContext context, WidgetRef ref, List<Enrollment> items) {
    final scheme = ref.watch(gradingSchemeProvider).valueOrNull;
    final out = <Widget>[];
    String? lastKey;
    for (final e in items) {
      if (e.order != lastKey) {
        lastKey = e.order;
        out.add(Padding(
          padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xs, left: Spacing.sm),
          child: Text('${e.sessionLabel} · Semester ${e.semester}',
              style: Theme.of(context).textTheme.titleSmall),
        ));
      }
      final s = e.score;
      out.add(ListTile(
        title: Text('${e.code} · ${e.title}', maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('${e.units} units · ${e.level} Level'),
        trailing: s == null
            ? Text('Add score', style: TextStyle(color: Theme.of(context).colorScheme.primary))
            : Text(scheme == null ? formatScore(s) : '${formatScore(s)} · ${scheme.bandFor(s).letter}',
                style: Theme.of(context).textTheme.titleSmall),
        onTap: () => showScoreSheet(context, e),
      ));
    }
    return out;
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(academicSummaryProvider);
    final scheme = ref.watch(gradingSchemeProvider).valueOrNull;
    final text = Theme.of(context).textTheme;
    final scheme0 = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: summary.when(
          skipLoadingOnReload: true,
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(gradingSchemeProvider)),
          data: (s) {
            final cgpa = s.cgpa;
            if (cgpa == null) {
              return const Text('Add your scores to see your GPA and CGPA.');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CGPA', style: text.labelLarge),
                Text(
                  '${cgpa.value.toStringAsFixed(2)}${scheme == null ? '' : ' / ${scheme.maxPoints.toStringAsFixed(1)}'}',
                  style: text.displaySmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text('${cgpa.units} units counted'),
                if (s.semesters.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      for (final r in s.semesters)
                        Chip(label: Text('${r.sessionLabel} S${r.semester}: ${r.gpa.value.toStringAsFixed(2)}')),
                    ],
                  ),
                ],
                if (s.carryovers.isNotEmpty) ...[
                  const SizedBox(height: Spacing.md),
                  Text('Carryovers: ${s.carryovers.map((e) => e.code).join(', ')}',
                      style: TextStyle(color: scheme0.error)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
