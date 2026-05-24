import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/song.dart';
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

  @override
  void initState() {
    super.initState();

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;

      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _togglePlay() async {
    if (widget.song.previewUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('這首歌沒有提供預覽音檔'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.stop();

      if (!mounted) return;
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.song.previewUrl));

      if (!mounted) return;
      setState(() {
        _isPlaying = true;
      });
    }
  }

  Future<void> _openOnYoutube() async {
    try {
      final opened = await _youtubeSearchService.openSongOnYoutube(widget.song);

      if (!mounted) return;

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('無法開啟 YouTube 搜尋'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '正在用 YouTube 搜尋：${widget.song.artistName} - ${widget.song.trackName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('開啟 YouTube 失敗：$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _addToFavorite() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      final songToSave = widget.song.copyWithMood(
        moodTitle: widget.moodTitle ?? widget.song.moodTitle,
        moodEmoji: widget.moodEmoji ?? widget.song.moodEmoji,
        moodColor: widget.moodColor ?? widget.song.moodColor,
      );

      if (user == null) {
        await _favoriteService.addFavoriteSong(songToSave);
      } else {
        await _firebaseFavoriteService.addFavoriteSong(songToSave);
      }

      if (!mounted) return;

      setState(() {
        _isFavorite = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            user == null
                ? '已收藏到本機：${songToSave.moodEmoji} ${songToSave.trackName}'
                : '已收藏到雲端：${songToSave.moodEmoji} ${songToSave.trackName}',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('收藏失敗：$e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFeatured) {
      return _buildFeaturedCard();
    }

    return _buildNormalCard();
  }

  Widget _buildFeaturedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.09),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
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
                icon: Icons.smart_display_rounded,
                isActive: false,
                onTap: _openOnYoutube,
                size: 46,
              ),
              const SizedBox(width: 10),
              _buildActionButton(
                icon: _isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                isActive: _isPlaying,
                onTap: _togglePlay,
                size: 46,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          widget.song.artworkUrl.isNotEmpty
              ? Image.network(
                  widget.song.artworkUrl.replaceAll('100x100bb', '600x600bb'),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(
                      width: double.infinity,
                      height: 220,
                      radius: 24,
                      iconSize: 52,
                    );
                  },
                )
              : _buildPlaceholder(
                  width: double.infinity,
                  height: 220,
                  radius: 24,
                  iconSize: 52,
                ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.28)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.88),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.headphones_rounded,
                    size: 15,
                    color: Color(0xFF2E7D62),
                  ),
                  SizedBox(width: 5),
                  Text(
                    '30 秒預覽',
                    style: TextStyle(
                      color: Color(0xFF2E7D62),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildArtwork(),
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
                icon: Icons.smart_display_rounded,
                isActive: false,
                onTap: _openOnYoutube,
                size: 38,
              ),
              const SizedBox(height: 8),
              _buildActionButton(
                icon: _isPlaying
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                isActive: _isPlaying,
                onTap: _togglePlay,
                size: 38,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: widget.song.artworkUrl.isNotEmpty
          ? Image.network(
              widget.song.artworkUrl.replaceAll('100x100bb', '300x300bb'),
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildPlaceholder(
                  width: 76,
                  height: 76,
                  radius: 18,
                  iconSize: 34,
                );
              },
            )
          : _buildPlaceholder(width: 76, height: 76, radius: 18, iconSize: 34),
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
            const Icon(
              Icons.person_rounded,
              size: 14,
              color: Color(0xFF5F7F73),
            ),
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
          size: size >= 46 ? 28 : 23,
        ),
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
}
