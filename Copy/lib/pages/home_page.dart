import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../models/song.dart';
import '../services/app_theme_controller.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../services/firebase_mood_history_service.dart';
import '../services/mood_history_service.dart';
import '../services/music_api_service.dart';
import '../services/weather_service.dart';
import '../widgets/breathing_exercise_sheet.dart';
import '../widgets/mood_card.dart';
import '../widgets/moodify_bottom_nav_bar.dart';
import '../widgets/song_card.dart';
import 'ai_chat_page.dart';
import 'history_page.dart';
import 'recommend_page.dart';
import 'weekly_report_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int favoriteCount = 0;
  int historyCount = 0;

  List<Map<String, dynamic>> moodRecords = const [];
  List<Song> recommendedSongs = const [];

  bool isLoadingRecommendations = false;
  bool isLoadingWeather = false;

  Mood? recommendationMood;

  String weatherText = '正在取得台北天氣';
  double? weatherTemperature;

  final List<Mood> moods = const [
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
    _loadHomeStats();
    _loadWeatherTheme();
  }

  Future<void> _refreshHome() async {
    await Future.wait([_loadHomeStats(), _loadWeatherTheme()]);
  }

  Future<void> _loadWeatherTheme() async {
    if (!mounted) return;

    setState(() {
      isLoadingWeather = true;
    });

    try {
      final weather = await WeatherService().fetchTaipeiWeather();

      MoodifyThemeController.instance.applyWeatherTheme(
        weatherTheme: weather.themeType,
        weatherLabel: weather.label,
        temperature: weather.temperature,
      );

      if (!mounted) return;

      setState(() {
        weatherText = weather.label;
        weatherTemperature = weather.temperature;
        isLoadingWeather = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        weatherText = '天氣暫時無法取得';
        weatherTemperature = null;
        isLoadingWeather = false;
      });
    }
  }

  Future<void> _loadHomeStats() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      final favorites = await FavoriteService().getFavoriteSongs();
      final histories = await MoodHistoryService().getMoodRecords();

      if (!mounted) return;

      setState(() {
        favoriteCount = favorites.length;
        historyCount = histories.length;
        moodRecords = histories;
      });

      await _loadHomeRecommendations(histories);
    } else {
      final favorites = await FirebaseFavoriteService().getFavoriteSongs();
      final histories = await FirebaseMoodHistoryService().getMoodRecords();

      if (!mounted) return;

      setState(() {
        favoriteCount = favorites.length;
        historyCount = histories.length;
        moodRecords = histories;
      });

      await _loadHomeRecommendations(histories);
    }
  }

  Future<void> _loadHomeRecommendations(
    List<Map<String, dynamic>> histories,
  ) async {
    final mood = _moodForRecommendation(histories);

    if (!mounted) return;

    setState(() {
      isLoadingRecommendations = true;
      recommendationMood = mood;
    });

    try {
      final songs = await MusicApiService().searchSongs(mood.keyword);

      if (!mounted) return;

      setState(() {
        recommendedSongs = songs.take(3).toList();
        isLoadingRecommendations = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        recommendedSongs = const [];
        isLoadingRecommendations = false;
      });
    }
  }

  Mood _moodForRecommendation(List<Map<String, dynamic>> histories) {
    if (histories.isEmpty) {
      return moods.firstWhere((mood) => mood.keyword == 'healing');
    }

    final latestTitle = histories.first['title']?.toString() ?? '';

    return moods.firstWhere(
      (mood) => mood.title == latestTitle,
      orElse: () => moods.firstWhere((mood) => mood.keyword == 'healing'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MoodifyThemeState>(
      valueListenable: MoodifyThemeController.instance.notifier,
      builder: (context, themeState, _) {
        final themeColors = moodifyColors(themeState);

        return Scaffold(
          backgroundColor: themeColors.background,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  themeColors.background,
                  themeColors.background2,
                  themeColors.card,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshHome,
                color: themeColors.primary,
                backgroundColor: themeColors.card,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    _buildTopTitle(themeColors),
                    const SizedBox(height: 22),
                    _buildTodaySummaryCard(themeState, themeColors),
                    const SizedBox(height: 18),
                    _buildWeatherThemeCard(themeState, themeColors),
                    const SizedBox(height: 18),
                    _buildCompanionQuoteCard(themeColors),
                    const SizedBox(height: 18),
                    _buildQuickActions(context, themeColors),
                    const SizedBox(height: 28),
                    _buildGroupTitle('今天的心情', themeColors),
                    const SizedBox(height: 10),
                    _buildMoodGrid(context),
                    const SizedBox(height: 24),
                    _buildMoodInsightCard(themeColors),
                    const SizedBox(height: 18),
                    _buildHomeRecommendationSection(context, themeColors),
                    const SizedBox(height: 18),
                    _buildDailyCard(themeColors),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const MoodifyBottomNavBar(
            currentTab: MoodifyTab.home,
          ),
        );
      },
    );
  }

  Widget _buildTopTitle(MoodifyThemeColors themeColors) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moodify',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: themeColors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '讓音樂慢慢照顧你的心情',
                style: TextStyle(
                  fontSize: 15,
                  color: themeColors.subText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: themeColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: themeColors.line, width: 0.6),
            boxShadow: [
              BoxShadow(
                color: themeColors.primary.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.music_note_rounded,
            color: themeColors.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummaryCard(
    MoodifyThemeState themeState,
    MoodifyThemeColors themeColors,
  ) {
    final now = DateTime.now();
    final dateText = '${now.month}/${now.day}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [themeColors.card, themeColors.soft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: themeColors.line.withOpacity(themeState.isDark ? 0.55 : 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColors.primary.withOpacity(
              themeState.isDark ? 0.14 : 0.10,
            ),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -26,
            top: -28,
            child: Container(
              width: 125,
              height: 125,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: themeColors.primary.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: -12,
            child: Icon(
              Icons.spa_rounded,
              size: 86,
              color: themeColors.primary.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: themeColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '今天 $dateText',
                      style: TextStyle(
                        color: themeColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: themeColors.card.withOpacity(0.80),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: themeColors.primary,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                '今天，也要好好聽見自己',
                style: TextStyle(
                  color: themeColors.text,
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                '選擇現在最接近的心情，Moodify 會推薦適合的音樂，也會幫你記錄下來。',
                style: TextStyle(
                  color: themeColors.subText,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: themeColors.card.withOpacity(
                    themeState.isDark ? 0.68 : 0.78,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: themeColors.line, width: 0.6),
                ),
                child: Row(
                  children: [
                    _buildSmallStat(
                      value: '$favoriteCount',
                      label: '收藏',
                      themeColors: themeColors,
                    ),
                    _buildVerticalDivider(themeColors),
                    _buildSmallStat(
                      value: '$historyCount',
                      label: '紀錄',
                      themeColors: themeColors,
                    ),
                    _buildVerticalDivider(themeColors),
                    _buildSmallStat(
                      value: 'AI',
                      label: '陪伴',
                      themeColors: themeColors,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({
    required String value,
    required String label,
    required MoodifyThemeColors themeColors,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: themeColors.text,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: themeColors.subText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(MoodifyThemeColors themeColors) {
    return Container(width: 1, height: 34, color: themeColors.line);
  }

  Widget _buildWeatherThemeCard(
    MoodifyThemeState themeState,
    MoodifyThemeColors themeColors,
  ) {
    final isWeatherMode = themeState.mode == MoodifyThemeMode.weather;

    final tempText = weatherTemperature == null
        ? ''
        : '・${weatherTemperature!.toStringAsFixed(0)}°C';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _iosCardDecoration(themeState, themeColors),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: themeColors.soft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              isLoadingWeather ? Icons.sync_rounded : themeColors.weatherIcon,
              color: themeColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '天氣主題',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: themeColors.text,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '台北 $weatherText$tempText，${isWeatherMode ? '已自動套用' : '可在「我的」開啟'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: themeColors.subText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isWeatherMode,
            activeColor: themeColors.primary,
            onChanged: (value) {
              MoodifyThemeController.instance.setMode(
                value ? MoodifyThemeMode.weather : MoodifyThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionQuoteCard(MoodifyThemeColors themeColors) {
    final latestTitle = moodRecords.isEmpty
        ? null
        : moodRecords.first['title']?.toString();

    final text = latestTitle == null
        ? '先不用急著變好，今天只要慢慢聽見自己就夠了。'
        : '最近你記錄了「$latestTitle」，今天可以讓音樂先陪你把心放鬆一點。';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _plainCardDecoration(themeColors),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: themeColors.soft,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: themeColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '今日一句陪伴',
                  style: TextStyle(
                    color: themeColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: themeColors.subText,
                    fontSize: 13.5,
                    height: 1.45,
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

  Widget _buildQuickActions(
    BuildContext context,
    MoodifyThemeColors themeColors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupTitle('快速開始', themeColors),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.5,
          children: [
            _buildQuickActionButton(
              icon: Icons.air_rounded,
              title: '3 分鐘呼吸',
              subtitle: '跟著節奏慢下來',
              themeColors: themeColors,
              onTap: () => _showBreathingSheet(context),
            ),
            _buildQuickActionButton(
              icon: Icons.auto_graph_rounded,
              title: '每週報告',
              subtitle: '看見心情趨勢',
              themeColors: themeColors,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeeklyReportPage()),
                );
                _loadHomeStats();
              },
            ),
            _buildQuickActionButton(
              icon: Icons.chat_bubble_rounded,
              title: 'AI 陪我聊',
              subtitle: '說說現在',
              themeColors: themeColors,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatPage()),
                );
              },
            ),
            _buildQuickActionButton(
              icon: Icons.shuffle_rounded,
              title: '隨機推薦',
              subtitle: '換一首歌',
              themeColors: themeColors,
              onTap: () async {
                final mood = moods[Random().nextInt(moods.length)];

                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecommendPage(mood: mood)),
                );

                _loadHomeStats();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required MoodifyThemeColors themeColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: _plainCardDecoration(themeColors, radius: 22),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: themeColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: themeColors.primary, size: 21),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: themeColors.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodGrid(BuildContext context) {
    return GridView.builder(
      itemCount: moods.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, index) {
        final mood = moods[index];

        return MoodCard(
          mood: mood,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RecommendPage(mood: mood)),
            );

            _loadHomeStats();
          },
        );
      },
    );
  }

  Widget _buildMoodInsightCard(MoodifyThemeColors themeColors) {
    final topMood = _topMoodInRecentRecords();

    final latestEmoji = moodRecords.isEmpty
        ? '🌿'
        : (moodRecords.first['emoji']?.toString() ?? '🌿');

    final latestTitle = moodRecords.isEmpty
        ? '還沒有紀錄'
        : (moodRecords.first['title']?.toString() ?? '心情');

    final title = topMood == null ? '開始累積你的心情趨勢' : '這週你比較常感到：$topMood';

    final subtitle = moodRecords.isEmpty
        ? '記錄幾次之後，這裡會顯示你最近的心情變化。'
        : '最近一次是 $latestEmoji $latestTitle，Moodify 會依照你的狀態調整推薦。';

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        );

        _loadHomeStats();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [themeColors.soft, themeColors.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: themeColors.line, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: themeColors.card.withOpacity(0.85),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                Icons.insights_rounded,
                color: themeColors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: themeColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: themeColors.subText,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: themeColors.subText.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  String? _topMoodInRecentRecords() {
    if (moodRecords.isEmpty) return null;

    final counts = <String, int>{};

    for (final record in moodRecords.take(12)) {
      final title = record['title']?.toString();

      if (title == null || title.isEmpty) continue;

      counts[title] = (counts[title] ?? 0) + 1;
    }

    if (counts.isEmpty) return null;

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  Widget _buildHomeRecommendationSection(
    BuildContext context,
    MoodifyThemeColors themeColors,
  ) {
    final mood =
        recommendationMood ??
        moods.firstWhere((item) => item.keyword == 'healing');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '推薦歌曲 ✨',
                    style: TextStyle(
                      color: themeColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    moodRecords.isEmpty
                        ? '先用溫柔的音樂陪你開始今天。'
                        : '依照最近的 ${mood.emoji} ${mood.title}，幫你挑幾首適合的歌。',
                    style: TextStyle(
                      color: themeColors.subText,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RecommendPage(mood: mood)),
                );

                _loadHomeStats();
              },
              style: TextButton.styleFrom(
                foregroundColor: themeColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              child: const Text(
                '看更多',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoadingRecommendations)
          _buildRecommendationLoadingCard(themeColors)
        else if (recommendedSongs.isEmpty)
          _buildEmptyRecommendationCard(context, mood, themeColors)
        else
          Column(
            children: recommendedSongs
                .map(
                  (song) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SongCard(
                      song: song,
                      moodTitle: mood.title,
                      moodEmoji: mood.emoji,
                      moodColor: mood.color.value,
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Widget _buildRecommendationLoadingCard(MoodifyThemeColors themeColors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _plainCardDecoration(themeColors),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: themeColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '正在幫你找適合現在心情的歌曲...',
              style: TextStyle(
                color: themeColors.subText,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendationCard(
    BuildContext context,
    Mood mood,
    MoodifyThemeColors themeColors,
  ) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RecommendPage(mood: mood)),
        );

        _loadHomeStats();
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _plainCardDecoration(themeColors),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: themeColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.queue_music_rounded,
                color: themeColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '還沒抓到推薦歌曲',
                    style: TextStyle(
                      color: themeColors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '點一下進入完整推薦頁，重新幫你找歌。',
                    style: TextStyle(
                      color: themeColors.subText,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: themeColors.subText.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyCard(MoodifyThemeColors themeColors) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HistoryPage()),
        );

        _loadHomeStats();
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _plainCardDecoration(themeColors),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: themeColors.soft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: themeColors.primary,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '心情月曆',
                    style: TextStyle(
                      color: themeColors.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '用月曆查看過去的情緒變化。',
                    style: TextStyle(
                      color: themeColors.subText,
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: themeColors.subText.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupTitle(String title, MoodifyThemeColors themeColors) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: themeColors.subText,
        ),
      ),
    );
  }

  void _showBreathingSheet(BuildContext context) {
    showBreathingExerciseSheet(context);
  }

  BoxDecoration _iosCardDecoration(
    MoodifyThemeState themeState,
    MoodifyThemeColors themeColors,
  ) {
    return BoxDecoration(
      color: themeColors.card.withOpacity(themeState.isDark ? 0.88 : 0.96),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: themeColors.line.withOpacity(0.85), width: 1),
      boxShadow: [
        BoxShadow(
          color: themeColors.primary.withOpacity(
            themeState.isDark ? 0.10 : 0.08,
          ),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  BoxDecoration _plainCardDecoration(
    MoodifyThemeColors themeColors, {
    double radius = 22,
  }) {
    return BoxDecoration(
      color: themeColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: themeColors.line, width: 0.6),
      boxShadow: [
        BoxShadow(
          color: themeColors.primary.withOpacity(0.05),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
