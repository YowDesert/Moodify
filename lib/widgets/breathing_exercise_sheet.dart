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

  int _phaseIndex = 0;
  int _secondsLeft = 4;
  bool _isRunning = true;

  final List<_BreathingPhase> _phases = const [
    _BreathingPhase(
      title: '吸氣',
      subtitle: '慢慢把空氣吸進來',
      seconds: 4,
      circleScale: 1.25,
    ),
    _BreathingPhase(
      title: '停留',
      subtitle: '讓肩膀放鬆，感覺身體慢慢安定',
      seconds: 2,
      circleScale: 1.25,
    ),
    _BreathingPhase(
      title: '吐氣',
      subtitle: '把緊繃跟著吐氣一起放掉',
      seconds: 6,
      circleScale: 0.72,
    ),
  ];

  _BreathingPhase get _currentPhase => _phases[_phaseIndex];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: _currentPhase.seconds),
      lowerBound: 0,
      upperBound: 1,
    );

    _startPhase();
  }

  void _startPhase() {
    _timer?.cancel();

    setState(() {
      _secondsLeft = _currentPhase.seconds;
    });

    _controller.duration = Duration(seconds: _currentPhase.seconds);
    _controller.forward(from: 0);

    if (!_isRunning) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isRunning) return;

      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        timer.cancel();
        _goNextPhase();
      }
    });
  }

  void _goNextPhase() {
    setState(() {
      _phaseIndex = (_phaseIndex + 1) % _phases.length;
    });

    _startPhase();
  }

  void _toggleRunning() {
    setState(() {
      _isRunning = !_isRunning;
    });

    if (_isRunning) {
      _controller.forward();
      _startPhase();
    } else {
      _timer?.cancel();
      _controller.stop();
    }
  }

  double _circleScale() {
    final progress = Curves.easeInOut.transform(_controller.value);

    if (_currentPhase.title == '吸氣') {
      return 0.72 + (1.25 - 0.72) * progress;
    }

    if (_currentPhase.title == '吐氣') {
      return 1.25 - (1.25 - 0.72) * progress;
    }

    return 1.25;
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
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99),
              ),
            ),

            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: green.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.air_rounded, color: green, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '跟著節奏呼吸',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2A24),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '吸氣 4 秒・停留 2 秒・吐氣 6 秒',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A827B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 34),

            SizedBox(
              height: 210,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final scale = _circleScale();

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 145,
                        height: 145,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: green.withOpacity(0.16),
                          boxShadow: [
                            BoxShadow(
                              color: green.withOpacity(0.16),
                              blurRadius: 36,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: green.withOpacity(0.18),
                            ),
                            child: Center(
                              child: Text(
                                '$_secondsLeft',
                                style: const TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w900,
                                  color: green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Column(
                key: ValueKey(_currentPhase.title),
                children: [
                  Text(
                    _currentPhase.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1F2A24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentPhase.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF737A75),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: _controller.value,
                backgroundColor: green.withOpacity(0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(green),
              ),
            ),

            const SizedBox(height: 26),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _toggleRunning,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: green,
                      side: BorderSide(color: green.withOpacity(0.22)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: Text(
                      _isRunning ? '暫停一下' : '繼續呼吸',
                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      '我準備好了',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreathingPhase {
  final String title;
  final String subtitle;
  final int seconds;
  final double circleScale;

  const _BreathingPhase({
    required this.title,
    required this.subtitle,
    required this.seconds,
    required this.circleScale,
  });
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
