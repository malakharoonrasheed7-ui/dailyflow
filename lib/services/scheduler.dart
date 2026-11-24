import '../models/app_data.dart';
import '../models/routine_block.dart';
import '../models/schedule_segment.dart';
import 'time_utils.dart';

class Scheduler {
  /// Converts fixed routine blocks to shifted intervals (06:00 AM = 0).
  static List<Map<String, dynamic>> _fixed(List<RoutineBlock> blocks) {
    final list = blocks.map((b) {
      int ss = shiftMin(toMin(b.start));
      int se = shiftMin(toMin(b.end));
      if (se <= ss) se += 1440;
      return {'b': b, 'ss': ss, 'se': se};
    }).toList();
    list.sort((a, b) => (a['ss'] as int).compareTo(b['ss'] as int));
    return list;
  }

  /// Calculates available free gaps between fixed routine blocks.
  static List<Map<String, int>> freeGaps(List<RoutineBlock> blocks) {
    final fx = _fixed(blocks);
    final gaps = <Map<String, int>>[];
    int cursor = 0;
    for (final b in fx) {
      final ss = b['ss'] as int;
      final se = b['se'] as int;
      if (ss > cursor) gaps.add({'ss': cursor, 'se': ss});
      cursor = cursor > se ? cursor : se;
    }
    if (cursor < 1440) gaps.add({'ss': cursor, 'se': 1440});
    return gaps.where((g) => (g['se']! - g['ss']!) >= 5).toList();
  }

  /// Builds a complete 24-hour chronological schedule including routine blocks,
  /// practice/social allocations, scheduled tasks, and remaining Free Time slots.
  static List<ScheduleSegment> buildSchedule(AppData data) {
    final fx = _fixed(data.blocks).map((b) {
      final blk = b['b'] as RoutineBlock;
      return ScheduleSegment(
        ss: b['ss'] as int,
        se: b['se'] as int,
        name: blk.name,
        cat: blk.cat,
        remind: blk.remind,
        blockId: blk.id,
      );
    }).toList();

    var gaps = freeGaps(data.blocks).map((g) => Map<String, int>.from(g)).toList();
    final segments = <ScheduleSegment>[...fx];

    void takeFromGaps(int minutesNeeded, String cat, String label) {
      gaps.sort((a, b) => (b['se']! - b['ss']!).compareTo(a['se']! - a['ss']!));
      int remaining = minutesNeeded;
      for (final g in gaps) {
        if (remaining <= 0) break;
        final avail = g['se']! - g['ss']!;
        if (avail <= 0) continue;
        final take = avail < remaining ? avail : remaining;
        segments.add(ScheduleSegment(
          ss: g['ss']!,
          se: g['ss']! + take,
          name: label,
          cat: cat,
        ));
        g['ss'] = g['ss']! + take;
        remaining -= take;
      }
    }

    if (data.practice > 0) takeFromGaps(data.practice, 'practice', 'Practice time');
    if (data.social > 0) takeFromGaps(data.social, 'social', 'Social media & rest');

    for (final t in data.tasks.where((t) => t.scheduled && t.ss != null && t.se != null)) {
      segments.add(ScheduleSegment(
        ss: t.ss!,
        se: t.se!,
        name: t.name,
        cat: 'task',
        remind: true,
        taskId: t.id,
      ));
    }

    // Find all occupied intervals and extract the remaining free open slots
    final occupied = segments.map((s) => {'ss': s.ss, 'se': s.se}).toList()
      ..sort((a, b) => a['ss']!.compareTo(b['ss']!));
    int cursor = 0;
    final open = <Map<String, int>>[];
    for (final o in occupied) {
      if (o['ss']! > cursor) open.add({'ss': cursor, 'se': o['ss']!});
      cursor = cursor > o['se']! ? cursor : o['se']!;
    }
    if (cursor < 1440) open.add({'ss': cursor, 'se': 1440});

    for (final o in open.where((o) => (o['se']! - o['ss']!) >= 5)) {
      final duration = o['se']! - o['ss']!;
      segments.add(ScheduleSegment(
        ss: o['ss']!,
        se: o['se']!,
        name: 'Free Time (${formatDuration(duration)})',
        cat: 'open',
      ));
    }

    segments.sort((a, b) => a.ss.compareTo(b.ss));
    return segments;
  }

  /// Returns available Free Time slots formatted for task slot picker.
  static List<Map<String, dynamic>> taskSlotOptions(AppData data) {
    final open = buildSchedule(data).where((s) => s.isOpen).toList();
    final out = <Map<String, dynamic>>[];
    for (final g in open) {
      final dur = g.se - g.ss;
      if (dur >= 15) {
        out.add({
          'ss': g.ss,
          'se': g.se,
          'dur': dur,
          'label': '${hhmm12(unshiftMin(g.ss))} – ${hhmm12(unshiftMin(g.se))} (${formatDuration(dur)})',
        });
      }
    }
    return out;
  }

  /// Automatically schedules unscheduled tasks into available free slots
  /// sorted by priority (High -> Medium -> Low).
  static int autoSchedule(AppData data) {
    var openSlots = buildSchedule(data).where((s) => s.isOpen).map((s) => {'ss': s.ss, 'se': s.se}).toList();
    const order = {'high': 0, 'medium': 1, 'low': 2};
    final pending = data.tasks.where((t) => !t.scheduled).toList()
      ..sort((a, b) => (order[a.priority] ?? 1).compareTo(order[b.priority] ?? 1));

    int scheduledCount = 0;
    for (final t in pending) {
      openSlots.sort((a, b) => (b['se']! - b['ss']!).compareTo(a['se']! - a['ss']!));
      for (final s in openSlots) {
        final avail = s['se']! - s['ss']!;
        if (avail >= t.duration) {
          t.scheduled = true;
          t.ss = s['ss'];
          t.se = s['ss']! + t.duration;
          s['ss'] = s['ss']! + t.duration;
          scheduledCount++;
          break;
        }
      }
    }
    return scheduledCount;
  }

  /// Deletes a routine block and automatically frees the slot.
  static void deleteBlockAndFreeSlot(AppData data, String blockId) {
    data.blocks.removeWhere((b) => b.id == blockId);
  }

  /// Adds a new routine block, automatically checking and adjusting any overlapping
  /// scheduled tasks so they are moved back to unscheduled without breaking.
  static bool addBlockAndAdjust(AppData data, RoutineBlock newBlock) {
    int newSs = shiftMin(toMin(newBlock.start));
    int newSe = shiftMin(toMin(newBlock.end));
    if (newSe <= newSs) newSe += 1440;

    bool hadOverlap = false;
    for (final t in data.tasks.where((t) => t.scheduled && t.ss != null && t.se != null)) {
      if (t.ss! < newSe && t.se! > newSs) {
        t.scheduled = false;
        t.ss = null;
        t.se = null;
        hadOverlap = true;
      }
    }
    data.blocks.add(newBlock);
    return hadOverlap;
  }

  /// Calculates statistics for the day
  static Map<String, dynamic> calculateStats(AppData data) {
    final schedule = buildSchedule(data);
    int totalRoutineMin = 0;
    int totalFreeMin = 0;
    int totalTaskMin = 0;
    int totalSleepMin = 0;

    for (final s in schedule) {
      final dur = s.se - s.ss;
      if (s.isOpen) {
        totalFreeMin += dur;
      } else if (s.cat == 'sleep') {
        totalSleepMin += dur;
      } else if (s.cat == 'task') {
        totalTaskMin += dur;
      } else {
        totalRoutineMin += dur;
      }
    }

    final totalTasks = data.tasks.length;
    final completedTasks = data.tasks.where((t) => t.isCompleted).length;
    final scheduledTasks = data.tasks.where((t) => t.scheduled).length;

    return {
      'routineHours': (totalRoutineMin / 60.0).toStringAsFixed(1),
      'freeHours': (totalFreeMin / 60.0).toStringAsFixed(1),
      'sleepHours': (totalSleepMin / 60.0).toStringAsFixed(1),
      'taskHours': (totalTaskMin / 60.0).toStringAsFixed(1),
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'scheduledTasks': scheduledTasks,
      'freeMinutes': totalFreeMin,
      'routineMinutes': totalRoutineMin,
    };
  }
}
