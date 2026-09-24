import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../../auth/presentation/validators.dart';
import '../domain/academic_choices.dart';
import 'profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _bio;
  late final TextEditingController _skills;
  late final TextEditingController _interests;
  int? _level, _grad;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull!;
    _name = TextEditingController(text: p.fullName ?? '');
    _bio = TextEditingController(text: p.bio ?? '');
    _skills = TextEditingController(text: p.skills.join(', '));
    _interests = TextEditingController(text: p.interests.join(', '));
    _level = p.level;
    _grad = p.graduationYear;
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _skills.dispose();
    _interests.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).update({
        'full_name': _name.text.trim(),
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'level': _level,
        'graduation_year': _grad,
        'skills': parseTags(_skills.text),
        'interests': parseTags(_interests.text),
      });
      ref.invalidate(profileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.md);
    final years = {...graduationYears(), if (_grad != null) _grad!}.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Full name'),
                    validator: Validators.fullName,
                  ),
                  gap,
                  TextFormField(
                    controller: _bio,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Bio'),
                  ),
                  gap,
                  DropdownButtonFormField<int>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: [for (final l in levels) DropdownMenuItem(value: l, child: Text('$l Level'))],
                    onChanged: (v) => setState(() => _level = v),
                  ),
                  gap,
                  DropdownButtonFormField<int>(
                    value: _grad,
                    decoration: const InputDecoration(labelText: 'Expected graduation year'),
                    items: [for (final y in years) DropdownMenuItem(value: y, child: Text('$y'))],
                    onChanged: (v) => setState(() => _grad = v),
                  ),
                  gap,
                  TextFormField(
                    controller: _skills,
                    decoration: const InputDecoration(
                      labelText: 'Skills',
                      helperText: 'Separate with commas, e.g. Python, Design',
                    ),
                  ),
                  gap,
                  TextFormField(
                    controller: _interests,
                    decoration: const InputDecoration(
                      labelText: 'Interests',
                      helperText: 'Separate with commas',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.lg),
            LoadingButton(label: 'Save', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
