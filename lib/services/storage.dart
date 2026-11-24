import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_data.dart';

class Storage {
  static const _key = 'dailyflow_data_v3';

  static Future<AppData> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var raw = prefs.getString(_key);

      if (raw == null) {
        final d = AppData.defaults();
        await save(d);
        return d;
      }
      return AppData.fromJson(jsonDecode(raw));
    } catch (_) {
      final d = AppData.defaults();
      await save(d);
      return d;
    }
  }

  static Future<void> save(AppData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(data.toJson()));
    } catch (_) {}
  }
}
