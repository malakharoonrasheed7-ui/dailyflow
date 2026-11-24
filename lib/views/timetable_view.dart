import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/routine_block.dart';
import '../models/schedule_segment.dart';
import '../services/scheduler.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/card_3d.dart';
import '../widgets/stat_badge_3d.dart';
import '../widgets/template_picker_dialog.dart';
import '../widgets/timeline_visualizer.dart';
import '../widgets/time_picker_12h.dart';

class TimetableView extends StatelessWidget {
  final AppData data;
  final Future<void> Function() onChange;
  final Function(int tabIndex)? onNavigateTab;

  const TimetableView({
    super.key,
    required this.data,
    required this.onChange,
    this.onNavigateTab,
  });

  void _showAddBlockFromFreeSlot(BuildContext context, ScheduleSegment seg) {
    final startMin = unshiftMin(seg.ss);
    final endMin = unshiftMin(seg.se);
    final startTod = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    final endTod = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

    final nameCtrl = TextEditingController();
    String cat = 'class';
    TimeOfDay selectedStart = startTod;
    TimeOfDay selectedEnd = endTod;
    bool remind = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⚡ Fill Free Slot with Routine',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(modalCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Activity Name',
                    hintText: 'e.g. Flutter Study, Gym, Project Work',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: cat,
                  items: BlockCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c.key,
                      child: Row(
                        children: [
                          Icon(c.icon, size: 18, color: c.lightColor),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setModalState(() => cat = v!),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('Start: ${timeOfDay12(selectedStart)}'),
                        onPressed: () async {
                          final t = await TimePicker12HDialog.show(modalCtx, initialTime: selectedStart, title: 'Select Start Time');
                          if (t != null) setModalState(() => selectedStart = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule, size: 16),
                        label: Text('End: ${timeOfDay12(selectedEnd)}'),
                        onPressed: () async {
                          final t = await TimePicker12HDialog.show(modalCtx, initialTime: selectedEnd, title: 'Select End Time');
                          if (t != null) setModalState(() => selectedEnd = t);
                        },
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: remind,
                    onChanged: (v) => setModalState(() => remind = v),
                    title: const Text('Enable Reminder Alarm', style: TextStyle(fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    final newBlock = RoutineBlock(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: nameCtrl.text.trim(),
                      cat: cat,
                      start: timeOfDay24(selectedStart),
                      end: timeOfDay24(selectedEnd),
                      remind: remind,
                    );
                    Scheduler.addBlockAndAdjust(data, newBlock);
                    await onChange();
                    if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Routine block added! Free time auto-adjusted.')),
                      );
                    }
                  },
                  child: const Text('Add to Schedule & Adjust Free Time', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final segments = Scheduler.buildSchedule(data);
    final stats = Scheduler.calculateStats(data);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 3D Stat Badges Row
        LayoutBuilder(builder: (ctx, constraints) {
          final isWide = constraints.maxWidth > 650;
          if (isWide) {
            return Row(
              children: [
                Expanded(
                  child: StatBadge3D(
                    title: 'ROUTINE',
                    value: '${stats['routineHours']}h',
                    subtitle: 'Classes & Sleep',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBadge3D(
                    title: 'FREE TIME',
                    value: '${stats['freeHours']}h',
                    subtitle: 'AM & PM Gaps',
                    icon: Icons.bolt_rounded,
                    color: const Color(0xFF00D2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: StatBadge3D(
                    title: 'TASKS',
                    value: '${stats['scheduledTasks']} / ${stats['totalTasks']}',
                    subtitle: '${stats['taskHours']}h scheduled',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFFF9F1C),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatBadge3D(
                        title: 'ROUTINE',
                        value: '${stats['routineHours']}h',
                        subtitle: 'Fixed blocks',
                        icon: Icons.calendar_month_rounded,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatBadge3D(
                        title: 'FREE TIME',
                        value: '${stats['freeHours']}h',
                        subtitle: 'AM & PM Gaps',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF00D2FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                StatBadge3D(
                  title: 'TASKS SCHEDULED',
                  value: '${stats['scheduledTasks']} of ${stats['totalTasks']} Tasks',
                  subtitle: '${stats['taskHours']}h in schedule',
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFFFF9F1C),
                ),
              ],
            );
          }
        }),
        const SizedBox(height: 12),

        // Action Buttons Row
        Row(
          children: [
            Expanded(
              flex: 3,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Auto-Fit Tasks into Free Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final scheduled = Scheduler.autoSchedule(data);
                  await onChange();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          scheduled > 0
                              ? '✨ Successfully fitted $scheduled task(s) into available free time!'
                              : 'All tasks already scheduled or no matching free slots.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Tasks', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  for (final t in data.tasks) {
                    t.scheduled = false;
                    t.ss = null;
                    t.se = null;
                  }
                  await onChange();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All tasks returned to unscheduled pool & slots freed!')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 1-Click Templates Switcher Button
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.accent),
            foregroundColor: AppTheme.accent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 18),
          label: const Text('⚡ Switch Routine Template / Mode (Exam, Weekend, Ramadan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          onPressed: () {
            TemplatePickerDialog.show(
              context,
              data: data,
              onTemplateApplied: onChange,
            );
          },
        ),
        const SizedBox(height: 14),

        // 24-Hour Timeline Visualizer
        TimelineVisualizer(
          segments: segments,
          onSegmentTap: (seg) {
            if (seg.isOpen) {
              _showAddBlockFromFreeSlot(context, seg);
            }
          },
        ),
        const SizedBox(height: 16),

        // Schedule List Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Timeline Schedule (AM / PM)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${segments.length} segments',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Schedule List Cards
        ...segments.map((seg) => _buildSegmentCard(context, seg, isDark)),
      ],
    );
  }

  Widget _buildSegmentCard(BuildContext context, ScheduleSegment seg, bool isDark) {
    final startMin = unshiftMin(seg.ss);
    final endMin = unshiftMin(seg.se);
    final timeStr = '${hhmm12(startMin)} – ${hhmm12(endMin)}';
    final dur = seg.se - seg.ss;
    final catColor = AppTheme.getCategoryColor(seg.cat);

    if (seg.isOpen) {
      // Free Time Slot Card
      return TiltCard3D(
        maxTiltAngle: 0.08,
        glowColor: AppTheme.accent,
        borderColor: AppTheme.accent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showAddBlockFromFreeSlot(context, seg),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF062E38).withValues(alpha: 0.5), const Color(0xFF0B1924)]
                  : [const Color(0xFFE0F7FA), const Color(0xFFF0FDFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accent),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatDuration(dur),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '⚡ Free Time Slot — Tap to fill with Routine or Task',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.add_circle_outline, color: AppTheme.accent, size: 20),
            ],
          ),
        ),
      );
    }

    // Routine Block or Scheduled Task Card
    return TiltCard3D(
      maxTiltAngle: 0.08,
      glowColor: catColor,
      borderColor: catColor.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: AppTheme.getCategoryGradient(seg.cat, isDark),
        ),
        child: Row(
          children: [
            // Category Color Bar
            Container(
              width: 4,
              height: 38,
              decoration: BoxDecoration(
                color: catColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${formatDuration(dur)}) · ${seg.cat.toUpperCase()}',
                        style: TextStyle(fontSize: 10, color: catColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    seg.name,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (seg.remind)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.alarm_on_rounded, size: 18, color: AppTheme.primary),
              ),
            if (seg.blockId != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                tooltip: 'Convert to Free Time',
                onPressed: () async {
                  Scheduler.deleteBlockAndFreeSlot(data, seg.blockId!);
                  await onChange();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Block removed & converted back to Free Time!')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
