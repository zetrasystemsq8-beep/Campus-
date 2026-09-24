abstract final class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(s)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Enter a password';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? fullName(String? v) {
    final s = v?.trim() ?? '';
    if (s.length < 2) return 'Enter your full name';
    if (s.length > 100) return 'Name is too long';
    return null;
  }

  static final _username = RegExp(r'^[a-zA-Z0-9_]{3,30}$');

  static String? username(String? v) {
    final s = v?.trim() ?? '';
    if (!_username.hasMatch(s)) return 'Use 3-30 letters, numbers or underscores';
    return null;
  }
}
