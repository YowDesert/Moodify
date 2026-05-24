import 'package:flutter/material.dart';
import '../models/mood.dart';
import '../widgets/mood_card.dart';
import 'ai_chat_page.dart';
import 'favorite_page.dart';
import 'recommend_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import '../services/favorite_service.dart';
import '../services/mood_history_service.dart';
import 'profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_favorite_service.dart';
import '../services/firebase_mood_history_service.dart';
import '../widgets/moodify_bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int favoriteCount = 0;
  int historyCount = 0;

  static const Color bgColor = Color(0xFFF5F5F7);
  static const Color primaryColor = Color(0xFF2E7D62);
  static const Color textColor = Color(0xFF1D1D1F);
  static const Color subTextColor = Color(0xFF6E6E73);
  static const Color cardColor = Colors.white;

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
      });
    } else {
      final favorites = await FirebaseFavoriteService().getFavoriteSongs();
      final histories = await FirebaseMoodHistoryService().getMoodRecords();

      if (!mounted) return;

      setState(() {
        favoriteCount = favorites.length;
        historyCount = histories.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FAF8), Color(0xFFF5F5F7), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHomeStats,
            color: primaryColor,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
              children: [
                _buildTopTitle(),
                const SizedBox(height: 22),
                _buildTodaySummaryCard(),
                const SizedBox(height: 28),
                _buildGroupTitle('今天的心情'),
                const SizedBox(height: 10),
                _buildMoodGrid(context),
                const SizedBox(height: 28),
                _buildDailyCard(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const MoodifyBottomNavBar(currentTab: MoodifyTab.home),
    );
  }

  Widget _buildTopTitle() {
    return Row(
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
                  letterSpacing: -1,
                  color: textColor,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '讓音樂慢慢照顧你的心情',
                style: TextStyle(
                  fontSize: 15,
                  color: subTextColor,
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
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA), width: 0.6),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: primaryColor,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D62).withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Color(0xFF2E7D62),
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Moodify',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F5C49),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '讓音樂慢慢照顧你的心情',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6D8B7D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiChatPage()),
            );
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E8),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF2E7D62),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaySummaryCard() {
    final now = DateTime.now();
    final dateText = '${now.month}/${now.day}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEFF8F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.10),
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
                color: const Color(0xFFB7E4C7).withOpacity(0.35),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: -12,
            child: Icon(
              Icons.spa_rounded,
              size: 86,
              color: const Color(0xFF2E7D62).withOpacity(0.08),
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
                      color: const Color(0xFFE8F3EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '今天 $dateText',
                      style: const TextStyle(
                        color: primaryColor,
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
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: primaryColor,
                      size: 19,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                '今天，也要好好聽見自己',
                style: TextStyle(
                  color: textColor,
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 9),
              const Text(
                '選擇現在最接近的心情，Moodify 會推薦適合的音樂，也會幫你記錄下來。',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 0.6,
                  ),
                ),
                child: Row(
                  children: [
                    _buildSmallStat(value: '$favoriteCount', label: '收藏'),
                    _buildVerticalDivider(),
                    _buildSmallStat(value: '$historyCount', label: '紀錄'),
                    _buildVerticalDivider(),
                    _buildSmallStat(value: 'AI', label: '陪伴'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStat({required String value, required String label}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: subTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, height: 34, color: const Color(0xFFE5E5EA));
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: subTextColor,
        ),
      ),
    );
  }

  Widget _heroPill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF1F5C49)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1F5C49),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.35),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFF1F5C49)),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF123D30),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF315F50),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroMiniInfo({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.32),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1F5C49)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1F5C49),
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
                  color: Color(0xFF1F5C49),
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF6D8B7D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F2E8),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '6 種心情',
            style: TextStyle(
              color: Color(0xFF2E7D62),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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

  Widget _buildDailyCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _iosCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: primaryColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '心情月曆',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '用月曆查看過去的情緒變化。',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFC7C7CC)),
        ],
      ),
    );
  }

  BoxDecoration _iosCardDecoration() {
    return BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE5E5EA), width: 0.6),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 82,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 66,
              child: Row(
                children: [
                  _buildNavItem(
                    icon: Icons.home_rounded,
                    label: '首頁',
                    isSelected: true,
                  ),
                  _buildNavItem(
                    icon: Icons.favorite_rounded,
                    label: '收藏',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FavoritePage()),
                      );
                      _loadHomeStats();
                    },
                  ),

                  const SizedBox(width: 86),

                  _buildNavItem(
                    icon: Icons.bar_chart_rounded,
                    label: '紀錄',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                      _loadHomeStats();
                    },
                  ),
                  _buildNavItem(
                    icon: Icons.person_rounded,
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
          ),

          Positioned(
            top: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AiChatPage()),
                );
              },
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF66D6A3), Color(0xFF2E7D62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2E7D62).withOpacity(0.28),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(height: 1),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Icon(
              icon,
              size: 23,
              color: isSelected
                  ? const Color(0xFF2E7D62)
                  : const Color(0xFF9AAFA6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF2E7D62)
                    : const Color(0xFF9AAFA6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
