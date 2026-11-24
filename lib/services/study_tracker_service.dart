import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/study_session.dart';
import 'notifications.dart';

class StudyTrackerService {
  static final StudyTrackerService _instance = StudyTrackerService._internal();
  factory StudyTrackerService() => _instance;
  StudyTrackerService._internal();

  static final ValueNotifier<bool> isRunningNotifier = ValueNotifier<bool>(false);
  static final ValueNotifier<int> elapsedSecondsNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<String> activeTitleNotifier = ValueNotifier<String>('Deep Study & Focus');
  static final ValueNotifier<String> activeCategoryNotifier = ValueNotifier<String>('study');

  static DateTime? _sessionStartTime;
  static Timer? _timer;

  static bool get isRunning => isRunningNotifier.value;
  static int get elapsedSeconds => elapsedSecondsNotifier.value;
  static String get activeTitle => activeTitleNotifier.value;
  static String get activeCategory => activeCategoryNotifier.value;

  static void start({String title = 'Deep Study & Focus', String category = 'study'}) {
    if (isRunning) return;
    _sessionStartTime = DateTime.now();
    activeTitleNotifier.value = title;
    activeCategoryNotifier.value = category;
    elapsedSecondsNotifier.value = 0;
    isRunningNotifier.value = true;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSecondsNotifier.value += 1;
    });

    // Post Live Sticky Lock-Screen & Status Bar Chronometer Notification on Android
    NotifyService.showStudyTimerNotification(
      title: title,
      category: category,
      startTime: _sessionStartTime!,
    );
  }

  static void pause() {
    _timer?.cancel();
    isRunningNotifier.value = false;
  }

  static void resume() {
    if (isRunning) return;
    isRunningNotifier.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSecondsNotifier.value += 1;
    });
    if (_sessionStartTime != null) {
      NotifyService.showStudyTimerNotification(
        title: activeTitleNotifier.value,
        category: activeCategoryNotifier.value,
        startTime: _sessionStartTime!,
      );
    }
  }

  static StudySession? stopAndSave() {
    _timer?.cancel();
    final totalSeconds = elapsedSecondsNotifier.value;
    final start = _sessionStartTime ?? DateTime.now().subtract(Duration(seconds: totalSeconds));
    final end = DateTime.now();

    isRunningNotifier.value = false;
    elapsedSecondsNotifier.value = 0;
    _sessionStartTime = null;

    // Clear sticky notification
    NotifyService.cancelStudyTimerNotification();

    final durationMins = (totalSeconds / 60).ceil();
    if (durationMins <= 0 && totalSeconds < 10) {
      return null; // Ignore negligible sessions (< 10 secs)
    }

    return StudySession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: activeTitleNotifier.value,
      category: activeCategoryNotifier.value,
      startTime: start,
      endTime: end,
      durationMinutes: durationMins < 1 ? 1 : durationMins,
    );
  }

  static void reset() {
    _timer?.cancel();
    isRunningNotifier.value = false;
    elapsedSecondsNotifier.value = 0;
    _sessionStartTime = null;
    NotifyService.cancelStudyTimerNotification();
  }

  static String formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    final secs = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
