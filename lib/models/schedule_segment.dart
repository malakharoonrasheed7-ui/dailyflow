class ScheduleSegment {
  final int ss; // shifted start (0..1439)
  final int se; // shifted end (0..1440)
  final String name;
  final String cat;
  final bool remind;
  final String? blockId;
  final String? taskId;

  ScheduleSegment({
    required this.ss,
    required this.se,
    required this.name,
    required this.cat,
    this.remind = false,
    this.blockId,
    this.taskId,
  });

  bool get isOpen => cat == 'open';
  int get durationMinutes => se - ss;
}
