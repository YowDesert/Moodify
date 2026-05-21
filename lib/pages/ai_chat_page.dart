import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<Map<String, String>> quickMoods = const [
    {'emoji': '😰', 'title': '我很焦慮', 'text': '我今天覺得很焦慮，腦袋一直停不下來，不知道該怎麼放鬆。'},
    {'emoji': '😴', 'title': '我很累', 'text': '我今天很累，感覺身體和心裡都沒有力氣，想好好休息。'},
    {'emoji': '😔', 'title': '我有點難過', 'text': '我今天有點難過，心情悶悶的，不太想跟別人說話。'},
    {'emoji': '🌙', 'title': '我睡不著', 'text': '我最近有點睡不著，躺著的時候會一直想很多事情。'},
    {'emoji': '🎧', 'title': '我想專心', 'text': '我想讓自己專心一點，但是現在很容易分心，需要一點安定感。'},
    {'emoji': '🌿', 'title': '我想被療癒', 'text': '我想讓心情慢慢平靜下來，希望可以被溫柔地陪伴一下。'},
  ];

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

    if (!mounted) return;

    setState(() {
      _result = reply;
      _isLoading = false;
    });
  }

  void _setQuickMood(String text) {
    setState(() {
      _controller.text = text;
    });
  }

  void _clearInput() {
    setState(() {
      _controller.clear();
      _result = '';
    });
  }

  Future<void> _copyResult() async {
    if (_result.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: _result));

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已複製 AI 回答'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
        actions: [
          IconButton(
            onPressed: _clearInput,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 24),
            _buildSectionHeader(
              title: '快速選擇',
              subtitle: '不知道怎麼說也沒關係，先選一個接近的狀態',
            ),
            const SizedBox(height: 14),
            _buildQuickMoodGrid(),
            const SizedBox(height: 24),
            _buildSectionHeader(title: '今天想說什麼？', subtitle: '寫下你的感受，AI 會陪你整理'),
            const SizedBox(height: 14),
            _buildInputCard(),
            const SizedBox(height: 18),
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
            right: -12,
            top: -10,
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 105,
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🌿 讓 AI 陪你整理心情',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF123D30),
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '你不用馬上變好，只要先把感受說出來。Moodify 會給你一段溫柔建議、適合的音樂方向和一個小行動。',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: Color(0xFF315F50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
            fontSize: 21,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1F5C49),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            height: 1.4,
            color: Color(0xFF6D8B7D),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickMoodGrid() {
    return GridView.builder(
      itemCount: quickMoods.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.5,
      ),
      itemBuilder: (context, index) {
        final item = quickMoods[index];

        return GestureDetector(
          onTap: () => _setQuickMood(item['text']!),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE1F0E8)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D62).withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(item['emoji']!, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item['title']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1F5C49),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        maxLines: 6,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: '例如：我今天很累，覺得有點焦慮，不太想跟人說話...',
          hintStyle: TextStyle(color: Color(0xFF9AAFA6)),
        ),
        style: const TextStyle(
          fontSize: 16,
          height: 1.55,
          color: Color(0xFF1F5C49),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
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
                disabledBackgroundColor: const Color(0xFFB8D8C8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 54,
          height: 54,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _clearInput,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D62),
              side: const BorderSide(color: Color(0xFF2E7D62), width: 1.3),
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Icon(Icons.close_rounded),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1F0E8)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 23,
            height: 23,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'AI 正在陪你整理心情...',
              style: TextStyle(
                color: Color(0xFF1F5C49),
                fontWeight: FontWeight.w700,
              ),
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
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE1F0E8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D62).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'AI 給你的回覆',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F5C49),
                  ),
                ),
              ),
              IconButton(
                onPressed: _copyResult,
                icon: const Icon(Icons.copy_rounded, color: Color(0xFF2E7D62)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _result,
            style: const TextStyle(
              fontSize: 16,
              height: 1.7,
              color: Color(0xFF1F5C49),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : _askAi,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                '重新生成',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E7D62),
                side: const BorderSide(color: Color(0xFF2E7D62)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
