import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../pages/immersive_player_page.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../services/youtube_search_service.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final bool isFeatured;
  final String? moodTitle;
  final String? moodEmoji;
  final int? moodColor;

  const SongCard({
    super.key,
    required this.song,
    this.isFeatured = false,
    this.moodTitle,
    this.moodEmoji,
    this.moodColor,
  });

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseFavoriteService _firebaseFavoriteService =
      FirebaseFavoriteService();
  final YoutubeSearchService _youtubeSearchService = YoutubeSearchService();

  bool _isFavorite = false;
  bool _isPlaying = false;

  Color get _moodColor => Color(widget.moodColor ?? widget.song.moodColor);
  String get _moodTitle => widget.moodTitle ?? widget.song.moodTitle;
  String get _moodEmoji => widget.moodEmoji ?? widget.song.moodEmoji;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlay() async {
    if (widget.song.previewUrl.isEmpty) {
      _showSnackBar('這首歌沒有提供預覽音檔');
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.stop();
      if (!mounted) return;
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.song.previewUrl));
      if (!mounted) return;
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _openPlayer() async {
    await _audioPlayer.stop();
    if (!mounted) return;
    setState(() => _isPlaying = false);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImmersivePlayerPage(
          song: widget.song,
          moodTitle: _moodTitle,
          moodEmoji: _moodEmoji,
          moodColor: _moodColor.value,
        ),
      ),
    );
  }

  Future<void> _openOnYoutube() async {
    try {
      final opened = await _youtubeSearchService.openSongOnYoutube(widget.song);
      if (!mounted) return;
      _showSnackBar(opened ? '正在用 YouTube 搜尋這首歌' : '無法開啟 YouTube 搜尋');
    } catch (e) {
      _showSnackBar('開啟 YouTube 失敗：$e');
    }
  }

  Future<void> _addToFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final songToSave = widget.song.copyWithMood(
        moodTitle: _moodTitle,
        moodEmoji: _moodEmoji,
        moodColor: _moodColor.value,
      );

      if (user == null) {
        await _favoriteService.addFavoriteSong(songToSave);
      } else {
        await _firebaseFavoriteService.addFavoriteSong(songToSave);
      }

      if (!mounted) return;
      setState(() => _isFavorite = true);
      _showSnackBar('已收藏：${songToSave.moodEmoji} ${songToSave.trackName}');
    } catch (e) {
      _showSnackBar('收藏失敗：$e');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isFeatured ? _buildFeaturedCard() : _buildNormalCard();
  }

  Widget _buildFeaturedCard() {
    return InkWell(
      onTap: _openPlayer,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(radius: 30, blur: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFeaturedImage(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSongInfo(
                    titleSize: 21,
                    artistSize: 15,
                    albumSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isActive: _isFavorite,
                  onTap: _addToFavorite,
                  size: 46,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  icon: Icons.fullscreen_rounded,
                  isActive: false,
                  onTap: _openPlayer,
                  size: 46,
                ),
                const SizedBox(width: 10),
                _buildActionButton(
                  icon: _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  isActive: _isPlaying,
                  onTap: _togglePlay,
                  size: 46,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedImage() {
    return Hero(
      tag: 'artwork-${widget.song.artworkUrl}-${widget.song.trackName}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            _artworkImage(width: double.infinity, height: 220, radius: 24, iconSize: 52),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.32)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: _pill(Icons.headphones_rounded, '沉浸播放'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalCard() {
    return InkWell(
      onTap: _openPlayer,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(radius: 24, blur: 16),
        child: Row(
          children: [
            Hero(
              tag: 'artwork-${widget.song.artworkUrl}-${widget.song.trackName}',
              child: _buildArtwork(),
            ),
            const SizedBox(width: 14),
            Expanded(child: _buildSongInfo()),
            const SizedBox(width: 8),
            Column(
              children: [
                _buildActionButton(
                  icon: _isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  isActive: _isFavorite,
                  onTap: _addToFavorite,
                  size: 38,
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  icon: _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  isActive: _isPlaying,
                  onTap: _togglePlay,
                  size: 38,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtwork() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: _artworkImage(width: 76, height: 76, radius: 18, iconSize: 34),
    );
  }

  Widget _artworkImage({
    required double width,
    required double height,
    required double radius,
    required double iconSize,
  }) {
    final url = widget.song.artworkUrl.replaceAll('100x100bb', '600x600bb');
    if (url.isEmpty) {
      return _buildPlaceholder(
        width: width,
        height: height,
        radius: radius,
        iconSize: iconSize,
      );
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(
        width: width,
        height: height,
        radius: radius,
        iconSize: iconSize,
      ),
    );
  }

  Widget _buildSongInfo({
    double titleSize = 17,
    double artistSize = 14,
    double albumSize = 12,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_moodTitle.isNotEmpty) ...[
          Text(
            '$_moodEmoji $_moodTitle',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _moodColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
        ],
        Text(
          widget.song.trackName,
          maxLines: widget.isFeatured ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1F5C49),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.person_rounded, size: 14, color: Color(0xFF5F7F73)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.song.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: artistSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5F7F73),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          widget.song.collectionName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: albumSize,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF9AAFA6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2E7D62) : const Color(0xFFE0F2E8),
          borderRadius: BorderRadius.circular(size * 0.36),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D62).withOpacity(0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF2E7D62),
          size: size >= 46 ? 27 : 22,
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF2E7D62)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF2E7D62),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder({
    required double width,
    required double height,
    required double radius,
    required double iconSize,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2E8),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.music_note_rounded,
        color: const Color(0xFF2E7D62),
        size: iconSize,
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius, required double blur}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE1F0E8)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2E7D62).withOpacity(0.07),
          blurRadius: blur,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}
