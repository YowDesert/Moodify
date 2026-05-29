import 'package:flutter/material.dart';

class Mood {
  final String title;
  final String emoji;
  final String keyword;
  final Color color;

  const Mood({
    required this.title,
    required this.emoji,
    required this.keyword,
    required this.color,
  });
}
