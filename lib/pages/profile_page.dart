import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/moodify_bottom_nav_bar.dart';

import '../services/auth_service.dart';
import '../services/sync_service.dart';
import '../services/favorite_service.dart';
import '../services/firebase_favorite_service.dart';
import '../services/mood_history_service.dart';
import '../services/firebase_mood_history_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final SyncService _syncService = SyncService();

  int favoriteCount = 0;
  int historyCount = 0;
  bool isLoadingStats = true;
  bool bedtimeRelax = true;
  bool morningMusic = true;

  static const Color bgColor = Color(0xFFFAFBF7);
  static const Color primaryColor = Color(0xFF2E6F52);
  static const Color deepGreen = Color(0xFF174632);
  static const Color textColor = Color(0xFF24312A);
  static const Color subTextColor = Color(0xFF7A817B);
  static const Color lineColor = Color(0xFFE8E6DD);
  static const Color softGreen = Color(0xFFEAF3EA);
  static const Color cardColor = Color(0xFFFFFEFA);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => isLoadingStats = true);

    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user == null) {
        final favorites = await FavoriteService().getFavoriteSongs();
        final histories = await MoodHistoryService().getMoodRecords();

        if (!mounted) return;
        setState(() {
          favoriteCount = favorites.length;
          historyCount = histories.length;
          isLoadingStats = false;
        });
      } else {
        final favorites = await FirebaseFavoriteService().getFavoriteSongs();
        final histories = await FirebaseMoodHistoryService().getMoodRecords();

        if (!mounted) return;
        setState(() {
          favoriteCount = favorites.length;
          historyCount = histories.length;
          isLoadingStats = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoadingStats = false);
    }
  }

  Future<void> _signIn() async {
    try {
      final result = await _authService.signInWithGoogle();

      if (result != null) {
        await _syncService.syncLocalDataToFirebase();
        await _loadStats();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登入成功，已同步本機資料到雲端'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google 登入失敗：$e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmSignOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('登出 Moodify？'),
          content: const Text('登出後，雲端收藏與心情紀錄需要重新登入才會顯示。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('登出', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldSignOut == true) {
      await _authService.signOut();
      await _loadStats();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已登出 Google 帳號'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refreshPage() async => _loadStats();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;

        return Scaffold(
          backgroundColor: bgColor,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFEFEFA),
                  Color(0xFFF8FAF4),
                  Color(0xFFFFFFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                onRefresh: _refreshPage,
                color: primaryColor,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    user == null
                        ? _buildGuestProfileCard()
                        : _buildUserProfileCard(user),
                    const SizedBox(height: 28),
                    _buildSectionTitle('偏好設定'),
                    const SizedBox(height: 12),
                    _buildPreferenceCard(user),
                    const SizedBox(height: 28),
                    _buildSectionTitle('我的習慣'),
                    const SizedBox(height: 12),
                    _buildHabitCards(),
                    const SizedBox(height: 24),
                    _buildUpgradeButton(),
                    const SizedBox(height: 14),
                    user == null ? _buildLoginButton() : _buildLogoutButton(),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: const MoodifyBottomNavBar(currentTab: MoodifyTab.profile),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          right: -18,
          top: -10,
          child: Icon(
            Icons.eco_rounded,
            size: 142,
            color: primaryColor.withOpacity(0.08),
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
                    '我的',
                    style: TextStyle(
                      fontSize: 46,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.6,
                      color: deepGreen,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '照顧你的個人空間',
                    style: TextStyle(
                      fontSize: 17,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _refreshPage,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _softShadow(opacity: 0.08, blur: 20),
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
        Positioned(
          right: 145,
          top: 30,
          child: Icon(
            Icons.auto_awesome_rounded,
            color: const Color(0xFFD8C98E).withOpacity(0.65),
            size: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildUserProfileCard(User user) {
    final name = user.displayName?.trim().isNotEmpty == true
        ? user.displayName!.trim()
        : 'Yuna';
    final photoUrl = user.photoURL;

    return _buildProfileCard(
      name: name,
      subtitle: '今天也在溫柔照顧自己',
      photoUrl: photoUrl,
      showCloudBadge: true,
    );
  }

  Widget _buildGuestProfileCard() {
    return _buildProfileCard(
      name: 'Yuna',
      subtitle: '登入後同步你的收藏與心情紀錄',
      showCloudBadge: false,
    );
  }

  Widget _buildProfileCard({
    required String name,
    required String subtitle,
    String? photoUrl,
    required bool showCloudBadge,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F6ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.3),
        boxShadow: _softShadow(opacity: 0.10, blur: 28, y: 14),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -32,
            child: Container(
              width: 170,
              height: 130,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(90),
              ),
            ),
          ),
          Positioned(
            right: 30,
            top: 2,
            child: Icon(
              Icons.eco_rounded,
              size: 80,
              color: primaryColor.withOpacity(0.08),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  _buildAvatar(photoUrl),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: deepGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFF78A785),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.eco_rounded,
                                color: Colors.white,
                                size: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            color: subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      shape: BoxShape.circle,
                      boxShadow: _softShadow(opacity: 0.07, blur: 14, y: 6),
                    ),
                    child: Icon(
                      showCloudBadge
                          ? Icons.chevron_right_rounded
                          : Icons.login_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.favorite_border_rounded,
                      title: '收藏',
                      value: isLoadingStats ? '...' : '$favoriteCount',
                      unit: '',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.calendar_month_rounded,
                      title: '連續紀錄',
                      value: isLoadingStats ? '...' : _streakText(),
                      unit: '天',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMiniStatCard(
                      icon: Icons.smart_toy_outlined,
                      title: '已陪伴',
                      value: isLoadingStats ? '...' : '$historyCount',
                      unit: '次',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _streakText() {
    if (historyCount <= 0) return '0';
    if (historyCount < 7) return '$historyCount';
    return '7';
  }

  Widget _buildAvatar(String? photoUrl) {
    return Container(
      width: 92,
      height: 92,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE6F0DE), Color(0xFFFAF5DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _softShadow(opacity: 0.08, blur: 18, y: 8),
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE8F3E6),
        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
        child: photoUrl == null ? const _SoftAvatarFace() : null,
      ),
    );
  }

  Widget _buildMiniStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      // 原本 88 在部分 Android 模擬器上會差幾 px，導致底部 RenderFlex overflow。
      height: 104,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: _softShadow(opacity: 0.06, blur: 16, y: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(height: 5),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.0,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              maxLines: 1,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.0,
                      color: deepGreen,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextSpan(
                    text: unit.isEmpty ? '' : ' $unit',
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.0,
                      color: textColor,
                      fontWeight: FontWeight.w700,
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Icon(
          Icons.eco_rounded,
          color: primaryColor.withOpacity(0.72),
          size: 23,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceCard(User? user) {
    return Container(
      decoration: _cardDecoration(radius: 26),
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.music_note_rounded,
            title: '音樂偏好',
            onTap: () {},
          ),
          _buildThinDivider(),
          _buildSettingRow(
            icon: Icons.notifications_none_rounded,
            title: '通知提醒',
            onTap: () {},
          ),
          _buildThinDivider(),
          _buildSettingRow(
            icon: Icons.smart_toy_outlined,
            title: 'AI 陪伴設定',
            onTap: () {},
          ),
          _buildThinDivider(),
          _buildSettingRow(
            icon: user == null
                ? Icons.phone_iphone_rounded
                : Icons.verified_user_outlined,
            title: '隱私與資料',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: softGreen,
                shape: BoxShape.circle,
                boxShadow: _softShadow(opacity: 0.03, blur: 10, y: 4),
              ),
              child: Icon(icon, color: primaryColor, size: 24),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF8B8F8B),
              size: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitCards() {
    return Row(
      children: [
        Expanded(
          child: _buildHabitCard(
            title: '睡前放鬆',
            line1: '每天睡前 15 分鐘',
            line2: '放鬆身心',
            icon: Icons.nightlight_round,
            iconColor: const Color(0xFF9C8ED0),
            bg1: const Color(0xFFF8F5FF),
            bg2: const Color(0xFFFFFFFF),
            value: bedtimeRelax,
            onChanged: (v) => setState(() => bedtimeRelax = v),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildHabitCard(
            title: '晨間音樂',
            line1: '每天早晨聽音樂',
            line2: '開啟美好的一天',
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFE5B452),
            bg1: const Color(0xFFFFF7E8),
            bg2: const Color(0xFFFFFFFF),
            value: morningMusic,
            onChanged: (v) => setState(() => morningMusic = v),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard({
    required String title,
    required String line1,
    required String line2,
    required IconData icon,
    required Color iconColor,
    required Color bg1,
    required Color bg2,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [bg1, bg2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: _softShadow(opacity: 0.07, blur: 18, y: 8),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -10,
            bottom: -10,
            child: Icon(
              Icons.eco_rounded,
              size: 58,
              color: primaryColor.withOpacity(0.08),
            ),
          ),

          Positioned(
            left: 2,
            top: 4,
            child: Icon(icon, color: iconColor.withOpacity(0.82), size: 42),
          ),

          Positioned(
            right: -8,
            bottom: -8,
            child: Transform.scale(
              scale: 0.68,
              child: Switch(
                value: value,
                activeColor: Colors.white,
                activeTrackColor: primaryColor.withOpacity(0.78),
                inactiveTrackColor: const Color(0xFFE3E3E3),
                onChanged: onChanged,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 56, right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  line1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 46),
                  child: Text(
                    line2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeButton() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF78A785), Color(0xFF2E6F52)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: _softShadow(opacity: 0.16, blur: 22, y: 10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {},
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                '升級 Moodify+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 18),
              Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return GestureDetector(
      onTap: _signIn,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: primaryColor.withOpacity(0.35), width: 1),
          boxShadow: _softShadow(opacity: 0.05, blur: 14, y: 6),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              bottom: -10,
              child: Icon(
                Icons.eco_rounded,
                color: primaryColor.withOpacity(0.10),
                size: 54,
              ),
            ),
            const Center(
              child: Text(
                '使用 Google 登入',
                style: TextStyle(
                  fontSize: 17,
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _confirmSignOut,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: primaryColor.withOpacity(0.35), width: 1),
          boxShadow: _softShadow(opacity: 0.05, blur: 14, y: 6),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 22,
              bottom: -12,
              child: Icon(
                Icons.eco_rounded,
                color: primaryColor.withOpacity(0.10),
                size: 58,
              ),
            ),
            Positioned(
              right: 24,
              bottom: -12,
              child: Icon(
                Icons.eco_rounded,
                color: primaryColor.withOpacity(0.10),
                size: 58,
              ),
            ),
            const Center(
              child: Text(
                '登出',
                style: TextStyle(
                  fontSize: 18,
                  color: primaryColor,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThinDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 80, right: 24),
      child: Divider(
        height: 1,
        thickness: 0.8,
        color: lineColor.withOpacity(0.9),
      ),
    );
  }

  BoxDecoration _cardDecoration({double radius = 24}) {
    return BoxDecoration(
      color: cardColor.withOpacity(0.95),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white, width: 1.2),
      boxShadow: _softShadow(opacity: 0.07, blur: 18, y: 8),
    );
  }

  List<BoxShadow> _softShadow({
    double opacity = 0.08,
    double blur = 18,
    double y = 8,
  }) {
    return [
      BoxShadow(
        color: const Color(0xFF2E6F52).withOpacity(opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(opacity * 0.22),
        blurRadius: blur * 0.65,
        offset: Offset(0, y * 0.45),
      ),
    ];
  }
}

class _SoftAvatarFace extends StatelessWidget {
  const _SoftAvatarFace();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          bottom: 14,
          child: Container(
            width: 48,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFF2E5CE),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ),
        ),
        Positioned(
          top: 20,
          child: Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFF9C8566),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          top: 30,
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFF4DCC7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_satisfied_alt_rounded,
              size: 25,
              color: Color(0xFF5E6E58),
            ),
          ),
        ),
        Positioned(
          left: 10,
          bottom: 10,
          child: Icon(
            Icons.eco_rounded,
            size: 24,
            color: const Color(0xFF2E6F52).withOpacity(0.35),
          ),
        ),
        Positioned(
          right: 9,
          top: 10,
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: const Color(0xFFD8C98E).withOpacity(0.85),
          ),
        ),
      ],
    );
  }
}
