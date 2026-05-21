import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../widgets/song_card.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseFavoriteService _firebaseFavoriteService =
      FirebaseFavoriteService();

  late Future<List<Song>> _favoriteSongsFuture;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _favoriteSongsFuture = _favoriteService.getFavoriteSongs();
    } else {
      _favoriteSongsFuture = _firebaseFavoriteService.getFavoriteSongs();
    }
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _loadFavorites();
    });
  }

  Future<void> _removeSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _favoriteService.removeFavoriteSong(song);
    } else {
      await _firebaseFavoriteService.removeFavoriteSong(song);
    }

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
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        title: const Text('我的收藏'),
        backgroundColor: const Color(0xFFF3FBF6),
        foregroundColor: const Color(0xFF1F5C49),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshFavorites,
        color: const Color(0xFF2E7D62),
        child: FutureBuilder<List<Song>>(
          future: _favoriteSongsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final songs = snapshot.data ?? [];

            if (songs.isEmpty) {
              return _buildEmptyView(user);
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: [
                _buildFavoriteHero(
                  count: songs.length,
                  isLoggedIn: user != null,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(title: '收藏歌曲', subtitle: '這些是你想再次聽見的聲音'),
                const SizedBox(height: 14),
                ..._buildGroupedFavoriteSections(songs),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildGroupedFavoriteSections(List<Song> songs) {
    final Map<String, List<Song>> groupedSongs = {};

    for (final song in songs) {
      final moodTitle = song.moodTitle.isEmpty ? '未分類' : song.moodTitle;
      groupedSongs.putIfAbsent(moodTitle, () => []);
      groupedSongs[moodTitle]!.add(song);
    }

    final widgets = <Widget>[];

    groupedSongs.forEach((moodTitle, moodSongs) {
      final firstSong = moodSongs.first;
      final emoji = firstSong.moodEmoji.isEmpty ? '🎵' : firstSong.moodEmoji;
      final color = Color(firstSong.moodColor);

      widgets.add(
        _buildMoodGroupHeader(
          emoji: emoji,
          title: moodTitle,
          count: moodSongs.length,
          color: color,
        ),
      );

      widgets.add(const SizedBox(height: 12));

      for (final song in moodSongs) {
        widgets.add(_buildDismissibleSongCard(song));
      }

      widgets.add(const SizedBox(height: 18));
    });

    return widgets;
  }

  Widget _buildMoodGroupHeader({
    required String emoji,
    required String title,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title == '未分類' ? '未分類收藏' : '$title收藏',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F5C49),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count 首歌曲',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F7F73),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteHero({required int count, required bool isLoggedIn}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB7E4C7), Color(0xFF95D5B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.14),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Icon(
              Icons.favorite_rounded,
              size: 112,
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你的音樂收藏',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123D30),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '把喜歡的旋律留下來，讓需要的時候可以再次找到它。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF315F50),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildHeroStat(
                    icon: Icons.music_note_rounded,
                    value: '$count',
                    label: '收藏歌曲',
                  ),
                  const SizedBox(width: 10),
                  _buildHeroStat(
                    icon: isLoggedIn
                        ? Icons.cloud_done_rounded
                        : Icons.phone_android_rounded,
                    value: isLoggedIn ? '雲端' : '本機',
                    label: isLoggedIn ? '已同步' : '未登入',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1F5C49), size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF123D30),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF315F50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F5C49),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6D8B7D),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissibleSongCard(Song song) {
    return Dismissible(
      key: ValueKey('${song.trackName}-${song.artistName}-${song.previewUrl}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('移除收藏？'),
                  content: Text('要把「${song.trackName}」從收藏移除嗎？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '移除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) {
        _removeSong(song);
      },
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
      child: SongCard(song: song),
    );
  }

  Widget _buildEmptyView(User? user) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 110),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Color(0xFF2E7D62),
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '還沒有收藏歌曲',
          textAlign: TextAlign.center,
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
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F0),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD6ECDF)),
          ),
          child: Text(
            user == null
                ? '目前你尚未登入，收藏會先存在本機。登入 Google 後可以同步到雲端。'
                : '你已登入 Google，之後收藏歌曲會儲存在雲端。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF5F7F73),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
