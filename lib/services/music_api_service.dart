import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class MusicApiService {
  final Random _random = Random();

  static const String _recentSongKey = 'recent_recommended_songs';
  static const int _recentKeepCount = 80;

  Future<List<Song>> searchSongs(String moodKeyword) async {
    final searchTerms = _pickSearchTerms(moodKeyword);
    final recentSongIds = await _loadRecentSongIds();
    final allSongs = <Song>[];

    try {
      for (final searchTerm in searchTerms) {
        final songs = await _fetchSongs(searchTerm);
        allSongs.addAll(songs);
      }

      final uniqueSongs = _dedupeSongs(allSongs);
      final freshSongs = uniqueSongs
          .where((song) => !recentSongIds.contains(_songKey(song)))
          .toList();

      // 優先給最近沒有出現過的歌；如果新歌不夠，就補一些舊歌，避免畫面空白。
      final candidates = freshSongs.length >= 8 ? freshSongs : uniqueSongs;
      final balancedSongs = _balanceArtists(candidates);
      balancedSongs.shuffle(_random);

      final result = balancedSongs.take(10).toList();
      await _saveRecentSongIds(result, recentSongIds);

      return result;
    } catch (e) {
      throw Exception('音樂資料載入失敗：$e');
    }
  }

  Future<List<Song>> _fetchSongs(String searchTerm) async {
    final encodedKeyword = Uri.encodeComponent(searchTerm);

    final url = Uri.parse(
      'https://itunes.apple.com/search'
      '?term=$encodedKeyword'
      '&media=music'
      '&entity=song'
      '&limit=30'
      '&country=TW'
      '&explicit=No',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('iTunes API 錯誤：${response.statusCode}');
    }

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

    songs.shuffle(_random);
    return songs;
  }

  List<String> _pickSearchTerms(String moodKeyword) {
    final terms = _moodSearchTerms[moodKeyword] ?? _moodSearchTerms['focus']!;
    final shuffledTerms = [...terms]..shuffle(_random);

    // 一次混合「心情關鍵字 + 類似歌手 + 音樂類型」，每次刷新都會不同。
    return shuffledTerms.take(4).toList();
  }

  List<Song> _dedupeSongs(List<Song> songs) {
    final seen = <String>{};
    final uniqueSongs = <Song>[];

    for (final song in songs) {
      final key = _songKey(song);
      if (seen.add(key)) {
        uniqueSongs.add(song);
      }
    }

    return uniqueSongs;
  }

  List<Song> _balanceArtists(List<Song> songs) {
    final artistCount = <String, int>{};
    final balanced = <Song>[];
    final backup = <Song>[];

    for (final song in songs) {
      final artistKey = song.artistName.trim().toLowerCase();
      final count = artistCount[artistKey] ?? 0;

      // 同一輪推薦同一位歌手最多出現 2 首，避免看起來都一樣。
      if (count < 2) {
        artistCount[artistKey] = count + 1;
        balanced.add(song);
      } else {
        backup.add(song);
      }
    }

    if (balanced.length < 10) {
      balanced.addAll(backup.take(10 - balanced.length));
    }

    return balanced;
  }

  Future<Set<String>> _loadRecentSongIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_recentSongKey) ?? <String>[]).toSet();
  }

  Future<void> _saveRecentSongIds(
    List<Song> songs,
    Set<String> oldRecentSongIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final newIds = songs.map(_songKey).toList();
    final mergedIds = <String>[
      ...newIds,
      ...oldRecentSongIds,
    ].take(_recentKeepCount).toList();

    await prefs.setStringList(_recentSongKey, mergedIds);
  }

  String _songKey(Song song) {
    return '${song.trackName}_${song.artistName}'.trim().toLowerCase();
  }

  static const Map<String, List<String>> _moodSearchTerms = {
    'upbeat': [
      'happy pop',
      'feel good pop',
      'dance pop',
      'summer pop',
      'Bruno Mars',
      'Dua Lipa',
      'Maroon 5',
      'Pharrell Williams',
      'OneRepublic',
      'Ariana Grande',
      'Taylor Swift upbeat',
      'Khalid upbeat',
      'The Weeknd pop',
      '五月天 快樂',
      '告五人',
      'Energy pop',
      'Jolin Tsai',
      'cheerful indie pop',
    ],
    'soft': [
      'sad acoustic',
      'emotional ballad',
      'piano ballad',
      'soft pop',
      'Adele',
      'Billie Eilish',
      'Sam Smith',
      'Laufey',
      'Lewis Capaldi',
      'Yiruma',
      'Ludovico Einaudi',
      'Eric Chou',
      '周興哲',
      '林宥嘉',
      '孫燕姿 抒情',
      'sad mandopop',
      'healing ballad',
    ],
    'calm': [
      'calm piano',
      'peaceful piano',
      'ambient music',
      'relaxing instrumental',
      'soft instrumental',
      'Brian Eno',
      'Max Richter',
      'Ólafur Arnalds',
      'Nils Frahm',
      'Yiruma calm',
      'Ludovico Einaudi calm',
      'acoustic calm',
      'chill acoustic',
      'gentle piano',
      'meditation music',
    ],
    'sleep': [
      'sleep piano',
      'deep sleep music',
      'soft piano',
      'sleep meditation',
      'relaxing piano',
      'Peder B. Helland',
      'Max Richter sleep',
      'ambient sleep',
      'rain sleep music',
      'gentle night piano',
      'dreamy instrumental',
      'calm night music',
      'sleep sounds',
      'lofi sleep',
    ],
    'focus': [
      'lofi study',
      'study beats',
      'lofi hip hop',
      'instrumental beats',
      'Chillhop',
      'Nujabes',
      'Jinsang',
      'idealism lofi',
      'jazzhop',
      'focus music',
      'deep focus',
      'ambient focus',
      'coding music',
      'study piano',
      'chill beats',
    ],
    'healing': [
      'healing music',
      'healing piano',
      'gentle piano',
      'acoustic calm',
      'nature sounds',
      'Joe Hisaishi',
      '久石讓',
      'Yiruma healing',
      'Ludovico Einaudi healing',
      'calming acoustic',
      'warm indie',
      'soft healing pop',
      'relaxing guitar',
      'peaceful music',
      '心靈 音樂',
    ],
    'quiet_piano': [
      'solo piano instrumental',
      'relaxing piano instrumental',
      'calm piano music',
      'peaceful piano',
      'sleep piano instrumental',
      'Yiruma piano',
      'Ludovico Einaudi piano',
    ],
  };
}
