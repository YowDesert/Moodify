import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../services/youtube_search_service.dart';

class ImmersivePlayerPage extends StatefulWidget {
  final Song song;
  final String? moodTitle;
  final String? moodEmoji;
  final int? moodColor;
  final bool autoPlay;

  const ImmersivePlayerPage({
    super.key,
    required this.song,
    this.moodTitle,
    this.moodEmoji,
    this.moodColor,
    this.autoPlay = true,
  });

  @override
  State<ImmersivePlayerPage> createState() => _ImmersivePlayerPageState();
}

class _ImmersivePlayerPageState extends State<ImmersivePlayerPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FavoriteService _favoriteService = FavoriteService();
  final FirebaseFavoriteService _firebaseFavoriteService =
      FirebaseFavoriteService();
  final YoutubeSearchService _youtubeSearchService = YoutubeSearchService();

  late final AnimationController _waveController;

  bool _isPlaying = false;
  bool _isFavorite = false;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 30);

  Color get _moodColor => Color(widget.moodColor ?? widget.song.moodColor);
  String get _moodTitle => widget.moodTitle ?? widget.song.moodTitle;
  String get _moodEmoji => widget.moodEmoji ?? widget.song.moodEmoji;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _audioPlayer.onPlayerComplete.listen((event) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    if (widget.autoPlay && widget.song.previewUrl.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _togglePlay());
    }
  }

  Widget _artworkFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.teal.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note_rounded,
          size: 96,
          color: Color(0xFF4F8F7A),
        ),
      ),
    );
  }

  Future<void> _togglePlay() async {
    if (widget.song.previewUrl.isEmpty) {
      _showSnackBar('這首歌沒有提供預覽音檔');
      return;
    }

    if (_isPlaying) {
      await _audioPlayer.pause();
      if (!mounted) return;
      setState(() => _isPlaying = false);
      return;
    }

    await _audioPlayer.play(UrlSource(widget.song.previewUrl));
    if (!mounted) return;
    setState(() => _isPlaying = true);
  }

  Future<void> _restart() async {
    if (widget.song.previewUrl.isEmpty) return;
    await _audioPlayer.seek(Duration.zero);
    await _audioPlayer.play(UrlSource(widget.song.previewUrl));
    if (!mounted) return;
    setState(() => _isPlaying = true);
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
      _showSnackBar('已收藏：${songToSave.trackName}');
    } catch (e) {
      _showSnackBar('收藏失敗：$e');
    }
  }

  Future<void> _openOnYoutube() async {
    try {
      final opened = await _youtubeSearchService.openSongOnYoutube(widget.song);
      if (!mounted) return;
      _showSnackBar(opened ? '正在開啟 YouTube 搜尋' : '無法開啟 YouTube 搜尋');
    } catch (e) {
      _showSnackBar('開啟 YouTube 失敗：$e');
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
    _waveController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final artwork = widget.song.artworkUrl.replaceAll('100x100bb', '600x600bb');

    return Scaffold(
      backgroundColor: const Color(0xFF101815),
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground(artwork)),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                child: Column(
                  children: [
                    _buildTopBar(),
                    const Spacer(),
                    Hero(
                      tag:
                          'artwork-${widget.song.artworkUrl}-${widget.song.trackName}',
                      child: _buildArtwork(artwork),
                    ),
                    const SizedBox(height: 28),
                    _buildSongText(),
                    const SizedBox(height: 20),
                    _buildWave(),
                    const SizedBox(height: 12),
                    _buildProgress(),
                    const SizedBox(height: 18),
                    _buildControls(),
                    const SizedBox(height: 18),
                    _buildMoodChip(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(String artwork) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (artwork.isNotEmpty)
          Image.network(
            artwork,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: Container(color: Colors.black.withOpacity(0.48)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.18),
                _moodColor.withOpacity(0.32),
                Colors.black.withOpacity(0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        _circleButton(
          icon: Icons.keyboard_arrow_down_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Expanded(
          child: Text(
            '沉浸播放',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ),
        _circleButton(icon: Icons.smart_display_rounded, onTap: _openOnYoutube),
      ],
    );
  }

  Widget _buildArtwork(String artwork) {
    return Center(
      child: SizedBox(
        width: 320,
        height: 320,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 42,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: artwork.isNotEmpty
                ? Image.network(
                    artwork,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _artworkFallback(),
                  )
                : _artworkFallback(),
          ),
        ),
      ),
    );
  }

  Widget _placeholderArtwork() {
    return Container(
      color: Colors.white.withOpacity(0.14),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: 84,
      ),
    );
  }

  Widget _buildSongText() {
    return Column(
      children: [
        Text(
          widget.song.trackName,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          widget.song.artistName,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildWave() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(19, (index) {
            final distance = (index - 9).abs();
            final base = 14.0 + (9 - distance) * 2.2;
            final pulse = _isPlaying
                ? _waveController.value * (16 - distance)
                : 0.0;
            return Container(
              width: 4,
              height: (base + pulse).clamp(10.0, 42.0),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22 + (9 - distance) * 0.035),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProgress() {
    final durationMs = _duration.inMilliseconds <= 0
        ? 1
        : _duration.inMilliseconds;
    final progress = (_position.inMilliseconds / durationMs).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 7,
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(_position), style: _timeStyle()),
            Text(_formatDuration(_duration), style: _timeStyle()),
          ],
        ),
      ],
    );
  }

  TextStyle _timeStyle() {
    return TextStyle(
      color: Colors.white.withOpacity(0.62),
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: _isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          onTap: _addToFavorite,
          size: 54,
          isActive: _isFavorite,
        ),
        const SizedBox(width: 18),
        GestureDetector(
          onTap: _togglePlay,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(_isPlaying ? 0.30 : 0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: const Color(0xFF1F5C49),
              size: 42,
            ),
          ),
        ),
        const SizedBox(width: 18),
        _circleButton(icon: Icons.replay_rounded, onTap: _restart, size: 54),
      ],
    );
  }

  Widget _buildMoodChip() {
    final text = _moodTitle.isEmpty ? '適合現在的心情' : '$_moodEmoji $_moodTitle';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 44,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.14)),
        ),
        child: Icon(
          icon,
          color: isActive ? _moodColor : Colors.white,
          size: size >= 54 ? 27 : 24,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString();
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
