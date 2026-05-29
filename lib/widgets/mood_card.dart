import 'package:flutter/material.dart';

import '../models/mood.dart';
import '../services/app_theme_controller.dart';

class MoodCard extends StatelessWidget {
  final Mood mood;
  final VoidCallback onTap;

  const MoodCard({super.key, required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MoodifyThemeState>(
      valueListenable: MoodifyThemeController.instance.notifier,
      builder: (context, themeState, _) {
        final colors = moodifyColors(themeState);
        final cardStart = themeState.isDark
            ? Color.lerp(colors.card, colors.background2, 0.26)!
            : Color.lerp(colors.card, mood.color, 0.06)!;
        final cardEnd = themeState.isDark
            ? Color.lerp(colors.card, mood.color, 0.08)!
            : Color.lerp(colors.card, mood.color, 0.13)!;
        final accentLine = Color.lerp(
          colors.line,
          mood.color,
          themeState.isDark ? 0.22 : 0.16,
        )!;
        final cornerBlob = Color.lerp(
          colors.soft,
          mood.color,
          themeState.isDark ? 0.18 : 0.34,
        )!;

        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [cardStart, cardEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: accentLine.withOpacity(0.95), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withOpacity(themeState.isDark ? 0.10 : 0.10),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -10,
                      child: Container(
                        width: 66,
                        height: 66,
                        decoration: BoxDecoration(
                          color: cornerBlob.withOpacity(themeState.isDark ? 0.24 : 0.56),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(24),
                            bottomLeft: Radius.circular(38),
                            bottomRight: Radius.circular(16),
                            topLeft: Radius.circular(38),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      top: 8,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: colors.card.withOpacity(themeState.isDark ? 0.12 : 0.38),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 8,
                      child: Container(
                        width: 30,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Color.lerp(colors.primary, mood.color, themeState.isDark ? 0.28 : 0.52)!
                              .withOpacity(themeState.isDark ? 0.38 : 0.34),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mood.emoji, style: TextStyle(fontSize: 36)),
                        Spacer(),
                        Text(
                          mood.title,
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.25,
                            color: colors.text,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          _getMoodSubtitle(mood.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.subText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMoodSubtitle(String title) {
    switch (title) {
      case '開心':
        return '保持這份光亮';
      case '難過':
        return '慢慢陪你沉澱';
      case '焦慮':
        return '讓呼吸變輕一點';
      case '疲憊':
        return '給自己一點休息';
      case '想專心':
        return '進入安靜節奏';
      case '療癒':
        return '溫柔地修復自己';
      default:
        return '聽一首適合的歌';
    }
  }
}
