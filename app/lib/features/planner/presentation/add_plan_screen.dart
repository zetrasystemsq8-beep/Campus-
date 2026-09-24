import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/loading_button.dart';
import '../domain/planner_models.dart';
import 'planner_providers.dart';

class AddPlanScreen extends ConsumerStatefulWidget {
  const AddPlanScreen({super.key});
  @override
  ConsumerState<AddPlanScreen> createState() => _AddPlanScreenState();
}

class _AddPlanScreenState extends ConsumerState<AddPlanScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _notes = TextEditingController();
  bool _isClass = false;
  PlannerKind _kind = PlannerKind.assignment;
  late DateTime _due = _defaultDue();
  int _weekday = DateTime.now().weekday;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 10, minute: 0);
  bool _loading = false;

  static DateTime _defaultDue() {
    final t = DateTime.now().add(const Duration(days: 1));
    return DateTime(t.year, t.month, t.day, 9);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (d != null) setState(() => _due = DateTime(d.year, d.month, d.day, _due.hour, _due.minute));
  }

  Future<void> _pickDueTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    if (t != null) setState(() => _due = DateTime(_due.year, _due.month, _due.day, t.hour, t.minute));
  }

  Future<void> _pickClassTime({required bool start}) async {
    final t = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  String? _clean(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_isClass && (_end.hour * 60 + _end.minute) <= (_start.hour * 60 + _start.minute)) {
      showMessage(context, 'End time must be after start time');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(plannerRepositoryProvider);
      if (_isClass) {
        await repo.addSlot(
          title: _title.text.trim(),
          weekday: _weekday,
          startsAt: formatHm(_start.hour, _start.minute),
          endsAt: formatHm(_end.hour, _end.minute),
          venue: _clean(_place),
        );
        ref.invalidate(timetableProvider);
      } else {
        await repo.addItem(
          kind: _kind,
          title: _title.text.trim(),
          dueAt: _due,
          location: _clean(_place),
          notes: _clean(_notes),
        );
        ref.invalidate(plannerItemsProvider);
      }
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
    return Scaffold(
      appBar: AppBar(title: Text(_isClass ? 'Add weekly class' : 'Add to planner')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Deadline / event')),
                ButtonSegment(value: true, label: Text('Weekly class')),
              ],
              selected: {_isClass},
              onSelectionChanged: (s) => setState(() => _isClass = s.first),
            ),
            gap,
            Form(
              key: _form,
              child: Column(
                children: [
                  if (!_isClass) ...[
                    DropdownButtonFormField<PlannerKind>(
                      value: _kind,
                      decoration: const InputDecoration(labelText: 'Type'),
                      items: [for (final k in PlannerKind.values) DropdownMenuItem(value: k, child: Text(k.label))],
                      onChanged: (v) => setState(() => _kind = v ?? _kind),
                    ),
                    gap,
                  ],
                  TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(labelText: _isClass ? 'Class (e.g. CSC101 Lecture)' : 'Title'),
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Enter a title';
                      return s.length > 120 ? 'Keep it under 120 characters' : null;
                    },
                  ),
                  gap,
                  if (_isClass) ...[
                    DropdownButtonFormField<int>(
                      value: _weekday,
                      decoration: const InputDecoration(labelText: 'Day'),
                      items: [for (var d = 1; d <= 7; d++) DropdownMenuItem(value: d, child: Text(weekdayNames[d - 1]))],
                      onChanged: (v) => setState(() => _weekday = v ?? _weekday),
                    ),
                    gap,
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickClassTime(start: true),
                            child: Text('Starts ${formatHm(_start.hour, _start.minute)}'),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickClassTime(start: false),
                            child: Text('Ends ${formatHm(_end.hour, _end.minute)}'),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(child: OutlinedButton(onPressed: _pickDate, child: Text(formatDate(_due)))),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _pickDueTime,
                            child: Text(formatHm(_due.hour, _due.minute)),
                          ),
                        ),
                      ],
                    ),
                  gap,
                  TextFormField(
                    controller: _place,
                    decoration: InputDecoration(labelText: _isClass ? 'Venue (optional)' : 'Location (optional)'),
                  ),
                  if (!_isClass) ...[
                    gap,
                    TextFormField(
                      controller: _notes,
                      maxLines: 3,
                      maxLength: 1000,
                      decoration: const InputDecoration(labelText: 'Notes (optional)'),
                    ),
                  ],
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
