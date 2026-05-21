import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/song.dart';

class MusicApiService {
  final Random _random = Random();

  Future<List<Song>> searchSongs(String moodKeyword) async {
    final searchTerm = _pickSearchTerm(moodKeyword);
    final encodedKeyword = Uri.encodeComponent(searchTerm);

    final url = Uri.parse(
      'https://itunes.apple.com/search'
      '?term=$encodedKeyword'
      '&media=music'
      '&entity=song'
      '&limit=20'
      '&country=TW'
      '&explicit=No',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'] ?? [];

        final songs = results
            .map((item) => Song.fromJson(item))
            .where(
              (song) =>
                  song.trackName.isNotEmpty &&
                  song.artistName.isNotEmpty &&
                  song.previewUrl.isNotEmpty,
            )
            .toList();

        songs.shuffle();

        return songs.take(10).toList();
      } else {
        throw Exception('iTunes API 錯誤：${response.statusCode}');
      }
    } catch (e) {
      throw Exception('音樂資料載入失敗：$e');
    }
  }

  String _pickSearchTerm(String moodKeyword) {
    final Map<String, List<String>> moodSearchTerms = {
      'upbeat': [
        'Bruno Mars',
        'Dua Lipa',
        'Maroon 5',
        'Pharrell Williams',
        'OneRepublic',
        'Ariana Grande',
      ],
      'soft': [
        'Yiruma',
        'Adele',
        'Ludovico Einaudi',
        'Billie Eilish',
        'Sam Smith',
        'piano ballad',
      ],
      'calm': [
        'Brian Eno',
        'Max Richter',
        'calm piano',
        'ambient music',
        'peaceful piano',
        'relaxing instrumental',
      ],
      'sleep': [
        'sleep piano',
        'Peder B. Helland',
        'relaxing piano',
        'deep sleep music',
        'soft piano',
        'sleep meditation',
      ],
      'focus': [
        'lofi study',
        'Nujabes',
        'Chillhop',
        'study beats',
        'lofi hip hop',
        'instrumental beats',
      ],
      'healing': [
        'Joe Hisaishi',
        'healing piano',
        'acoustic calm',
        'nature sounds',
        'gentle piano',
        'healing music',
      ],
    };

    final terms = moodSearchTerms[moodKeyword] ?? ['lofi study'];
    return terms[_random.nextInt(terms.length)];
  }
}
