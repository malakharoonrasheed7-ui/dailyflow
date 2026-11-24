import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/alarm_audio_service.dart';
import '../services/notifications.dart';
import '../theme/app_theme.dart';

class AlarmMissionDialog extends StatefulWidget {
  final String title;
  final String message;
  final String missionType; // 'simple', 'math', 'taps'
  final VoidCallback? onDismissed;

  const AlarmMissionDialog({
    super.key,
    this.title = '⏰ Scheduled Routine Alarm',
    this.message = 'Time to switch your routine block and stay in flow!',
    this.missionType = 'math',
    this.onDismissed,
  });

  static Future<void> show(
    BuildContext context, {
    String title = '⏰ Scheduled Routine Alarm',
    String message = 'Time to switch your routine block and stay in flow!',
    String missionType = 'math',
    VoidCallback? onDismissed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlarmMissionDialog(
        title: title,
        message: message,
        missionType: missionType,
        onDismissed: onDismissed,
      ),
    );
  }

  @override
  State<AlarmMissionDialog> createState() => _AlarmMissionDialogState();
}

class _AlarmMissionDialogState extends State<AlarmMissionDialog> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // Math Puzzle State
  late int num1;
  late int num2;
  late int expectedAnswer;
  final answerCtrl = TextEditingController();
  String? mathError;

  // Rapid Taps State
  int tapCount = 0;
  final int requiredTaps = 5;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _generateMath();
  }

  void _generateMath() {
    final rng = Random();
    num1 = rng.nextInt(35) + 12;
    num2 = rng.nextInt(35) + 11;
    expectedAnswer = num1 + num2;
    answerCtrl.clear();
    mathError = null;
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _silenceAndClose() async {
    await AlarmAudioService.stop();
    await NotifyService.cancel(9999);
    widget.onDismissed?.call();
    if (mounted) Navigator.of(context).pop();
  }

  void _verifyMath() {
    final userVal = int.tryParse(answerCtrl.text.trim());
    if (userVal == expectedAnswer) {
      _silenceAndClose();
    } else {
      setState(() {
        mathError = 'Wrong answer! Try again to stop alarm.';
        _generateMath();
      });
    }
  }

  void _registerTap() {
    setState(() {
      tapCount++;
      if (tapCount >= requiredTaps) {
        _silenceAndClose();
      }
    });
  }

  Future<void> _snooze(int minutes) async {
    await AlarmAudioService.stop();
    final now = DateTime.now().add(Duration(minutes: minutes));
    await NotifyService.scheduleExactAlarm(
      id: 9998,
      title: '⏰ SNOOZED: ${widget.title}',
      body: widget.message,
      scheduledDate: now,
    );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alarm snoozed for $minutes minutes!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: ScaleTransition(
          scale: _pulseAnim,
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFFF4B4B), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4B4B).withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Alarm Icon Badge
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF0000)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF0000).withValues(alpha: 0.5),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 38),
                  ),
                  const SizedBox(height: 14),

                  // Title & Message
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Mission Area
                  if (widget.missionType == 'math') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.psychology_rounded, size: 20, color: AppTheme.accent),
                              SizedBox(width: 6),
                              Text('Morning Math Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '$num1  +  $num2  =  ?',
                            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 2),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: answerCtrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            autofocus: true,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Enter sum to stop',
                              errorText: mathError,
                              filled: true,
                              fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            ),
                            onSubmitted: (_) => _verifyMath(),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 20),
                            label: const Text('Solve & Stop Alarm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: _verifyMath,
                          ),
                        ],
                      ),
                    ),
                  ] else if (widget.missionType == 'taps') ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFF9F1C).withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.touch_app_rounded, size: 20, color: Color(0xFFFF9F1C)),
                              SizedBox(width: 6),
                              Text('Rapid Tap Mission', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Tap the button $requiredTaps times rapidly to wake up:'),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF9F1C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: _registerTap,
                            child: Text(
                              'TAP TO STOP ($tapCount / $requiredTaps)',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Simple Stop Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B4B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.stop_circle_rounded, size: 24),
                      label: const Text('STOP ALARM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                      onPressed: _silenceAndClose,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Snooze Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.snooze_rounded, size: 16),
                          label: const Text('Snooze 5m', style: TextStyle(fontSize: 12)),
                          onPressed: () => _snooze(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.snooze_rounded, size: 16),
                          label: const Text('Snooze 10m', style: TextStyle(fontSize: 12)),
                          onPressed: () => _snooze(10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
