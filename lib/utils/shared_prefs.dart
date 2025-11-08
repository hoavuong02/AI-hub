import 'dart:convert';

import 'package:aihub/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static const String _loadLastOpenedAiKey = 'loadLastOpenedAi';
  static const String _defaultAiNameKey = 'defaultAiName';
  static const String _lastAiNameKey = 'lastAiName';
  static const String _fontSizeKey = 'font_size';
  static const String _aiStatusListKey = 'ai_status_list';

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
    await SharedPreferences.getInstance();
    final aiStatusList = await _getAiStatusList();

    final aiStatus = aiStatusList.firstWhere(
      (ai) => ai['name'] == aiName,
      orElse: () => {'name': aiName, 'enabled': true},
    );

    return aiStatus['enabled'] as bool;
  }

  static Future<void> setAiStatus(String aiName, bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    final aiStatusList = await _getAiStatusList();

    final index = aiStatusList.indexWhere((ai) => ai['name'] == aiName);
    if (index >= 0) {
      aiStatusList[index]['enabled'] = isEnabled;
    } else {
      aiStatusList.add({'name': aiName, 'enabled': isEnabled});
    }

    await prefs.setString(_aiStatusListKey, _encodeAiStatusList(aiStatusList));
  }

  static Future<void> saveLastAiName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastAiNameKey, name);
  }

  static Future<String> getLastAiName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastAiNameKey) ?? 'ChatGPT';
  }

  static Future<void> setFontSize(String size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, size);
  }

  static Future<String> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fontSizeKey) ?? 'medium';
  }

  static Future<List<Map<String, dynamic>>> _getAiStatusList() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = prefs.getString(_aiStatusListKey);

    if (encodedList == null) {
      return aiList.map((ai) => {'name': ai['name'], 'enabled': true}).toList();
    }

    return _decodeAiStatusList(encodedList);
  }

  static String _encodeAiStatusList(List<Map<String, dynamic>> aiStatusList) {
    return jsonEncode(aiStatusList);
  }

  static List<Map<String, dynamic>> _decodeAiStatusList(String encodedList) {
    try {
      final decoded = jsonDecode(encodedList) as List;
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      return aiList.map((ai) => {'name': ai['name'], 'enabled': true}).toList();
    }
  }

  static Future<Map<String, dynamic>> getAllSettings() async {
    final settings = <String, dynamic>{};

    final aiStatusList = await _getAiStatusList();
    settings['ai_status_list'] = aiStatusList;

    settings[_loadLastOpenedAiKey] = await getLoadLastOpenedAi();
    settings[_defaultAiNameKey] = await getDefaultAiName();
    settings[_fontSizeKey] = await getFontSize();
    settings[_lastAiNameKey] = await getLastAiName();

    return settings;
  }

  static Future<void> restoreSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();

    if (settings.containsKey('ai_status_list') &&
        settings['ai_status_list'] is List) {
      final aiStatusList = settings['ai_status_list'] as List;
      final encodedList = jsonEncode(aiStatusList);
      await prefs.setString(_aiStatusListKey, encodedList);
    } else {
      final defaultAiStatusList = aiList
          .map((ai) => {'name': ai['name'], 'enabled': true})
          .toList();
      await prefs.setString(
        _aiStatusListKey,
        _encodeAiStatusList(defaultAiStatusList),
      );
    }

    await setLoadLastOpenedAi(settings[_loadLastOpenedAiKey] as bool? ?? true);
    await setDefaultAiName(settings[_defaultAiNameKey] as String? ?? 'ChatGPT');
    await setFontSize(settings[_fontSizeKey] as String? ?? 'medium');

    if (settings[_lastAiNameKey] is String) {
      await saveLastAiName(settings[_lastAiNameKey] as String);
    }
  }

  static Future<List<Map<String, dynamic>>> getEnabledAis() async {
    final aiStatusList = await _getAiStatusList();
    return aiStatusList.where((ai) => ai['enabled'] == true).toList();
  }

  static Future<List<Map<String, dynamic>>> getDisabledAis() async {
    final aiStatusList = await _getAiStatusList();
    return aiStatusList.where((ai) => ai['enabled'] == false).toList();
  }

  static Future<bool> hasEnabledAis() async {
    final enabledAis = await getEnabledAis();
    return enabledAis.isNotEmpty;
  }
}
