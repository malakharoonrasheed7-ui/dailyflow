import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/routine_block.dart';
import '../services/notifications.dart';
import '../services/scheduler.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/card_3d.dart';
import '../widgets/template_picker_dialog.dart';
import '../widgets/time_picker_12h.dart';

class RoutineView extends StatefulWidget {
  final AppData data;
  final Future<void> Function() onChange;

  const RoutineView({super.key, required this.data, required this.onChange});

  @override
  State<RoutineView> createState() => _RoutineViewState();
}

class _RoutineViewState extends State<RoutineView> {
  final nameCtrl = TextEditingController();
  String cat = 'class';
  TimeOfDay? start;
  TimeOfDay? end;
  bool remind = true;

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  void _onFreeGapSelected(Map<String, int> gap) {
    final s = unshiftMin(gap['ss']!);
    final e = unshiftMin(gap['se']!);
    setState(() {
      start = TimeOfDay(hour: s ~/ 60, minute: s % 60);
      end = TimeOfDay(hour: e ~/ 60, minute: e % 60);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected Free Slot: ${hhmm12(s)} – ${hhmm12(e)}. Fill in the details below!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _addBlock() async {
    final name = nameCtrl.text.trim();
    if (name.isEmpty || start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a block name and pick both start and end times (AM/PM).')),
      );
      return;
    }

    final newBlock = RoutineBlock(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      cat: cat,
      start: timeOfDay24(start!),
      end: timeOfDay24(end!),
      remind: remind,
    );

    final hadOverlap = Scheduler.addBlockAndAdjust(widget.data, newBlock);
    nameCtrl.clear();
    setState(() {
      start = null;
      end = null;
      remind = true;
    });

    await widget.onChange();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hadOverlap
                ? 'Routine block added! Overlapping task was moved to unscheduled and free time shifted.'
                : 'Routine block added! Free time automatically adjusted.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gaps = Scheduler.freeGaps(widget.data.blocks);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // 1-Click Routine Templates Bar
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.auto_awesome_mosaic_rounded, size: 18),
          label: const Text('📋 Switch Timetable Mode / Template (Exam, Weekend, Ramadan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          onPressed: () {
            TemplatePickerDialog.show(
              context,
              data: widget.data,
              onTemplateApplied: widget.onChange,
            );
          },
        ),
        const SizedBox(height: 12),

        // 🌅 Dedicated Morning Wake-Up Flow Alarm Card
        TiltCard3D(
          maxTiltAngle: 0.05,
          glowColor: const Color(0xFFFF9F1C),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFF9F1C).withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFFFF9F1C), Color(0xFFFF4B4B)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🌅 Morning Wake-Up Alarm',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              widget.data.morningAlarmEnabled
                                  ? 'Rings daily at ${hhmmStr12(widget.data.morningAlarmTime)} with Challenge'
                                  : 'Alarm is currently disabled',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: widget.data.morningAlarmEnabled
                                    ? const Color(0xFFFF9F1C)
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: widget.data.morningAlarmEnabled ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: widget.data.morningAlarmEnabled,
                      activeColor: const Color(0xFFFF9F1C),
                      onChanged: (val) async {
                        widget.data.morningAlarmEnabled = val;
                        await widget.onChange();
                        setState(() {});
                      },
                    ),
                  ],
                ),
                if (widget.data.morningAlarmEnabled) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: Color(0xFFFF9F1C)),
                          ),
                          icon: const Icon(Icons.alarm, color: Color(0xFFFF9F1C), size: 18),
                          label: Text(
                            'Wake Time: ${hhmmStr12(widget.data.morningAlarmTime)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: () async {
                            final parsed = parseTimeOfDay(widget.data.morningAlarmTime);
                            final picked = await TimePicker12HDialog.show(
                              context,
                              initialTime: parsed,
                              title: 'Pick Morning Wake-Up Time (AM/PM)',
                            );
                            if (picked != null) {
                              widget.data.morningAlarmTime = timeOfDay24(picked);
                              await widget.onChange();
                              setState(() {});
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9F1C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        label: const Text('Test Sound', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        onPressed: () async {
                          final msg = await NotifyService.sendTestNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Available Free Time Windows Banner
        TiltCard3D(
          maxTiltAngle: 0.08,
          glowColor: AppTheme.accent,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Available Free Windows (AM / PM)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap any free window below to auto-fill start & end times into a new routine block.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                if (gaps.isEmpty)
                  const Text('No free gaps currently available.', style: TextStyle(fontSize: 12, color: Colors.grey))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: gaps.map((g) {
                      final s = unshiftMin(g['ss']!);
                      final e = unshiftMin(g['se']!);
                      final dur = g['se']! - g['ss']!;
                      return ActionChip(
                        avatar: const Icon(Icons.add, size: 16, color: AppTheme.accent),
                        label: Text(
                          '${hhmm12(s)} – ${hhmm12(e)} (${formatDuration(dur)})',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                        ),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        onPressed: () => _onFreeGapSelected(g),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Create New Block Card
        TiltCard3D(
          maxTiltAngle: 0.06,
          glowColor: primary,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add New Routine Block',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Block Name / Subject',
                    hintText: 'e.g. MCSE Class, Python Lab, Morning Gym',
                    prefixIcon: const Icon(Icons.label_outline, size: 20),
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
                  onChanged: (v) => setState(() => cat = v!),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // 12-Hour AM/PM Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          start == null ? 'Start (AM/PM)' : timeOfDay12(start!),
                          style: TextStyle(
                            fontWeight: start != null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () async {
                          final t = await TimePicker12HDialog.show(
                            context,
                            initialTime: start ?? TimeOfDay.now(),
                            title: 'Pick Start Time (AM/PM)',
                          );
                          if (t != null) setState(() => start = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.access_time_filled, size: 18),
                        label: Text(
                          end == null ? 'End (AM/PM)' : timeOfDay12(end!),
                          style: TextStyle(
                            fontWeight: end != null ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        onPressed: () async {
                          final t = await TimePicker12HDialog.show(
                            context,
                            initialTime: end ?? TimeOfDay.now(),
                            title: 'Pick End Time (AM/PM)',
                          );
                          if (t != null) setState(() => end = t);
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
                    onChanged: (v) => setState(() => remind = v),
                    title: const Text('Schedule Reminder Alarm', style: TextStyle(fontSize: 13.5)),
                    subtitle: const Text('Plays alarm & pushes notification', style: TextStyle(fontSize: 11)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 18),
                  label: const Text('Save Block & Auto-Shift Free Time', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: _addBlock,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Routine Blocks List
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Fixed Routine Blocks',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.data.blocks.length} blocks',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.data.blocks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No fixed routine blocks yet. Add one above!'),
            ),
          )
        else
          ...widget.data.blocks.map((b) {
            final catObj = BlockCategory.fromKey(b.cat);
            return TiltCard3D(
              maxTiltAngle: 0.07,
              glowColor: catObj.lightColor,
              borderColor: catObj.lightColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.getCategoryGradient(b.cat, isDark),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catObj.lightColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(catObj.icon, color: catObj.lightColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hhmmStr12(b.start)} – ${hhmmStr12(b.end)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b.name,
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${catObj.label}${b.remind ? ' · 🔔 Reminder Active' : ''}',
                            style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    // Convert to Free Time button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      tooltip: 'Convert slot to Free Time',
                      onPressed: () async {
                        Scheduler.deleteBlockAndFreeSlot(widget.data, b.id);
                        await widget.onChange();
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
          }),
      ],
    );
  }
}
