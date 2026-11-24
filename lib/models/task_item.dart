class TaskItem {
  String id;
  String name;
  String priority; // 'high', 'medium', 'low'
  int duration;    // in minutes
  bool scheduled;
  int? ss;         // shifted start minutes from dayStart (06:00 AM)
  int? se;         // shifted end minutes from dayStart (06:00 AM)
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.name,
    required this.duration,
    required this.priority,
    this.scheduled = false,
    this.ss,
    this.se,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'duration': duration,
        'priority': priority,
        'scheduled': scheduled,
        'ss': ss,
        'se': se,
        'isCompleted': isCompleted,
      };

  factory TaskItem.fromJson(Map<String, dynamic> j) => TaskItem(
        id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: j['name'] ?? '',
        duration: j['duration'] ?? 30,
        priority: j['priority'] ?? 'medium',
        scheduled: j['scheduled'] ?? false,
        ss: j['ss'],
        se: j['se'],
        isCompleted: j['isCompleted'] ?? false,
      );

  TaskItem copyWith({
    String? id,
    String? name,
    String? priority,
    int? duration,
    bool? scheduled,
    int? ss,
    int? se,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      priority: priority ?? this.priority,
      scheduled: scheduled ?? this.scheduled,
      ss: ss ?? this.ss,
      se: se ?? this.se,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
