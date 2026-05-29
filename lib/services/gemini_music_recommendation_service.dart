import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/mood.dart';
import '../models/song.dart';
import 'music_api_service.dart';

class AiSongPick {
  final String title;
  final String artist;
  final String reason;

  AiSongPick({
    required this.title,
    required this.artist,
    required this.reason,
  });
}

class AiMusicRecommendationResult {
  final List<Song> songs;
  final String reason;
  final bool usedAi;

  AiMusicRecommendationResult({
    required this.songs,
    required this.reason,
    required this.usedAi,
  });
}

class GeminiMusicRecommendationService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY']?.trim() ?? '';

  // 如果 gemini-2.5-flash 你的帳號不能用，再改成 gemini-1.5-flash。
  static String _model = 'gemini-2.5-flash';

  final MusicApiService _backupMusicApiService = MusicApiService();

  Future<AiMusicRecommendationResult> recommendSongsByMood(Mood mood) async {
    if (_apiKey.isEmpty) {
      debugPrint('沒有讀到 GEMINI_API_KEY，改用原本 iTunes mood keyword 推薦');
      return _fallbackResult(mood);
    }

    try {
      final picks = await _askGeminiForSongs(mood);

      if (picks.isEmpty) {
        debugPrint('Gemini 沒有產生歌曲，改用 fallback');
        return _fallbackResult(mood);
      }

      final songs = <Song>[];

      for (final pick in picks) {
        final song = await _searchITunesBestMatch(pick);

        songs.add(
          song.copyWithMood(
            moodTitle: mood.title,
            moodEmoji: mood.emoji,
            moodColor: mood.color.value,
          ),
        );
      }

      if (songs.isEmpty) {
        debugPrint('iTunes 沒有找到歌曲，改用 fallback');
        return _fallbackResult(mood);
      }

      return AiMusicRecommendationResult(
        songs: songs,
        usedAi: true,
        reason: _buildReason(mood, picks),
      );
    } catch (e, stack) {
      debugPrint('Gemini song recommendation failed: $e');
      debugPrint('$stack');
      return _fallbackResult(mood);
    }
  }

  Future<List<AiSongPick>> _askGeminiForSongs(Mood mood) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey',
    );

    final prompt =
        '''
你是 Moodify App 的 AI 音樂推薦助手。
使用者剛剛點擊的心情是：${mood.emoji} ${mood.title}
心情 keyword：${mood.keyword}

請推薦 6 首真的存在、Spotify 或 Apple Music 上容易搜尋到的歌曲。
推薦要符合這個心情，不要每次都只推薦同一批熱門歌。
可以混合中文、英文、日文、韓文歌曲，但歌名和歌手要正確。

規則：
- 只回傳合法 JSON，不要 markdown，不要 ```。
- 不要寫不存在的歌。
- artist 請填主要歌手，不要填 Spotify、YouTube、Various Artists。
- reason 用繁體中文，最多 18 個字。
- title 和 artist 不要空白。

格式：
{
  "songs": [
    {
      "title": "歌曲名稱",
      "artist": "歌手名稱",
      "reason": "推薦原因"
    }
  ]
}
''';

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
          'maxOutputTokens': 2048,
          'temperature': 0.9,
          'topP': 0.95,
          'responseMimeType': 'application/json',
        },
      }),
    );

    if (response.statusCode != 200) {
      debugPrint('Gemini API 錯誤 status: ${response.statusCode}');
      debugPrint('Gemini API 錯誤 body: ${response.body}');
      return [];
    }

    final rawText = _extractGeminiText(response.body);
    debugPrint('Gemini songs raw text: $rawText');

    if (rawText.trim().isEmpty) {
      debugPrint('Gemini songs raw text 是空的');
      return [];
    }

    final data = _decodeJsonObject(rawText);
    final items = data['songs'];

    if (items is! List) {
      debugPrint('Gemini songs 欄位不是 List');
      return [];
    }

    return items
        .whereType<Map>()
        .map((item) {
          return AiSongPick(
            title: (item['title'] ?? '').toString().trim(),
            artist: (item['artist'] ?? '').toString().trim(),
            reason: (item['reason'] ?? '').toString().trim(),
          );
        })
        .where((pick) => pick.title.isNotEmpty && pick.artist.isNotEmpty)
        .take(6)
        .toList();
  }

  Future<Song> _searchITunesBestMatch(AiSongPick pick) async {
    final fallbackSong = Song(
      trackName: pick.title,
      artistName: pick.artist,
      collectionName: 'Gemini AI 推薦',
      artworkUrl: '',
      previewUrl: '',
      spotifyUrl: '',
    );

    try {
      final url = Uri.https('itunes.apple.com', '/search', {
        'term': '${pick.title} ${pick.artist}',
        'media': 'music',
        'entity': 'song',
        'country': 'TW',
        'limit': '10',
      });

      final response = await http.get(url);

      if (response.statusCode != 200) {
        debugPrint('iTunes API 錯誤 status: ${response.statusCode}');
        return fallbackSong;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = (data['results'] as List?) ?? [];

      if (results.isEmpty) {
        debugPrint('iTunes 找不到：${pick.title} - ${pick.artist}');
        return fallbackSong;
      }

      final candidates = results
          .whereType<Map<String, dynamic>>()
          .map(Song.fromITunesResult)
          .toList();

      if (candidates.isEmpty) {
        return fallbackSong;
      }

      return _pickClosestSong(candidates, pick);
    } catch (e) {
      debugPrint('iTunes search failed: $e');
      return fallbackSong;
    }
  }

  Song _pickClosestSong(List<Song> candidates, AiSongPick pick) {
    String clean(String value) {
      return value
          .toLowerCase()
          .replaceAll(
            RegExp(r'[^a-z0-9\u4e00-\u9fff\u3040-\u30ff\uac00-\ud7af]+'),
            ' ',
          )
          .trim();
    }

    final targetTitle = clean(pick.title);
    final targetArtist = clean(pick.artist);

    Song best = candidates.first;
    var bestScore = -1;

    for (final song in candidates) {
      final title = clean(song.trackName);
      final artist = clean(song.artistName);

      var score = 0;

      if (title == targetTitle) score += 8;
      if (title.contains(targetTitle) || targetTitle.contains(title)) {
        score += 4;
      }

      if (artist == targetArtist) score += 6;
      if (artist.contains(targetArtist) || targetArtist.contains(artist)) {
        score += 3;
      }

      if (song.previewUrl.isNotEmpty) score += 1;
      if (song.artworkUrl.isNotEmpty) score += 1;

      if (score > bestScore) {
        bestScore = score;
        best = song;
      }
    }

    if (bestScore <= 0) {
      return Song(
        trackName: pick.title,
        artistName: pick.artist,
        collectionName: 'Gemini AI 推薦',
        artworkUrl: '',
        previewUrl: '',
        spotifyUrl: '',
      );
    }

    return best;
  }

  String _extractGeminiText(String responseBody) {
    try {
      final data = jsonDecode(responseBody);
      final parts = data['candidates']?[0]?['content']?['parts'];

      if (parts is List) {
        return parts
            .map((part) => part is Map ? part['text']?.toString() ?? '' : '')
            .join('\n')
            .trim();
      }

      return '';
    } catch (e) {
      debugPrint('Gemini response parse failed: $e');
      debugPrint('Gemini original body: $responseBody');
      return '';
    }
  }

  Map<String, dynamic> _decodeJsonObject(String rawText) {
    var clean = rawText
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```', '')
        .trim();

    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');

    if (start >= 0 && end > start) {
      clean = clean.substring(start, end + 1);
    }

    try {
      final decoded = jsonDecode(clean);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (e) {
      debugPrint('Gemini songs JSON parse failed: $e');
      debugPrint('Gemini songs raw text: $rawText');
    }

    return {};
  }

  String _buildReason(Mood mood, List<AiSongPick> picks) {
    final firstReason = picks
        .map((pick) => pick.reason)
        .firstWhere((reason) => reason.isNotEmpty, orElse: () => '');

    if (firstReason.isNotEmpty) {
      return 'Gemini 依照「${mood.title}」挑選歌曲：$firstReason。你也可以刷新，讓 AI 換一批不同的推薦。';
    }

    return 'Gemini 依照「${mood.title}」幫你挑選歌曲，並用 iTunes 補上封面與預覽音檔。你也可以刷新，讓 AI 換一批不同的推薦。';
  }

  Future<AiMusicRecommendationResult> _fallbackResult(Mood mood) async {
    final songs = await _backupMusicApiService.searchSongs(mood.keyword);

    return AiMusicRecommendationResult(
      songs: songs
          .map(
            (song) => song.copyWithMood(
              moodTitle: mood.title,
              moodEmoji: mood.emoji,
              moodColor: mood.color.value,
            ),
          )
          .toList(),
      usedAi: false,
      reason: '目前 Gemini 暫時無法使用，所以先用原本的心情關鍵字推薦歌曲；等 API 正常後會自動改回 AI 推薦。',
    );
  }
}
