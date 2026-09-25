import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/qa_models.dart';

class QaRepository {
  QaRepository(this._client);
  final SupabaseClient _client;

  static const _qSelect = 'id, title, body, answer_count, accepted_answer_id, created_at, '
      'author_id, course:courses(code, title), author:profiles(username, full_name)';
  static const _aSelect = '*, author:profiles(username, full_name), votes:answer_votes(user_id)';

  Future<List<Question>> feed({
    String query = '',
    bool unansweredOnly = false,
    String? courseId,
    int offset = 0,
    int limit = 20,
  }) =>
      guarded(() async {
        var q = _client.from('questions').select(_qSelect);
        final term = query.trim();
        if (term.isNotEmpty) {
          q = q.textSearch('search', term, config: 'english', type: TextSearchType.websearch);
        }
        if (unansweredOnly) q = q.eq('answer_count', 0);
        if (courseId != null) q = q.eq('course_id', courseId);
        final rows = await q.order('created_at', ascending: false).range(offset, offset + limit - 1);
        return [for (final r in rows) Question.fromMap(r)];
      });

  Future<QuestionDetail> detail(String id) => guarded(() async {
        final results = await Future.wait<dynamic>([
          _client.from('questions').select(_qSelect).eq('id', id).maybeSingle(),
          _client.from('answers').select(_aSelect).eq('question_id', id),
          _client.from('saved_questions').select('question_id').eq('question_id', id).maybeSingle(),
        ]);
        final qRow = results[0] as Map<String, dynamic>?;
        if (qRow == null) throw const AppFailure('This question is no longer available.');
        final question = Question.fromMap(qRow);
        final answers = [for (final r in results[1] as List) Answer.fromMap(r as Map<String, dynamic>)];
        return QuestionDetail(
          question: question,
          answers: sortAnswers(answers, question.acceptedAnswerId),
          saved: results[2] != null,
        );
      });

  Future<String> ask({
    required String title,
    required String body,
    String? courseId,
    required bool isPublic,
  }) =>
      guarded(() async {
        final row = await _client
            .from('questions')
            .insert({
              'title': title,
              'body': body,
              'course_id': courseId,
              'visibility': isPublic ? 'public' : 'university',
            })
            .select('id')
            .single();
        return row['id'] as String;
      });

  Future<void> deleteQuestion(String id) => guarded(() async {
        await _client.from('questions').delete().eq('id', id);
      });

  Future<void> postAnswer(String questionId, String body) => guarded(() async {
        await _client.from('answers').insert({'question_id': questionId, 'body': body});
      });

  Future<void> deleteAnswer(String id) => guarded(() async {
        await _client.from('answers').delete().eq('id', id);
      });

  Future<void> vote(String answerId, {required bool on}) => guarded(() async {
        if (on) {
          await _client.from('answer_votes').insert({'answer_id': answerId});
        } else {
          await _client.from('answer_votes').delete().eq('answer_id', answerId);
        }
      });

  Future<void> accept(String answerId) => guarded(() async {
        await _client.rpc('accept_answer', params: {'_answer_id': answerId});
      });

  Future<void> setSaved(String questionId, {required bool saved}) => guarded(() async {
        if (saved) {
          await _client.from('saved_questions').insert({'question_id': questionId});
        } else {
          await _client.from('saved_questions').delete().eq('question_id', questionId);
        }
      });

  Future<List<Question>> saved() => guarded(() async {
        final rows = await _client
            .from('saved_questions')
            .select('created_at, question:questions($_qSelect)')
            .order('created_at', ascending: false)
            .limit(100);
        return [
          for (final r in rows)
            if (r['question'] != null) Question.fromMap(r['question'] as Map<String, dynamic>),
        ];
      });
}
