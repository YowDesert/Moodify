import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/song.dart';

class FirebaseFavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get _user => _auth.currentUser;

  CollectionReference<Map<String, dynamic>>? get _favoritesRef {
    final user = _user;

    if (user == null) {
      return null;
    }

    return _firestore.collection('users').doc(user.uid).collection('favorites');
  }

  Future<void> addFavoriteSong(Song song) async {
    final ref = _favoritesRef;

    if (ref == null) {
      throw Exception('尚未登入，無法同步到雲端');
    }

    final songId = _createSongId(song);

    await ref.doc(songId).set({
      'trackName': song.trackName,
      'artistName': song.artistName,
      'collectionName': song.collectionName,
      'artworkUrl': song.artworkUrl,
      'previewUrl': song.previewUrl,
      'spotifyUrl': song.spotifyUrl,
      'moodTitle': song.moodTitle,
      'moodEmoji': song.moodEmoji,
      'moodColor': song.moodColor,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Song>> getFavoriteSongs() async {
    final ref = _favoritesRef;

    if (ref == null) {
      return [];
    }

    final snapshot = await ref.orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return Song(
        trackName: data['trackName'] ?? '未知歌曲',
        artistName: data['artistName'] ?? '未知歌手',
        collectionName: data['collectionName'] ?? '未知專輯',
        artworkUrl: data['artworkUrl'] ?? '',
        previewUrl: data['previewUrl'] ?? '',
        spotifyUrl: data['spotifyUrl'] ?? '',
        moodTitle: data['moodTitle'] ?? '',
        moodEmoji: data['moodEmoji'] ?? '',
        moodColor: data['moodColor'] ?? 0xFF95D5B2,
      );
    }).toList();
  }

  Future<void> removeFavoriteSong(Song song) async {
    final ref = _favoritesRef;

    if (ref == null) {
      return;
    }

    final songId = _createSongId(song);
    await ref.doc(songId).delete();
  }

  String _createSongId(Song song) {
    return '${song.trackName}_${song.artistName}'
        .replaceAll('/', '_')
        .replaceAll('\\', '_')
        .replaceAll('#', '_')
        .replaceAll('?', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }
}
