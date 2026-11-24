import 'package:flutter/material.dart';

enum BlockCategory {
  routineClass('class', 'Class / Study', Icons.school_rounded, Color(0xFF3B82F6), Color(0xFF1E3A8A)),
  sleep('sleep', 'Sleep / Rest', Icons.bedtime_rounded, Color(0xFF8B5CF6), Color(0xFF4C1D95)),
  practice('practice', 'Skill Practice', Icons.code_rounded, Color(0xFF10B981), Color(0xFF064E3B)),
  social('social', 'Social & Chill', Icons.forum_rounded, Color(0xFFEC4899), Color(0xFF831843)),
  work('work', 'Work / Project', Icons.work_rounded, Color(0xFFF59E0B), Color(0xFF78350F)),
  fitness('fitness', 'Workout / Health', Icons.fitness_center_rounded, Color(0xFFEF4444), Color(0xFF7F1D1D));

  final String key;
  final String label;
  final IconData icon;
  final Color lightColor;
  final Color darkColor;

  const BlockCategory(this.key, this.label, this.icon, this.lightColor, this.darkColor);

  static BlockCategory fromKey(String key) {
    return BlockCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => BlockCategory.routineClass,
    );
  }
}

class RoutineBlock {
  String id;
  String name;
  String cat;
  String start; // "HH:MM" 24-hr format
  String end;   // "HH:MM" 24-hr format
  bool remind;

  RoutineBlock({
    required this.id,
    required this.name,
    required this.cat,
    required this.start,
    required this.end,
    required this.remind,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cat': cat,
        'start': start,
        'end': end,
        'remind': remind,
      };

  factory RoutineBlock.fromJson(Map<String, dynamic> j) => RoutineBlock(
        id: j['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: j['name'] ?? '',
        cat: j['cat'] ?? 'class',
        start: j['start'] ?? '09:00',
        end: j['end'] ?? '10:00',
        remind: j['remind'] ?? false,
      );

  RoutineBlock copyWith({
    String? id,
    String? name,
    String? cat,
    String? start,
    String? end,
    bool? remind,
  }) {
    return RoutineBlock(
      id: id ?? this.id,
      name: name ?? this.name,
      cat: cat ?? this.cat,
      start: start ?? this.start,
      end: end ?? this.end,
      remind: remind ?? this.remind,
    );
  }
}
