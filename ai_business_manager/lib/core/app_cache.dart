import 'dart:convert';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provider for Local Cache
final appCacheProvider = FutureProvider<AppCache>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return AppCache(prefs);
});

class AppCache {
  final SharedPreferences _prefs;

  AppCache(this._prefs);

  // Generic Write String
  Future<void> writeString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  // Generic Read String
  String? readString(String key) {
    return _prefs.getString(key);
  }

  // Write JSON object (Map)
  Future<void> writeJson(String key, Map<String, dynamic> json) async {
    final stringValue = jsonEncode(json);
    await _prefs.setString(key, stringValue);
  }

  // Read JSON object
  Map<String, dynamic>? readJson(String key) {
    final stringValue = _prefs.getString(key);
    if (stringValue == null) return null;
    try {
      return jsonDecode(stringValue) as Map<String, dynamic>;
    } catch (e) {
      return null; // Handle malformed data gracefully
    }
  }

  // Write JSON List
  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> list,
  ) async {
    final stringValue = jsonEncode(list);
    await _prefs.setString(key, stringValue);
  }

  // Read JSON List
  List<Map<String, dynamic>>? readJsonList(String key) {
    final stringValue = _prefs.getString(key);
    if (stringValue == null) return null;
    try {
      final decodedList = jsonDecode(stringValue) as List<dynamic>;
      return decodedList.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      return null; // Handle malformed data gracefully
    }
  }

  // Remove Data
  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
