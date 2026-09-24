/// Minimal id + label pair used for dropdown choices.
class Option {
  const Option(this.id, this.name);
  factory Option.fromMap(Map<String, dynamic> m) => Option(m['id'] as String, m['name'] as String);
  final String id;
  final String name;
}
