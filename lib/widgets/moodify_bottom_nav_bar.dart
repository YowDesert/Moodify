import 'package:flutter/material.dart';

import '../pages/ai_chat_page.dart';
import '../pages/favorite_page.dart';
import '../pages/history_page.dart';
import '../pages/home_page.dart';
import '../pages/profile_page.dart';

enum MoodifyTab { home, favorite, ai, history, profile }

class MoodifyBottomNavBar extends StatelessWidget {
  const MoodifyBottomNavBar({
    super.key,
    required this.currentTab,
  });

  final MoodifyTab currentTab;

  static const Color primaryColor = Color(0xFF2E7D62);
  static const Color inactiveColor = Color(0xFF9AAFA6);

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
    final isAiSelected = currentTab == MoodifyTab.ai;

    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
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
                      onTap: () => _openTab(context, MoodifyTab.home),
                    ),
                    _NavItem(
                      icon: Icons.favorite_rounded,
                      label: '收藏',
                      isSelected: currentTab == MoodifyTab.favorite,
                      onTap: () => _openTab(context, MoodifyTab.favorite),
                    ),
                    const SizedBox(width: 86),
                    _NavItem(
                      icon: Icons.bar_chart_rounded,
                      label: '紀錄',
                      isSelected: currentTab == MoodifyTab.history,
                      onTap: () => _openTab(context, MoodifyTab.history),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
                      label: '我的',
                      isSelected: currentTab == MoodifyTab.profile,
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
                  duration: const Duration(milliseconds: 180),
                  width: isAiSelected ? 68 : 62,
                  height: isAiSelected ? 68 : 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6ED8A7), Color(0xFF2E7D62)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(isAiSelected ? 0.34 : 0.24),
                        blurRadius: isAiSelected ? 22 : 18,
                        offset: const Offset(0, 8),
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
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? MoodifyBottomNavBar.primaryColor
                  : MoodifyBottomNavBar.inactiveColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? MoodifyBottomNavBar.primaryColor
                    : MoodifyBottomNavBar.inactiveColor,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected
                    ? MoodifyBottomNavBar.primaryColor
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
