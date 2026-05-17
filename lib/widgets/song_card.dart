import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/song.dart';
import '../services/favorite_service.dart';

class SongCard extends StatefulWidget {
  final Song song;

  const SongCard({super.key, required this.song});

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FavoriteService _favoriteService = FavoriteService();
  bool _isFavorite = false;
  bool _isPlaying = false;

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
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(widget.song.previewUrl));
      setState(() {
        _isPlaying = true;
      });
    }

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _addToFavorite() async {
    await _favoriteService.addFavoriteSong(widget.song);

    if (!mounted) return;

    setState(() {
      _isFavorite = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已收藏：${widget.song.trackName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: widget.song.artworkUrl.isNotEmpty
                ? Image.network(
                    widget.song.artworkUrl.replaceAll('100x100bb', '300x300bb'),
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.song.trackName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F5C49),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.song.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF5F7F73),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.song.collectionName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9AAFA6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              GestureDetector(
                onTap: _addToFavorite,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isFavorite
                        ? const Color(0xFF2E7D62)
                        : const Color(0xFFE0F2E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.favorite_rounded,
                    color: _isFavorite ? Colors.white : const Color(0xFF2E7D62),
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? const Color(0xFF2E7D62)
                        : const Color(0xFFE0F2E8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    color: _isPlaying ? Colors.white : const Color(0xFF2E7D62),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Color(0xFF2E7D62),
        size: 34,
      ),
    );
  }
}
