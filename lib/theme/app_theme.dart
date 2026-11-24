import 'package:flutter/material.dart';
import '../models/app_data.dart';
import '../services/time_utils.dart';

class AppTheme {
  // Brand Colors
  static const primary = Color(0xFF00D2FF);
  static const primaryDark = Color(0xFF0066FF);
  static const secondary = Color(0xFF9D4EDD);
  static const accent = Color(0xFF00F5D4);
  static const cardDark = Color(0xFF131B2A);
  static const surfaceDark = Color(0xFF0B0F17);

  // Category Color Map
  static Color getCategoryColor(String cat) {
    switch (cat) {
      case 'class':
        return const Color(0xFF3B82F6);
      case 'sleep':
        return const Color(0xFF8B5CF6);
      case 'practice':
        return const Color(0xFF10B981);
      case 'social':
        return const Color(0xFFEC4899);
      case 'work':
        return const Color(0xFFF59E0B);
      case 'fitness':
        return const Color(0xFFEF4444);
      case 'task':
        return const Color(0xFFFF9F1C);
      case 'open':
        return const Color(0xFF00D2FF);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static LinearGradient getCategoryGradient(String cat, bool isDark) {
    final c = getCategoryColor(cat);
    if (isDark) {
      return LinearGradient(
        colors: [c.withValues(alpha: 0.22), c.withValues(alpha: 0.08)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [c.withValues(alpha: 0.14), c.withValues(alpha: 0.04)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  static bool isNightNow(AppData data) {
    if (data.themeMode == 'dark') return true;
    if (data.themeMode == 'light') return false;

    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final s = toMin(data.darkStart);
    final e = toMin(data.darkEnd);
    if (s == e) return false;
    if (s < e) {
      return nowMin >= s && nowMin < e;
    } else {
      return nowMin >= s || nowMin < e;
    }
  }

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF090D14),
    primaryColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF00D2FF),
      secondary: Color(0xFF9D4EDD),
      tertiary: Color(0xFF00F5D4),
      surface: Color(0xFF111827),
      surfaceContainerHighest: Color(0xFF1F2937),
      onSurface: Color(0xFFF3F4F6),
      onSurfaceVariant: Color(0xFF9CA3AF),
      outline: Color(0xFF374151),
    ),
    cardColor: const Color(0xFF111827),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF090D14),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF1F2937),
      thickness: 1,
    ),
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3F6FA),
    primaryColor: const Color(0xFF0284C7),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF0284C7),
      secondary: Color(0xFF7C3AED),
      tertiary: Color(0xFF059669),
      surface: Colors.white,
      surfaceContainerHighest: Color(0xFFE2E8F0),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF64748B),
      outline: Color(0xFFCBD5E1),
    ),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      centerTitle: false,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );
}
