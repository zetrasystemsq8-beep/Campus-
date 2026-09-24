import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../domain/planner_models.dart';
import 'planner_providers.dart';

class PlannerTab extends ConsumerWidget {
  const PlannerTab({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(plannerItemsProvider);
    ref.invalidate(timetableProvider);
    await ref.read(plannerItemsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(plannerItemsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planner'),
        actions: [
          IconButton(
            tooltip: 'Weekly timetable',
            icon: const Icon(Icons.calendar_view_week),
            onPressed: () => context.push('/planner/timetable'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/planner/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: items.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(plannerItemsProvider)),
        data: (list) {
          final now = DateTime.now();
          final overdue = list.where((i) => !i.isDone && i.dueAt.isBefore(now)).toList();
          final upcoming = list.where((i) => !i.isDone && !i.dueAt.isBefore(now)).toList();
          final done = list.where((i) => i.isDone).toList().reversed.toList();
          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                const _TodayClasses(),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(Spacing.xl),
                    child: EmptyState(
                      icon: Icons.event_note_outlined,
                      title: 'Nothing planned',
                      message: 'Add assignments, tests, exams and study sessions so nothing slips.',
                    ),
                  ),
                _Section(title: 'Overdue', items: overdue, highlight: true),
                _Section(title: 'Upcoming', items: upcoming),
                _Section(title: 'Completed', items: done),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodayClasses extends ConsumerWidget {
  const _TodayClasses();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(timetableProvider).valueOrNull ?? const <TimetableSlot>[];
    final today = slots.where((s) => s.weekday == DateTime.now().weekday).toList();
    if (today.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(Spacing.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's classes", style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            for (final s in today)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text('${s.startsAt}-${s.endsAt}  ${s.title}${s.venue == null ? '' : ' · ${s.venue}'}'),
              ),
          ],
        ),
      ),
    );
  }
}

class _Section extends ConsumerWidget {
  const _Section({required this.title, required this.items, this.highlight = false});
  final String title;
  final List<PlannerItem> items;
  final bool highlight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final repo = ref.read(plannerRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.xs),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: highlight ? scheme.error : null)),
        ),
        for (final i in items)
          Dismissible(
            key: ValueKey(i.id),
            direction: DismissDirection.endToStart,
            background: Container(
              color: scheme.errorContainer,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: Spacing.lg),
              child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
            ),
            onDismissed: (_) async {
              try {
                await repo.deleteItem(i.id);
              } catch (e) {
                if (context.mounted) showFailure(context, e);
              }
              ref.invalidate(plannerItemsProvider);
            },
            child: CheckboxListTile(
              value: i.isDone,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(i.title,
                  style: i.isDone ? const TextStyle(decoration: TextDecoration.lineThrough) : null),
              subtitle: Text(
                  '${i.kind.label} · ${formatDateTime(i.dueAt)}${i.location == null ? '' : ' · ${i.location}'}'),
              onChanged: (v) async {
                try {
                  await repo.setDone(i.id, v ?? false);
                } catch (e) {
                  if (context.mounted) showFailure(context, e);
                }
                ref.invalidate(plannerItemsProvider);
              },
            ),
          ),
      ],
    );
  }
}
