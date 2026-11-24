import 'routine_block.dart';
import 'task_item.dart';

class RoutineTemplate {
  final String id;
  final String title;
  final String icon;
  final String description;
  final List<RoutineBlock> blocks;
  final List<TaskItem> tasks;
  final int practice;
  final int social;

  const RoutineTemplate({
    required this.id,
    required this.title,
    required this.icon,
    required this.description,
    required this.blocks,
    required this.tasks,
    required this.practice,
    required this.social,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'icon': icon,
        'description': description,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'practice': practice,
        'social': social,
      };

  factory RoutineTemplate.fromJson(Map<String, dynamic> j) => RoutineTemplate(
        id: j['id'] ?? '',
        title: j['title'] ?? '',
        icon: j['icon'] ?? '⚡',
        description: j['description'] ?? '',
        blocks: ((j['blocks'] as List?) ?? []).map((e) => RoutineBlock.fromJson(e)).toList(),
        tasks: ((j['tasks'] as List?) ?? []).map((e) => TaskItem.fromJson(e)).toList(),
        practice: j['practice'] ?? 90,
        social: j['social'] ?? 45,
      );

  static List<RoutineTemplate> builtInTemplates() => [
        // 1. Standard Developer & Study Flow
        RoutineTemplate(
          id: 'tpl_std',
          title: 'Developer & Study Flow',
          icon: '💻',
          description: 'Balanced daily routine with classes, lab practice, and recovery.',
          blocks: [
            RoutineBlock(id: 'std_b1', name: 'Morning Focus & Planning', cat: 'social', start: '10:00', end: '14:00', remind: false),
            RoutineBlock(id: 'std_b2', name: 'CCTV & Network Lab', cat: 'class', start: '14:00', end: '16:00', remind: true),
            RoutineBlock(id: 'std_b3', name: 'MCSE Server Systems', cat: 'class', start: '16:00', end: '18:00', remind: true),
            RoutineBlock(id: 'std_b4', name: 'Python & AI Development', cat: 'class', start: '23:00', end: '00:30', remind: true),
            RoutineBlock(id: 'std_b5', name: 'Sleep & Recovery', cat: 'sleep', start: '03:00', end: '10:00', remind: false),
          ],
          tasks: [
            TaskItem(id: 'std_t1', name: 'Revise Python OOP exercises', duration: 45, priority: 'high', scheduled: false),
            TaskItem(id: 'std_t2', name: 'Practice subnetting lab', duration: 30, priority: 'medium', scheduled: false),
          ],
          practice: 90,
          social: 45,
        ),

        // 2. Exam & Hardcore Focus Mode
        RoutineTemplate(
          id: 'tpl_exam',
          title: 'Exam / Hardcore Focus Mode',
          icon: '🎯',
          description: 'Intense study intervals, high practice target, and minimal distraction.',
          blocks: [
            RoutineBlock(id: 'ex_b1', name: 'Early Morning Revision', cat: 'class', start: '08:00', end: '11:00', remind: true),
            RoutineBlock(id: 'ex_b2', name: 'Deep Problem Solving & Past Papers', cat: 'class', start: '12:00', end: '16:00', remind: true),
            RoutineBlock(id: 'ex_b3', name: 'Technical Revision & Mock Tests', cat: 'class', start: '18:00', end: '22:00', remind: true),
            RoutineBlock(id: 'ex_b4', name: 'Night Sleep', cat: 'sleep', start: '00:00', end: '07:30', remind: false),
          ],
          tasks: [
            TaskItem(id: 'ex_t1', name: 'Complete 3 Mock Exams', duration: 90, priority: 'high', scheduled: false),
            TaskItem(id: 'ex_t2', name: 'Formulas & Short Notes Memorization', duration: 45, priority: 'high', scheduled: false),
          ],
          practice: 180,
          social: 20,
        ),

        // 3. Weekend & Chill Recovery Mode
        RoutineTemplate(
          id: 'tpl_weekend',
          title: 'Weekend & Chill Mode',
          icon: '🌴',
          description: 'Relaxed routine with sports, family time, and leisure.',
          blocks: [
            RoutineBlock(id: 'wk_b1', name: 'Late Breakfast & Outdoor Sport', cat: 'social', start: '11:00', end: '14:00', remind: false),
            RoutineBlock(id: 'wk_b2', name: 'Side Projects & Creative Fun', cat: 'class', start: '16:00', end: '18:30', remind: false),
            RoutineBlock(id: 'wk_b3', name: 'Family & Friends Meetup', cat: 'social', start: '20:00', end: '23:30', remind: false),
            RoutineBlock(id: 'wk_b4', name: 'Deep Rest', cat: 'sleep', start: '02:00', end: '10:30', remind: false),
          ],
          tasks: [
            TaskItem(id: 'wk_t1', name: 'Read a tech article or book chapter', duration: 30, priority: 'low', scheduled: false),
            TaskItem(id: 'wk_t2', name: 'Organize workspace & backups', duration: 25, priority: 'medium', scheduled: false),
          ],
          practice: 40,
          social: 120,
        ),

        // 4. Ramadan Special Routine
        RoutineTemplate(
          id: 'tpl_ramadan',
          title: 'Ramadan Special Routine',
          icon: '🌙',
          description: 'Structured around Suhoor, Fajr, Work, Iftar, and Taraweeh.',
          blocks: [
            RoutineBlock(id: 'ram_b1', name: 'Suhoor & Fajr Prayer', cat: 'social', start: '04:00', end: '06:00', remind: true),
            RoutineBlock(id: 'ram_b2', name: 'Morning Rest', cat: 'sleep', start: '06:00', end: '10:30', remind: false),
            RoutineBlock(id: 'ram_b3', name: 'Work & Class Block', cat: 'class', start: '11:00', end: '16:00', remind: true),
            RoutineBlock(id: 'ram_b4', name: 'Iftar & Maghrib Family Time', cat: 'social', start: '18:00', end: '19:45', remind: true),
            RoutineBlock(id: 'ram_b5', name: 'Isha & Taraweeh Prayers', cat: 'class', start: '20:00', end: '22:00', remind: true),
            RoutineBlock(id: 'ram_b6', name: 'Late Night Coding / Study', cat: 'class', start: '22:30', end: '02:00', remind: true),
            RoutineBlock(id: 'ram_b7', name: 'Power Nap', cat: 'sleep', start: '02:00', end: '03:45', remind: false),
          ],
          tasks: [
            TaskItem(id: 'ram_t1', name: 'Daily Quran Recitation', duration: 30, priority: 'high', scheduled: false),
            TaskItem(id: 'ram_t2', name: 'Night Programming Session', duration: 60, priority: 'high', scheduled: false),
          ],
          practice: 60,
          social: 60,
        ),
      ];
}
