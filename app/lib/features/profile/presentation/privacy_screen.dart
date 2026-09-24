import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../domain/profile.dart';
import 'profile_providers.dart';

const _visibilityLabels = {
  VisibilityLevel.public: 'Everyone',
  VisibilityLevel.university: 'Students at my university',
  VisibilityLevel.private: 'Only me',
};

const _messageLabels = {
  MessagePermission.everyone: 'Everyone',
  MessagePermission.university: 'Students at my university',
  MessagePermission.nobody: 'No one',
};

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});
  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  late VisibilityLevel _profile, _contact, _activity;
  late MessagePermission _message;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull!;
    _profile = p.profileVisibility;
    _contact = p.contactVisibility;
    _activity = p.activityVisibility;
    _message = p.messagePermission;
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(profileRepositoryProvider).update({
        'profile_visibility': _profile.name,
        'contact_visibility': _contact.name,
        'activity_visibility': _activity.name,
        'message_permission': _message.name,
      });
      ref.invalidate(profileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showFailure(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _visibility(String label, VisibilityLevel value, ValueChanged<VisibilityLevel> set) =>
      _EnumDropdown<VisibilityLevel>(
        label: label,
        value: value,
        labels: _visibilityLabels,
        onChanged: (v) => setState(() => set(v)),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: Spacing.md);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _visibility('Who can see my profile', _profile, (v) => _profile = v),
            gap,
            _visibility('Who can see my contact details', _contact, (v) => _contact = v),
            gap,
            _visibility('Who can see my activity', _activity, (v) => _activity = v),
            gap,
            _EnumDropdown<MessagePermission>(
              label: 'Who can message me',
              value: _message,
              labels: _messageLabels,
              onChanged: (v) => setState(() => _message = v),
            ),
            const SizedBox(height: Spacing.lg),
            LoadingButton(label: 'Save', loading: _loading, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

class _EnumDropdown<T extends Enum> extends StatelessWidget {
  const _EnumDropdown({
    required this.label,
    required this.value,
    required this.labels,
    required this.onChanged,
  });
  final String label;
  final T value;
  final Map<T, String> labels;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [for (final e in labels.entries) DropdownMenuItem(value: e.key, child: Text(e.value))],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
