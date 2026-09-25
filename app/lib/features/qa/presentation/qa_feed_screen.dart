import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/state_views.dart';
import '../data/qa_repository.dart';
import '../domain/qa_models.dart';
import 'qa_providers.dart';

class QaFeedScreen extends ConsumerStatefulWidget {
  const QaFeedScreen({super.key});
  @override
  ConsumerState<QaFeedScreen> createState() => _QaFeedScreenState();
}

class _QaFeedScreenState extends ConsumerState<QaFeedScreen> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  bool _unansweredOnly = false;
  final List<Question> _items = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  int _seq = 0;

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_loadingMore && _hasMore && _scroll.position.extentAfter < 400) _loadMore();
  }

  Future<void> _load() async {
    final seq = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(qaRepositoryProvider).feed(
            query: _query.text,
            unansweredOnly: _unansweredOnly,
            limit: _pageSize,
          );
      if (!mounted || seq != _seq) return;
      setState(() {
        _items
          ..clear()
          ..addAll(res);
        _hasMore = res.length == _pageSize;
      });
    } catch (e) {
      if (mounted && seq == _seq) setState(() => _error = e);
    } finally {
      if (mounted && seq == _seq) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final res = await ref.read(qaRepositoryProvider).feed(
            query: _query.text,
            unansweredOnly: _unansweredOnly,
            offset: _items.length,
            limit: _pageSize,
          );
      if (!mounted) return;
      setState(() {
        _items.addAll(res);
        _hasMore = res.length == _pageSize;
      });
    } catch (_) {
      // Silent: the user can keep scrolling or pull to refresh to retry.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onQueryChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        actions: [
          IconButton(
            tooltip: 'Saved questions',
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () => context.push('/qa/saved'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final posted = await context.push<bool>('/qa/ask');
          if (posted == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Ask'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.md, Spacing.md, Spacing.md, 0),
            child: TextField(
              controller: _query,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(labelText: 'Search questions', prefixIcon: Icon(Icons.search)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilterChip(
                label: const Text('Unanswered only'),
                selected: _unansweredOnly,
                onSelected: (v) {
                  setState(() => _unansweredOnly = v);
                  _load();
                },
              ),
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading && _items.isEmpty) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) return ErrorRetry(error: _error!, onRetry: _load);
    if (_items.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'No questions yet',
        message: 'Be the first to ask something your coursemates can help with.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: _items.length + (_hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i >= _items.length) {
            return const Padding(
              padding: EdgeInsets.all(Spacing.md),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final q = _items[i];
          return ListTile(
            leading: Icon(
              q.isAnswered ? Icons.check_circle : Icons.help_outline,
              color: q.isAnswered ? Colors.green : null,
            ),
            title: Text(q.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${q.authorName}${q.courseCode == null ? '' : ' · ${q.courseCode}'} · ${timeAgo(q.createdAt)}',
            ),
            trailing: Text('${q.answerCount}'),
            onTap: () => context.push('/qa/${q.id}'),
          );
        },
      ),
    );
  }
}
