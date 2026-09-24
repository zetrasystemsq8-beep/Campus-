import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/feedback.dart';
import '../../../core/widgets/state_views.dart';
import '../../profile/domain/academic_choices.dart';
import '../../profile/presentation/profile_providers.dart';
import '../domain/course.dart';
import 'enrollment_providers.dart';

class AddCourseScreen extends ConsumerStatefulWidget {
  const AddCourseScreen({super.key});
  @override
  ConsumerState<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends ConsumerState<AddCourseScreen> {
  final _query = TextEditingController();
  Timer? _debounce;
  String _session = currentSessionLabel();
  int _semester = 1;
  bool _myDepartment = true;
  List<Course>? _results;
  Object? _error;
  bool _loading = false;
  int _seq = 0;
  final _added = <String>{};

  String _key(String courseId) => '$courseId|$_session|$_semester';

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dept = ref.read(profileProvider).valueOrNull?.departmentId;
      final res = await ref
          .read(enrollmentRepositoryProvider)
          .searchCourses(departmentId: _myDepartment ? dept : null, query: _query.text);
      if (mounted && seq == _seq) setState(() => _results = res);
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _search);
  }

  Future<void> _add(Course c) async {
    try {
      await ref
          .read(enrollmentRepositoryProvider)
          .enroll(courseId: c.id, sessionLabel: _session, semester: _semester);
      ref.invalidate(enrollmentsProvider);
      if (mounted) setState(() => _added.add(_key(c.id)));
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = {
      for (final e in ref.watch(enrollmentsProvider).valueOrNull ?? const [])
        '${e.courseId}|${e.sessionLabel}|${e.semester}',
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Add course')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _session,
                        decoration: const InputDecoration(labelText: 'Session'),
                        items: [for (final s in sessionLabels()) DropdownMenuItem(value: s, child: Text(s))],
                        onChanged: (v) => setState(() => _session = v ?? _session),
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _semester,
                        decoration: const InputDecoration(labelText: 'Semester'),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('First')),
                          DropdownMenuItem(value: 2, child: Text('Second')),
                        ],
                        onChanged: (v) => setState(() => _semester = v ?? _semester),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.md),
                TextField(
                  controller: _query,
                  onChanged: _onQueryChanged,
                  textInputAction: TextInputAction.search,
                  decoration: const InputDecoration(labelText: 'Search code or title', prefixIcon: Icon(Icons.search)),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilterChip(
                    label: const Text('My department only'),
                    selected: _myDepartment,
                    onSelected: (v) {
                      setState(() => _myDepartment = v);
                      _search();
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _results(existing)),
        ],
      ),
    );
  }

  Widget _results(Set<String> existing) {
    if (_error != null && _results == null) return ErrorRetry(error: _error!, onRetry: _search);
    final results = _results;
    if (results == null) return const SizedBox.shrink();
    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off,
        title: 'No courses found',
        message: 'Try another search, or turn off "My department only".',
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, i) {
        final c = results[i];
        final done = existing.contains(_key(c.id)) || _added.contains(_key(c.id));
        return ListTile(
          title: Text('${c.code} · ${c.title}', maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('${c.units} units · ${c.level} Level${c.departmentName == null ? '' : ' · ${c.departmentName}'}'),
          trailing: done
              ? const Icon(Icons.check_circle, color: Colors.green, semanticLabel: 'Added')
              : IconButton(icon: const Icon(Icons.add_circle_outline), tooltip: 'Add ${c.code}', onPressed: () => _add(c)),
        );
      },
    );
  }
}
