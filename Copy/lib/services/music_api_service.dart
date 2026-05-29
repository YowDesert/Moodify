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
        final songs = await _fetchITunesSongs(searchTerm);
        allSongs.addAll(songs);
      }

      if (allSongs.isEmpty) {
        allSongs.addAll(_fallbackSongs(moodKeyword));
      }

      final uniqueSongs = _dedupeSongs(allSongs);
      final freshSongs = uniqueSongs
          .where((song) => !recentSongIds.contains(_songKey(song)))
          .toList();

      final candidates = freshSongs.length >= 8 ? freshSongs : uniqueSongs;
      final balancedSongs = _balanceArtists(candidates);
      balancedSongs.shuffle(_random);

      final result = balancedSongs.take(10).toList();
      await _saveRecentSongIds(result, recentSongIds);

      return result;
    } catch (e) {
      final backup = _fallbackSongs(moodKeyword)..shuffle(_random);
      if (backup.isNotEmpty) return backup.take(10).toList();
      throw Exception('iTunes 預覽音樂資料載入失敗：$e');
    }
  }

  Future<List<Song>> _fetchITunesSongs(String searchTerm) async {
    final url = Uri.https('itunes.apple.com', '/search', {
      'term': searchTerm,
      'media': 'music',
      'entity': 'song',
      'country': 'TW',
      'limit': '30',
    });

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('iTunes API 錯誤：${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (data['results'] as List?) ?? const [];

    final songs = results
        .whereType<Map<String, dynamic>>()
        .map(Song.fromITunesResult)
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
    return shuffledTerms.take(4).toList();
  }

  List<Song> _dedupeSongs(List<Song> songs) {
    final seen = <String>{};
    final uniqueSongs = <Song>[];

    for (final song in songs) {
      final key = _songKey(song);
      if (seen.add(key)) uniqueSongs.add(song);
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
    final previewKey = song.previewUrl.trim().toLowerCase();
    if (previewKey.isNotEmpty) return previewKey;
    return '${song.trackName}_${song.artistName}'.trim().toLowerCase();
  }

  List<Song> _fallbackSongs(String moodKeyword) {
    final songs = _fallbackSongData[moodKeyword] ?? _fallbackSongData['focus']!;
    return songs
        .map(
          (item) => Song(
            trackName: item[0],
            artistName: item[1],
            collectionName: 'Spotify / YouTube 搜尋推薦',
            artworkUrl: '',
            previewUrl: '',
            // 不先存 Spotify 搜尋網址，避免舊資料或空查詢變成 /search/recent。
            // 點 Spotify 時由 SpotifySearchService 即時用「歌手 + 歌名」產生搜尋網址。
            spotifyUrl: '',
          ),
        )
        .toList();
  }

  static const Map<String, List<List<String>>> _fallbackSongData = {
    'upbeat': [
      ['Treasure', 'Bruno Mars'],
      ['Levitating', 'Dua Lipa'],
      ['Sugar', 'Maroon 5'],
      ['Happy', 'Pharrell Williams'],
      ['Counting Stars', 'OneRepublic'],
      ['愛你', '王心凌'],
      ['派對動物', '五月天'],
      ['星期五晚上', 'Energy'],
    ],
    'soft': [
      ['Someone Like You', 'Adele'],
      ['Love Yourself', 'Justin Bieber'],
      ['Before You Go', 'Lewis Capaldi'],
      ['Until I Found You', 'Stephen Sanchez'],
      ['怎麼了', '周興哲'],
      ['說謊', '林宥嘉'],
      ['遇見', '孫燕姿'],
      ['Let Her Go', 'Passenger'],
    ],
    'calm': [
      ['River Flows In You', 'Yiruma'],
      ['Nuvole Bianche', 'Ludovico Einaudi'],
      ['Near Light', 'Ólafur Arnalds'],
      ['Says', 'Nils Frahm'],
      ['An Ending, a Beginning', 'Dustin O\'Halloran'],
      ['Experience', 'Ludovico Einaudi'],
      ['Weightless', 'Marconi Union'],
      ['Kiss The Rain', 'Yiruma'],
    ],
    'sleep': [
      ['Deep Sleep', 'Peder B. Helland'],
      ['Sleep', 'Max Richter'],
      ['Dream 3', 'Max Richter'],
      ['Night', 'Ludovico Einaudi'],
      ['Calm Sleep Music', 'Peder B. Helland'],
      ['Soft Rain', 'Sleep Sounds'],
      ['Piano Sleep Music', 'Sleep Music'],
      ['Gentle Night Piano', 'Relaxing Piano Music'],
    ],
    'focus': [
      ['Luv(sic) pt3', 'Nujabes'],
      ['Feather', 'Nujabes'],
      ['Affection', 'Jinsang'],
      ['Snowfall', 'Øneheart'],
      ['Study and Relax', 'Lofi Fruits Music'],
      ['Coding Mode', 'Chillhop Music'],
      ['Idealism', 'Ikigai'],
      ['Deep Focus', 'Spotify'],
    ],
    'healing': [
      ['One Summer\'s Day', 'Joe Hisaishi'],
      ['Merry-Go-Round of Life', 'Joe Hisaishi'],
      ['River Flows In You', 'Yiruma'],
      ['Nuvole Bianche', 'Ludovico Einaudi'],
      ['Kiss The Rain', 'Yiruma'],
      ['Experience', 'Ludovico Einaudi'],
      ['Spring', 'Joe Hisaishi'],
      ['Always With Me', 'Yumi Kimura'],
    ],
    'quiet_piano': [
      ['River Flows In You', 'Yiruma'],
      ['Kiss The Rain', 'Yiruma'],
      ['Nuvole Bianche', 'Ludovico Einaudi'],
      ['Una Mattina', 'Ludovico Einaudi'],
      ['Comptine d\'un autre été', 'Yann Tiersen'],
      ['Near Light', 'Ólafur Arnalds'],
      ['Opus 23', 'Dustin O\'Halloran'],
      ['Experience', 'Ludovico Einaudi'],
    ],
  };

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
