import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/favorite_service.dart';
import '../widgets/song_card.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final FavoriteService _favoriteService = FavoriteService();

  late Future<List<Song>> _favoriteSongsFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    _favoriteSongsFuture = _favoriteService.getFavoriteSongs();
  }

  Future<void> _removeSong(Song song) async {
    await _favoriteService.removeFavoriteSong(song);

    if (!mounted) return;

    setState(() {
      _loadFavorites();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除：${song.trackName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: const Color(0xFFF3FBF6),
        foregroundColor: const Color(0xFF1F5C49),
        elevation: 0,
      ),
      body: FutureBuilder<List<Song>>(
        future: _favoriteSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final songs = snapshot.data ?? [];

          if (songs.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return Dismissible(
                key: ValueKey('${song.trackName}-${song.artistName}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.only(right: 22),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE76F51),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                ),
                onDismissed: (_) {
                  _removeSong(song);
                },
                child: SongCard(song: song),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Color(0xFF2E7D62),
                size: 44,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '還沒有收藏歌曲',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F5C49),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '到推薦頁按下愛心，就可以把喜歡的歌曲收藏起來。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF6D8B7D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
