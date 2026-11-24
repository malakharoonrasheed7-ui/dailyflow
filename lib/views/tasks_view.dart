import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../models/task_item.dart';
import '../services/scheduler.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/card_3d.dart';
import '../widgets/time_picker_12h.dart';

enum TaskScheduleMode { exactTime, freeSlot, unscheduled }

class TasksView extends StatefulWidget {
  final AppData data;
  final Future<void> Function() onChange;

  const TasksView({super.key, required this.data, required this.onChange});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  final nameCtrl = TextEditingController();
  final durCtrl = TextEditingController(text: '15');
  String priority = 'medium';
  TaskScheduleMode scheduleMode = TaskScheduleMode.exactTime;

  TimeOfDay customStartTime = TimeOfDay.now();
  Map<String, dynamic>? selectedFreeSlot;

  @override
  void dispose() {
    nameCtrl.dispose();
    durCtrl.dispose();
    super.dispose();
  }

  Color _getPriorityColor(String prio) {
    switch (prio) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  int _getDuration() {
    final d = int.tryParse(durCtrl.text.trim());
    return (d != null && d > 0) ? d : 15;
  }

  TimeOfDay _getCalculatedEndTime(TimeOfDay start, int durMin) {
    final totalMin = (start.hour * 60 + start.minute + durMin) % 1440;
    return TimeOfDay(hour: totalMin ~/ 60, minute: totalMin % 60);
  }

  Future<void> _addTask() async {
    final name = nameCtrl.text.trim();
    final dur = int.tryParse(durCtrl.text.trim());
    if (name.isEmpty || dur == null || dur <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid task name and duration (e.g. 10 min).')),
      );
      return;
    }

    final task = TaskItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      duration: dur,
      priority: priority,
    );

    if (scheduleMode == TaskScheduleMode.exactTime) {
      final startMin = customStartTime.hour * 60 + customStartTime.minute;
      final shiftedStart = shiftMin(startMin);
      task.scheduled = true;
      task.ss = shiftedStart;
      task.se = shiftedStart + dur;
    } else if (scheduleMode == TaskScheduleMode.freeSlot && selectedFreeSlot != null) {
      final slotDur = (selectedFreeSlot!['se'] as int) - (selectedFreeSlot!['ss'] as int);
      if (dur > slotDur) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task duration ($dur min) exceeds the selected free slot ($slotDur min).')),
        );
        return;
      }
      task.scheduled = true;
      task.ss = selectedFreeSlot!['ss'];
      task.se = selectedFreeSlot!['ss'] + dur;
    } else {
      task.scheduled = false;
      task.ss = null;
      task.se = null;
    }

    widget.data.tasks.add(task);
    nameCtrl.clear();
    setState(() {
      selectedFreeSlot = null;
    });
    await widget.onChange();

    if (mounted) {
      final message = task.scheduled && task.ss != null && task.se != null
          ? '✅ Task scheduled at ${hhmm12(unshiftMin(task.ss!))} – ${hhmm12(unshiftMin(task.se!))} ($dur min)!'
          : '📥 Task added to unscheduled pool!';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showEditTaskDialog(TaskItem task) {
    final editNameCtrl = TextEditingController(text: task.name);
    final editDurCtrl = TextEditingController(text: task.duration.toString());
    String editPriority = task.priority;
    bool isScheduled = task.scheduled;
    TimeOfDay editStartTime = task.ss != null
        ? TimeOfDay(hour: unshiftMin(task.ss!) ~/ 60, minute: unshiftMin(task.ss!) % 60)
        : TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final isDark = Theme.of(modalCtx).brightness == Brightness.dark;
          final primary = Theme.of(modalCtx).colorScheme.primary;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '✏️ Edit / Reschedule Task',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(modalCtx).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: editNameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Task Title',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: editDurCtrl,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration (min)',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: editPriority,
                          items: const [
                            DropdownMenuItem(value: 'high', child: Text('🔴 High')),
                            DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
                            DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
                          ],
                          onChanged: (v) => setModalState(() => editPriority = v!),
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Quick Duration Chips for edit modal
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [10, 15, 20, 30, 45, 60, 90].map((m) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text('${m}m', style: const TextStyle(fontSize: 11)),
                            onPressed: () => setModalState(() => editDurCtrl.text = m.toString()),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isScheduled,
                      onChanged: (v) => setModalState(() => isScheduled = v),
                      title: const Text('Schedule at Exact Time (AM/PM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: Text(
                        isScheduled ? 'Task is placed in timeline' : 'Unscheduled pool (Auto-fit later)',
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ),
                  ),
                  if (isScheduled) ...[
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.access_time_filled, size: 20, color: AppTheme.accent),
                      label: Text(
                        'Start Time: ${timeOfDay12(editStartTime)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      onPressed: () async {
                        final t = await TimePicker12HDialog.show(
                          modalCtx,
                          initialTime: editStartTime,
                          title: 'Set Task Start Time (AM/PM)',
                        );
                        if (t != null) setModalState(() => editStartTime = t);
                      },
                    ),
                  ],
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final n = editNameCtrl.text.trim();
                      final d = int.tryParse(editDurCtrl.text.trim());
                      if (n.isEmpty || d == null || d <= 0) return;

                      task.name = n;
                      task.duration = d;
                      task.priority = editPriority;

                      if (isScheduled) {
                        final startMin = editStartTime.hour * 60 + editStartTime.minute;
                        final shifted = shiftMin(startMin);
                        task.scheduled = true;
                        task.ss = shifted;
                        task.se = shifted + d;
                      } else {
                        task.scheduled = false;
                        task.ss = null;
                        task.se = null;
                      }

                      await widget.onChange();
                      if (modalCtx.mounted) Navigator.of(modalCtx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Task updated successfully!')),
                        );
                      }
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final freeSlots = Scheduler.taskSlotOptions(widget.data);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    final pendingCount = widget.data.tasks.where((t) => !t.scheduled).length;
    final scheduledCount = widget.data.tasks.where((t) => t.scheduled).length;
    final duration = _getDuration();
    final calculatedEndTime = _getCalculatedEndTime(customStartTime, duration);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Add Task Card
        TiltCard3D(
          maxTiltAngle: 0.06,
          glowColor: const Color(0xFFFF9F1C),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131B2A) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '⚡ Add New Task / Activity',
                      style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F1C).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '12-Hour AM/PM Custom',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFFF9F1C)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    hintText: 'e.g. 10m Quick Revision, Python Lab, Gym',
                    prefixIcon: const Icon(Icons.assignment_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: durCtrl,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Duration (min)',
                          prefixIcon: const Icon(Icons.timelapse_rounded, size: 20),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        items: const [
                          DropdownMenuItem(
                            value: 'high',
                            child: Row(children: [
                              Icon(Icons.flag_rounded, size: 16, color: Color(0xFFEF4444)),
                              SizedBox(width: 6),
                              Text('High'),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Row(children: [
                              Icon(Icons.flag_rounded, size: 16, color: Color(0xFFF59E0B)),
                              SizedBox(width: 6),
                              Text('Medium'),
                            ]),
                          ),
                          DropdownMenuItem(
                            value: 'low',
                            child: Row(children: [
                              Icon(Icons.flag_rounded, size: 16, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Text('Low'),
                            ]),
                          ),
                        ],
                        onChanged: (v) => setState(() => priority = v!),
                        decoration: InputDecoration(
                          labelText: 'Priority',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Quick Duration Preset Chips (including 10m, 15m, 20m, 30m, 45m, 60m)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [10, 15, 20, 30, 45, 60, 90, 120].map((m) {
                      final isSelected = durCtrl.text.trim() == m.toString();
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('${m}m', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                          selected: isSelected,
                          selectedColor: const Color(0xFFFF9F1C).withValues(alpha: 0.25),
                          onSelected: (_) => setState(() => durCtrl.text = m.toString()),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Schedule Mode Selector Tabs
                const Text(
                  'Choose Timing & Scheduling Option:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SegmentedButton<TaskScheduleMode>(
                  segments: const [
                    ButtonSegment(
                      value: TaskScheduleMode.exactTime,
                      label: Text('Exact Time', style: TextStyle(fontSize: 11.5)),
                      icon: Icon(Icons.access_time_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: TaskScheduleMode.freeSlot,
                      label: Text('Free Slots', style: TextStyle(fontSize: 11.5)),
                      icon: Icon(Icons.bolt_rounded, size: 15),
                    ),
                    ButtonSegment(
                      value: TaskScheduleMode.unscheduled,
                      label: Text('Auto-Fit Pool', style: TextStyle(fontSize: 11.5)),
                      icon: Icon(Icons.inbox_rounded, size: 15),
                    ),
                  ],
                  selected: {scheduleMode},
                  onSelectionChanged: (set) => setState(() => scheduleMode = set.first),
                ),
                const SizedBox(height: 12),

                // MODE 1: Exact Custom 12-Hour AM/PM Time
                if (scheduleMode == TaskScheduleMode.exactTime) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Selected Start Time (AM / PM):', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeOfDay12(customStartTime),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.accent),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accent,
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              icon: const Icon(Icons.schedule, size: 16),
                              label: const Text('Change Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () async {
                                final t = await TimePicker12HDialog.show(
                                  context,
                                  initialTime: customStartTime,
                                  title: 'Select Task Start Time (AM / PM)',
                                );
                                if (t != null) setState(() => customStartTime = t);
                              },
                            ),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Will run: ${timeOfDay12(customStartTime)} – ${timeOfDay12(calculatedEndTime)} ($duration min)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // MODE 2: Pick from Free Slots
                if (scheduleMode == TaskScheduleMode.freeSlot) ...[
                  if (freeSlots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('No free time slots available right now. You can pick Exact Time above!', style: TextStyle(fontSize: 12)),
                    )
                  else
                    DropdownButtonFormField<Map<String, dynamic>?>(
                      initialValue: selectedFreeSlot,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('👉 Select an available Free Time Slot...'),
                        ),
                        ...freeSlots.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s['label'], style: const TextStyle(fontSize: 12.5)),
                            )),
                      ],
                      onChanged: (v) => setState(() => selectedFreeSlot = v),
                      decoration: InputDecoration(
                        labelText: 'Available Free Time Window (AM/PM)',
                        prefixIcon: const Icon(Icons.bolt_rounded, color: AppTheme.accent, size: 20),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                ],

                // MODE 3: Unscheduled Pool
                if (scheduleMode == TaskScheduleMode.unscheduled) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 18, color: AppTheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Task will be saved into the Unscheduled Pool. You can tap "Auto-Fit" to instantly place it in free time gaps.',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_task_rounded, size: 20),
                  label: Text(
                    scheduleMode == TaskScheduleMode.exactTime
                        ? 'Add Task (${timeOfDay12(customStartTime)} · $duration min)'
                        : 'Add Task to Schedule',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Auto-Schedule Card
        if (pendingCount > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary.withValues(alpha: 0.2), AppTheme.secondary.withValues(alpha: 0.15)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ $pendingCount unscheduled tasks in pool',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'Auto-fit them into available free time windows instantly.',
                        style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  onPressed: () async {
                    final count = Scheduler.autoSchedule(widget.data);
                    await widget.onChange();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fitted $count task(s) into free time!')),
                      );
                    }
                  },
                  child: const Text('Auto-Fit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),

        // Tasks Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Task List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              '$scheduledCount scheduled · $pendingCount pending',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.data.tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No tasks yet. Create your first task above!'),
            ),
          )
        else
          ...widget.data.tasks.map((t) {
            final prioColor = _getPriorityColor(t.priority);
            final timeInfo = t.scheduled && t.ss != null && t.se != null
                ? '${hhmm12(unshiftMin(t.ss!))} – ${hhmm12(unshiftMin(t.se!))}'
                : 'Not scheduled (Pool)';

            return TiltCard3D(
              maxTiltAngle: 0.07,
              glowColor: prioColor,
              borderColor: prioColor.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131B2A) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    // Completion Checkbox
                    Checkbox(
                      value: t.isCompleted,
                      activeColor: primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (v) async {
                        setState(() => t.isCompleted = v ?? false);
                        await widget.onChange();
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              decoration: t.isCompleted ? TextDecoration.lineThrough : null,
                              color: t.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: prioColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  t.priority.toUpperCase(),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: prioColor),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${t.duration}m · $timeInfo',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: t.scheduled ? AppTheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: t.scheduled ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Edit / Reschedule Task Button
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      tooltip: 'Edit / Reschedule Time',
                      onPressed: () => _showEditTaskDialog(t),
                    ),
                    // If scheduled, option to unschedule (return to free time)
                    if (t.scheduled)
                      IconButton(
                        icon: const Icon(Icons.undo_rounded, size: 18),
                        tooltip: 'Unschedule (Free this slot)',
                        onPressed: () async {
                          setState(() {
                            t.scheduled = false;
                            t.ss = null;
                            t.se = null;
                          });
                          await widget.onChange();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task unscheduled and time slot freed!')),
                            );
                          }
                        },
                      ),
                    // Delete Task button
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      tooltip: 'Delete task',
                      onPressed: () async {
                        widget.data.tasks.removeWhere((x) => x.id == t.id);
                        await widget.onChange();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task deleted!')),
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
