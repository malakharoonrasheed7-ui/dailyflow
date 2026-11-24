import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import '../models/app_data.dart';
import 'time_utils.dart';

import 'alarm_audio_service.dart';

@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  AlarmAudioService.stop();
}

void onNotificationResponse(NotificationResponse response) {
  AlarmAudioService.stop();
}

class NotifyService {
  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static bool notificationsGranted = false;
  static bool exactAlarmsGranted = false;

  /// Ensures alarm sound files are extracted and ready on local storage
  static Future<String> ensureSoundFilesInstalled() async {
    if (kIsWeb) return '';
    try {
      if (Platform.isWindows) {
        final byteData = await rootBundle.load('assets/audio/alarm.wav');
        final bytes = byteData.buffer.asUint8List();

        // 1. Install to C:\DailyFlow\alarm.wav
        try {
          final dir1 = Directory(r'C:\DailyFlow');
          if (!await dir1.exists()) await dir1.create(recursive: true);
          final file1 = File(r'C:\DailyFlow\alarm.wav');
          await file1.writeAsBytes(bytes);
        } catch (_) {}

        // 2. Install to LocalAppData\DailyFlow\alarm.wav as resilient fallback
        final localAppData = Platform.environment['LOCALAPPDATA'] ?? r'C:\';
        final dir2 = Directory('$localAppData\\DailyFlow');
        if (!await dir2.exists()) await dir2.create(recursive: true);
        final file2 = File('$localAppData\\DailyFlow\\alarm.wav');
        await file2.writeAsBytes(bytes);

        return file2.path;
      }
    } catch (_) {}
    return r'C:\DailyFlow\alarm.wav';
  }

  static Future<void> init() async {
    await ensureSoundFilesInstalled();
    await AlarmAudioService.init();
    if (kIsWeb || !Platform.isAndroid) return;

    tzdata.initializeTimeZones();

    final now = DateTime.now();
    final offset = now.timeZoneOffset;

    // Resolve exact matching timezone location from database
    tz.Location? matchedLocation;
    try {
      if (tz.timeZoneDatabase.locations.containsKey(now.timeZoneName)) {
        matchedLocation = tz.getLocation(now.timeZoneName);
      }
    } catch (_) {}

    if (matchedLocation == null) {
      for (final loc in tz.timeZoneDatabase.locations.values) {
        if (loc.currentTimeZone.offset == offset.inMilliseconds) {
          matchedLocation = loc;
          break;
        }
      }
    }

    if (matchedLocation == null) {
      final wholeHours = (offset.inMinutes / 60).round();
      final etcName = wholeHours == 0 ? 'Etc/GMT' : 'Etc/GMT${wholeHours > 0 ? '-' : '+'}${wholeHours.abs()}';
      try {
        matchedLocation = tz.getLocation(etcName);
      } catch (_) {
        matchedLocation = tz.UTC;
      }
    }

    tz.setLocalLocation(matchedLocation);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: onNotificationResponse,
        onDidReceiveBackgroundNotificationResponse: onBackgroundNotificationResponse,
      );
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }

    // Explicitly create the high-priority loud alarm channel with sound & alarm audio stream
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      try {
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_channel');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_channel_v2');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_channel_v3');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_channel_v4');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_loud_v5');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_loud_v6');
        await androidImpl.deleteNotificationChannel('dailyflow_alarm_loud_v7');
      } catch (_) {}

      final loudChannel = AndroidNotificationChannel(
        'dailyflow_alarm_loud_v8',
        'DailyFlow Alarm Sound (Loud)',
        description: 'Loud continuous audio alarm ringtone with vibration until dismissed',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );
      try {
        await androidImpl.createNotificationChannel(loudChannel);
      } catch (_) {}

      final studyChannel = const AndroidNotificationChannel(
        'dailyflow_study_timer_channel',
        'DailyFlow Live Study Timer',
        description: 'Sticky chronometer notification while study/focus timer is active',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: true,
      );
      try {
        await androidImpl.createNotificationChannel(studyChannel);
      } catch (_) {}
    }

    await requestPermissions();
  }

  static const int studyTimerNotificationId = 55555;

  /// Shows sticky live Chronometer notification on Android status bar & Lock Screen
  static Future<void> showStudyTimerNotification({
    required String title,
    required String category,
    required DateTime startTime,
  }) async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;

    final androidDetails = AndroidNotificationDetails(
      'dailyflow_study_timer_channel',
      'DailyFlow Live Study Timer',
      channelDescription: 'Sticky chronometer notification while study/focus timer is active',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      when: startTime.millisecondsSinceEpoch,
      usesChronometer: true,
      chronometerCountDown: false,
      onlyAlertOnce: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.stopwatch,
      color: const Color(0xFF0284C7),
      actions: const [
        AndroidNotificationAction(
          'open_app',
          '📖 View In App',
          showsUserInterface: true,
        ),
      ],
    );

    try {
      await _plugin.show(
        studyTimerNotificationId,
        '⏱️ Focus Active: $title',
        'Live focus session running · Tap to view in app',
        NotificationDetails(android: androidDetails),
      );
    } catch (_) {}
  }

  /// Cancels live Chronometer notification when study session stops
  static Future<void> cancelStudyTimerNotification() async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    try {
      await _plugin.cancel(studyTimerNotificationId);
    } catch (_) {}
  }

  static Future<void> requestPermissions() async {
    if (kIsWeb || !Platform.isAndroid) return;
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    try {
      notificationsGranted = await androidImpl?.requestNotificationsPermission() ?? false;
    } catch (_) {
      notificationsGranted = false;
    }
    try {
      exactAlarmsGranted = await androidImpl?.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      exactAlarmsGranted = false;
    }
  }

  static Future<void> cancelAll() async {
    await AlarmAudioService.stop();
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  static Future<void> cancel(int id) async {
    await AlarmAudioService.stop();
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> scheduleExactAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    await scheduleOnce(id, title, body, scheduledDate);
  }

  /// Schedules an alarm 1 minute from now so user can close the app and test background ringing
  static Future<String> scheduleTestAlarmInOneMinute() async {
    if (kIsWeb || !Platform.isAndroid) return 'Test alarm notifications run on Android devices.';
    if (!_initialized) return 'Notifications not initialized. Reopen the app.';
    final testTime = DateTime.now().add(const Duration(minutes: 1));
    await scheduleOnce(
      888888,
      '⏰ DailyFlow 1-Minute Alarm Test',
      '🔔 Alarm ringing! App was closed and alarm triggered successfully.',
      testTime,
    );
    return '✅ Test Alarm scheduled for ${hhmm12(testTime.hour * 60 + testTime.minute)} (1 min from now)! Close/kill the app and lock your screen now to test.';
  }

  /// Sends immediate looping test notification and starts infinite alarm playback
  static Future<String> sendTestNow() async {
    await AlarmAudioService.playLooping();
    if (kIsWeb || !Platform.isAndroid) return 'Alarm is ringing in an infinite loop! Tap "Stop Alarm" to stop.';
    if (!_initialized) return 'Notifications not initialized. Reopen the app.';
    try {
      await _plugin.show(
        999999,
        'DailyFlow Loud Alarm',
        '🔔 Alarm is ringing continuously! Tap "🛑 Stop Alarm" to turn off.',
        _details('dailyflow_alarm_loud_v8', 'DailyFlow Alarm Sound (Loud)', useCustomSound: true),
      );
      return '🔔 Alarm is ringing in infinite loop! Check notifications or tap Stop Alarm.';
    } catch (e) {
      return 'Alarm started ringing!';
    }
  }

  /// Android Notification with FLAG_INSISTENT (4) for continuous repeating audio
  /// and "Stop Alarm" action button until dismissed by user.
  static NotificationDetails _details(String channelId, String channelName, {required bool useCustomSound}) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Persistent alarm ringtones until dismissed',
        importance: Importance.max,
        priority: Priority.max,
        sound: useCustomSound ? const RawResourceAndroidNotificationSound('alarm') : null,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        ongoing: true,
        autoCancel: false,
        ticker: 'DailyFlow Alarm',
        // FLAG_INSISTENT (4) causes continuous audio repetition until user dismisses
        additionalFlags: Int32List.fromList([4]),
        actions: const [
          AndroidNotificationAction(
            'stop_alarm',
            '🛑 Stop Alarm',
            cancelNotification: true,
            showsUserInterface: true,
          ),
        ],
      ),
    );
  }

  static Future<void> scheduleDaily(int id, String title, String body, int hour, int minute) async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (when.isBefore(now)) when = when.add(const Duration(days: 1));

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        when,
        _details('dailyflow_alarm_loud_v8', 'DailyFlow Alarm Sound (Loud)', useCustomSound: true),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          _details('dailyflow_alarm_loud_v8', 'DailyFlow Alarm Sound (Loud)', useCustomSound: true),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (_) {}
    }
  }

  static Future<void> scheduleOnce(int id, String title, String body, DateTime when) async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    final tzWhen = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tzWhen,
        _details('dailyflow_alarm_loud_v8', 'DailyFlow Alarm Sound (Loud)', useCustomSound: true),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          tzWhen,
          _details('dailyflow_alarm_loud_v8', 'DailyFlow Alarm Sound (Loud)', useCustomSound: true),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {}
    }
  }

  static Future<void> resyncAll(AppData data) async {
    if (kIsWeb || !Platform.isAndroid || !_initialized) return;
    await cancelAll();

    // 1. Dedicated Morning Wake-Up Alarm
    if (data.morningAlarmEnabled) {
      final t = toMin(data.morningAlarmTime);
      await scheduleDaily(
        777777,
        '🌅 Morning Wake-Up Flow Alarm',
        'Time to wake up! Complete morning challenge to silence alarm.',
        t ~/ 60,
        t % 60,
      );
    }

    // 2. Routine Blocks Alarms
    int id = 1;
    for (final b in data.blocks.where((b) => b.remind)) {
      final t = toMin(b.start);
      await scheduleDaily(
        id++,
        'DailyFlow: ${b.name}',
        'Starts at ${hhmmStr12(b.start)} · Tap Stop to turn off',
        t ~/ 60,
        t % 60,
      );
    }

    // 3. Scheduled Tasks Alarms
    for (final t in data.tasks.where((t) => t.scheduled && t.ss != null)) {
      final now = DateTime.now();
      final actual = unshiftMin(t.ss!);
      var when = DateTime(now.year, now.month, now.day, actual ~/ 60, actual % 60);
      if (when.isBefore(now)) when = when.add(const Duration(days: 1));
      await scheduleOnce(
        id++,
        'DailyFlow Task: ${t.name}',
        'Scheduled at ${hhmm12(actual)} · Tap Stop to turn off',
        when,
      );
    }
  }
}

class WindowsTaskSync {
  static Future<String> syncAll(AppData data, String soundPath) async {
    if (kIsWeb || !Platform.isWindows) return 'Windows Task Sync is only available on Windows OS.';
    final installedPath = await NotifyService.ensureSoundFilesInstalled();
    final effectiveSound = soundPath.trim().isNotEmpty ? soundPath.trim() : installedPath;

    final buffer = StringBuffer();
    if (data.morningAlarmEnabled) {
      final ok = await _createTask('DailyFlow_MorningAlarm', data.morningAlarmTime, '🌅 Morning Wake-Up Flow Alarm', effectiveSound);
      buffer.writeln('Morning Alarm (${hhmmStr12(data.morningAlarmTime)}): ${ok ? "synced with looping alarm" : "failed"}');
    }
    for (final b in data.blocks.where((b) => b.remind)) {
      final ok = await _createTask('DailyFlow_${b.id}', b.start, b.name, effectiveSound);
      buffer.writeln('${b.name} (${hhmmStr12(b.start)}): ${ok ? "synced with looping alarm" : "failed"}');
    }
    for (final t in data.tasks.where((t) => t.scheduled && t.ss != null)) {
      final time = hhmm(unshiftMin(t.ss!));
      final ok = await _createTask('DailyFlow_task_${t.id}', time, t.name, effectiveSound);
      buffer.writeln('${t.name} (${hhmm12(unshiftMin(t.ss!))}): ${ok ? "synced with looping alarm" : "failed"}');
    }
    return buffer.isEmpty ? 'No reminders marked with alarm.' : buffer.toString();
  }

  /// Registers Windows Scheduled Task with continuous looping SoundPlayer until user clicks OK.
  static Future<bool> _createTask(String taskName, String hhmmTime, String label, String soundPath) async {
    final safeLabel = label.replaceAll("'", "''");
    final psScript =
        "\$s = '$soundPath'; "
        "if (-not (Test-Path \$s)) { \$s = [System.IO.Path]::Combine(\$env:LOCALAPPDATA, 'DailyFlow', 'alarm.wav') }; "
        "\$p = New-Object System.Media.SoundPlayer \$s; "
        "try { \$p.PlayLooping() } catch {}; "
        "Add-Type -AssemblyName PresentationFramework; "
        "[System.Windows.MessageBox]::Show('$safeLabel`n`nTime: $hhmmTime`n`n[ Click OK to Stop Alarm ]', 'DailyFlow Alarm Reminder', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Exclamation); "
        "try { \$p.Stop() } catch {}";

    final action = 'powershell -WindowStyle Hidden -Command "$psScript"';
    try {
      final result = await Process.run(
        'schtasks',
        ['/create', '/tn', taskName, '/tr', action, '/sc', 'daily', '/st', hhmmTime, '/f'],
      );
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  static Future<void> removeAll(AppData data) async {
    if (kIsWeb || !Platform.isWindows) return;
    for (final b in data.blocks) {
      await Process.run('schtasks', ['/delete', '/tn', 'DailyFlow_${b.id}', '/f']);
    }
    for (final t in data.tasks) {
      await Process.run('schtasks', ['/delete', '/tn', 'DailyFlow_task_${t.id}', '/f']);
    }
  }

  /// Directly tests the looping alarm on Windows
  static Future<void> testWindowsAlarmLoop(String soundPath) async {
    if (kIsWeb || !Platform.isWindows) return;
    final psScript =
        "\$s = '$soundPath'; "
        "if (-not (Test-Path \$s)) { \$s = [System.IO.Path]::Combine(\$env:LOCALAPPDATA, 'DailyFlow', 'alarm.wav') }; "
        "\$p = New-Object System.Media.SoundPlayer \$s; "
        "try { \$p.PlayLooping() } catch {}; "
        "Add-Type -AssemblyName PresentationFramework; "
        "[System.Windows.MessageBox]::Show('🔔 DailyFlow Test Alarm is Ringing!`n`nClick OK to Stop Alarm.', 'DailyFlow Alarm Test', [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information); "
        "try { \$p.Stop() } catch {}";

    Process.start('powershell', ['-WindowStyle', 'Hidden', '-Command', psScript]);
  }
}
