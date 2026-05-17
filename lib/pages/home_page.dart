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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int favoriteCount = 0;
  int historyCount = 0;

  final List<Mood> moods = const [
    Mood(
      title: '開心',
      emoji: '😊',
      keyword: 'happy pop',
      color: Color(0xFFFFD166),
    ),
    Mood(
      title: '難過',
      emoji: '😔',
      keyword: 'sad piano',
      color: Color(0xFF8ECAE6),
    ),
    Mood(
      title: '焦慮',
      emoji: '😰',
      keyword: 'calm relaxing',
      color: Color(0xFFA8DADC),
    ),
    Mood(
      title: '疲憊',
      emoji: '😴',
      keyword: 'sleep piano',
      color: Color(0xFFCDB4DB),
    ),
    Mood(
      title: '想專心',
      emoji: '🎧',
      keyword: 'lofi study',
      color: Color(0xFFB7E4C7),
    ),
    Mood(
      title: '療癒',
      emoji: '🌿',
      keyword: 'healing music',
      color: Color(0xFF95D5B2),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHomeStats();
  }

  Future<void> _loadHomeStats() async {
    final favorites = await FavoriteService().getFavoriteSongs();
    final histories = await MoodHistoryService().getMoodRecords();

    if (!mounted) return;

    setState(() {
      favoriteCount = favorites.length;
      historyCount = histories.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      body: RefreshIndicator(
        onRefresh: _loadHomeStats,
        color: const Color(0xFF2E7D62),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFEAF8F0), Color(0xFFF7FCF9), Color(0xFFFFFFFF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _buildHeroSection(),
                  const SizedBox(height: 26),
                  _buildSectionHeader(title: '今天的心情', subtitle: '選一個最接近你的狀態'),
                  const SizedBox(height: 16),
                  _buildMoodGrid(context),
                  const SizedBox(height: 26),
                  _buildDailyCard(),
                ],
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: _buildBottomNavBar(context),
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

  Widget _buildHeroSection() {
    final now = DateTime.now();
    final dateText = '${now.month}/${now.day}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFB7E4C7), Color(0xFF95D5B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.18),
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
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: -16,
            child: Icon(
              Icons.spa_rounded,
              size: 92,
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _heroPill(
                    icon: Icons.calendar_today_rounded,
                    text: '今天 $dateText',
                  ),
                  const SizedBox(width: 8),
                  _heroPill(icon: Icons.auto_awesome_rounded, text: 'AI 陪伴'),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                '今天，也要好好聽見自己',
                style: TextStyle(
                  color: Color(0xFF123D30),
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '選擇心情後，Moodify 會推薦音樂、記錄狀態，也可以讓 AI 陪你整理今天的感受。',
                style: TextStyle(
                  color: Color(0xFF315F50),
                  fontSize: 15,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _heroStatCard(
                    icon: Icons.favorite_rounded,
                    value: '$favoriteCount',
                    label: '收藏歌曲',
                  ),
                  const SizedBox(width: 10),
                  _heroStatCard(
                    icon: Icons.bar_chart_rounded,
                    value: '$historyCount',
                    label: '心情紀錄',
                  ),
                ],
              ),
            ],
          ),
        ],
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
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.05,
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
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2E7D62),
              size: 28,
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '建立你的心情日記',
                  style: TextStyle(
                    color: Color(0xFF1F5C49),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  '每天記錄一點點，慢慢看見自己的變化。',
                  style: TextStyle(
                    color: Color(0xFF6D8B7D),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFF95AFA4),
          ),
        ],
      ),
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
                    colors: [Color(0xFF52B788), Color(0xFF2D6A4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2E7D62).withOpacity(0.26),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
