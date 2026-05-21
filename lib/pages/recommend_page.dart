import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/mood.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../services/mood_history_service.dart';
import '../services/firebase_mood_history_service.dart';
import '../widgets/song_card.dart';

class RecommendPage extends StatefulWidget {
  final Mood mood;

  const RecommendPage({super.key, required this.mood});

  @override
  State<RecommendPage> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final MusicApiService _musicApiService = MusicApiService();
  final MoodHistoryService _moodHistoryService = MoodHistoryService();
  final FirebaseMoodHistoryService _firebaseMoodHistoryService =
      FirebaseMoodHistoryService();

  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _musicApiService.searchSongs(widget.mood.keyword);
    _saveMoodRecord();
  }

  Future<void> _saveMoodRecord() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _moodHistoryService.addMoodRecord(widget.mood);
    } else {
      await _firebaseMoodHistoryService.addMoodRecord(widget.mood);
    }
  }

  void _refreshSongs() {
    setState(() {
      _songsFuture = _musicApiService.searchSongs(widget.mood.keyword);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('正在重新為你推薦音樂...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3FBF6),
        elevation: 0,
        foregroundColor: const Color(0xFF1F5C49),
        title: Text('${widget.mood.emoji} ${widget.mood.title} 推薦'),
        actions: [
          IconButton(
            onPressed: _refreshSongs,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshSongs();
        },
        color: const Color(0xFF2E7D62),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoodHero(),
              const SizedBox(height: 24),
              _buildSectionHeader(title: '今日主推薦', subtitle: '根據你的心情，先聽這一首'),
              const SizedBox(height: 14),
              _buildMusicSection(),
              const SizedBox(height: 24),
              _buildSectionHeader(title: '今日療癒語錄', subtitle: '給現在的你一點溫柔'),
              const SizedBox(height: 14),
              _buildQuoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            widget.mood.color.withOpacity(0.82),
            const Color(0xFFEAF8F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            top: -18,
            child: Text(
              widget.mood.emoji,
              style: TextStyle(
                fontSize: 115,
                color: Colors.white.withOpacity(0.22),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: -20,
            child: Icon(
              Icons.graphic_eq_rounded,
              size: 90,
              color: Colors.white.withOpacity(0.18),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMoodTag(),
              const SizedBox(height: 18),
              Text(widget.mood.emoji, style: const TextStyle(fontSize: 54)),
              const SizedBox(height: 12),
              Text(
                '你選擇了「${widget.mood.title}」',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123D30),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getMoodDescription(widget.mood.title),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF315F50),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoodTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 15,
            color: Color(0xFF1F5C49),
          ),
          const SizedBox(width: 5),
          Text(
            _getMusicType(widget.mood.title),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F5C49),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }

  Widget _buildMusicSection() {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingMusicCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(
            message: snapshot.error.toString(),
            onRetry: _refreshSongs,
          );
        }

        final songs = snapshot.data ?? [];

        if (songs.isEmpty) {
          return _buildErrorCard(
            message: '找不到適合的歌曲，請稍後再試。',
            onRetry: _refreshSongs,
          );
        }

        final mainSong = songs.first;
        final otherSongs = songs.skip(1).take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SongCard(
              song: mainSong,
              isFeatured: true,
              moodTitle: widget.mood.title,
              moodEmoji: widget.mood.emoji,
              moodColor: widget.mood.color.value,
            ),
            const SizedBox(height: 14),
            _buildReasonCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(title: '更多推薦', subtitle: '也許你也會喜歡這些聲音'),
            const SizedBox(height: 14),
            ...otherSongs.map(
              (song) => SongCard(
                song: song,
                moodTitle: widget.mood.title,
                moodEmoji: widget.mood.emoji,
                moodColor: widget.mood.color.value,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReasonCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6ECDF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: Color(0xFF2E7D62),
              size: 25,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '推薦理由',
                  style: TextStyle(
                    color: Color(0xFF1F5C49),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getRecommendationReason(widget.mood.title),
                  style: const TextStyle(
                    color: Color(0xFF5F7F73),
                    fontSize: 14,
                    height: 1.55,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMusicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              '正在為你尋找適合的音樂...',
              style: TextStyle(
                color: Color(0xFF1F5C49),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFF2E7D62),
            size: 42,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1F5C49),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新載入'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D62),
              side: const BorderSide(color: Color(0xFF2E7D62)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '“',
            style: TextStyle(
              fontSize: 42,
              height: 1,
              color: Color(0xFF95D5B2),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getQuote(widget.mood.title),
              style: const TextStyle(
                fontSize: 16,
                height: 1.7,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F5C49),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodDescription(String title) {
    switch (title) {
      case '開心':
        return '把這份明亮的心情留下來，讓音樂陪你把今天變得更有節奏。';
      case '難過':
        return '沒關係，難過的時候不用急著變好，先讓自己被溫柔接住。';
      case '焦慮':
        return '先慢慢呼吸，讓音樂幫你把混亂的思緒整理成安靜的節奏。';
      case '疲憊':
        return '你已經努力很多了，現在可以讓身體和心都放鬆一點。';
      case '想專心':
        return '進入一個安靜的狀態，讓專注慢慢回到你身邊。';
      case '療癒':
        return '給自己一點柔軟的時間，慢慢修復今天消耗掉的能量。';
      default:
        return '讓 Moodify 為你找到適合現在心情的音樂。';
    }
  }

  String _getMusicType(String title) {
    switch (title) {
      case '開心':
        return '輕快 Pop 音樂';
      case '難過':
        return '溫柔鋼琴音樂';
      case '焦慮':
        return '放鬆冥想音樂';
      case '疲憊':
        return '睡眠鋼琴音樂';
      case '想專心':
        return 'Lo-fi Study 音樂';
      case '療癒':
        return '自然系療癒音樂';
      default:
        return '心情推薦音樂';
    }
  }

  String _getRecommendationReason(String title) {
    switch (title) {
      case '開心':
        return '開心的時候適合聽節奏明亮、旋律輕快的歌曲，讓好心情被延續下來。';
      case '難過':
        return '難過的時候不一定要立刻振作，溫柔的鋼琴與慢節奏音樂能陪你慢慢沉澱。';
      case '焦慮':
        return '焦慮時適合聽穩定、重複性高的旋律，讓呼吸和思緒慢慢回到平穩。';
      case '疲憊':
        return '疲憊時需要降低刺激感，柔和的睡眠音樂可以讓身體慢慢放鬆。';
      case '想專心':
        return '想專心時適合 Lo-fi 或純音樂，少一點歌詞干擾，幫助你進入自己的節奏。';
      case '療癒':
        return '療癒系音樂能讓情緒放慢，像替今天的自己留一個安靜的休息空間。';
      default:
        return 'Moodify 會依照你的心情，推薦適合現在狀態的音樂。';
    }
  }

  String _getQuote(String title) {
    switch (title) {
      case '開心':
        return '把今天的小小快樂收藏起來，它會在以後某個普通的日子裡，再次照亮你。';
      case '難過':
        return '你不需要馬上好起來，願意承認自己累了，也是一種溫柔的勇敢。';
      case '焦慮':
        return '先不用解決所有事情，先好好呼吸一次，讓自己回到現在。';
      case '疲憊':
        return '休息不是停下來，而是讓你有力氣繼續走向想去的地方。';
      case '想專心':
        return '專注不是逼自己更努力，而是把不必要的聲音慢慢放下。';
      case '療癒':
        return '慢慢來也沒有關係，植物也是一點一點長成森林的。';
      default:
        return '今天也請記得，溫柔地對待自己。';
    }
  }
}
