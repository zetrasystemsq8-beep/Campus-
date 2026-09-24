import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/state_views.dart';
import 'planner_providers.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = ref.watch(timetableProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly timetable')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/planner/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      body: slots.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(timetableProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_view_week,
              title: 'No classes yet',
              message: 'Add your weekly lectures and labs. Today\'s classes will show in your planner.',
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              for (var d = 1; d <= 7; d++) ...[
                if (list.any((s) => s.weekday == d)) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, Spacing.xs),
                    child: Text(weekdayNames[d - 1], style: Theme.of(context).textTheme.titleSmall),
                  ),
                  for (final s in list.where((s) => s.weekday == d))
                    ListTile(
                      title: Text(s.title),
                      subtitle: Text('${s.startsAt}-${s.endsAt}${s.venue == null ? '' : ' · ${s.venue}'}'),
                      trailing: IconButton(
                        tooltip: 'Delete ${s.title}',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await ref.read(plannerRepositoryProvider).deleteSlot(s.id);
                          } catch (e) {
                            if (context.mounted) showFailure(context, e);
                          }
                          ref.invalidate(timetableProvider);
                        },
                      ),
                    ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
