enum VisibilityLevel { public, university, private }

enum MessagePermission { everyone, university, nobody }

T _enumFrom<T extends Enum>(List<T> values, Object? raw, T fallback) =>
    values.firstWhere((e) => e.name == raw, orElse: () => fallback);

String? _nestedName(Map<String, dynamic> m, String key) =>
    (m[key] as Map<String, dynamic>?)?['name'] as String?;

class Profile {
  const Profile({
    required this.id,
    required this.username,
    this.fullName,
    this.bio,
    this.universityId,
    this.facultyId,
    this.departmentId,
    this.programmeId,
    this.universityName,
    this.facultyName,
    this.departmentName,
    this.programmeName,
    this.level,
    this.graduationYear,
    this.skills = const [],
    this.interests = const [],
    this.profileVisibility = VisibilityLevel.university,
    this.contactVisibility = VisibilityLevel.private,
    this.activityVisibility = VisibilityLevel.university,
    this.messagePermission = MessagePermission.university,
    this.verification = 'unverified',
    this.reputation = 0,
    this.onboardedAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? bio;
  final String? universityId;
  final String? facultyId;
  final String? departmentId;
  final String? programmeId;
  final String? universityName;
  final String? facultyName;
  final String? departmentName;
  final String? programmeName;
  final int? level;
  final int? graduationYear;
  final List<String> skills;
  final List<String> interests;
  final VisibilityLevel profileVisibility;
  final VisibilityLevel contactVisibility;
  final VisibilityLevel activityVisibility;
  final MessagePermission messagePermission;
  final String verification;
  final int reputation;
  final DateTime? onboardedAt;

  bool get isOnboarded => onboardedAt != null;
  bool get isVerified => verification == 'verified';

  String get displayName {
    final n = fullName?.trim() ?? '';
    return n.isNotEmpty ? n : username;
  }

  String get firstName => displayName.split(' ').first;

  String get initials {
    final parts = displayName.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  factory Profile.fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        username: m['username'] as String,
        fullName: m['full_name'] as String?,
        bio: m['bio'] as String?,
        universityId: m['university_id'] as String?,
        facultyId: m['faculty_id'] as String?,
        departmentId: m['department_id'] as String?,
        programmeId: m['programme_id'] as String?,
        universityName: _nestedName(m, 'university'),
        facultyName: _nestedName(m, 'faculty'),
        departmentName: _nestedName(m, 'department'),
        programmeName: _nestedName(m, 'programme'),
        level: m['level'] as int?,
        graduationYear: m['graduation_year'] as int?,
        skills: List<String>.from(m['skills'] as List? ?? const []),
        interests: List<String>.from(m['interests'] as List? ?? const []),
        profileVisibility:
            _enumFrom(VisibilityLevel.values, m['profile_visibility'], VisibilityLevel.university),
        contactVisibility:
            _enumFrom(VisibilityLevel.values, m['contact_visibility'], VisibilityLevel.private),
        activityVisibility:
            _enumFrom(VisibilityLevel.values, m['activity_visibility'], VisibilityLevel.university),
        messagePermission:
            _enumFrom(MessagePermission.values, m['message_permission'], MessagePermission.university),
        verification: m['verification'] as String? ?? 'unverified',
        reputation: m['reputation'] as int? ?? 0,
        onboardedAt:
            m['onboarded_at'] == null ? null : DateTime.parse(m['onboarded_at'] as String),
      );
}
