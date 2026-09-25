import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/option_dropdown.dart';
import '../../academics/presentation/enrollment_providers.dart';
import '../../profile/presentation/profile_providers.dart';
import 'qa_providers.dart';

class AskQuestionScreen extends ConsumerStatefulWidget {
  const AskQuestionScreen({super.key});
  @override
  ConsumerState<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends ConsumerState<AskQuestionScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _body = TextEditingController();
  String? _courseId;
  bool _public = false;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(qaRepositoryProvider).ask(
            title: _title.text.trim(),
            body: _body.text.trim(),
            courseId: _courseId,
            isPublic: _public,
          );
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.md);
    final myEnrollments = ref.watch(enrollmentsProvider).valueOrNull ?? const [];
    final university = ref.watch(profileProvider).valueOrNull?.universityName ?? 'your university';

    return Scaffold(
      appBar: AppBar(title: const Text('Ask a question')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.length < 10) return 'Be more specific (at least 10 characters)';
                      return s.length > 200 ? 'Keep it under 200 characters' : null;
                    },
                  ),
                  gap,
                  TextFormField(
                    controller: _body,
                    maxLines: 6,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                      labelText: 'Details (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  gap,
                  if (myEnrollments.isNotEmpty)
                    OptionDropdown(
                      label: 'Related course (optional)',
                      options: AsyncValue.data([
                        for (final e in {for (final e in myEnrollments) e.courseId: e}.values)
                          Option(e.courseId, '${e.code} · ${e.title}'),
                      ]),
                      value: _courseId,
                      onRetry: () {},
                      onChanged: (v) => setState(() => _courseId = v),
                    ),
                ],
              ),
            ),
            gap,
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _public,
              title: const Text('Visible to all universities'),
              subtitle: Text(_public ? 'Any student can see this' : 'Only students at $university can see this'),
              onChanged: (v) => setState(() => _public = v),
            ),
            const SizedBox(height: Spacing.lg),
            LoadingButton(label: 'Post question', loading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
