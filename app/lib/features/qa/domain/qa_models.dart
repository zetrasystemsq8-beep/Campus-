String authorLabel(Map<String, dynamic>? author) {
  final name = (author?['full_name'] as String?)?.trim() ?? '';
  if (name.isNotEmpty) return name;
  return (author?['username'] as String?) ?? 'Student';
}

class Question {
  const Question({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.answerCount,
    required this.createdAt,
    this.courseCode,
    this.acceptedAnswerId,
  });

  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final String? courseCode;
  final int answerCount;
  final String? acceptedAnswerId;
  final DateTime createdAt;

  bool get isAnswered => acceptedAnswerId != null;

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String? ?? '',
        authorId: m['author_id'] as String,
        authorName: authorLabel(m['author'] as Map<String, dynamic>?),
        courseCode: (m['course'] as Map<String, dynamic>?)?['code'] as String?,
        answerCount: m['answer_count'] as int? ?? 0,
        acceptedAnswerId: m['accepted_answer_id'] as String?,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class Answer {
  const Answer({
    required this.id,
    required this.questionId,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.helpfulCount,
    required this.votedByMe,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String body;
  final String authorId;
  final String authorName;
  final int helpfulCount;
  final bool votedByMe;
  final DateTime createdAt;

  factory Answer.fromMap(Map<String, dynamic> m) => Answer(
        id: m['id'] as String,
        questionId: m['question_id'] as String,
        body: m['body'] as String,
        authorId: m['author_id'] as String,
        authorName: authorLabel(m['author'] as Map<String, dynamic>?),
        helpfulCount: m['helpful_count'] as int? ?? 0,
        // RLS only exposes the caller's own vote rows, so any row means "I voted".
        votedByMe: (m['votes'] as List?)?.isNotEmpty ?? false,
        createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      );
}

class QuestionDetail {
  const QuestionDetail({required this.question, required this.answers, required this.saved});
  final Question question;
  final List<Answer> answers;
  final bool saved;
}

/// Accepted answer first, then most helpful, then oldest.
List<Answer> sortAnswers(List<Answer> answers, String? acceptedId) {
  final sorted = [...answers];
  sorted.sort((a, b) {
    if (a.id == acceptedId) return -1;
    if (b.id == acceptedId) return 1;
    final byHelpful = b.helpfulCount.compareTo(a.helpfulCount);
    return byHelpful != 0 ? byHelpful : a.createdAt.compareTo(b.createdAt);
  });
  return sorted;
}
