import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import 'moderation_providers.dart';

const _reasons = [
  'Spam or scam',
  'Harassment or abuse',
  'Wrong or misleading',
  'Inappropriate content',
  'Other',
];

Future<void> showReportSheet(
  BuildContext context, {
  required String targetType,
  required String targetId,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ReportSheet(targetType: targetType, targetId: targetId),
    );

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.targetType, required this.targetId});
  final String targetType;
  final String targetId;
  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  String? _reason;
  bool _loading = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reason == null) {
      showMessage(context, 'Choose a reason');
      return;
    }
    setState(() => _loading = true);
    try {
      final text = _details.text.trim();
      await ref.read(moderationRepositoryProvider).report(
            targetType: widget.targetType,
            targetId: widget.targetId,
            reason: _reason!,
            details: text.isEmpty ? null : text,
          );
      if (!mounted) return;
      showMessage(context, 'Thanks. A moderator will review this.');
      Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Spacing.lg, 0, Spacing.lg, MediaQuery.viewInsetsOf(context).bottom + Spacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Report', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final r in _reasons)
                  ChoiceChip(
                    label: Text(r),
                    selected: _reason == r,
                    onSelected: (_) => setState(() => _reason = r),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            TextField(
              controller: _details,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(labelText: 'Details (optional)'),
            ),
            LoadingButton(label: 'Submit report', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
