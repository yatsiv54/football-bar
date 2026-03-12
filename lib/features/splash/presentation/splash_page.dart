import 'dart:async';
import 'dart:math' as math;

import '../../../core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), _navigateNext);
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _navigateNext() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('welcome_seen') ?? false;
    if (!mounted) return;
    context.go(seen ? '/home' : '/welcome');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyColors.bgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Loading...',
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(fontSize: 32),
            ),
            SizedBox(height: 24),
            _DotLoader(),
          ],
        ),
      ),
    );
  }
}

class _DotLoader extends StatefulWidget {
  const _DotLoader();

  @override
  State<_DotLoader> createState() => _DotLoaderState();
}

class _DotLoaderState extends State<_DotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const total = 8;
    const radius = 30.0;
    const dotSize = 13.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value * total;
        final active = progress.floor() % total;
        final fillStep = active;

        return SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(total, (i) {
              final angle = -math.pi / 2 + (2 * math.pi / total) * i;
              final dx = radius * math.cos(angle);
              final dy = radius * math.sin(angle);
              final isActive = i == active;
              final isFilled = i <= fillStep;
              return Transform.translate(
                offset: Offset(dx, dy),
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: isActive || isFilled
                        ? MyColors.primaryPurple
                        : MyColors.primaryLightBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
