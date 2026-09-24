import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/date_format.dart';
import '../academics/presentation/enrollment_providers.dart';
import '../academics/domain/grading.dart';
import '../planner/domain/planner_models.dart';
import '../planner/presentation/planner_providers.dart';
import '../profile/presentation/profile_providers.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(profileProvider).valueOrNull;
    if (p == null) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;

    final cgpa = ref.watch(academicSummaryProvider).valueOrNull?.cgpa;
    final scheme = ref.watch(gradingSchemeProvider).valueOrNull;
    final now = DateTime.now();
    final upcoming = (ref.watch(plannerItemsProvider).valueOrNull ?? const <PlannerItem>[])
        .where((i) => !i.isDone && !i.dueAt.isBefore(now))
        .take(3)
        .toList();
    final today = (ref.watch(timetableProvider).valueOrNull ?? const <TimetableSlot>[])
        .where((s) => s.weekday == now.weekday)
        .toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Semantics(
            header: true,
            child: Text('Hi, ${p.firstName}',
                style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
          ),
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
                  if (p.level != null)
                    Text('${p.level} Level${p.graduationYear != null ? ' · Graduating ${p.graduationYear}' : ''}'),
                ],
              ),
            ),
          ),
          if (cgpa != null)
            Card(
              child: ListTile(
                title: const Text('Your CGPA'),
                subtitle: Text('${cgpa.units} units counted'),
                trailing: Text(
                  '${cgpa.value.toStringAsFixed(2)}${scheme == null ? '' : ' / ${scheme.maxPoints.toStringAsFixed(1)}'}',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          if (today.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's classes", style: text.titleSmall),
                    const SizedBox(height: Spacing.sm),
                    for (final s in today)
                      Text('${s.startsAt}-${s.endsAt}  ${s.title}${s.venue == null ? '' : ' · ${s.venue}'}'),
                  ],
                ),
              ),
            ),
          if (upcoming.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coming up', style: text.titleSmall),
                    const SizedBox(height: Spacing.sm),
                    for (final i in upcoming)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('${i.title} · ${i.kind.label} · ${formatDateTime(i.dueAt)}'),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
