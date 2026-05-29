import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/moodify_bottom_nav_bar.dart';

import '../models/song.dart';
import '../models/mood.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import 'ai_chat_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'immersive_player_page.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseFavoriteService _firebaseFavoriteService =
      FirebaseFavoriteService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _searchController = TextEditingController();

  late Future<List<Song>> _favoriteSongsFuture;

  String selectedTab = '全部';
  String searchQuery = '';
  String? _playingPreviewUrl;

  static const Color bgColor = Color(0xFFFBFCF8);
  static const Color primaryColor = Color(0xFF4E8E65);
  static const Color deepGreen = Color(0xFF214A35);
  static const Color textColor = Color(0xFF2B352E);
  static const Color subTextColor = Color(0xFF7E877F);
  static const Color lineColor = Color(0xFFE8E7DE);
  static const Color cardColor = Color(0xFFFFFEFB);

  final List<Mood> moodTabs = const [
    Mood(title: '開心', emoji: '😊', keyword: 'upbeat', color: Color(0xFFFFD166)),
    Mood(title: '難過', emoji: '😔', keyword: 'soft', color: Color(0xFF8ECAE6)),
    Mood(title: '焦慮', emoji: '😰', keyword: 'calm', color: Color(0xFFA8DADC)),
    Mood(title: '疲憊', emoji: '😴', keyword: 'sleep', color: Color(0xFFCDB4DB)),
    Mood(title: '想專心', emoji: '🎧', keyword: 'focus', color: Color(0xFFB7E4C7)),
    Mood(
      title: '療癒',
      emoji: '🌿',
      keyword: 'healing',
      color: Color(0xFF95D5B2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() => _playingPreviewUrl = null);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    _favoriteSongsFuture = user == null
        ? _favoriteService.getFavoriteSongs()
        : _firebaseFavoriteService.getFavoriteSongs();
  }

  Future<void> _refreshFavorites() async {
    setState(_loadFavorites);
  }

  Future<void> _removeSong(Song song) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _favoriteService.removeFavoriteSong(song);
    } else {
      await _firebaseFavoriteService.removeFavoriteSong(song);
    }

    if (!mounted) return;

    setState(_loadFavorites);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已移除收藏：${song.trackName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _togglePreview(Song song) async {
    if (song.previewUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('這首歌曲沒有提供預覽音檔'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_playingPreviewUrl == song.previewUrl) {
      await _audioPlayer.stop();
      if (!mounted) return;
      setState(() => _playingPreviewUrl = null);
      return;
    }

    await _audioPlayer.stop();
    await _audioPlayer.play(UrlSource(song.previewUrl));

    if (!mounted) return;
    setState(() => _playingPreviewUrl = song.previewUrl);
  }

  Future<void> _openImmersivePlayer(Song song) async {
    await _audioPlayer.stop();

    if (!mounted) return;

    setState(() {
      _playingPreviewUrl = null;
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ImmersivePlayerPage(song: song)),
    );
  }

  List<Song> _getFilteredSongs(List<Song> songs) {
    final q = searchQuery.trim().toLowerCase();

    return songs.where((song) {
      final matchesTab =
          selectedTab == '全部' || _songBelongsToTab(song, selectedTab);
      final matchesSearch =
          q.isEmpty ||
          song.trackName.toLowerCase().contains(q) ||
          song.artistName.toLowerCase().contains(q) ||
          song.collectionName.toLowerCase().contains(q) ||
          song.moodTitle.toLowerCase().contains(q);

      return matchesTab && matchesSearch;
    }).toList();
  }

  bool _songBelongsToTab(Song song, String tab) {
    if (tab == '全部') return true;

    final mood = song.moodTitle.trim();
    final targetMood = tab.trim();

    if (mood == targetMood) return true;

    // 舊收藏可能沒有 moodTitle，這裡保留一點容錯，避免以前收藏的歌完全找不到分類。
    final combined =
        '${song.trackName} ${song.artistName} ${song.collectionName} $mood'
            .toLowerCase();

    final matchedMood = moodTabs.firstWhere(
      (item) => item.title == targetMood,
      orElse: () => Mood(
        title: targetMood,
        emoji: '',
        keyword: targetMood.toLowerCase(),
        color: primaryColor,
      ),
    );

    return combined.contains(matchedMood.keyword.toLowerCase()) ||
        combined.contains(targetMood.toLowerCase());
  }

  String _featuredTitle(List<Song> songs) {
    if (selectedTab != '全部') return '$selectedTab收藏歌單';

    if (songs.isEmpty) return '我的收藏歌單';

    final firstMood = songs.first.moodTitle.trim();
    if (firstMood.isNotEmpty) return '$firstMood收藏歌單';
    return '把喜歡的音樂存起來';
  }

  String _featuredCountText(int count) => '$count 首歌曲';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEFB), Color(0xFFFBFCF8), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshFavorites,
            color: primaryColor,
            child: FutureBuilder<List<Song>>(
              future: _favoriteSongsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final songs = snapshot.data ?? [];
                final filteredSongs = _getFilteredSongs(songs);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    _buildTopTabs(),
                    const SizedBox(height: 18),
                    if (songs.isEmpty)
                      _buildEmptyView(user)
                    else ...[
                      _buildFeaturedCard(
                        filteredSongs.isNotEmpty
                            ? filteredSongs.first
                            : songs.first,
                        filteredSongs.isNotEmpty
                            ? filteredSongs.length
                            : songs.length,
                      ),
                      const SizedBox(height: 16),
                      if (filteredSongs.isEmpty)
                        _buildNoFilteredResult()
                      else ...[
                        ...filteredSongs.take(4).map(_buildFavoriteTile),
                        const SizedBox(height: 24),
                        _buildRecentHeader(),
                        const SizedBox(height: 14),
                        _buildRecentFavorites(
                          filteredSongs.length > 1
                              ? filteredSongs.skip(1).take(6).toList()
                              : songs.take(6).toList(),
                        ),
                      ],
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MoodifyBottomNavBar(
        currentTab: MoodifyTab.favorite,
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: 8,
          top: 52,
          child: Container(
            width: 190,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2E8),
              borderRadius: BorderRadius.circular(90),
            ),
          ),
        ),
        Positioned(
          right: 26,
          top: 10,
          child: Icon(
            Icons.spa_rounded,
            color: primaryColor.withOpacity(0.14),
            size: 110,
          ),
        ),
        Positioned(
          right: 96,
          top: 28,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFD8C98E).withOpacity(0.72),
            size: 16,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moodify',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: deepGreen,
                      letterSpacing: -0.8,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '收藏',
                    style: TextStyle(
                      fontSize: 46,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      color: deepGreen,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '把陪伴你的音樂存起來',
                    style: TextStyle(
                      fontSize: 17,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _refreshFavorites,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _softShadow(opacity: 0.08, blur: 20, y: 8),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  color: primaryColor,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: _softShadow(opacity: 0.05, blur: 16, y: 6),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF8F8A73), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: '搜尋你收藏的音樂或心情',
                hintStyle: TextStyle(
                  color: Color(0xFFA2A09A),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: const TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF8F8A73)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    final tabs = <String>['全部', ...moodTabs.map((mood) => mood.title)];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final isSelected = selectedTab == tab;
          final mood = tab == '全部'
              ? null
              : moodTabs.firstWhere((item) => item.title == tab);

          return GestureDetector(
            onTap: () => setState(() => selectedTab = tab),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : const Color(0xFFF4F3ED),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? primaryColor
                      : Colors.white.withOpacity(0.9),
                  width: 1.1,
                ),
                boxShadow: isSelected
                    ? _softShadow(opacity: 0.10, blur: 14, y: 7)
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (mood != null) ...[
                    Text(mood.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    tab,
                    style: TextStyle(
                      color: isSelected ? Colors.white : deepGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCard(Song song, int count) {
    final isPlaying = _playingPreviewUrl == song.previewUrl;

    return GestureDetector(
      onTap: () => _openImmersivePlayer(song),
      child: Container(
        height: 230,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            colors: [Color(0xFFEFF2F8), Color(0xFFFCEFD9), Color(0xFFF7E6E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 1.4),
          boxShadow: _softShadow(opacity: 0.08, blur: 22, y: 10),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -8,
              bottom: 10,
              child: Icon(
                Icons.spa_rounded,
                color: primaryColor.withOpacity(0.18),
                size: 90,
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white.withOpacity(0.6),
                size: 18,
              ),
            ),
            Positioned(
              right: 6,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: SizedBox(
                  width: 170,
                  height: 118,
                  child: song.artworkUrl.isNotEmpty
                      ? Image.network(
                          song.artworkUrl.replaceAll('100x100bb', '600x600bb'),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _featuredLandscapePlaceholder(),
                        )
                      : _featuredLandscapePlaceholder(),
                ),
              ),
            ),
            Positioned(
              right: 26,
              bottom: 24,
              child: GestureDetector(
                onTap: () => _openImmersivePlayer(song),
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.93),
                    shape: BoxShape.circle,
                    boxShadow: _softShadow(opacity: 0.07, blur: 12, y: 6),
                  ),
                  child: Icon(
                    isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: primaryColor,
                    size: 38,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),
                Text(
                  _featuredTitle([song]),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: deepGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _featuredCountText(count),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5F6B64),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _featuredLandscapePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9EFD8), Color(0xFFE8EEF3), Color(0xFFEFD6D0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -8,
            bottom: 16,
            right: -8,
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFC9D8E0).withOpacity(0.55),
                borderRadius: BorderRadius.circular(40),
              ),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 24,
            right: -10,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFDDB9C6).withOpacity(0.35),
                borderRadius: BorderRadius.circular(32),
              ),
            ),
          ),
          Positioned(
            right: 26,
            top: 18,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF3C3AA).withOpacity(0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteTile(Song song) {
    return GestureDetector(
      onTap: () => _openImmersivePlayer(song),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.1),
          boxShadow: _softShadow(opacity: 0.045, blur: 14, y: 6),
        ),
        child: Row(
          children: [
            _buildArtwork(song, size: 92, radius: 18),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.trackName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: deepGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buildSongDescription(song),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  onPressed: () => _removeSong(song),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                  splashRadius: 22,
                ),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: Color(0xFF738073),
                  ),
                  onSelected: (value) {
                    if (value == 'play') {
                      _openImmersivePlayer(song);
                    } else if (value == 'remove') {
                      _removeSong(song);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'play', child: Text('播放預覽')),
                    PopupMenuItem(value: 'remove', child: Text('移除收藏')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      children: [
        Icon(
          Icons.eco_rounded,
          color: primaryColor.withOpacity(0.74),
          size: 23,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            '最近收藏',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: subTextColor,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '查看全部',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: subTextColor,
                ),
              ),
              SizedBox(width: 2),
              Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFavorites(List<Song> songs) {
    final displaySongs = songs.isEmpty ? <Song>[] : songs;

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displaySongs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final song = displaySongs[index];
          final isPlaying = _playingPreviewUrl == song.previewUrl;

          return GestureDetector(
            onTap: () => _openImmersivePlayer(song),
            child: Container(
              width: 270,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: index.isEven
                      ? [const Color(0xFFF1F7ED), Colors.white]
                      : [const Color(0xFFF5F0FF), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white, width: 1.1),
                boxShadow: _softShadow(opacity: 0.04, blur: 12, y: 6),
              ),
              child: Row(
                children: [
                  _buildArtwork(song, size: 72, radius: 16),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.trackName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: deepGreen,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${song.artistName} · ${song.collectionName.isEmpty ? '1' : '1'} 首歌曲',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openImmersivePlayer(song),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.90),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        color: primaryColor,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtwork(
    Song song, {
    required double size,
    required double radius,
  }) {
    final imageUrl = song.artworkUrl.replaceAll('100x100bb', '300x300bb');

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _artworkPlaceholder(size),
              )
            : _artworkPlaceholder(size),
      ),
    );
  }

  Widget _artworkPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F5EE), Color(0xFFFAFBF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        Icons.spa_rounded,
        color: primaryColor.withOpacity(0.35),
        size: size * 0.42,
      ),
    );
  }

  String _buildSongDescription(Song song) {
    if (song.moodTitle.isNotEmpty) {
      return '收藏心情：${song.moodTitle}';
    }
    if (song.collectionName.isNotEmpty) {
      return song.collectionName;
    }
    return '陪你慢慢安放思緒';
  }

  Widget _buildNoFilteredResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: _cardDecoration(radius: 26),
      child: const Column(
        children: [
          Icon(Icons.music_off_rounded, color: primaryColor, size: 42),
          SizedBox(height: 12),
          Text(
            '這個分類還沒有符合的收藏',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: deepGreen,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '你可以切換分類，或搜尋其他歌曲名稱與心情。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(User? user) {
    return Column(
      children: [
        const SizedBox(height: 56),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3EA),
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: primaryColor,
            size: 46,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '還沒有收藏歌曲',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: deepGreen,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '到推薦頁按下愛心，就可以把喜歡的歌曲收藏起來。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: subTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(radius: 24),
          child: Text(
            user == null
                ? '目前尚未登入，收藏會先存在本機。登入 Google 後即可同步到雲端。'
                : '你已登入 Google，收藏歌曲會儲存在雲端，換裝置也能同步。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: '首頁',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              },
            ),
            _buildNavItem(
              icon: Icons.favorite_rounded,
              label: '收藏',
              isSelected: true,
            ),
            _buildNavItem(
              icon: Icons.smart_toy_outlined,
              label: 'AI 陪伴',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatPage()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.bar_chart_rounded,
              label: '紀錄',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              label: '我的',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFFB0B4AE),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? primaryColor : const Color(0xFF9CA39C),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: cardColor.withOpacity(0.96),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: _softShadow(opacity: 0.05, blur: 16, y: 6),
    );
  }

  List<BoxShadow> _softShadow({
    double opacity = 0.06,
    double blur = 16,
    double y = 8,
  }) {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(opacity * 0.18),
        blurRadius: blur * 0.6,
        offset: Offset(0, y * 0.45),
      ),
    ];
  }
}
