import 'dart:math' as math;
import 'dart:ui';
import '../widgets/moodify_bottom_nav_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_mood_history_service.dart';
import '../services/mood_history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MoodHistoryService _historyService = MoodHistoryService();
  final FirebaseMoodHistoryService _firebaseHistoryService =
      FirebaseMoodHistoryService();

  static const Color bgColor = Color(0xFFFAFAF7);
  static const Color primaryColor = Color(0xFF3F7D5B);
  static const Color softGreen = Color(0xFFEAF3EC);
  static const Color textColor = Color(0xFF1F2522);
  static const Color subTextColor = Color(0xFF747B76);
  static const Color lineColor = Color(0xFFE8E5DE);
  static const Color cardColor = Color(0xFFFFFEFB);

  late Future<List<Map<String, dynamic>>> _recordsFuture;
  List<Map<String, dynamic>> _allRecords = [];

  int _selectedRange = 0; // 0 = 本週, 1 = 本月
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _recordsFuture = _historyService.getMoodRecords();
    } else {
      _recordsFuture = _firebaseHistoryService.getMoodRecords();
    }
  }

  Future<void> _refreshRecords() async {
    setState(_loadRecords);
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _historyService.deleteMoodRecord(record);
    } else {
      await _firebaseHistoryService.deleteMoodRecord(record);
    }

    if (!mounted) return;

    setState(_loadRecords);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已刪除這筆心情紀錄'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final records = snapshot.data ?? [];
            _allRecords = records;

            return RefreshIndicator(
              onRefresh: _refreshRecords,
              color: primaryColor,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 120),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 22),
                  _buildSegmentedControl(),
                  const SizedBox(height: 24),
                  if (records.isEmpty) ...[
                    _buildEmptyState(),
                  ] else ...[
                    _buildTrendCard(records),
                    const SizedBox(height: 26),
                    _buildCalendarStrip(records),
                    const SizedBox(height: 26),
                    _buildRecentRecords(records),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const MoodifyBottomNavBar(currentTab: MoodifyTab.history),
    );
  }

  Widget _buildHeroHeader() {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          const Positioned(
            right: -12,
            top: 6,
            child: Opacity(
              opacity: 0.16,
              child: Icon(Icons.eco_rounded, size: 150, color: primaryColor),
            ),
          ),
          Positioned(
            left: 0,
            top: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '紀錄',
                  style: TextStyle(
                    fontSize: 44,
                    height: 1,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '看看最近的心情變化',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 16,
            child: _glassIconButton(
              icon: Icons.music_note_rounded,
              onTap: _refreshRecords,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.78),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: primaryColor, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: lineColor),
      ),
      child: Row(
        children: [_buildSegmentButton('本週', 0), _buildSegmentButton('本月', 1)],
      ),
    );
  }

  Widget _buildSegmentButton(String title, int index) {
    final selected = _selectedRange == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRange = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : subTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendCard(List<Map<String, dynamic>> records) {
    final days = _selectedRange == 0 ? _weekDays() : _monthSampleDays();
    final points = days.map((day) => _averageScoreForDay(day)).toList();
    final total = _countRecordsInDays(days);
    final mostCommon = _getMostCommonMood(_recordsInDays(days));
    final average = _averageScore(_recordsInDays(days));

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: _iosCardDecoration(radius: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  '本週心情趨勢',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: primaryColor,
                  ),
                ),
              ),
              Text(
                '心情分數 (0-10)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 196,
            child: CustomPaint(
              painter: MoodTrendPainter(points: points),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(days.length, (index) {
                  final day = days[index];
                  final record = _firstRecordForDay(day);
                  final emoji = record?['emoji'] ?? '—';
                  final score = points[index] ?? 5.0;
                  final top = (1 - (score / 10)) * 128 + 12;

                  return Expanded(
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Positioned(
                          top: top,
                          child: _buildMoodBubble(emoji, _moodColor(record)),
                        ),
                        Positioned(
                          bottom: 0,
                          child: Text(
                            _weekdayText(day),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: subTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFBF7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: lineColor),
            ),
            child: Row(
              children: [
                _summaryTile(Icons.calendar_month_rounded, '本週紀錄', '$total 次'),
                _softDivider(),
                _summaryTile(Icons.wb_sunny_rounded, '最常出現', mostCommon),
                _softDivider(),
                _summaryTile(
                  Icons.sentiment_satisfied_alt_rounded,
                  '平均心情',
                  '${average.toStringAsFixed(1)} /10',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBubble(String emoji, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.28),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.72), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: primaryColor, size: 26),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: subTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _softDivider() {
    return Container(width: 1, height: 40, color: lineColor);
  }

  Widget _buildCalendarStrip(List<Map<String, dynamic>> records) {
    final days = _weekDays();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.eco_rounded, color: primaryColor, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '心情日曆',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.86),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: lineColor),
              ),
              child: const Text(
                '查看完整日曆',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: _iosCardDecoration(radius: 24),
          child: Row(
            children: [
              const Icon(Icons.chevron_left_rounded, color: subTextColor),
              ...days.map((day) {
                final selected = _isSameDate(day, _selectedDay);
                final today = _isSameDate(day, DateTime.now());
                final record = _firstRecordForDay(day);
                final emoji = record?['emoji'] ?? '—';

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedDay = day),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? softGreen : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _weekdayText(day),
                            style: const TextStyle(
                              fontSize: 13,
                              color: subTextColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: today
                                ? const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  )
                                : EdgeInsets.zero,
                            decoration: today
                                ? BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(18),
                                  )
                                : null,
                            child: Text(
                              today ? '今天' : '${day.day}',
                              style: TextStyle(
                                fontSize: 17,
                                color: today ? Colors.white : textColor,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(emoji, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const Icon(Icons.chevron_right_rounded, color: subTextColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentRecords(List<Map<String, dynamic>> records) {
    final selectedRecords = _recordsForDay(_selectedDay);
    final displayRecords = selectedRecords.isEmpty
        ? records.take(5).toList()
        : selectedRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.article_outlined, color: primaryColor, size: 25),
            SizedBox(width: 9),
            Text(
              '近期心情紀錄',
              style: TextStyle(
                color: primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (displayRecords.isEmpty)
          _buildNoRecordForDay()
        else
          ...displayRecords.map(_buildDismissibleRecordCard),
      ],
    );
  }

  Widget _buildDismissibleRecordCard(Map<String, dynamic> record) {
    final keyText =
        '${record['title']}-${record['emoji']}-${record['date']}-${record['time']}-${record['id'] ?? ''}';

    return Dismissible(
      key: ValueKey(keyText),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('刪除這筆紀錄？'),
                  content: const Text('這只會刪除你選擇的這一筆心情紀錄。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        '刪除',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                );
              },
            ) ??
            false;
      },
      onDismissed: (_) => _deleteRecord(record),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: _buildRecordCard(record),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final title = record['title'] ?? '未知心情';
    final emoji = record['emoji'] ?? '🌿';
    final date = record['date'] ?? '';
    final time = record['time'] ?? '';
    final keyword = record['keyword'] ?? '';
    final color = _moodColor(record);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: _iosCardDecoration(radius: 22),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 70,
            decoration: BoxDecoration(
              color: color.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 34)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _shortDate(date),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  keyword.toString().trim().isEmpty
                      ? '今天的心情是$title，記得溫柔照顧自己。'
                      : keyword.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424844),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.chevron_right_rounded, color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 44),
      decoration: _iosCardDecoration(radius: 30),
      child: Column(
        children: const [
          Icon(Icons.eco_rounded, color: primaryColor, size: 62),
          SizedBox(height: 18),
          Text(
            '還沒有心情紀錄',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '從首頁選擇心情後，Moodify 會幫你記錄每天的狀態。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: subTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoRecordForDay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: _iosCardDecoration(radius: 24),
      child: const Text(
        '這一天還沒有紀錄',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          color: subTextColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<DateTime> _weekDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<DateTime> _monthSampleDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(
      7,
      (index) => today.subtract(Duration(days: (6 - index) * 4)),
    );
  }

  List<Map<String, dynamic>> _recordsInDays(List<DateTime> days) {
    return _allRecords.where((record) {
      final date = _parseRecordDate(record['date']);
      if (date == null) return false;
      return days.any((day) => _isSameDate(day, date));
    }).toList();
  }

  int _countRecordsInDays(List<DateTime> days) => _recordsInDays(days).length;

  List<Map<String, dynamic>> _recordsForDay(DateTime day) {
    return _allRecords.where((record) {
      final recordDate = _parseRecordDate(record['date']);
      return recordDate != null && _isSameDate(recordDate, day);
    }).toList();
  }

  Map<String, dynamic>? _firstRecordForDay(DateTime day) {
    final list = _recordsForDay(day);
    if (list.isEmpty) return null;
    return list.first;
  }

  double? _averageScoreForDay(DateTime day) {
    final records = _recordsForDay(day);
    if (records.isEmpty) return null;

    final total = records.fold<double>(
      0,
      (sum, record) => sum + _moodScore(record),
    );
    return total / records.length;
  }

  double _averageScore(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return 0;
    final total = records.fold<double>(
      0,
      (sum, record) => sum + _moodScore(record),
    );
    return total / records.length;
  }

  double _moodScore(Map<String, dynamic> record) {
    final text = '${record['title'] ?? ''}${record['keyword'] ?? ''}';

    if (text.contains('開心') || text.contains('快樂') || text.contains('放鬆'))
      return 8.0;
    if (text.contains('平靜') || text.contains('舒服')) return 7.0;
    if (text.contains('普通') || text.contains('還好')) return 6.0;
    if (text.contains('累') || text.contains('疲憊')) return 5.0;
    if (text.contains('難過') || text.contains('低落')) return 4.0;
    if (text.contains('焦慮') || text.contains('壓力')) return 4.2;
    if (text.contains('生氣')) return 3.6;

    return 6.5;
  }

  String _getMostCommonMood(List<Map<String, dynamic>> records) {
    if (records.isEmpty) return '尚無';

    final Map<String, int> counter = {};
    for (final record in records) {
      final title = record['title'] ?? '未知';
      counter[title] = (counter[title] ?? 0) + 1;
    }

    String result = counter.keys.first;
    int maxCount = 0;
    counter.forEach((key, value) {
      if (value > maxCount) {
        result = key;
        maxCount = value;
      }
    });

    return result;
  }

  DateTime? _parseRecordDate(dynamic dateValue) {
    if (dateValue == null) return null;

    try {
      final parts = dateValue.toString().split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayText(DateTime date) {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return names[date.weekday - 1];
  }

  String _shortDate(String date) {
    final parsed = _parseRecordDate(date);
    if (parsed == null) return date;
    return '${parsed.month}/${parsed.day}';
  }

  Color _moodColor(Map<String, dynamic>? record) {
    if (record == null) return const Color(0xFFC9D8C8);
    final value = record['color'];
    if (value is int) return Color(value);
    return const Color(0xFF95D5B2);
  }

  BoxDecoration _iosCardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: cardColor.withOpacity(0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: lineColor, width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }
}

class MoodTrendPainter extends CustomPainter {
  final List<double?> points;

  MoodTrendPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final chartTop = 8.0;
    final chartBottom = size.height - 34;
    final chartHeight = chartBottom - chartTop;
    final step = size.width / math.max(points.length - 1, 1);

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E5DE)
      ..strokeWidth = 1;

    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = chartTop + chartHeight * ratio;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final availablePoints = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final score = points[i] ?? 5.0;
      final x = i * step;
      final y = chartTop + (1 - (score / 10)) * chartHeight;
      availablePoints.add(Offset(x, y));
    }

    if (availablePoints.length < 2) return;

    final path = Path()
      ..moveTo(availablePoints.first.dx, availablePoints.first.dy);
    for (var i = 1; i < availablePoints.length; i++) {
      final previous = availablePoints[i - 1];
      final current = availablePoints[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath = Path.from(path)
      ..lineTo(availablePoints.last.dx, chartBottom)
      ..lineTo(availablePoints.first.dx, chartBottom)
      ..close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x553F7D5B), Color(0x00FFFFFF)],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF6E9A80)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 7.0;
    double x = start.dx;
    while (x < end.dx) {
      canvas.drawLine(
        Offset(x, start.dy),
        Offset(math.min(x + dashWidth, end.dx), end.dy),
        paint,
      );
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant MoodTrendPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
