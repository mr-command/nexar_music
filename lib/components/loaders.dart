import 'dart:math' as math;
import 'package:flutter/material.dart';

class MusicPlayingIndicator extends StatefulWidget {
  const MusicPlayingIndicator({
    super.key,
    this.size = 32,
    this.color = Colors.green,
    this.isPlaying = true,
  });

  final double size;
  final Color color;
  final bool isPlaying;

  @override
  State<MusicPlayingIndicator> createState() =>
      _MusicPlayingIndicatorState();
}

class _MusicPlayingIndicatorState extends State<MusicPlayingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant MusicPlayingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _EqualizerPainter(
              progress: _controller.value,
              color: widget.color,
              isPlaying: widget.isPlaying,
            ),
          );
        },
      ),
    );
  }
}

class _EqualizerPainter extends CustomPainter {
  const _EqualizerPainter({
    required this.progress,
    required this.color,
    required this.isPlaying,
  });

  final double progress;
  final Color color;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const barCount = 3;
    const barWidthFactor = 0.19;
    const gapFactor = 0.13;

    final barWidth = size.width * barWidthFactor;
    final gap = size.width * gapFactor;

    final totalWidth = barCount * barWidth + (barCount - 1) * gap;
    final startX = (size.width - totalWidth) / 2;

    const phases = [0.0, 1.7, 3.2];

    for (var i = 0; i < barCount; i++) {
      final wave = (math.sin(
                progress * 2 * math.pi + phases[i],
              ) +
              1) /
          2;

      final secondaryWave = (math.sin(
                progress * 4 * math.pi + phases[i] * 0.7,
              ) +
              1) /
          2;

      final normalizedHeight = isPlaying
          ? 0.25 + 0.75 * (wave * 0.7 + secondaryWave * 0.3)
          : 0.25;

      final barHeight = size.height * normalizedHeight;

      final x = startX + i * (barWidth + gap);
      final y = (size.height - barHeight) / 2;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EqualizerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.isPlaying != isPlaying;
  }
}
