import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/mood_history_service.dart';
import '../services/firebase_mood_history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MoodHistoryService _historyService = MoodHistoryService();
  final FirebaseMoodHistoryService _firebaseHistoryService =
      FirebaseMoodHistoryService();

  late Future<List<Map<String, dynamic>>> _recordsFuture;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  List<Map<String, dynamic>> _allRecords = [];

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

  Future<void> _clearHistory() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _historyService.clearHistory();
    } else {
      await _firebaseHistoryService.clearHistory();
    }

    if (!mounted) return;

    setState(() {
      _loadRecords();
      _allRecords = [];
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已清除心情紀錄'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await _historyService.deleteMoodRecord(record);
    } else {
      await _firebaseHistoryService.deleteMoodRecord(record);
    }

    if (!mounted) return;

    setState(() {
      _loadRecords();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已刪除這筆心情紀錄'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _refreshRecords() async {
    setState(() {
      _loadRecords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        title: const Text('心情月曆'),
        backgroundColor: const Color(0xFFF3FBF6),
        foregroundColor: const Color(0xFF1F5C49),
        elevation: 0,
        actions: [],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRecords,
        color: const Color(0xFF2E7D62),
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _recordsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final records = snapshot.data ?? [];
            _allRecords = records;

            if (records.isEmpty) {
              return _buildEmptyView();
            }

            final selectedRecords = _getRecordsForDay(_selectedDay);

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              children: [
                _buildCalendarCard(),
                const SizedBox(height: 22),
                _buildStatsCard(records),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: '這一天的心情',
                  subtitle: _formatSelectedDate(_selectedDay),
                ),
                const SizedBox(height: 14),
                if (selectedRecords.isEmpty)
                  _buildNoRecordForDay()
                else
                  ...selectedRecords.map(
                    (record) => _buildDismissibleRecordCard(record),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: TableCalendar<Map<String, dynamic>>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        eventLoader: (day) {
          return _getRecordsForDay(day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1F5C49),
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: Color(0xFF2E7D62),
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF2E7D62),
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: Color(0xFF6D8B7D),
            fontWeight: FontWeight.w700,
          ),
          weekendStyle: TextStyle(
            color: Color(0xFF6D8B7D),
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: false,
          todayDecoration: BoxDecoration(
            color: Color(0xFFE0F2E8),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: Color(0xFF1F5C49),
            fontWeight: FontWeight.w900,
          ),
          selectedDecoration: BoxDecoration(
            color: Color(0xFF2E7D62),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
          defaultTextStyle: TextStyle(
            color: Color(0xFF1F5C49),
            fontWeight: FontWeight.w700,
          ),
          weekendTextStyle: TextStyle(
            color: Color(0xFF1F5C49),
            fontWeight: FontWeight.w700,
          ),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();

            final firstRecord = events.first;
            final emoji = firstRecord['emoji'] ?? '🌿';

            return Positioned(
              bottom: 1,
              child: Text(emoji, style: const TextStyle(fontSize: 13)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsCard(List<Map<String, dynamic>> records) {
    final totalCount = records.length;
    final latestRecord = records.first;

    final mostCommonMood = _getMostCommonMood(records);
    final latestEmoji = latestRecord['emoji'] ?? '🌿';
    final latestTitle = latestRecord['title'] ?? '未知心情';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB7E4C7), Color(0xFF95D5B2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.14),
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
            child: Icon(
              Icons.calendar_month_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你的心情小宇宙',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123D30),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '透過月曆慢慢看見自己的情緒變化。',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF315F50),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatItem(
                    icon: Icons.timeline_rounded,
                    value: '$totalCount',
                    label: '總紀錄',
                  ),
                  const SizedBox(width: 10),
                  _buildStatItem(
                    icon: Icons.favorite_rounded,
                    value: mostCommonMood,
                    label: '最常出現',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildLatestMoodCard(emoji: latestEmoji, title: latestTitle),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.38),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF1F5C49), size: 20),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF123D30),
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF315F50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestMoodCard({required String emoji, required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '最近一次心情：$title',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF123D30),
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F5C49),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6D8B7D),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final title = record['title'] ?? '未知心情';
    final emoji = record['emoji'] ?? '🌿';
    final date = record['date'] ?? '';
    final time = record['time'] ?? '';
    final colorValue = record['color'] ?? 0xFF95D5B2;
    final color = Color(colorValue);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: color.withOpacity(0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F5C49),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$date  $time',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6D8B7D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
      onDismissed: (_) {
        _deleteRecord(record);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.only(right: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: const Color(0xFFE76F51),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: _buildRecordCard(record),
    );
  }

  Widget _buildNoRecordForDay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: const Column(
        children: [
          Icon(Icons.nights_stay_rounded, color: Color(0xFF95D5B2), size: 42),
          SizedBox(height: 12),
          Text(
            '這一天還沒有心情紀錄',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F5C49),
            ),
          ),
          SizedBox(height: 6),
          Text(
            '從首頁選擇一個心情後，就會出現在月曆裡。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF6D8B7D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 120),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2E8),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFF2E7D62),
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '還沒有心情紀錄',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F5C49),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '從首頁選擇心情後，Moodify 會幫你記錄每天的狀態，並顯示在月曆上。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF6D8B7D),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getRecordsForDay(DateTime day) {
    return _allRecords.where((record) {
      final recordDate = _parseRecordDate(record['date']);
      if (recordDate == null) return false;

      return isSameDay(recordDate, day);
    }).toList();
  }

  DateTime? _parseRecordDate(dynamic dateValue) {
    if (dateValue == null) return null;

    final dateString = dateValue.toString();

    try {
      final parts = dateString.split('/');

      if (parts.length != 3) return null;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  String _formatSelectedDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  String _getMostCommonMood(List<Map<String, dynamic>> records) {
    final Map<String, int> counter = {};

    for (final record in records) {
      final title = record['title'] ?? '未知';
      counter[title] = (counter[title] ?? 0) + 1;
    }

    String result = '無';
    int maxCount = 0;

    counter.forEach((key, value) {
      if (value > maxCount) {
        result = key;
        maxCount = value;
      }
    });

    return result;
  }
}
