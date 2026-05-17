import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final AiService _aiService = AiService();

  String _result = '';
  bool _isLoading = false;

  Future<void> _askAi() async {
    final text = _controller.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('請先輸入你今天的心情'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _result = '';
    });

    final reply = await _aiService.getMoodAdvice(text);

    setState(() {
      _result = reply;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FBF6),
      appBar: AppBar(
        title: const Text('AI 心情小助手'),
        backgroundColor: const Color(0xFFF3FBF6),
        foregroundColor: const Color(0xFF1F5C49),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 22),
            _buildInputCard(),
            const SizedBox(height: 22),
            _buildButton(),
            const SizedBox(height: 22),
            if (_isLoading) _buildLoadingCard(),
            if (_result.isNotEmpty) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB7E4C7), Color(0xFF95D5B2)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🌿 跟我說說今天的心情',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Color(0xFF123D30),
            ),
          ),
          SizedBox(height: 10),
          Text(
            '我會根據你的心情，給你一段溫柔建議和適合的音樂方向。',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFF315F50),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '例如：我今天很累，覺得有點焦慮，不太想跟人說話...',
          hintStyle: TextStyle(color: Color(0xFF9AAFA6)),
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.5,
          color: Color(0xFF1F5C49),
        ),
      ),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _askAi,
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text(
          '讓 AI 陪我一下',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D62),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 14),
          Text(
            'AI 正在陪你整理心情...',
            style: TextStyle(
              color: Color(0xFF1F5C49),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        _result,
        style: const TextStyle(
          fontSize: 16,
          height: 1.7,
          color: Color(0xFF1F5C49),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
