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
請根據使用者的心情，用繁體中文回答。

回答規則：
1. 回答長度控制在 150 到 220 字
2. 語氣溫柔、自然，像朋友陪伴
3. 一定要完整回答三個段落
4. 不要只回一句話
5. 不要太長篇大論

請固定格式：

🌿 給你的話
用 2～3 句話安慰使用者，回應他的感受。

🎧 適合的音樂
推薦一種音樂類型，並簡短說明原因。

✨ 小行動
給一個今天可以馬上做到的小行動。

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
          'generationConfig': {'maxOutputTokens': 380, 'temperature': 0.8},
        }),
      );

      if (response.statusCode == 200) {
        await _increaseUsageCount();

        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (text == null) {
          return 'AI 沒有回傳內容，請再試一次。';
        }

        final cleanText = text.trim();

        if (cleanText.length < 60) {
          return '''
🌿 給你的話
親愛的，聽起來你今天真的有些累了。沒關係，不需要逼自己馬上變好，先允許自己慢慢停下來。

🎧 適合的音樂
我推薦你聽柔和鋼琴或 Lo-fi 音樂，旋律比較平穩，可以讓心情慢慢安定。

✨ 小行動
先喝一口水，深呼吸三次，給自己一分鐘安靜的時間。
''';
        }

        return cleanText;
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
