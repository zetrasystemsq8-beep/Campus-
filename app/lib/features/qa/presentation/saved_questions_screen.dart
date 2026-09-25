import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/widgets/state_views.dart';
import 'qa_providers.dart';

class SavedQuestionsScreen extends ConsumerWidget {
  const SavedQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedQuestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved questions')),
      body: saved.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(error: e, onRetry: () => ref.invalidate(savedQuestionsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_outline,
              title: 'Nothing saved',
              message: 'Save questions to find them again quickly.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final q = items[i];
              return ListTile(
                title: Text(q.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                subtitle: Text('${q.authorName} · ${timeAgo(q.createdAt)}'),
                onTap: () => context.push('/qa/${q.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
