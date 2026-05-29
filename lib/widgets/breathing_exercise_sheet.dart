import 'dart:async';
import 'package:flutter/material.dart';

class BreathingExerciseSheet extends StatefulWidget {
  const BreathingExerciseSheet({super.key});

  @override
  State<BreathingExerciseSheet> createState() => _BreathingExerciseSheetState();
}

class _BreathingExerciseSheetState extends State<BreathingExerciseSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  int _modeIndex = 0;
  int _phaseIndex = 0;
  int _secondsLeft = 4;
  int _cyclesDone = 0;
  bool _isRunning = true;

  final List<_BreathingMode> _modes = const [
    _BreathingMode(
      title: '焦慮安定',
      subtitle: '吸 4・停 2・吐 6，讓身體慢慢降速',
      icon: Icons.spa_rounded,
      phases: [
        _BreathingPhase('吸氣', '慢慢把空氣吸進來', 4, 0.72, 1.28),
        _BreathingPhase('停留', '不用用力，讓肩膀自然放鬆', 2, 1.28, 1.28),
        _BreathingPhase('吐氣', '把緊繃跟著吐氣一起放掉', 6, 1.28, 0.72),
      ],
    ),
    _BreathingMode(
      title: '睡前放鬆',
      subtitle: '吸 4・吐 8，適合準備休息時使用',
      icon: Icons.nightlight_round,
      phases: [
        _BreathingPhase('吸氣', '輕輕吸氣，不需要吸滿', 4, 0.72, 1.22),
        _BreathingPhase('吐氣', '吐久一點，讓身體知道可以休息了', 8, 1.22, 0.68),
      ],
    ),
    _BreathingMode(
      title: '專注盒式',
      subtitle: '吸 4・停 4・吐 4・停 4，找回節奏',
      icon: Icons.center_focus_strong_rounded,
      phases: [
        _BreathingPhase('吸氣', '把注意力慢慢拉回現在', 4, 0.72, 1.22),
        _BreathingPhase('停留', '保持安靜，感覺身體的穩定', 4, 1.22, 1.22),
        _BreathingPhase('吐氣', '慢慢吐氣，放掉多餘雜念', 4, 1.22, 0.72),
        _BreathingPhase('停留', '空一下，準備下一次吸氣', 4, 0.72, 0.72),
      ],
    ),
  ];

  _BreathingMode get _currentMode => _modes[_modeIndex];
  _BreathingPhase get _currentPhase => _currentMode.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _currentPhase.seconds),
    );
    _startPhase(resetAnimation: true);
  }

  void _startPhase({bool resetAnimation = true}) {
    _timer?.cancel();
    setState(() => _secondsLeft = _currentPhase.seconds);

    _controller.duration = Duration(seconds: _currentPhase.seconds);
    if (resetAnimation) {
      _controller.forward(from: 0);
    } else {
      _controller.forward();
    }

    if (!_isRunning) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) return;

      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        _goNextPhase();
      }
    });
  }

  void _goNextPhase() {
    setState(() {
      _phaseIndex = (_phaseIndex + 1) % _currentMode.phases.length;
      if (_phaseIndex == 0) _cyclesDone++;
    });
    _startPhase(resetAnimation: true);
  }

  void _changeMode(int index) {
    if (_modeIndex == index) return;
    _timer?.cancel();
    setState(() {
      _modeIndex = index;
      _phaseIndex = 0;
      _cyclesDone = 0;
      _isRunning = true;
    });
    _startPhase(resetAnimation: true);
  }

  void _toggleRunning() {
    setState(() => _isRunning = !_isRunning);

    if (_isRunning) {
      _controller.forward();
      _startPhase(resetAnimation: false);
    } else {
      _timer?.cancel();
      _controller.stop();
    }
  }

  double _circleScale() {
    final progress = Curves.easeInOutCubic.transform(_controller.value);
    return _currentPhase.fromScale +
        (_currentPhase.toScale - _currentPhase.fromScale) * progress;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF2F7D5B);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 26),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              _buildHeader(green),
              const SizedBox(height: 18),
              _buildModeSelector(green),
              const SizedBox(height: 28),
              _buildBreathingCircle(green),
              const SizedBox(height: 10),
              _buildPhaseText(),
              const SizedBox(height: 20),
              _buildProgress(green),
              const SizedBox(height: 24),
              _buildActions(green),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color green) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: green.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(_currentMode.icon, color: green, size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '跟著節奏呼吸',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1F2A24),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Text(
                  _currentMode.subtitle,
                  key: ValueKey(_currentMode.subtitle),
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF7A827B),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(Color green) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _modes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final mode = _modes[index];
          final selected = index == _modeIndex;
          return GestureDetector(
            onTap: () => _changeMode(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? green : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? green : const Color(0xFFE4ECE5),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: green.withOpacity(0.18),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(mode.icon, size: 17, color: selected ? Colors.white : green),
                  const SizedBox(width: 6),
                  Text(
                    mode.title,
                    style: TextStyle(
                      color: selected ? Colors.white : green,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreathingCircle(Color green) {
    return SizedBox(
      height: 218,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final scale = _circleScale();
            final glow = _isRunning ? 0.18 + _controller.value * 0.10 : 0.12;

            return Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: scale * 1.22,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: green.withOpacity(0.12), width: 1.5),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [green.withOpacity(0.22), const Color(0xFFB7E4C7).withOpacity(0.38)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: green.withOpacity(glow),
                          blurRadius: 42,
                          spreadRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.62),
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '$_secondsLeft',
                              key: ValueKey(_secondsLeft),
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: green,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhaseText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Column(
        key: ValueKey('${_modeIndex}_${_phaseIndex}'),
        children: [
          Text(
            _currentPhase.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1F2A24),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentPhase.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: Color(0xFF7A827B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(Color green) {
    final totalSeconds = _currentPhase.seconds;
    final progress = 1 - ((_secondsLeft - 1) / totalSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: _controller.value > 0 ? _controller.value : progress,
            backgroundColor: green.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(green),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '完成 $_cyclesDone 輪',
              style: const TextStyle(
                color: Color(0xFF7A827B),
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              _isRunning ? '正在進行' : '已暫停',
              style: TextStyle(
                color: green,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(Color green) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _toggleRunning,
            style: OutlinedButton.styleFrom(
              foregroundColor: green,
              side: BorderSide(color: green.withOpacity(0.22)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: Text(
              _isRunning ? '暫停一下' : '繼續呼吸',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: green,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            ),
            child: const Text(
              '我準備好了',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ],
    );
  }
}

class _BreathingMode {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<_BreathingPhase> phases;

  const _BreathingMode({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.phases,
  });
}

class _BreathingPhase {
  final String title;
  final String subtitle;
  final int seconds;
  final double fromScale;
  final double toScale;

  const _BreathingPhase(
    this.title,
    this.subtitle,
    this.seconds,
    this.fromScale,
    this.toScale,
  );
}

void showBreathingExerciseSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    builder: (_) => const BreathingExerciseSheet(),
  );
}
