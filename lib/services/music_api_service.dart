import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicApiService {
  Future<List<Song>> searchSongs(String keyword) async {
    final encodedKeyword = Uri.encodeComponent(keyword);

    final url = Uri.parse(
      'https://itunes.apple.com/search?term=$encodedKeyword&media=music&entity=song&limit=10',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];

        return results.map((item) => Song.fromJson(item)).toList();
      } else {
        throw Exception('iTunes API 錯誤：${response.statusCode}');
      }
    } catch (e) {
      throw Exception('音樂資料載入失敗：$e');
    }
  }
}
