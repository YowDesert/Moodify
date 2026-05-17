import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/song.dart';

class FavoriteService {
  static const String _favoriteSongsKey = 'favorite_songs';

  Future<List<Song>> getFavoriteSongs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_favoriteSongsKey);

    if (jsonString == null || jsonString.isEmpty) {
      return [];
    }

    final List data = jsonDecode(jsonString);
    return data.map((item) => Song.fromJson(item)).toList();
  }

  Future<void> addFavoriteSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getFavoriteSongs();

    final alreadyExists = songs.any(
      (item) =>
          item.trackName == song.trackName &&
          item.artistName == song.artistName,
    );

    if (!alreadyExists) {
      songs.add(song);
    }

    final jsonString = jsonEncode(songs.map((song) => song.toJson()).toList());

    await prefs.setString(_favoriteSongsKey, jsonString);
  }

  Future<void> removeFavoriteSong(Song song) async {
    final prefs = await SharedPreferences.getInstance();
    final songs = await getFavoriteSongs();

    songs.removeWhere(
      (item) =>
          item.trackName == song.trackName &&
          item.artistName == song.artistName,
    );

    final jsonString = jsonEncode(songs.map((song) => song.toJson()).toList());

    await prefs.setString(_favoriteSongsKey, jsonString);
  }
}
