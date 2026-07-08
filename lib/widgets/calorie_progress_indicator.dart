import 'dart:math';
import 'package:flutter/material.dart';

class CalorieProgressIndicator extends StatefulWidget {
  final int caloriesBurned;
  final int dailyGoal;

  const CalorieProgressIndicator({
    super.key,
    required this.caloriesBurned,
    required this.dailyGoal,
  });

  @override
  State<CalorieProgressIndicator> createState() =>
      _CalorieProgressIndicatorState();
}

class _CalorieProgressIndicatorState extends State<CalorieProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    final double targetProgress = widget.dailyGoal > 0
        ? min(1.0, widget.caloriesBurned / widget.dailyGoal)
        : 0.0;

    _animation = Tween<double>(
      begin: 0.0,
      end: targetProgress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant CalorieProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.caloriesBurned != widget.caloriesBurned ||
        oldWidget.dailyGoal != widget.dailyGoal) {
      final double targetProgress = widget.dailyGoal > 0
          ? min(1.0, widget.caloriesBurned / widget.dailyGoal)
          : 0.0;

      _animation = Tween<double>(begin: _animation.value, end: targetProgress)
          .animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = widget.dailyGoal > 0
        ? ((widget.caloriesBurned / widget.dailyGoal) * 100).toInt()
        : 0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _CalorieRingPainter(
                    progress: _animation.value,
                    trackColor: theme.brightness == Brightness.light
                        ? Colors.grey.withAlpha(38)
                        : Colors.white.withAlpha(20),
                    progressColors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
              );
            },
          ),

          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: theme.colorScheme.tertiary,
                size: 32,
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.caloriesBurned}',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              Text(
                'of ${widget.dailyGoal} kcal',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalorieRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> progressColors;

  _CalorieRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (progressColors.length == 1) {
      progressPaint.color = progressColors.first;
    } else {
      progressPaint.shader = SweepGradient(
        colors: progressColors,
        startAngle: -pi / 2,
        endAngle: pi * 1.5,
        tileMode: TileMode.clamp,
      ).createShader(rect);
    }

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, progressPaint);

    if (progress > 0.05) {
      final startCapX = center.dx + radius * cos(-pi / 2);
      final startCapY = center.dy + radius * sin(-pi / 2);
      final shadowPaint = Paint()
        ..color = progressColors.first.withAlpha(127)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawCircle(
        Offset(startCapX, startCapY),
        strokeWidth / 2,
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColors != progressColors;
  }
}
