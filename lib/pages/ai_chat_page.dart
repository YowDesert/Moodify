import 'package:flutter/material.dart';
import '../widgets/moodify_bottom_nav_bar.dart';

import '../services/ai_service.dart';
import '../models/mood.dart';
import '../widgets/breathing_exercise_sheet.dart';
import 'recommend_page.dart';
import 'favorite_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'profile_page.dart';



class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AiService _aiService = AiService();

  bool _isLoading = false;
  late List<_ChatMessage> _messages;

  static const Color bgColor = Color(0xFFFAFBF7);
  static const Color primaryColor = Color(0xFF4D8B63);
  static const Color deepGreen = Color(0xFF1F4A34);
  static const Color textColor = Color(0xFF2A342D);
  static const Color subTextColor = Color(0xFF7E877F);
  static const Color cardColor = Color(0xFFFFFEFB);

  final List<_QuickPrompt> quickMoods = const [
    _QuickPrompt('😰', '焦慮', '我今天有點焦慮，腦袋一直停不下來，想慢慢放鬆一下。'),
    _QuickPrompt('😴', '疲憊', '我今天有點累，也有點煩，想找一些能讓我慢慢放鬆的音樂。'),
    _QuickPrompt('😔', '難過', '我今天心情有點低落，不太想說很多話，但想有人陪我一下。'),
    _QuickPrompt('🎧', '想專心', '我現在很容易分心，想找能讓我穩定下來、專心一點的方法。'),
    _QuickPrompt('🌿', '想被療癒', '我想要被溫柔陪伴，讓心情慢慢平靜下來。'),
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      _ChatMessage(
        isUser: false,
        text: '嗨，我在這裡陪你。\n今天有什麼想聊的嗎？我可以陪你整理情緒，也可以幫你找適合現在心情的音樂。',
        time: DateTime.now(),
        actions: const ['3 分鐘呼吸', '安靜鋼琴'],
        featured: _RecommendationPack.defaultPack().featured,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = _ChatMessage(
      isUser: true,
      text: text,
      time: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    final aiResult = await _aiService.getMoodChat(
      text,
      recentMessages: _conversationContext(),
    );
    final pack = _RecommendationPack.fromAiResult(aiResult);

    if (!mounted) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          isUser: false,
          text: aiResult.reply,
          time: DateTime.now(),
          actions: pack.actions,
          featured: pack.featured,
        ),
      );
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _startConversation() {
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  void _resetConversation() {
    setState(() {
      _messages = [
        _ChatMessage(
          isUser: false,
          text: '新的對話開始了。\n你可以直接告訴我現在的心情，我會用對話的方式陪你慢慢整理。',
          time: DateTime.now(),
          actions: const ['呼吸一下', '柔和音樂'],
          featured: _RecommendationPack.defaultPack().featured,
        ),
      ];
      _controller.clear();
      _isLoading = false;
    });
  }

  List<String> _conversationContext() {
    return _messages
        .where((message) => message.text.trim().isNotEmpty)
        .toList()
        .reversed
        .take(6)
        .toList()
        .reversed
        .map(
          (message) => '${message.isUser ? '使用者' : 'Moodify'}：${message.text}',
        )
        .toList();
  }

  _RecommendationPack _buildRecommendationPack(String text) {
    final lower = text.toLowerCase();

    bool hasAny(List<String> keywords) =>
        keywords.any((k) => lower.contains(k));

    if (hasAny(['專心', '分心', 'focus', 'study', '工作', '學習'])) {
      return const _RecommendationPack(
        actions: ['番茄鐘 25 分鐘', '專注鋼琴'],
        featured: _FeaturedRecommendation(
          title: '穩穩專注下來',
          description: '用穩定節奏陪你回到當下，減少雜念與干擾。',
          itemCount: '18 首歌',
          duration: '50 分鐘',
          icon: Icons.piano_rounded,
          accent: Color(0xFFEDE9FF),
        ),
      );
    }

    if (hasAny(['睡', '累', '疲憊', '休息', '晚安'])) {
      return const _RecommendationPack(
        actions: ['睡前放鬆', '晚安白噪音'],
        featured: _FeaturedRecommendation(
          title: '慢慢放鬆入夜',
          description: '柔和旋律和安靜節拍，幫助你把今天的疲憊慢慢放下。',
          itemCount: '16 首歌',
          duration: '45 分鐘',
          icon: Icons.nightlight_round,
          accent: Color(0xFFF2EEFF),
        ),
      );
    }

    if (hasAny(['焦慮', '煩', '緊張', '不安', 'anx'])) {
      return const _RecommendationPack(
        actions: ['3 分鐘呼吸', '安靜鋼琴'],
        featured: _FeaturedRecommendation(
          title: '慢慢沉靜下來',
          description: '柔和旋律，陪你放慢腳步，讓心回到平靜。',
          itemCount: '20 首歌',
          duration: '60 分鐘',
          icon: Icons.spa_rounded,
          accent: Color(0xFFEAF5EB),
        ),
      );
    }

    if (hasAny(['難過', '低落', '傷心', '哭'])) {
      return const _RecommendationPack(
        actions: ['溫柔陪伴', '療癒木吉他'],
        featured: _FeaturedRecommendation(
          title: '讓情緒被接住',
          description: '不急著變好，先讓溫柔的聲音陪你待一會。',
          itemCount: '14 首歌',
          duration: '42 分鐘',
          icon: Icons.favorite_outline_rounded,
          accent: Color(0xFFF9F0F2),
        ),
      );
    }

    return _RecommendationPack.defaultPack();
  }

  Mood _moodForActionTitle(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('開心') || lower.contains('快樂') || lower.contains('輕快')) {
      return const Mood(
        title: '開心',
        emoji: '😊',
        keyword: 'upbeat',
        color: Color(0xFFFFD166),
      );
    }

    if (lower.contains('難過') ||
        lower.contains('溫柔') ||
        lower.contains('木吉他') ||
        lower.contains('陪伴')) {
      return const Mood(
        title: '難過',
        emoji: '😔',
        keyword: 'soft',
        color: Color(0xFF8ECAE6),
      );
    }

    if (lower.contains('焦慮') ||
        lower.contains('呼吸') ||
        lower.contains('安靜') ||
        lower.contains('平靜') ||
        lower.contains('鋼琴')) {
      return const Mood(
        title: '焦慮',
        emoji: '😰',
        keyword: 'calm',
        color: Color(0xFFA8DADC),
      );
    }

    if (lower.contains('睡') ||
        lower.contains('晚安') ||
        lower.contains('白噪音') ||
        lower.contains('放鬆')) {
      return const Mood(
        title: '疲憊',
        emoji: '😴',
        keyword: 'sleep',
        color: Color(0xFFCDB4DB),
      );
    }

    if (lower.contains('專注') ||
        lower.contains('番茄') ||
        lower.contains('focus') ||
        lower.contains('工作') ||
        lower.contains('讀書')) {
      return const Mood(
        title: '想專心',
        emoji: '🎧',
        keyword: 'focus',
        color: Color(0xFFB7E4C7),
      );
    }

    return const Mood(
      title: '療癒',
      emoji: '🌿',
      keyword: 'healing',
      color: Color(0xFF95D5B2),
    );
  }

  void _handleActionTap(String title) {
    final lower = title.toLowerCase();

    if (title.contains('呼吸')) {
      showBreathingExerciseSheet(context);
      return;
    }

    if (title.contains('鋼琴')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RecommendPage(
            mood: Mood(
              title: '安靜鋼琴',
              emoji: '🎹',
              keyword: 'solo piano instrumental calm relaxing',
              color: Color(0xFFEAF5EB),
            ),
          ),
        ),
      );
      return;
    }

    if (title.contains('白噪音')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const RecommendPage(
            mood: Mood(
              title: '晚安白噪音',
              emoji: '🌙',
              keyword: 'sleep white noise ambient',
              color: Color(0xFFF2EEFF),
            ),
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RecommendPage(
          mood: Mood(
            title: '療癒',
            emoji: '🌿',
            keyword: 'healing calm instrumental',
            color: Color(0xFFEAF5EB),
          ),
        ),
      ),
    );
  }

  Future<void> _openRecommendation(Mood mood) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecommendPage(mood: mood)),
    );
  }

  void _handleFeaturedTap(_FeaturedRecommendation item) {
    _openRecommendation(_moodForActionTitle(item.title));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFEFB), Color(0xFFFAFBF7), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 22),
                    _buildHeroCard(),
                    const SizedBox(height: 18),
                    _buildQuickPrompts(),
                    const SizedBox(height: 16),
                    ..._buildChatWidgets(),
                    if (_isLoading) ...[
                      const SizedBox(height: 8),
                      _buildTypingBubble(),
                    ],
                  ],
                ),
              ),
              _buildComposer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MoodifyBottomNavBar(currentTab: MoodifyTab.ai),
    );
  }

  List<Widget> _buildChatWidgets() {
    final widgets = <Widget>[];

    for (final message in _messages) {
      widgets.add(_buildMessageRow(message));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI 陪伴',
                style: TextStyle(
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: deepGreen,
                  letterSpacing: -1.2,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '跟你的情緒助理聊聊',
                style: TextStyle(
                  fontSize: 17,
                  color: subTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                boxShadow: _softShadow(opacity: 0.07, blur: 20, y: 8),
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _resetConversation,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE8E7DE)),
                ),
                child: const Text(
                  '重置',
                  style: TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF0F6ED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: _softShadow(opacity: 0.08, blur: 24, y: 10),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -12,
            bottom: -10,
            child: Icon(
              Icons.spa_rounded,
              size: 118,
              color: primaryColor.withOpacity(0.10),
            ),
          ),
          Row(
            children: [
              _buildBotAvatar(96),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '在線陪伴中',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: deepGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF87B67A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '有什麼想聊的嗎？\n我會一直在這裡陪著你。',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _startConversation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF679A74), Color(0xFF3F7A55)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: _softShadow(opacity: 0.12, blur: 16, y: 8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              '開始對話',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quickMoods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = quickMoods[index];
          return GestureDetector(
            onTap: () => _sendMessage(item.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE7E7DF), width: 1),
              ),
              child: Center(
                child: Text(
                  '${item.emoji} ${item.title}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageRow(_ChatMessage message) {
    if (message.isUser) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F6EB),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.time),
                  style: const TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildUserCircle(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBotAvatar(46),
            const SizedBox(width: 10),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white, width: 1.1),
                  boxShadow: _softShadow(opacity: 0.045, blur: 12, y: 5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.65,
                        color: textColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(message.time),
                      style: const TextStyle(
                        fontSize: 12,
                        color: subTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (message.actions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: message.actions.map(_buildActionChip).toList(),
            ),
          ),
        ],
        if (message.featured != null) ...[
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(left: 0),
            child: _buildRecommendationCard(message.featured!),
          ),
        ],
      ],
    );
  }

  Widget _buildTypingBubble() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBotAvatar(46),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white, width: 1.1),
            boxShadow: _softShadow(opacity: 0.04, blur: 12, y: 5),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Dot(),
              SizedBox(width: 6),
              _Dot(),
              SizedBox(width: 6),
              _Dot(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionChip(String title) {
    final icon = title.contains('鋼琴')
        ? Icons.piano_rounded
        : title.contains('呼吸')
        ? Icons.spa_rounded
        : title.contains('白噪音')
        ? Icons.nights_stay_outlined
        : Icons.play_arrow_rounded;

    return InkWell(
      onTap: () => _handleActionTap(title),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF6EF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFF0E8DB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primaryColor, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: deepGreen,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.play_arrow_rounded, color: primaryColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(_FeaturedRecommendation item) {
    return InkWell(
      onTap: () => _handleFeaturedTap(item),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF2F7F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 1.2),
          boxShadow: _softShadow(opacity: 0.06, blur: 16, y: 6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text(
                  '為你推薦',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: deepGreen,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Color(0xFF9ABE8D),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [item.accent.withOpacity(0.95), Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: primaryColor.withOpacity(0.25),
                        size: 54,
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: primaryColor,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: deepGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: subTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 14,
                        runSpacing: 8,
                        children: [
                          _recommendMeta(
                            icon: Icons.music_note_rounded,
                            text: item.itemCount,
                          ),
                          _recommendMeta(
                            icon: Icons.schedule_rounded,
                            text: item.duration,
                          ),
                          _recommendMeta(
                            icon: Icons.chevron_right_rounded,
                            text: '去聽歌',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendMeta({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: subTextColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(color: const Color(0xFFEAE8DF).withOpacity(0.9)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8F3),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8E7DE)),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: '告訴我你現在的心情...',
                  hintStyle: TextStyle(
                    color: Color(0xFFA1A69F),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isLoading
                      ? [const Color(0xFFB6D1BF), const Color(0xFFB6D1BF)]
                      : [const Color(0xFF679A74), const Color(0xFF3F7A55)],
                ),
                shape: BoxShape.circle,
                boxShadow: _softShadow(opacity: 0.09, blur: 16, y: 6),
              ),
              child: Icon(
                _isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFEFB), Color(0xFFF0F5EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: _softShadow(opacity: 0.06, blur: 14, y: 6),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.07,
            child: Icon(
              Icons.energy_savings_leaf_rounded,
              color: const Color(0xFF92B083),
              size: size * 0.22,
            ),
          ),
          Container(
            width: size * 0.62,
            height: size * 0.52,
            decoration: BoxDecoration(
              color: const Color(0xFF43755A),
              borderRadius: BorderRadius.circular(size * 0.24),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: size * 0.07,
                    height: size * 0.07,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: size * 0.12),
                  Icon(
                    Icons.sentiment_satisfied_alt_rounded,
                    color: Colors.white,
                    size: size * 0.18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCircle() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8E7DE)),
      ),
      child: const Icon(Icons.person_outline_rounded, color: Color(0xFF8D8D85)),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '今天 $hour:$minute';
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: '首頁',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (_) => false,
                );
              },
            ),
            _buildNavItem(
              icon: Icons.favorite_border_rounded,
              label: '收藏',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritePage()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.smart_toy_rounded,
              label: 'AI 陪伴',
              isSelected: true,
            ),
            _buildNavItem(
              icon: Icons.bar_chart_rounded,
              label: '紀錄',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryPage()),
                );
              },
            ),
            _buildNavItem(
              icon: Icons.person_outline_rounded,
              label: '我的',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : const Color(0xFFB0B4AE),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected ? primaryColor : const Color(0xFF9CA39C),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: isSelected ? 28 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BoxShadow> _softShadow({
    double opacity = 0.06,
    double blur = 16,
    double y = 8,
  }) {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(opacity),
        blurRadius: blur,
        offset: Offset(0, y),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(opacity * 0.18),
        blurRadius: blur * 0.6,
        offset: Offset(0, y * 0.4),
      ),
    ];
  }
}

class _QuickPrompt {
  final String emoji;
  final String title;
  final String text;

  const _QuickPrompt(this.emoji, this.title, this.text);
}

class _ChatMessage {
  final bool isUser;
  final String text;
  final DateTime time;
  final List<String> actions;
  final _FeaturedRecommendation? featured;

  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.time,
    this.actions = const [],
    this.featured,
  });
}

class _RecommendationPack {
  final List<String> actions;
  final _FeaturedRecommendation featured;

  const _RecommendationPack({required this.actions, required this.featured});

  factory _RecommendationPack.fromAiResult(AiChatResult result) {
    IconData icon;
    Color accent;
    String itemCount;
    String duration;

    switch (result.moodKey) {
      case 'upbeat':
        icon = Icons.wb_sunny_rounded;
        accent = const Color(0xFFFFF3D8);
        itemCount = '隨機歌曲';
        duration = '輕快';
        break;
      case 'soft':
        icon = Icons.favorite_outline_rounded;
        accent = const Color(0xFFF9F0F2);
        itemCount = '相似心情';
        duration = '溫柔';
        break;
      case 'calm':
        icon = Icons.spa_rounded;
        accent = const Color(0xFFEAF5EB);
        itemCount = '放鬆歌曲';
        duration = '平靜';
        break;
      case 'sleep':
        icon = Icons.nightlight_round;
        accent = const Color(0xFFF2EEFF);
        itemCount = '睡前歌曲';
        duration = '慢節奏';
        break;
      case 'focus':
        icon = Icons.piano_rounded;
        accent = const Color(0xFFEDE9FF);
        itemCount = '專注歌曲';
        duration = '穩定';
        break;
      default:
        icon = Icons.energy_savings_leaf_rounded;
        accent = const Color(0xFFEAF5EB);
        itemCount = '療癒歌曲';
        duration = '舒服';
        break;
    }

    return _RecommendationPack(
      actions: result.actions,
      featured: _FeaturedRecommendation(
        title: result.musicTitle,
        description: result.musicDescription,
        itemCount: itemCount,
        duration: duration,
        icon: icon,
        accent: accent,
      ),
    );
  }

  factory _RecommendationPack.defaultPack() {
    return const _RecommendationPack(
      actions: ['3 分鐘呼吸', '安靜鋼琴'],
      featured: _FeaturedRecommendation(
        title: '慢慢沉靜下來',
        description: '柔和旋律，陪你放慢腳步，讓心回到平靜。',
        itemCount: '20 首歌',
        duration: '60 分鐘',
        icon: Icons.spa_rounded,
        accent: Color(0xFFEAF5EB),
      ),
    );
  }
}

class _FeaturedRecommendation {
  final String title;
  final String description;
  final String itemCount;
  final String duration;
  final IconData icon;
  final Color accent;

  const _FeaturedRecommendation({
    required this.title,
    required this.description,
    required this.itemCount,
    required this.duration,
    required this.icon,
    required this.accent,
  });
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: const Color(0xFF97A498).withOpacity(0.75),
        shape: BoxShape.circle,
      ),
    );
  }
}
