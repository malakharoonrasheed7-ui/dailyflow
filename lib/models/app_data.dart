import 'routine_block.dart';
import 'routine_template.dart';
import 'study_session.dart';
import 'task_item.dart';

class AppData {
  List<RoutineBlock> blocks;
  List<TaskItem> tasks;
  int practice;
  int social;
  String darkStart; // "18:00"
  String darkEnd;   // "06:00"
  String themeMode; // 'auto', 'dark', 'light'
  String alarmMissionType; // 'simple', 'math', 'taps'
  bool morningAlarmEnabled; // dedicated morning wake-up alarm
  String morningAlarmTime;  // "06:30" (AM/PM)
  List<RoutineTemplate> customTemplates;

  // Streak & Habit Tracking
  int currentStreak;
  int bestStreak;
  String lastCheckInDate; // "YYYY-MM-DD"
  List<String> completedDates; // ["YYYY-MM-DD", ...]

  // Live Study & Focus Sessions Tracking
  List<StudySession> studySessions;
  int dailyStudyGoalMinutes;

  // User Profile Customization
  String profileName;
  String profileTitle;
  String profileBio;
  String profileEmail;
  String profilePhone;
  String profileLocation;
  List<String> profileSkills;

  AppData({
    required this.blocks,
    required this.tasks,
    required this.practice,
    required this.social,
    this.darkStart = '18:00',
    this.darkEnd = '06:00',
    this.themeMode = 'auto',
    this.alarmMissionType = 'math',
    this.morningAlarmEnabled = true,
    this.morningAlarmTime = '06:30',
    this.customTemplates = const [],
    this.currentStreak = 1,
    this.bestStreak = 1,
    this.lastCheckInDate = '',
    this.completedDates = const [],
    this.studySessions = const [],
    this.dailyStudyGoalMinutes = 180, // 3 hours daily goal default
    this.profileName = 'Haroon Rasheed',
    this.profileTitle = 'Full-Stack Developer & ERP Specialist',
    this.profileBio =
        'Full-Stack Developer specializing in Odoo ERP, React.js, Python and Flutter. Builds tailored software systems, enterprise applications and automated workflows end-to-end.',
    this.profileEmail = 'haricyberofficial@gmail.com',
    this.profilePhone = '0335-5706152',
    this.profileLocation = 'Peshawar, KPK, Pakistan',
    this.profileSkills = const [
      'Flutter & Dart',
      'Odoo ERP',
      'React.js',
      'Python Backend',
      'Full-Stack',
    ],
  });

  // Automatically update daily streak when app is opened
  void autoCheckInToday() {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    if (lastCheckInDate == today) {
      if (!completedDates.contains(today)) {
        completedDates = [...completedDates, today];
      }
      return;
    }

    final yesterday = now.subtract(const Duration(days: 1));
    final yStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    if (lastCheckInDate == yStr) {
      currentStreak += 1;
    } else if (lastCheckInDate.isEmpty) {
      currentStreak = 1;
    } else {
      // Missed one or more days -> start fresh streak
      currentStreak = 1;
    }

    if (currentStreak > bestStreak) {
      bestStreak = currentStreak;
    }

    lastCheckInDate = today;
    if (!completedDates.contains(today)) {
      completedDates = [...completedDates, today];
    }
  }

  factory AppData.defaults() {
    final now = DateTime.now();
    final appData = AppData(
      blocks: [
        RoutineBlock(id: 'b1', name: 'Free Wind Down & Morning Flow', cat: 'social', start: '10:00', end: '14:00', remind: false),
        RoutineBlock(id: 'b2', name: 'CCTV & Network Class', cat: 'class', start: '14:00', end: '16:00', remind: true),
        RoutineBlock(id: 'b3', name: 'MCSE Server Systems', cat: 'class', start: '16:00', end: '18:00', remind: true),
        RoutineBlock(id: 'b4', name: 'Python & AI Development', cat: 'class', start: '23:00', end: '00:30', remind: true),
        RoutineBlock(id: 'b5', name: 'Sleep & Recovery', cat: 'sleep', start: '03:00', end: '10:00', remind: false),
      ],
      tasks: [
        TaskItem(id: 't1', name: 'Revise Python OOP exercises', duration: 45, priority: 'high', scheduled: false),
        TaskItem(id: 't2', name: 'Practice subnetting lab', duration: 30, priority: 'medium', scheduled: false),
      ],
      practice: 90,
      social: 45,
      darkStart: '18:00',
      darkEnd: '06:00',
      themeMode: 'auto',
      alarmMissionType: 'math',
      morningAlarmEnabled: true,
      morningAlarmTime: '06:30',
      customTemplates: const [],
      currentStreak: 1,
      bestStreak: 1,
      lastCheckInDate: '',
      completedDates: const [],
      dailyStudyGoalMinutes: 180,
      studySessions: [
        StudySession(
          id: 's1',
          title: 'Python OOP & Data Structures',
          category: 'coding',
          startTime: now.subtract(const Duration(hours: 4)),
          endTime: now.subtract(const Duration(hours: 2, minutes: 45)),
          durationMinutes: 75,
        ),
        StudySession(
          id: 's2',
          title: 'Networking CCTV Configurations',
          category: 'study',
          startTime: now.subtract(const Duration(days: 1, hours: 3)),
          endTime: now.subtract(const Duration(days: 1, hours: 1)),
          durationMinutes: 120,
        ),
        StudySession(
          id: 's3',
          title: 'Flutter UI Components & State',
          category: 'coding',
          startTime: now.subtract(const Duration(days: 2, hours: 2)),
          endTime: now.subtract(const Duration(days: 2)),
          durationMinutes: 90,
        ),
      ],
      profileName: 'Haroon Rasheed',
      profileTitle: 'Full-Stack Developer & ERP Specialist',
      profileBio:
          'Full-Stack Developer specializing in Odoo ERP, React.js, Python and Flutter. Builds tailored software systems, enterprise applications and automated workflows end-to-end.',
      profileEmail: 'haricyberofficial@gmail.com',
      profilePhone: '0335-5706152',
      profileLocation: 'Peshawar, KPK, Pakistan',
      profileSkills: const [
        'Flutter & Dart',
        'Odoo ERP',
        'React.js',
        'Python Backend',
        'Full-Stack',
      ],
    );
    appData.autoCheckInToday();
    return appData;
  }

  Map<String, dynamic> toJson() => {
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'tasks': tasks.map((t) => t.toJson()).toList(),
        'practice': practice,
        'social': social,
        'darkStart': darkStart,
        'darkEnd': darkEnd,
        'themeMode': themeMode,
        'alarmMissionType': alarmMissionType,
        'morningAlarmEnabled': morningAlarmEnabled,
        'morningAlarmTime': morningAlarmTime,
        'customTemplates': customTemplates.map((t) => t.toJson()).toList(),
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'lastCheckInDate': lastCheckInDate,
        'completedDates': completedDates,
        'studySessions': studySessions.map((s) => s.toJson()).toList(),
        'dailyStudyGoalMinutes': dailyStudyGoalMinutes,
        'profileName': profileName,
        'profileTitle': profileTitle,
        'profileBio': profileBio,
        'profileEmail': profileEmail,
        'profilePhone': profilePhone,
        'profileLocation': profileLocation,
        'profileSkills': profileSkills,
      };

  factory AppData.fromJson(Map<String, dynamic> j) {
    final appData = AppData(
      blocks: ((j['blocks'] as List?) ?? []).map((e) => RoutineBlock.fromJson(e)).toList(),
      tasks: ((j['tasks'] as List?) ?? []).map((e) => TaskItem.fromJson(e)).toList(),
      practice: j['practice'] ?? 90,
      social: j['social'] ?? 45,
      darkStart: j['darkStart'] ?? '18:00',
      darkEnd: j['darkEnd'] ?? '06:00',
      themeMode: j['themeMode'] ?? 'auto',
      alarmMissionType: j['alarmMissionType'] ?? 'math',
      morningAlarmEnabled: j['morningAlarmEnabled'] ?? true,
      morningAlarmTime: j['morningAlarmTime'] ?? '06:30',
      customTemplates: ((j['customTemplates'] as List?) ?? [])
          .map((e) => RoutineTemplate.fromJson(e))
          .toList(),
      currentStreak: j['currentStreak'] ?? 1,
      bestStreak: j['bestStreak'] ?? 1,
      lastCheckInDate: j['lastCheckInDate'] ?? '',
      completedDates: j['completedDates'] != null ? List<String>.from(j['completedDates']) : [],
      studySessions: ((j['studySessions'] as List?) ?? [])
          .map((e) => StudySession.fromJson(e))
          .toList(),
      dailyStudyGoalMinutes: j['dailyStudyGoalMinutes'] ?? 180,
      profileName: j['profileName'] ?? 'Haroon Rasheed',
      profileTitle: j['profileTitle'] ?? 'Full-Stack Developer & ERP Specialist',
      profileBio: j['profileBio'] ??
          'Full-Stack Developer specializing in Odoo ERP, React.js, Python and Flutter. Builds tailored software systems, enterprise applications and automated workflows end-to-end.',
      profileEmail: j['profileEmail'] ?? 'haricyberofficial@gmail.com',
      profilePhone: j['profilePhone'] ?? '0335-5706152',
      profileLocation: j['profileLocation'] ?? 'Peshawar, KPK, Pakistan',
      profileSkills: j['profileSkills'] != null
          ? List<String>.from(j['profileSkills'])
          : [
              'Flutter & Dart',
              'Odoo ERP',
              'React.js',
              'Python Backend',
              'Full-Stack',
            ],
    );
    appData.autoCheckInToday();
    return appData;
  }
}
