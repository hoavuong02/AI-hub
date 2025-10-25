import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String _lastAiIndexKey = 'lastAiIndex';

  static Future<int> getLastAiIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastAiIndexKey) ?? 0;
  }

  static Future<void> saveLastAiIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastAiIndexKey, index);
    } catch (e) {
      debugPrint('Error saving last AI index: $e');
    }
  }
}
