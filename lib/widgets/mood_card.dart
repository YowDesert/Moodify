import 'package:flutter/material.dart';
import '../models/mood.dart';

class MoodCard extends StatelessWidget {
  final Mood mood;
  final VoidCallback onTap;

  const MoodCard({super.key, required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE4F2EA), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D62).withOpacity(0.07),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: mood.color.withOpacity(0.28),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -24,
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: mood.color.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mood.emoji, style: const TextStyle(fontSize: 38)),
                    const Spacer(),
                    Text(
                      mood.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F5C49),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getMoodSubtitle(mood.title),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7D948A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
