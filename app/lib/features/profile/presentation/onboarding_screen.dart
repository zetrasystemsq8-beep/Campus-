import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/option_dropdown.dart';
import '../../academics/presentation/academic_providers.dart';
import '../../auth/presentation/validators.dart';
import '../domain/academic_choices.dart';
import 'profile_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController();
  late final TextEditingController _fullName;
  String? _uni, _fac, _dept, _prog;
  int? _level, _grad;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fullName = TextEditingController(text: ref.read(profileProvider).valueOrNull?.fullName ?? '');
  }

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).update({
        'username': _username.text.trim().toLowerCase(),
        'full_name': _fullName.text.trim(),
        'university_id': _uni,
        'faculty_id': _fac,
        'department_id': _dept,
        'programme_id': _prog,
        'level': _level,
        'graduation_year': _grad,
        'onboarded_at': DateTime.now().toUtc().toIso8601String(),
      });
      ref.invalidate(profileProvider);
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.md);
    return AuthScaffold(
      title: 'Set up your profile',
      subtitle: 'Tell us where you study so we can show what matters to you.',
      children: [
        Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _fullName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: Validators.fullName,
              ),
              gap,
              TextFormField(
                controller: _username,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Username', prefixText: '@'),
                validator: Validators.username,
              ),
              gap,
              OptionDropdown(
                label: 'University',
                options: ref.watch(universitiesProvider),
                value: _uni,
                onRetry: () => ref.invalidate(universitiesProvider),
                onChanged: (v) => setState(() {
                  _uni = v;
                  _fac = _dept = _prog = null;
                }),
                validator: (v) => v == null ? 'Select your university' : null,
              ),
              if (_uni != null) ...[
                gap,
                OptionDropdown(
                  label: 'Faculty',
                  options: ref.watch(facultiesProvider(_uni!)),
                  value: _fac,
                  onRetry: () => ref.invalidate(facultiesProvider(_uni!)),
                  onChanged: (v) => setState(() {
                    _fac = v;
                    _dept = _prog = null;
                  }),
                  validator: (v) => v == null ? 'Select your faculty' : null,
                ),
              ],
              if (_fac != null) ...[
                gap,
                OptionDropdown(
                  label: 'Department',
                  options: ref.watch(departmentsProvider(_fac!)),
                  value: _dept,
                  onRetry: () => ref.invalidate(departmentsProvider(_fac!)),
                  onChanged: (v) => setState(() {
                    _dept = v;
                    _prog = null;
                  }),
                  validator: (v) => v == null ? 'Select your department' : null,
                ),
              ],
              if (_dept != null) ...[
                gap,
                OptionDropdown(
                  label: 'Programme (optional)',
                  options: ref.watch(programmesProvider(_dept!)),
                  value: _prog,
                  onRetry: () => ref.invalidate(programmesProvider(_dept!)),
                  onChanged: (v) => setState(() => _prog = v),
                ),
              ],
              gap,
              DropdownButtonFormField<int>(
                value: _level,
                decoration: const InputDecoration(labelText: 'Level'),
                items: [for (final l in levels) DropdownMenuItem(value: l, child: Text('$l Level'))],
                onChanged: (v) => setState(() => _level = v),
                validator: (v) => v == null ? 'Select your level' : null,
              ),
              gap,
              DropdownButtonFormField<int>(
                value: _grad,
                decoration: const InputDecoration(labelText: 'Expected graduation year'),
                items: [for (final y in graduationYears()) DropdownMenuItem(value: y, child: Text('$y'))],
                onChanged: (v) => setState(() => _grad = v),
                validator: (v) => v == null ? 'Select a year' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.lg),
        LoadingButton(label: 'Continue', loading: _loading, onPressed: _submit),
      ],
    );
  }
}
