class Lesson {
  final String id;
  final String title;
  final String subject;
  final String icon;
  final String content;

  const Lesson({
    required this.id,
    required this.title,
    required this.subject,
    required this.icon,
    required this.content,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled lesson',
      subject: json['subject']?.toString() ?? 'General',
      icon: json['icon']?.toString() ?? '📘',
      content: json['content']?.toString() ?? '',
    );
  }
}
