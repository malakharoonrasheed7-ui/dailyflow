import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../screens/alarm_mission_dialog.dart';
import '../services/notifications.dart';
import '../services/time_utils.dart';
import '../theme/app_theme.dart';
import '../widgets/card_3d.dart';
import '../widgets/time_picker_12h.dart';

class SettingsView extends StatefulWidget {
  final AppData data;
  final Future<void> Function() onChange;
  final String soundPath;
  final void Function(String) onSoundPathChange;
  final Future<String> Function() onWindowsSync;

  const SettingsView({
    super.key,
    required this.data,
    required this.onChange,
    required this.soundPath,
    required this.onSoundPathChange,
    required this.onWindowsSync,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late TextEditingController practiceCtrl;
  late TextEditingController socialCtrl;
  late TextEditingController soundCtrl;
  String syncReport = '';

  @override
  void initState() {
    super.initState();
    practiceCtrl = TextEditingController(text: widget.data.practice.toString());
    socialCtrl = TextEditingController(text: widget.data.social.toString());
    soundCtrl = TextEditingController(text: widget.soundPath);
  }

  @override
  void dispose() {
    practiceCtrl.dispose();
    socialCtrl.dispose();
    soundCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDarkTime(bool isStart) async {
    final current = isStart ? widget.data.darkStart : widget.data.darkEnd;
    final parsed = parseTimeOfDay(current);

    final t = await TimePicker12HDialog.show(
      context,
      initialTime: parsed,
      title: isStart ? 'Dark Mode Start Time (AM/PM)' : 'Dark Mode End Time (AM/PM)',
    );

    if (t == null) return;
    final formatted = timeOfDay24(t);
    if (isStart) {
      widget.data.darkStart = formatted;
    } else {
      widget.data.darkEnd = formatted;
    }
    await widget.onChange();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        // Theme & Appearance
        TiltCard3D(
          maxTiltAngle: 0.05,
          glowColor: AppTheme.secondary,
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
                const Row(
                  children: [
                    Icon(Icons.palette_outlined, color: AppTheme.secondary, size: 20),
                    SizedBox(width: 8),
                    Text('Appearance & Dark Window', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Set your preferred theme mode or customize your exact AM/PM dark mode window.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'auto', label: Text('Auto (Window)'), icon: Icon(Icons.schedule, size: 16)),
                    ButtonSegment(value: 'dark', label: Text('Dark'), icon: Icon(Icons.dark_mode, size: 16)),
                    ButtonSegment(value: 'light', label: Text('Light'), icon: Icon(Icons.light_mode, size: 16)),
                  ],
                  selected: {widget.data.themeMode},
                  onSelectionChanged: (set) async {
                    widget.data.themeMode = set.first;
                    await widget.onChange();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.nightlight_round, size: 16),
                        label: Text('Starts: ${hhmmStr12(widget.data.darkStart)}'),
                        onPressed: () => _pickDarkTime(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.wb_sunny_rounded, size: 16),
                        label: Text('Ends: ${hhmmStr12(widget.data.darkEnd)}'),
                        onPressed: () => _pickDarkTime(false),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Daily Targets
        TiltCard3D(
          maxTiltAngle: 0.05,
          glowColor: AppTheme.primary,
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
                const Row(
                  children: [
                    Icon(Icons.track_changes_rounded, color: AppTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text('Daily Routine Allocation Targets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: practiceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Practice Target (min)',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: socialCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Social Target (min)',
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    widget.data.practice = int.tryParse(practiceCtrl.text) ?? widget.data.practice;
                    widget.data.social = int.tryParse(socialCtrl.text) ?? widget.data.social;
                    await widget.onChange();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Daily targets updated!')),
                      );
                    }
                  },
                  child: const Text('Save Targets'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Notifications & Alarms
        TiltCard3D(
          maxTiltAngle: 0.05,
          glowColor: const Color(0xFF10B981),
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
                const Row(
                  children: [
                    Icon(Icons.notifications_active_outlined, color: Color(0xFF10B981), size: 20),
                    SizedBox(width: 8),
                    Text('Alarms & Persistent Ringtones (Offline)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Embedded Ringtone: alarm.wav & alarm.mp3 saved permanently in app assets.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'When an alarm fires, it will ring continuously in a loop until you tap "Stop Alarm" or click OK. Works even when the app is completely closed or device restarted.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),

                // Dedicated Morning Alarm Toggle & Picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF9F1C).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.wb_sunny_rounded, color: Color(0xFFFF9F1C), size: 18),
                              SizedBox(width: 8),
                              Text('Morning Wake-Up Alarm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Color(0xFFFF9F1C)),
                          ),
                          icon: const Icon(Icons.access_time_rounded, color: Color(0xFFFF9F1C), size: 18),
                          label: Text(
                            'Daily Alarm Time: ${hhmmStr12(widget.data.morningAlarmTime)}',
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
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Alarm Dismiss Mission:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'math', label: Text('Math Puzzle 🧠'), icon: Icon(Icons.calculate_outlined, size: 16)),
                    ButtonSegment(value: 'taps', label: Text('5 Rapid Taps 👆'), icon: Icon(Icons.touch_app_outlined, size: 16)),
                    ButtonSegment(value: 'simple', label: Text('Simple Stop'), icon: Icon(Icons.stop_circle_outlined, size: 16)),
                  ],
                  selected: {widget.data.alarmMissionType},
                  onSelectionChanged: (set) async {
                    widget.data.alarmMissionType = set.first;
                    await widget.onChange();
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await NotifyService.requestPermissions();
                          setState(() {});
                        },
                        child: const Text('Permissions', style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.volume_up_rounded, size: 16),
                        label: const Text('Test Alarm Sound', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          final res = await NotifyService.sendTestNow();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.psychology_rounded, size: 18),
                  label: const Text('🎮 Test Alarm Morning Challenge Modal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () {
                    AlarmMissionDialog.show(
                      context,
                      title: '⏰ Wake-Up Morning Challenge',
                      message: 'Solve the challenge to stop the ringing alarm!',
                      missionType: widget.data.alarmMissionType,
                    );
                  },
                ),
                const SizedBox(height: 8),
                // 1-Minute App Close Test Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9F1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.timer_outlined, size: 18),
                  label: const Text('⏰ Schedule 1-Min Alarm (Close App to Test)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  onPressed: () async {
                    final res = await NotifyService.scheduleTestAlarmInOneMinute();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                  label: const Text('🔊 Test Windows Looping Alarm (PC)', style: TextStyle(fontSize: 12)),
                  onPressed: () => WindowsTaskSync.testWindowsAlarmLoop(soundCtrl.text.trim()),
                ),
                const SizedBox(height: 14),

                // OEM Background Guide Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.phone_android_rounded, size: 16, color: AppTheme.primary),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Android Background & Offline Guide (Xiaomi / Samsung / Oppo)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '1. Set Battery Saver to "No restrictions" (App Info > Battery saver).\n'
                        '2. Turn ON "Autostart" in App Info.\n'
                        '3. Ensure device Alarm Volume is turned UP.',
                        style: TextStyle(fontSize: 11, height: 1.4, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Windows Task Sync
                TextField(
                  controller: soundCtrl,
                  decoration: InputDecoration(
                    labelText: 'Windows: Sound .wav Path',
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.sync_alt_rounded, size: 16),
                  label: const Text('Sync to Windows Task Scheduler'),
                  onPressed: () async {
                    widget.onSoundPathChange(soundCtrl.text.trim());
                    final report = await widget.onWindowsSync();
                    setState(() => syncReport = report);
                  },
                ),
                if (syncReport.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(syncReport, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Reset Data
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.restore_rounded),
          label: const Text('Reset All Data to Defaults'),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Reset All Data?'),
                content: const Text('This will reset your routine blocks and tasks back to defaults. This action cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Reset', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              final defaults = AppData.defaults();
              widget.data.blocks
                ..clear()
                ..addAll(defaults.blocks);
              widget.data.tasks
                ..clear()
                ..addAll(defaults.tasks);
              widget.data.practice = 90;
              widget.data.social = 45;
              await widget.onChange();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data has been reset to defaults!')),
                );
              }
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
