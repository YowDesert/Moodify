import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mood.dart';

class MoodHistoryService {
  static const String _historyKey = 'mood_history';

  Future<void> addMoodRecord(Mood mood) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getMoodRecords();

    final now = DateTime.now();

    final newRecord = {
      'title': mood.title,
      'emoji': mood.emoji,
      'keyword': mood.keyword,
      'color': mood.color.value,
      'date': '${now.year}/${now.month}/${now.day}',
      'time':
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    };

    records.insert(0, newRecord);

    await prefs.setString(_historyKey, jsonEncode(records));
  }

  Future<List<Map<String, dynamic>>> getMoodRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_historyKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List data = jsonDecode(jsonString);
    return data.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deleteMoodRecord(Map<String, dynamic> targetRecord) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getMoodRecords();

    records.removeWhere((record) {
      return record['title'] == targetRecord['title'] &&
          record['emoji'] == targetRecord['emoji'] &&
          record['date'] == targetRecord['date'] &&
          record['time'] == targetRecord['time'];
    });

    await prefs.setString(_historyKey, jsonEncode(records));
  }
}
