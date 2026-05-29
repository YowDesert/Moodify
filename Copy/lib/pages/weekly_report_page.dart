import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/firebase_mood_history_service.dart';
import '../services/mood_history_service.dart';

class WeeklyReportPage extends StatefulWidget {
  const WeeklyReportPage({super.key});

  @override
  State<WeeklyReportPage> createState() => _WeeklyReportPageState();
}

class _WeeklyReportPageState extends State<WeeklyReportPage> {
  final MoodHistoryService _historyService = MoodHistoryService();
  final FirebaseMoodHistoryService _firebaseHistoryService =
      FirebaseMoodHistoryService();

  static const Color bgColor = Color(0xFFFAFAF7);
  static const Color primaryColor = Color(0xFF3F7D5B);
  static const Color textColor = Color(0xFF1F2522);
  static const Color subTextColor = Color(0xFF747B76);

  late Future<List<Map<String, dynamic>>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
  }

  Future<List<Map<String, dynamic>>> _loadRecords() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _historyService.getMoodRecords();
    return _firebaseHistoryService.getMoodRecords();
  }

  Future<void> _refresh() async {
    setState(() => _recordsFuture = _loadRecords());
    await _recordsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primaryColor),
              );
            }

            final allRecords = snapshot.data ?? [];
            final report = _WeeklyReport.fromRecords(allRecords);

            return RefreshIndicator(
              onRefresh: _refresh,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 20),
                  _buildHeroCard(report),
                  const SizedBox(height: 16),
                  _buildStatsRow(report),
                  const SizedBox(height: 16),
                  _buildTrendCard(report),
                  const SizedBox(height: 16),
                  _buildMoodDistribution(report),
                  const SizedBox(height: 16),
                  _buildSuggestionCard(report),
                  const SizedBox(height: 16),
                  _buildDailyList(report),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFE8E5DE)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '每週心情報告',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '看看這 7 天，心情怎麼流動',
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(_WeeklyReport report) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFEAF8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -20,
            child: Icon(
              Icons.auto_graph_rounded,
              size: 106,
              color: primaryColor.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2F2E8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  report.dateRangeText,
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                report.heroTitle,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                report.heroSubtitle,
                style: const TextStyle(
                  color: subTextColor,
                  fontSize: 14.5,
                  height: 1.55,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(_WeeklyReport report) {
    return Row(
      children: [
        Expanded(
          child: _smallStatCard(
            value: '${report.weekRecords.length}',
            label: '本週紀錄',
            icon: Icons.edit_note_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            value: report.topMoodText,
            label: '最多心情',
            icon: Icons.favorite_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _smallStatCard(
            value: '${report.activeDays}/7',
            label: '有記錄天數',
            icon: Icons.calendar_month_rounded,
          ),
        ),
      ],
    );
  }

  Widget _smallStatCard({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textColor,
              fontSize: 19,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: subTextColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(_WeeklyReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('7 天心情曲線', '不是評分高低，而是幫你看見狀態'),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeeklyTrendPainter(days: report.days),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistribution(_WeeklyReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('心情比例', '本週比較常出現的情緒'),
          const SizedBox(height: 16),
          if (report.moodCounts.isEmpty)
            const Text(
              '這週還沒有心情紀錄，先從首頁選一個心情開始。',
              style: TextStyle(color: subTextColor, fontWeight: FontWeight.w600),
            )
          else
            ...report.moodCounts.entries.map((entry) {
              final ratio = entry.value / report.weekRecords.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${entry.value} 次',
                          style: const TextStyle(
                            color: subTextColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFEAF3EC),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _colorForMood(entry.key),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(_WeeklyReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF8F2),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFD9EEE2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.lightbulb_rounded, color: primaryColor),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Moodify 給你的建議',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  report.suggestion,
                  style: const TextStyle(
                    color: subTextColor,
                    fontSize: 14,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyList(_WeeklyReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('每日紀錄', '最近 7 天的心情足跡'),
          const SizedBox(height: 14),
          ...report.days.map((day) {
            final mood = day.records.isEmpty
                ? '尚無紀錄'
                : day.records.first['emoji']?.toString() == null
                    ? day.records.first['title'].toString()
                    : '${day.records.first['emoji']} ${day.records.first['title']}';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBF7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8E5DE)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    child: Text(
                      day.weekdayText,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      mood,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: day.records.isEmpty ? subTextColor : textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    day.records.isEmpty ? '' : '${day.records.length} 筆',
                    style: const TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: textColor,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: subTextColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration({required double radius}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFE8E5DE), width: 0.8),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 22,
          offset: const Offset(0, 12),
        ),
      ],
    );
  }

  Color _colorForMood(String mood) {
    if (mood.contains('開心')) return const Color(0xFFFFC857);
    if (mood.contains('難過')) return const Color(0xFF8ECAE6);
    if (mood.contains('焦慮')) return const Color(0xFFA8DADC);
    if (mood.contains('疲憊')) return const Color(0xFFCDB4DB);
    if (mood.contains('專心')) return const Color(0xFF74C69D);
    return const Color(0xFF95D5B2);
  }
}

class _WeeklyReport {
  final DateTime start;
  final DateTime end;
  final List<Map<String, dynamic>> weekRecords;
  final List<_DayMood> days;
  final Map<String, int> moodCounts;

  _WeeklyReport({
    required this.start,
    required this.end,
    required this.weekRecords,
    required this.days,
    required this.moodCounts,
  });

  factory _WeeklyReport.fromRecords(List<Map<String, dynamic>> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final end = today;

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      final parts = value.toString().split('/');
      if (parts.length != 3) return null;
      try {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      } catch (_) {
        return null;
      }
    }

    bool isSameDate(DateTime a, DateTime b) {
      return a.year == b.year && a.month == b.month && a.day == b.day;
    }

    final weekRecords = records.where((record) {
      final date = parseDate(record['date']);
      if (date == null) return false;
      return !date.isBefore(start) && !date.isAfter(end);
    }).toList();

    final days = List.generate(7, (index) {
      final date = start.add(Duration(days: index));
      final dayRecords = weekRecords.where((record) {
        final recordDate = parseDate(record['date']);
        return recordDate != null && isSameDate(recordDate, date);
      }).toList();
      return _DayMood(date: date, records: dayRecords);
    });

    final counts = <String, int>{};
    for (final record in weekRecords) {
      final emoji = record['emoji']?.toString() ?? '';
      final title = record['title']?.toString() ?? '未知心情';
      final key = emoji.isEmpty ? title : '$emoji $title';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _WeeklyReport(
      start: start,
      end: end,
      weekRecords: weekRecords,
      days: days,
      moodCounts: Map.fromEntries(sortedEntries),
    );
  }

  String get dateRangeText => '${start.month}/${start.day} - ${end.month}/${end.day}';

  int get activeDays => days.where((day) => day.records.isNotEmpty).length;

  String get topMoodText {
    if (moodCounts.isEmpty) return '尚無';
    return moodCounts.keys.first;
  }

  String get heroTitle {
    if (weekRecords.isEmpty) return '這週還沒留下心情足跡';
    return '這週你比較常出現：$topMoodText';
  }

  String get heroSubtitle {
    if (weekRecords.isEmpty) {
      return '先不用急著補滿紀錄。從今天開始選一個心情，Moodify 就能幫你整理每週狀態。';
    }
    return '你這週記錄了 ${weekRecords.length} 次心情，其中 $activeDays 天有留下紀錄。這些不是分數，而是讓你更了解自己的線索。';
  }

  String get suggestion {
    if (weekRecords.isEmpty) {
      return '今天可以先做一次 3 分鐘呼吸，再選一首療癒音樂，讓 APP 開始累積你的心情節奏。';
    }

    final top = topMoodText;
    if (top.contains('焦慮')) {
      return '焦慮出現比較多時，可以優先使用「焦慮安定」呼吸模式，再聽安靜鋼琴或自然聲音，讓身體先慢下來。';
    }
    if (top.contains('疲憊')) {
      return '疲憊比較多時，不一定要逼自己振作。可以用睡前放鬆呼吸，搭配柔和音樂，先把休息補回來。';
    }
    if (top.contains('難過')) {
      return '難過比較多時，可以選溫柔、不刺激的歌曲。也可以在心情紀錄旁寫一句原因，幫自己把情緒說出來。';
    }
    if (top.contains('開心')) {
      return '這週有不少開心的時刻，記得收藏讓你有力量的歌曲。之後低潮時，它會變成你的能量歌單。';
    }
    if (top.contains('專心')) {
      return '你這週很常進入專注狀態，可以建立固定的專注歌單，讓開始讀書或工作時更快進入節奏。';
    }
    return '這週的狀態正在累積中。繼續保持簡單記錄，Moodify 會更懂你適合什麼音樂與放鬆方式。';
  }
}

class _DayMood {
  final DateTime date;
  final List<Map<String, dynamic>> records;

  _DayMood({required this.date, required this.records});

  String get weekdayText {
    const names = ['一', '二', '三', '四', '五', '六', '日'];
    return '${date.month}/${date.day} 週${names[date.weekday - 1]}';
  }

  double? get score {
    if (records.isEmpty) return null;
    final total = records.fold<double>(0, (sum, record) => sum + _moodScore(record));
    return total / records.length;
  }

  static double _moodScore(Map<String, dynamic> record) {
    final text = '${record['title'] ?? ''}${record['keyword'] ?? ''}';
    if (text.contains('開心') || text.contains('upbeat')) return 8.5;
    if (text.contains('療癒') || text.contains('healing')) return 7.2;
    if (text.contains('專心') || text.contains('focus')) return 7.0;
    if (text.contains('疲憊') || text.contains('sleep')) return 5.0;
    if (text.contains('難過') || text.contains('soft')) return 4.2;
    if (text.contains('焦慮') || text.contains('calm')) return 4.4;
    return 6.2;
  }
}

class _WeeklyTrendPainter extends CustomPainter {
  final List<_DayMood> days;

  _WeeklyTrendPainter({required this.days});

  @override
  void paint(Canvas canvas, Size size) {
    const primary = Color(0xFF3F7D5B);
    const grid = Color(0xFFE8E5DE);
    final top = 12.0;
    final bottom = size.height - 34;
    final chartHeight = bottom - top;
    final step = size.width / math.max(days.length - 1, 1);

    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;

    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = top + chartHeight * ratio;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = <Offset>[];
    for (var i = 0; i < days.length; i++) {
      final score = days[i].score ?? 5.8;
      final x = i * step;
      final y = top + (1 - score / 10) * chartHeight;
      offsets.add(Offset(x, y));
    }

    if (offsets.length >= 2) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
      for (var i = 1; i < offsets.length; i++) {
        final previous = offsets[i - 1];
        final current = offsets[i];
        final controlX = (previous.dx + current.dx) / 2;
        path.cubicTo(controlX, previous.dy, controlX, current.dy, current.dx, current.dy);
      }

      final fillPath = Path.from(path)
        ..lineTo(offsets.last.dx, bottom)
        ..lineTo(offsets.first.dx, bottom)
        ..close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x553F7D5B), Color(0x00FFFFFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, top, size.width, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      final linePaint = Paint()
        ..color = primary
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }

    final dotPaint = Paint()..color = primary;
    final emptyDotPaint = Paint()..color = const Color(0xFFC9D8C8);
    final labelStyle = const TextStyle(
      color: Color(0xFF747B76),
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );

    const weekdayNames = ['一', '二', '三', '四', '五', '六', '日'];
    for (var i = 0; i < offsets.length; i++) {
      canvas.drawCircle(offsets[i], 5, days[i].records.isEmpty ? emptyDotPaint : dotPaint);
      final painter = TextPainter(
        text: TextSpan(text: weekdayNames[days[i].date.weekday - 1], style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(offsets[i].dx - painter.width / 2, size.height - 22));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyTrendPainter oldDelegate) {
    return oldDelegate.days != days;
  }
}
