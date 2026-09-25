import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_providers.dart';
import '../../moderation/presentation/report_sheet.dart';
import '../data/qa_repository.dart';
import '../domain/qa_models.dart';
import 'qa_providers.dart';

class QuestionDetailScreen extends ConsumerStatefulWidget {
  const QuestionDetailScreen({super.key, required this.questionId});
  final String questionId;
  @override
  ConsumerState<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends ConsumerState<QuestionDetailScreen> {
  final _answer = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _answer.text.trim();
    if (text.isEmpty) return;
    setState(() => _posting = true);
    try {
      await ref.read(qaRepositoryProvider).postAnswer(widget.questionId, text);
      _answer.clear();
      ref.invalidate(questionDetailProvider(widget.questionId));
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _toggleSave(bool saved) async {
    try {
      await ref.read(qaRepositoryProvider).setSaved(widget.questionId, saved: !saved);
      ref.invalidate(questionDetailProvider(widget.questionId));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _toggleVote(String answerId, bool voted) async {
    try {
      await ref.read(qaRepositoryProvider).vote(answerId, on: !voted);
      ref.invalidate(questionDetailProvider(widget.questionId));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _accept(String answerId) async {
    try {
      await ref.read(qaRepositoryProvider).accept(answerId);
      ref.invalidate(questionDetailProvider(widget.questionId));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(questionDetailProvider(widget.questionId));
    final myId = ref.watch(currentUserIdProvider);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Question'),
        actions: [
          if (detail.hasValue)
            IconButton(
              tooltip: detail.value!.saved ? 'Unsave' : 'Save',
              icon: Icon(detail.value!.saved ? Icons.bookmark : Icons.bookmark_outline),
              onPressed: () => _toggleSave(detail.value!.saved),
            ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'report') {
                showReportSheet(context, targetType: 'question', targetId: widget.questionId);
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Report question'))],
          ),
        ],
      ),
      body: detail.when(
        skipLoadingOnReload: true,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(questionDetailProvider(widget.questionId)),
        ),
        data: (d) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  Text(d.question.title, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    '${d.question.authorName}'
                    '${d.question.courseCode == null ? '' : ' · ${d.question.courseCode}'}'
                    ' · ${timeAgo(d.question.createdAt)}',
                    style: text.bodySmall,
                  ),
                  if (d.question.body.isNotEmpty) ...[
                    const SizedBox(height: Spacing.md),
                    Text(d.question.body),
                  ],
                  const Divider(height: Spacing.xl),
                  Text('${d.answers.length} ${d.answers.length == 1 ? 'answer' : 'answers'}',
                      style: text.titleSmall),
                  const SizedBox(height: Spacing.sm),
                  if (d.answers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Spacing.lg),
                      child: Text('No answers yet. Be the first to help.'),
                    ),
                  for (final a in d.answers)
                    _AnswerTile(
                      answer: a,
                      isAccepted: a.id == d.question.acceptedAnswerId,
                      isQuestionOwner: d.question.authorId == myId,
                      isMine: a.authorId == myId,
                      onVote: () => _toggleVote(a.id, a.votedByMe),
                      onAccept: () => _accept(a.id),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.sm, Spacing.md, Spacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _answer,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(hintText: 'Write an answer'),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    _posting
                        ? const SizedBox(
                            height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : IconButton.filled(icon: const Icon(Icons.send), onPressed: _post),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.answer,
    required this.isAccepted,
    required this.isQuestionOwner,
    required this.isMine,
    required this.onVote,
    required this.onAccept,
  });

  final Answer answer;
  final bool isAccepted;
  final bool isQuestionOwner;
  final bool isMine;
  final VoidCallback onVote;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: isAccepted ? scheme.primaryContainer.withValues(alpha: 0.35) : null,
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAccepted)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.xs),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 18, color: scheme.primary),
                    const SizedBox(width: 4),
                    Text('Accepted answer', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            Text(answer.body),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Text('${answer.authorName} · ${timeAgo(answer.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                if (isQuestionOwner && !isAccepted)
                  TextButton(onPressed: onAccept, child: const Text('Accept')),
                if (!isMine)
                  IconButton(
                    tooltip: answer.votedByMe ? 'Remove helpful vote' : 'Mark as helpful',
                    icon: Icon(answer.votedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: answer.votedByMe ? scheme.primary : null, size: 20),
                    onPressed: onVote,
                  ),
                Text('${answer.helpfulCount}'),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'report') {
                      showReportSheet(context, targetType: 'answer', targetId: answer.id);
                    }
                  },
                  itemBuilder: (_) => const [PopupMenuItem(value: 'report', child: Text('Report answer'))],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
