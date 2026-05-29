import 'package:flutter/material.dart';

import '../pages/ai_chat_page.dart';
import '../pages/favorite_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';
import '../services/app_theme_controller.dart';

enum MoodifyTab { home, favorite, ai, history, profile }

class MoodifyBottomNavBar extends StatelessWidget {
  const MoodifyBottomNavBar({
    super.key,
    required this.currentTab,
  });

  final MoodifyTab currentTab;

  void _openTab(BuildContext context, MoodifyTab tab) {
    if (tab == currentTab) return;

    Widget page;
    switch (tab) {
      case MoodifyTab.home:
        page = const HomePage();
        break;
      case MoodifyTab.favorite:
        page = const FavoritePage();
        break;
      case MoodifyTab.ai:
        page = const AiChatPage();
        break;
      case MoodifyTab.history:
        page = const HistoryPage();
        break;
      case MoodifyTab.profile:
        page = const ProfilePage();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MoodifyThemeState>(
      valueListenable: MoodifyThemeController.instance.notifier,
      builder: (context, themeState, _) {
        final colors = moodifyColors(themeState);
        final isAiSelected = currentTab == MoodifyTab.ai;

        return Container(
          height: 92,
          decoration: BoxDecoration(
            color: colors.card.withOpacity(themeState.isDark ? 0.92 : 0.96),
            border: Border(top: BorderSide(color: colors.line, width: 0.8)),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(themeState.isDark ? 0.14 : 0.08),
                blurRadius: 24,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    height: 70,
                    child: Row(
                      children: [
                        _NavItem(
                          icon: Icons.home_rounded,
                          label: '首頁',
                          isSelected: currentTab == MoodifyTab.home,
                          colors: colors,
                          onTap: () => _openTab(context, MoodifyTab.home),
                        ),
                        _NavItem(
                          icon: Icons.favorite_rounded,
                          label: '收藏',
                          isSelected: currentTab == MoodifyTab.favorite,
                          colors: colors,
                          onTap: () => _openTab(context, MoodifyTab.favorite),
                        ),
                        SizedBox(width: 86),
                        _NavItem(
                          icon: Icons.bar_chart_rounded,
                          label: '紀錄',
                          isSelected: currentTab == MoodifyTab.history,
                          colors: colors,
                          onTap: () => _openTab(context, MoodifyTab.history),
                        ),
                        _NavItem(
                          icon: Icons.person_rounded,
                          label: '我的',
                          isSelected: currentTab == MoodifyTab.profile,
                          colors: colors,
                          onTap: () => _openTab(context, MoodifyTab.profile),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -4,
                  child: GestureDetector(
                    onTap: () => _openTab(context, MoodifyTab.ai),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 180),
                      width: isAiSelected ? 68 : 62,
                      height: isAiSelected ? 68 : 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [colors.primary.withOpacity(0.72), colors.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withOpacity(isAiSelected ? 0.34 : 0.24),
                            blurRadius: isAiSelected ? 22 : 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: colors.card, width: 4),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
                          SizedBox(height: 1),
                          Text('AI', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.2)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
 }

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final MoodifyThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inactive = colors.subText.withOpacity(0.70);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: isSelected ? colors.primary : inactive),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? colors.primary : inactive,
              ),
            ),
            SizedBox(height: 4),
            AnimatedContainer(
              duration: Duration(milliseconds: 180),
              width: isSelected ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
