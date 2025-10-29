import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String _lastAiIndexKey = 'lastAiIndex';
  static const String _loadLastOpenedAiKey = 'loadLastOpenedAi';
  static const String _defaultAiNameKey = 'defaultAiName';
  static const String _aiStatusPrefix = 'ai_status_';

  static Future<int> getLastAiIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastAiIndexKey) ?? 0;
  }

  static Future<void> saveLastAiIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastAiIndexKey, index);
  }

  static Future<bool> getLoadLastOpenedAi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loadLastOpenedAiKey) ?? true;
  }

  static Future<void> setLoadLastOpenedAi(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loadLastOpenedAiKey, value);
  }

  static Future<String> getDefaultAiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_defaultAiNameKey) ?? 'ChatGPT';
  }

  static Future<void> setDefaultAiName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultAiNameKey, name);
  }

  static Future<bool> getAiStatus(String aiName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_aiStatusPrefix$aiName') ?? true;
  }

  static Future<void> setAiStatus(String aiName, bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_aiStatusPrefix$aiName', isEnabled);
  }

  // Add this method to SharedPrefs class
  static Future<void> saveLastAiName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastAiName', name);
  }

  static Future<String> getLastAiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastAiName') ?? 'ChatGPT';
  }
}
