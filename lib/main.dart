import 'dart:async';
import 'package:flutter/material.dart';
import 'models/app_data.dart';
import 'screens/alarm_mission_dialog.dart';
import 'services/alarm_audio_service.dart';
import 'services/notifications.dart';
import 'services/storage.dart';
import 'services/time_utils.dart';
import 'theme/app_theme.dart';
import 'views/about_view.dart';
import 'views/analytics_view.dart';
import 'views/routine_view.dart';
import 'views/settings_view.dart';
import 'views/tasks_view.dart';
import 'views/timetable_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotifyService.init();
  runApp(const DailyFlowApp());
}

class DailyFlowApp extends StatefulWidget {
  const DailyFlowApp({super.key});

  @override
  State<DailyFlowApp> createState() => _DailyFlowAppState();
}

class _DailyFlowAppState extends State<DailyFlowApp> {
  AppData? data;
  int tab = 0;
  String soundPath = r'C:\DailyFlow\alarm.wav';
  Timer? _clockTicker;
  String? _lastAlarmTriggeredTime;

  @override
  void initState() {
    super.initState();
    _load();
    // Update every 15s to check minute boundaries for live alarms and recalculate time markers
    _clockTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _checkLiveAlarms();
        setState(() {});
      }
    });
  }

  void _checkLiveAlarms() {
    if (data == null) return;
    final now = DateTime.now();
    final currentHHMM = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    if (_lastAlarmTriggeredTime == currentHHMM) return;

    bool shouldTrigger = false;
    String alarmTitle = 'DailyFlow Alarm';
    String alarmMsg = 'Time to switch routines and stay in flow!';

    // 1. Morning Alarm check
    if (data!.morningAlarmEnabled && data!.morningAlarmTime == currentHHMM) {
      shouldTrigger = true;
      alarmTitle = '🌅 Morning Wake-Up Flow Alarm';
      alarmMsg = 'Good morning! Time to wake up and start your daily flow.';
    }

    // 2. Routine Blocks check
    if (!shouldTrigger) {
      for (final b in data!.blocks.where((b) => b.remind)) {
        if (b.start == currentHHMM) {
          shouldTrigger = true;
          alarmTitle = '⏰ Routine Block: ${b.name}';
          alarmMsg = 'Scheduled block starting now (${hhmmStr12(b.start)}).';
          break;
        }
      }
    }

    // 3. Tasks check
    if (!shouldTrigger) {
      for (final t in data!.tasks.where((t) => t.scheduled && t.ss != null)) {
        final taskActual = unshiftMin(t.ss!);
        final taskHHMM = '${(taskActual ~/ 60).toString().padLeft(2, '0')}:${(taskActual % 60).toString().padLeft(2, '0')}';
        if (taskHHMM == currentHHMM) {
          shouldTrigger = true;
          alarmTitle = '📋 Task: ${t.name}';
          alarmMsg = 'Scheduled focus task starting now.';
          break;
        }
      }
    }

    if (shouldTrigger) {
      _lastAlarmTriggeredTime = currentHHMM;
      AlarmAudioService.playLooping();
      if (mounted) {
        AlarmMissionDialog.show(
          context,
          title: alarmTitle,
          message: alarmMsg,
          missionType: data!.alarmMissionType,
        );
      }
    }
  }

  @override
  void dispose() {
    _clockTicker?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final d = await Storage.load();
    d.autoCheckInToday();
    setState(() => data = d);
    await Storage.save(d);
    await _resync();
  }

  Future<void> _persist() async {
    if (data == null) return;
    await Storage.save(data!);
    setState(() {});
    await _resync();
  }

  Future<void> _resync() async {
    if (data == null) return;
    await NotifyService.resyncAll(data!);
  }

  ThemeData _getCurrentTheme() {
    if (data == null) return AppTheme.darkTheme;
    return AppTheme.isNightNow(data!) ? AppTheme.darkTheme : AppTheme.lightTheme;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _getCurrentTheme();

    return MaterialApp(
      title: 'DailyFlow',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: data == null
          ? const Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your schedule...'),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 850;
                final views = [
                  TimetableView(
                    data: data!,
                    onChange: _persist,
                    onNavigateTab: (idx) => setState(() => tab = idx),
                  ),
                  RoutineView(data: data!, onChange: _persist),
                  TasksView(data: data!, onChange: _persist),
                  AnalyticsView(data: data!, onChange: _persist),
                  SettingsView(
                    data: data!,
                    onChange: _persist,
                    soundPath: soundPath,
                    onSoundPathChange: (p) => setState(() => soundPath = p),
                    onWindowsSync: () => WindowsTaskSync.syncAll(data!, soundPath),
                  ),
                  AboutView(data: data!, onChange: _persist),
                ];

                final titles = [
                  'Timetable & Day Flow',
                  'Daily Routine',
                  'Tasks & Planner',
                  'Analytics & Streaks',
                  'Settings & Sync',
                  'About DailyFlow',
                ];

                return Scaffold(
                  appBar: AppBar(
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titles[tab],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${hhmm12(DateTime.now().hour * 60 + DateTime.now().minute)} · ${getDayPeriod(DateTime.now().hour * 60 + DateTime.now().minute)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      IconButton(
                        tooltip: 'Toggle Theme',
                        icon: Icon(
                          AppTheme.isNightNow(data!) ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          size: 20,
                        ),
                        onPressed: () async {
                          final currentMode = data!.themeMode;
                          if (currentMode == 'dark') {
                            data!.themeMode = 'light';
                          } else if (currentMode == 'light') {
                            data!.themeMode = 'auto';
                          } else {
                            data!.themeMode = 'dark';
                          }
                          await _persist();
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                  body: Column(
                    children: [
                      // Active Alarm Ringing Banner (Loops non-stop until dismissed)
                      ValueListenableBuilder<bool>(
                        valueListenable: AlarmAudioService.isRingingNotifier,
                        builder: (ctx, isRinging, _) {
                          if (!isRinging) return const SizedBox.shrink();
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.redAccent, blurRadius: 16, spreadRadius: 2),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.alarm_on_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '🔔 ALARM IS RINGING!',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      Text(
                                        'Plays continuously until you stop it.',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.red.shade800,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                                  label: const Text('DISMISS / SOLVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  onPressed: () async {
                                    if (data?.alarmMissionType == 'simple') {
                                      await AlarmAudioService.stop();
                                      await NotifyService.cancelAll();
                                    } else {
                                      AlarmMissionDialog.show(
                                        context,
                                        title: '⏰ Wake-Up Alarm Mission',
                                        message: 'Complete the challenge to silence your scheduled alarm!',
                                        missionType: data?.alarmMissionType ?? 'math',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      Expanded(
                        child: isDesktop
                            ? Row(
                                children: [
                                  // Desktop Navigation Rail
                                  NavigationRail(
                                    selectedIndex: tab,
                                    onDestinationSelected: (i) => setState(() => tab = i),
                                    labelType: NavigationRailLabelType.all,
                                    leading: const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Icon(Icons.hourglass_top_rounded, color: AppTheme.primary, size: 28),
                                    ),
                                    destinations: const [
                                      NavigationRailDestination(
                                        icon: Icon(Icons.today_outlined),
                                        selectedIcon: Icon(Icons.today, color: AppTheme.primary),
                                        label: Text('Timetable'),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.schedule_outlined),
                                        selectedIcon: Icon(Icons.schedule, color: AppTheme.primary),
                                        label: Text('Routine'),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.task_alt_outlined),
                                        selectedIcon: Icon(Icons.task_alt, color: AppTheme.primary),
                                        label: Text('Tasks'),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.local_fire_department_outlined),
                                        selectedIcon: Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B00)),
                                        label: Text('Analytics'),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.settings_outlined),
                                        selectedIcon: Icon(Icons.settings, color: AppTheme.primary),
                                        label: Text('Settings'),
                                      ),
                                      NavigationRailDestination(
                                        icon: Icon(Icons.info_outline),
                                        selectedIcon: Icon(Icons.info, color: AppTheme.primary),
                                        label: Text('About'),
                                      ),
                                    ],
                                  ),
                                  const VerticalDivider(thickness: 1, width: 1),
                                  // Centered Desktop Content Area
                                  Expanded(
                                    child: Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(maxWidth: 1000),
                                        child: views[tab],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : views[tab],
                      ),
                    ],
                  ),
                  bottomNavigationBar: isDesktop
                      ? null
                      : NavigationBar(
                          selectedIndex: tab,
                          onDestinationSelected: (i) => setState(() => tab = i),
                          destinations: const [
                            NavigationDestination(
                              icon: Icon(Icons.today_outlined),
                              selectedIcon: Icon(Icons.today, color: AppTheme.primary),
                              label: 'Timetable',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.schedule_outlined),
                              selectedIcon: Icon(Icons.schedule, color: AppTheme.primary),
                              label: 'Routine',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.task_alt_outlined),
                              selectedIcon: Icon(Icons.task_alt, color: AppTheme.primary),
                              label: 'Tasks',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.local_fire_department_outlined),
                              selectedIcon: Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B00)),
                              label: 'Analytics',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.settings_outlined),
                              selectedIcon: Icon(Icons.settings, color: AppTheme.primary),
                              label: 'Settings',
                            ),
                            NavigationDestination(
                              icon: Icon(Icons.info_outline),
                              selectedIcon: Icon(Icons.info, color: AppTheme.primary),
                              label: 'About',
                            ),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
