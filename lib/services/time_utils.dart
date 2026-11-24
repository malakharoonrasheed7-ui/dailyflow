import 'package:flutter/material.dart';

/// Anchor at 06:00 AM (360 min) so day schedule (e.g. sleep 03:00 AM - 10:00 AM)
/// flows continuously in one 24-hour cycle.
const int dayStart = 360;

int shiftMin(int m) => ((m - dayStart) % 1440 + 1440) % 1440;
int unshiftMin(int s) => ((s + dayStart) % 1440 + 1440) % 1440;

/// Parses "HH:MM" (24-hour) string to minutes from 00:00 (0..1439).
int toMin(String s) {
  try {
    final p = s.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  } catch (_) {
    return 0;
  }
}

/// Converts total minutes (0..1439) into 24-hour "HH:MM" string.
String hhmm(int m) {
  m = ((m % 1440) + 1440) % 1440;
  final h = m ~/ 60, mm = m % 60;
  return '${h.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
}

/// Formats total minutes into 12-hour format with AM/PM (e.g. "09:30 AM", "02:15 PM").
String hhmm12(int m) {
  m = ((m % 1440) + 1440) % 1440;
  final h24 = m ~/ 60, mm = m % 60;
  final period = h24 < 12 ? 'AM' : 'PM';
  var h12 = h24 % 12;
  if (h12 == 0) h12 = 12;
  return '${h12.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')} $period';
}

/// Converts a 24-hour "HH:MM" string to 12-hour "HH:MM AM/PM".
String hhmmStr12(String hhmmStr) => hhmm12(toMin(hhmmStr));

/// Converts a [TimeOfDay] into 12-hour "HH:MM AM/PM".
String timeOfDay12(TimeOfDay t) {
  final period = t.hour < 12 ? 'AM' : 'PM';
  var h12 = t.hour % 12;
  if (h12 == 0) h12 = 12;
  return '${h12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} $period';
}

/// Converts [TimeOfDay] to 24-hour "HH:MM".
String timeOfDay24(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Converts "HH:MM" 24h string to [TimeOfDay].
TimeOfDay parseTimeOfDay(String hhmmStr) {
  final m = toMin(hhmmStr);
  return TimeOfDay(hour: m ~/ 60, minute: m % 60);
}

/// Formats duration in minutes to readable "Xh Ym" or "Y min".
String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// Returns the period of the day for visual indicators.
String getDayPeriod(int minuteOfDay) {
  final h = (minuteOfDay % 1440) ~/ 60;
  if (h >= 5 && h < 12) return 'Morning (AM)';
  if (h >= 12 && h < 17) return 'Afternoon (PM)';
  if (h >= 17 && h < 21) return 'Evening (PM)';
  return 'Night (PM/AM)';
}

/// Returns current local time in shifted minutes (relative to 06:00 AM).
int getCurrentShiftedMinutes() {
  final now = DateTime.now();
  final curMin = now.hour * 60 + now.minute;
  return shiftMin(curMin);
}
