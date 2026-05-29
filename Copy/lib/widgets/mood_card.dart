import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodCard extends StatelessWidget {
  final Mood mood;
  final VoidCallback onTap;

  const MoodCard({super.key, required this.mood, required this.onTap});

  static const Color textColor = Color(0xFF1D1D1F);
  static const Color subTextColor = Color(0xFF6E6E73);

  @override
  Widget build(BuildContext context) {
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
              colors: [Colors.white, mood.color.withOpacity(0.16)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white, width: 1),
            boxShadow: [
              BoxShadow(
                color: mood.color.withOpacity(0.16),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  top: -12,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.55),
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
                      color: mood.color.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 36)),
                    const Spacer(),
                    Text(
                      mood.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _getMoodSubtitle(mood.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: subTextColor,
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
