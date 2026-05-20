import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../models/song.dart';
import '../services/music_api_service.dart';
import '../widgets/song_card.dart';
import '../services/mood_history_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_mood_history_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3FBF6),
        elevation: 0,
        foregroundColor: const Color(0xFF1F5C49),
        title: Text('${widget.mood.emoji} ${widget.mood.title} 推薦'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMoodHero(),
            const SizedBox(height: 24),
            _buildSectionTitle('為你推薦的音樂'),
            const SizedBox(height: 14),
            _buildMusicCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('今日療癒語錄'),
            const SizedBox(height: 14),
            _buildQuoteCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            widget.mood.color.withOpacity(0.75),
            const Color(0xFFEAF8F0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.12),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -12,
            child: Text(
              widget.mood.emoji,
              style: TextStyle(
                fontSize: 100,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.mood.emoji, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              Text(
                '你選擇了「${widget.mood.title}」',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123D30),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getMoodDescription(widget.mood.title),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1F5C49),
      ),
    );
  }

  Widget _buildMusicCard() {
    return FutureBuilder<List<Song>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingMusicCard();
        }

        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }

        final songs = snapshot.data ?? [];

        if (songs.isEmpty) {
          return _buildErrorCard('找不到適合的歌曲，請稍後再試。');
        }

        return Column(
          children: songs.map((song) {
            return SongCard(song: song);
          }).toList(),
        );
      },
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
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 14),
          Text(
            '正在為你尋找適合的音樂...',
            style: TextStyle(
              color: Color(0xFF1F5C49),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF1F5C49),
          fontWeight: FontWeight.w700,
        ),
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
      child: Text(
        _getQuote(widget.mood.title),
        style: const TextStyle(
          fontSize: 16,
          height: 1.7,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F5C49),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.favorite_rounded),
            label: const Text('收藏'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D62),
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重新推薦'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D62),
              side: const BorderSide(color: Color(0xFF2E7D62), width: 1.4),
              minimumSize: const Size(0, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
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

  String _getQuote(String title) {
    switch (title) {
      case '開心':
        return '「把今天的小小快樂收藏起來，它會在以後某個普通的日子裡，再次照亮你。」';
      case '難過':
        return '「你不需要馬上好起來，願意承認自己累了，也是一種溫柔的勇敢。」';
      case '焦慮':
        return '「先不用解決所有事情，先好好呼吸一次，讓自己回到現在。」';
      case '疲憊':
        return '「休息不是停下來，而是讓你有力氣繼續走向想去的地方。」';
      case '想專心':
        return '「專注不是逼自己更努力，而是把不必要的聲音慢慢放下。」';
      case '療癒':
        return '「慢慢來也沒有關係，植物也是一點一點長成森林的。」';
      default:
        return '「今天也請記得，溫柔地對待自己。」';
    }
  }
}
