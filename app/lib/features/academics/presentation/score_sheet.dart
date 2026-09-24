import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../domain/enrollment.dart';
import 'enrollment_providers.dart';

String formatScore(double s) => s == s.roundToDouble() ? s.toInt().toString() : s.toString();

Future<void> showScoreSheet(BuildContext context, Enrollment e) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ScoreSheet(enrollment: e),
    );

class ScoreSheet extends ConsumerStatefulWidget {
  const ScoreSheet({super.key, required this.enrollment});
  final Enrollment enrollment;
  @override
  ConsumerState<ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends ConsumerState<ScoreSheet> {
  late final TextEditingController _score;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = widget.enrollment.score;
    _score = TextEditingController(text: s == null ? '' : formatScore(s));
  }

  @override
  void dispose() {
    _score.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      ref.invalidate(enrollmentsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _save() {
    final raw = _score.text.trim();
    double? value;
    if (raw.isNotEmpty) {
      value = double.tryParse(raw);
      if (value == null || value < 0 || value > 100) {
        showMessage(context, 'Enter a score between 0 and 100');
        return;
      }
    }
    _run(() => ref.read(enrollmentRepositoryProvider).setScore(widget.enrollment.id, value));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.enrollment;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Spacing.lg, 0, Spacing.lg, MediaQuery.viewInsetsOf(context).bottom + Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('${e.code} · ${e.title}', style: Theme.of(context).textTheme.titleMedium),
          Text('${e.units} units · ${e.sessionLabel} semester ${e.semester}'),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _score,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Score (0-100)', helperText: 'Leave empty if not out yet'),
          ),
          const SizedBox(height: Spacing.md),
          LoadingButton(label: 'Save', loading: _loading, onPressed: _save),
          TextButton(
            onPressed: _loading
                ? null
                : () => _run(() => ref.read(enrollmentRepositoryProvider).remove(e.id)),
            child: Text('Remove course', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}
