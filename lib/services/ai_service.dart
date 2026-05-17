import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiService {
  static final String _apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  static const String _model = 'gemini-2.5-flash';

  static const int _dailyLimit = 10;

  Future<String> getMoodAdvice(String userMoodText) async {
    if (_apiKey.isEmpty) {
      return '找不到 Gemini API Key，請確認 .env 是否設定正確。';
    }
    final canUse = await _canUseToday();

    if (!canUse) {
      return '今天的 AI 使用次數已經達到上限囉 🌿\n\n為了避免超過免費額度，Moodify 每天最多使用 AI $_dailyLimit 次。明天再來讓我陪你整理心情吧。';
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt =
        '''
你是 Moodify App 裡的 AI 心情療癒助手。
你的語氣要溫柔、自然、像朋友陪伴，但不要太誇張。

請根據使用者的心情，用繁體中文回答。
回答一定要完整，不可以只回一句話。

請固定用以下格式回答：

🌿 給你的話
用 3～4 句話安慰使用者，理解他的感受。

🎧 適合的音樂
推薦一種音樂類型，並說明為什麼適合現在聽。

✨ 今天的小行動
給一個很簡單、可以立刻做到的小行動。

回答長度請控制在 100 到 250 字左右。

使用者心情：
$userMoodText
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {'maxOutputTokens': 600, 'temperature': 0.7},
        }),
      );

      if (response.statusCode == 200) {
        await _increaseUsageCount();

        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text == null) {
          return 'AI 沒有回傳內容，請再試一次。';
        }

        return text;
      } else if (response.statusCode == 429) {
        return 'Gemini 免費額度暫時用完了，請晚一點再試。';
      } else {
        return 'Gemini API 發生錯誤：${response.statusCode}\n${response.body}';
      }
    } catch (e) {
      return '連線失敗：$e';
    }
  }

  Future<bool> _canUseToday() async {
    final prefs = await SharedPreferences.getInstance();

    final today = _todayString();
    final savedDate = prefs.getString('ai_usage_date');
    final count = prefs.getInt('ai_usage_count') ?? 0;

    if (savedDate != today) {
      await prefs.setString('ai_usage_date', today);
      await prefs.setInt('ai_usage_count', 0);
      return true;
    }

    return count < _dailyLimit;
  }

  Future<void> _increaseUsageCount() async {
    final prefs = await SharedPreferences.getInstance();

    final today = _todayString();
    final savedDate = prefs.getString('ai_usage_date');
    final count = prefs.getInt('ai_usage_count') ?? 0;

    if (savedDate != today) {
      await prefs.setString('ai_usage_date', today);
      await prefs.setInt('ai_usage_count', 1);
    } else {
      await prefs.setInt('ai_usage_count', count + 1);
    }
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }
}
