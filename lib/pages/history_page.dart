import 'package:flutter/material.dart';
import '../services/mood_history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MoodHistoryService _historyService = MoodHistoryService();

  late Future<List<Map<String, dynamic>>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  void _loadRecords() {
    _recordsFuture = _historyService.getMoodRecords();
  }

  Future<void> _clearHistory() async {
    await _historyService.clearHistory();

    if (!mounted) return;

    setState(() {
      _loadRecords();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已清除心情紀錄'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        title: const Text('心情紀錄'),
        backgroundColor: const Color(0xFFF3FBF6),
        foregroundColor: const Color(0xFF1F5C49),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearHistory,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return _buildEmptyView();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              return _buildRecordCard(record);
            },
          );
        },
      ),
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF9AAFA6)),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF2E7D62),
                size: 44,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              '還沒有心情紀錄',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F5C49),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '從首頁選擇心情後，Moodify 會幫你記錄每天的狀態。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF6D8B7D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
