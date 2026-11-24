class StudySession {
  final String id;
  final String title;
  final String category; // 'study', 'coding', 'revision', 'reading', 'practice', 'other'
  final DateTime startTime;
  final DateTime endTime;
  final int durationMinutes;

  StudySession({
    required this.id,
    required this.title,
    required this.category,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'durationMinutes': durationMinutes,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Study Session',
        category: json['category'] ?? 'study',
        startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
        endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
        durationMinutes: json['durationMinutes'] ?? 0,
      );
}
