import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiChatResult {
  final String reply;
  final String moodKey;
  final List<String> actions;
  final String musicTitle;
  final String musicDescription;

  const AiChatResult({
    required this.reply,
    required this.moodKey,
    required this.actions,
    required this.musicTitle,
    required this.musicDescription,
  });

  factory AiChatResult.fallback(String userText) {
    final lower = userText.toLowerCase();
    final random = Random();

    bool hasAny(List<String> words) => words.any((w) => lower.contains(w));

    if (hasAny(['happy', '開心', '快樂', '爽', '興奮', '很棒', '好開心'])) {
      final replies = [
        '聽起來你現在的能量很亮耶，這種開心很值得被好好留住。你可以不用急著把它變得很有意義，就讓自己享受現在的輕盈感.\n\n我會幫你配一點明亮、節奏感比較舒服的歌，讓這份好心情延續久一點。',
        '我感覺到你現在是有點雀躍、想把心情打開的狀態。這很好，今天可以對自己大方一點，讓音樂陪你把這個瞬間放大。',
      ];
      return AiChatResult(
        reply: replies[random.nextInt(replies.length)],
        moodKey: 'upbeat',
        actions: const ['開心歌單', '記下今天'],
        musicTitle: '把好心情放大',
        musicDescription: '明亮流行、輕快節奏，讓現在的開心感再延續一下。',
      );
    }

    if (hasAny(['焦慮', '緊張', '不安', '煩', 'anxious', 'stress', 'stressed'])) {
      final replies = [
        '聽起來你的腦袋現在跑得很快，好像很多事情同時擠在一起。先不用急著把全部問題解決，我們先把速度降下來就好。\n\n等一下可以先聽一點很穩、很慢的音樂，讓身體先知道：現在是安全的。',
        '我懂，那種心裡一直被拉緊的感覺真的會很累。你不用馬上變冷靜，我們只要先讓呼吸慢一點，讓注意力回到現在。',
      ];
      return AiChatResult(
        reply: replies[random.nextInt(replies.length)],
        moodKey: 'calm',
        actions: const ['3 分鐘呼吸', '安靜鋼琴'],
        musicTitle: '慢慢安定下來',
        musicDescription: '平穩的鋼琴和環境音，幫你把心裡的雜訊慢慢降下來。',
      );
    }

    if (hasAny(['難過', '低落', '傷心', '哭', 'sad', 'depressed', '失落'])) {
      return const AiChatResult(
        reply:
            '聽起來你今天心裡有一塊地方比較重。你不用急著把自己說服成「沒事」，有些情緒本來就需要被看見。\n\n我會陪你找一點溫柔、不吵的歌，不是要把難過趕走，而是讓你不用一個人扛著它。',
        moodKey: 'soft',
        actions: ['溫柔陪伴', '療癒木吉他'],
        musicTitle: '讓情緒被接住',
        musicDescription: '柔和人聲與木吉他，陪你慢慢整理心裡那份低落。',
      );
    }

    if (hasAny(['累', '疲憊', '睡', '晚安', 'sleep', 'tired', 'exhausted'])) {
      return const AiChatResult(
        reply:
            '你現在比較像是身體和心都需要休息了。今天已經撐到這裡，其實就很不容易。\n\n先不要再要求自己產出什麼，讓音樂變得柔一點、慢一點，陪你把今天慢慢放下來。',
        moodKey: 'sleep',
        actions: ['睡前放鬆', '晚安白噪音'],
        musicTitle: '慢慢放鬆入夜',
        musicDescription: '柔和鋼琴、白噪音與慢節奏，讓疲憊慢慢沉下來。',
      );
    }

    if (hasAny(['專心', '分心', '讀書', '工作', 'focus', 'study', 'coding'])) {
      return const AiChatResult(
        reply:
            '你現在不是不夠努力，比較像是注意力被太多東西切開了。先不用逼自己一次進入狀態，我們可以從一小段開始。\n\n我會幫你找節奏穩、存在感不太強的音樂，讓你比較容易回到手上的事情。',
        moodKey: 'focus',
        actions: ['番茄鐘 25 分鐘', '專注鋼琴'],
        musicTitle: '穩穩專注下來',
        musicDescription: 'Lo-fi、輕節拍與簡單旋律，幫你降低分心感。',
      );
    }

    return const AiChatResult(
      reply:
          '我有收到你的心情。你不需要把感受講得很完整才值得被理解，先照你現在的樣子待著就可以。\n\n我會先用比較溫柔、乾淨的音樂陪你，讓心情有一點空間可以慢慢整理。',
      moodKey: 'healing',
      actions: ['呼吸一下', '柔和音樂'],
      musicTitle: '給自己一點空間',
      musicDescription: '溫柔旋律和乾淨聲響，陪你慢慢回到舒服一點的位置。',
    );
  }
}

class AiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

  // 如果這個模型回 404 或 400，可以先改成 gemini-1.5-flash。
  static const String _model = 'gemini-2.5-flash';
  static const int _dailyLimit = 30;

  Future<String> getMoodAdvice(String userMoodText) async {
    final result = await getMoodChat(userMoodText);
    return result.reply;
  }

  Future<AiChatResult> getMoodChat(
    String userMoodText, {
    List<String> recentMessages = const [],
  }) async {
    debugPrint('Gemini API Key exists: ${_apiKey.isNotEmpty}');

    if (_apiKey.isEmpty) {
      debugPrint('沒有讀到 GEMINI_API_KEY，所以使用本機 fallback');
      return AiChatResult.fallback(userMoodText);
    }

    final canUse = await _canUseToday();
    if (!canUse) {
      return const AiChatResult(
        reply:
            '今天的 AI 使用次數已經達到上限囉。為了避免超過免費額度，Moodify 今天先用本機陪伴模式回覆你。\n\n你可以先把現在最重的感覺交給音樂，不用急著處理完所有事情。',
        moodKey: 'healing',
        actions: ['呼吸一下', '柔和音樂'],
        musicTitle: '先安靜陪你一下',
        musicDescription: '用柔和旋律陪你暫時停下來，讓心慢慢變鬆。',
      );
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final historyText = recentMessages.isEmpty
        ? '沒有前文。'
        : recentMessages.take(6).join('\n');

    final prompt =
        '''
你是 Moodify App 裡的 AI 心情陪伴助手，請像真人朋友一樣自然聊天。

重要規則：
- 使用繁體中文回覆；如果使用者主要用英文，可以自然混合英文。
- 不要固定使用「給你的話 / 適合的音樂 / 小行動」三段式。
- 不要像心理測驗結果，也不要一直說「親愛的」。
- 依照使用者實際文字判斷情緒，不要每次都判斷成專注或療癒。
- reply 長度約 60～160 字。
- 不能提供醫療診斷。如果使用者有明顯自傷危機，要溫柔提醒找信任的人或當地緊急資源。

你必須只回傳合法 JSON，不要 markdown，不要 ```，不要在 JSON 外面加任何文字。
格式如下：
{
  "reply": "自然聊天式回覆",
  "moodKey": "upbeat",
  "actions": ["短按鈕1", "短按鈕2"],
  "musicTitle": "推薦卡標題",
  "musicDescription": "推薦原因"
}

moodKey 只能選其中一個：
- upbeat：開心、興奮、有活力、想快樂
- soft：難過、失落、想被陪伴
- calm：焦慮、緊張、煩躁、不安
- sleep：疲憊、想睡、晚安、需要休息
- focus：想專心、讀書、工作、分心
- healing：不明確、想被療癒、想安靜

最近對話：
$historyText

使用者這次說：
$userMoodText
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'maxOutputTokens': 520,
            'temperature': 0.9,
            'topP': 0.95,
            'topK': 40,

            // 這行很重要：要求 Gemini 直接輸出 JSON。
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Gemini API 錯誤 status: ${response.statusCode}');
        debugPrint('Gemini API 錯誤 body: ${response.body}');
        return AiChatResult.fallback(userMoodText);
      }

      await _increaseUsageCount();

      final rawText = _extractGeminiText(response.body);
      debugPrint('Gemini raw text: $rawText');

      if (rawText.trim().isEmpty) {
        debugPrint('Gemini 回傳空文字');
        return AiChatResult.fallback(userMoodText);
      }

      return _parseGeminiResult(rawText, userMoodText);
    } catch (e, stack) {
      debugPrint('Gemini exception: $e');
      debugPrint('Gemini stack: $stack');
      return AiChatResult.fallback(userMoodText);
    }
  }

  String _extractGeminiText(String responseBody) {
    final data = jsonDecode(responseBody);

    final parts = data['candidates']?[0]?['content']?['parts'];
    if (parts is List) {
      return parts
          .map((part) => part is Map ? part['text']?.toString() ?? '' : '')
          .join('\n')
          .trim();
    }

    return '';
  }

  AiChatResult _parseGeminiResult(String rawText, String userText) {
    final fallback = AiChatResult.fallback(userText);

    try {
      final data = _decodeGeminiJson(rawText);

      // Gemini 如果真的沒有照 JSON 回，至少不要把整段 JSON 或原始資料顯示到畫面。
      if (data == null) {
        final cleaned = _cleanReplyText(rawText);
        if (cleaned.length >= 8 && !cleaned.trim().startsWith('{')) {
          final mood = _guessMoodKey(userText);
          return AiChatResult(
            reply: cleaned,
            moodKey: mood,
            actions: _defaultActions(mood),
            musicTitle: _defaultMusicTitle(mood),
            musicDescription: _defaultMusicDescription(mood),
          );
        }

        return fallback;
      }

      final moodKey = _normalizeMoodKey((data['moodKey'] ?? '').toString());
      final reply = _cleanReplyText((data['reply'] ?? '').toString());
      final actions = _parseActions(data['actions'], moodKey);
      final musicTitle = (data['musicTitle'] ?? '').toString().trim();
      final musicDescription = (data['musicDescription'] ?? '')
          .toString()
          .trim();

      if (reply.length < 8 || reply.trim().startsWith('{')) {
        return fallback;
      }

      return AiChatResult(
        reply: reply,
        moodKey: moodKey,
        actions: actions,
        musicTitle: musicTitle.isEmpty
            ? _defaultMusicTitle(moodKey)
            : musicTitle,
        musicDescription: musicDescription.isEmpty
            ? _defaultMusicDescription(moodKey)
            : musicDescription,
      );
    } catch (e) {
      debugPrint('Gemini parse failed: $e');
      return fallback;
    }
  }

  Map<String, dynamic>? _decodeGeminiJson(String rawText) {
    var clean = rawText.trim();

    clean = clean
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```', '')
        .trim();

    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start >= 0 && end > start) {
      clean = clean.substring(start, end + 1);
    }

    // 標準 JSON。
    try {
      final decoded = jsonDecode(clean);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    // 有時候 Gemini 會輸出 {'reply': '...'}，這裡修成 JSON。
    final loose = clean
        .replaceAllMapped(
          RegExp(r"'([A-Za-z0-9_]+)'\s*:"),
          (match) => '"${match.group(1)}":',
        )
        .replaceAllMapped(RegExp(r":\s*'([^']*)'"), (match) {
          final value = match.group(1) ?? '';
          return ': ${jsonEncode(value)}';
        })
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*]'), ']');

    try {
      final decoded = jsonDecode(loose);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    // 最後保底：只抓欄位，不讓畫面顯示整段 raw JSON。
    final reply = _extractJsonLikeString(clean, 'reply');
    if (reply == null || reply.trim().isEmpty) return null;

    return {
      'reply': reply,
      'moodKey': _extractJsonLikeString(clean, 'moodKey') ?? 'healing',
      'musicTitle': _extractJsonLikeString(clean, 'musicTitle') ?? '',
      'musicDescription':
          _extractJsonLikeString(clean, 'musicDescription') ?? '',
      'actions': _extractJsonLikeActions(clean),
    };
  }

  String? _extractJsonLikeString(String text, String key) {
    final pattern = RegExp(
      r'''["']''' + RegExp.escape(key) + r'''["']\s*:\s*(["'])(.*?)\1''',
      dotAll: true,
    );
    final match = pattern.firstMatch(text);
    return match?.group(2)?.trim();
  }

  List<String> _extractJsonLikeActions(String text) {
    final pattern = RegExp(
      r'''["']actions["']\s*:\s*\[(.*?)\]''',
      dotAll: true,
    );
    final match = pattern.firstMatch(text);
    if (match == null) return const ['呼吸一下', '柔和音樂'];

    final inside = match.group(1) ?? '';
    final itemPattern = RegExp(r'''(["'])(.*?)\1''', dotAll: true);
    final items = itemPattern
        .allMatches(inside)
        .map((m) => (m.group(2) ?? '').trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList();

    return items.isEmpty ? const ['呼吸一下', '柔和音樂'] : items;
  }

  String _cleanReplyText(String value) {
    var clean = value
        .replaceAll(r'\n', '\n')
        .replaceAll(RegExp(r'^reply\s*[:：]\s*', caseSensitive: false), '')
        .trim();

    // 如果不小心傳進來的是 JSON，盡量只取 reply 欄位。
    final maybeReply = _extractJsonLikeString(clean, 'reply');
    if (maybeReply != null && maybeReply.trim().isNotEmpty) {
      clean = maybeReply.trim();
    }

    return clean.trim();
  }

  List<String> _parseActions(dynamic value, String moodKey) {
    if (value is List) {
      final actions = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .take(2)
          .toList();
      if (actions.isNotEmpty) return actions;
    }

    return _defaultActions(moodKey);
  }

  List<String> _defaultActions(String moodKey) {
    switch (moodKey) {
      case 'upbeat':
        return const ['開心歌單', '記下今天'];
      case 'soft':
        return const ['溫柔陪伴', '療癒木吉他'];
      case 'calm':
        return const ['3 分鐘呼吸', '安靜鋼琴'];
      case 'sleep':
        return const ['睡前放鬆', '晚安白噪音'];
      case 'focus':
        return const ['番茄鐘 25 分鐘', '專注鋼琴'];
      default:
        return const ['呼吸一下', '柔和音樂'];
    }
  }

  String _normalizeMoodKey(String value) {
    const allowed = {'upbeat', 'soft', 'calm', 'sleep', 'focus', 'healing'};
    final key = value.trim().toLowerCase();
    return allowed.contains(key) ? key : 'healing';
  }

  String _guessMoodKey(String text) {
    final lower = text.toLowerCase();

    bool hasAny(List<String> words) => words.any((w) => lower.contains(w));

    if (hasAny(['happy', '開心', '快樂', '爽', '興奮', '很棒', '好開心'])) {
      return 'upbeat';
    }
    if (hasAny(['焦慮', '緊張', '不安', '煩', 'anxious', 'stress', 'stressed'])) {
      return 'calm';
    }
    if (hasAny(['難過', '低落', '傷心', '哭', 'sad', 'depressed', '失落'])) {
      return 'soft';
    }
    if (hasAny(['累', '疲憊', '睡', '晚安', 'sleep', 'tired', 'exhausted'])) {
      return 'sleep';
    }
    if (hasAny(['專心', '分心', '讀書', '工作', 'focus', 'study', 'coding'])) {
      return 'focus';
    }
    return 'healing';
  }

  String _defaultMusicTitle(String moodKey) {
    switch (moodKey) {
      case 'upbeat':
        return '把快樂放大';
      case 'soft':
        return '溫柔接住你';
      case 'calm':
        return '慢慢安定';
      case 'sleep':
        return '放鬆入夜';
      case 'focus':
        return '穩穩專注';
      default:
        return '給自己空間';
    }
  }

  String _defaultMusicDescription(String moodKey) {
    switch (moodKey) {
      case 'upbeat':
        return '輕快節奏陪你延續現在的好心情。';
      case 'soft':
        return '柔和旋律陪你慢慢整理低落感。';
      case 'calm':
        return '平穩聲音幫心裡的雜訊降下來。';
      case 'sleep':
        return '慢節奏和柔和聲響陪你休息。';
      case 'focus':
        return '穩定節拍幫你回到手上的事。';
      default:
        return '乾淨溫柔的音樂陪你安靜一下。';
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
