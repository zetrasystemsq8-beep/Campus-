enum PlannerKind { assignment, test, exam, study, event, task }

extension PlannerKindLabel on PlannerKind {
  String get label => switch (this) {
        PlannerKind.assignment => 'Assignment',
        PlannerKind.test => 'Test',
        PlannerKind.exam => 'Exam',
        PlannerKind.study => 'Study session',
        PlannerKind.event => 'Event',
        PlannerKind.task => 'Task',
      };
}

class PlannerItem {
  const PlannerItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.dueAt,
    this.location,
    this.notes,
    this.isDone = false,
  });

  final String id;
  final PlannerKind kind;
  final String title;
  final DateTime dueAt; // local time
  final String? location;
  final String? notes;
  final bool isDone;

  factory PlannerItem.fromMap(Map<String, dynamic> m) => PlannerItem(
        id: m['id'] as String,
        kind: PlannerKind.values.firstWhere((k) => k.name == m['kind'], orElse: () => PlannerKind.task),
        title: m['title'] as String,
        dueAt: DateTime.parse(m['due_at'] as String).toLocal(),
        location: m['location'] as String?,
        notes: m['notes'] as String?,
        isDone: m['is_done'] as bool? ?? false,
      );
}

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.title,
    required this.weekday,
    required this.startsAt,
    required this.endsAt,
    this.venue,
  });

  final String id;
  final String title;
  final int weekday; // 1 = Monday ... 7 = Sunday
  final String startsAt; // HH:MM
  final String endsAt;
  final String? venue;

  factory TimetableSlot.fromMap(Map<String, dynamic> m) => TimetableSlot(
        id: m['id'] as String,
        title: m['title'] as String,
        weekday: m['weekday'] as int,
        startsAt: (m['starts_at'] as String).substring(0, 5),
        endsAt: (m['ends_at'] as String).substring(0, 5),
        venue: m['venue'] as String?,
      );
}
