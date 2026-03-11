import 'dart:math';
import 'package:flutter/material.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  final List<_Particle> particles = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _generateParticles();
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainPage()),
        );
      }
    });
  }

  void _generateParticles() {
    final random = Random();
    for (int i = 0; i < 40; i++) {
      particles.add(
        _Particle(
          angle: random.nextDouble() * pi * 2,
          speed: random.nextDouble() * 250 + 150,
          size: random.nextDouble() * 10 + 5,
        ),
      );
    }
  }

  double _shake() {
    if (_controller.value < 0.25) {
      return sin(_controller.value * 120) * 15;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final explodeProgress =
        (_controller.value - 0.4).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        color: const Color(0xFF0F1115),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              alignment: Alignment.center,
              children: [

                // Shockwave ring
                if (explodeProgress > 0)
                  Container(
                    width: 600 * explodeProgress,
                    height: 600 * explodeProgress,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.orange.withOpacity(
                          1 - explodeProgress,
                        ),
                        width: 4,
                      ),
                    ),
                  ),

                // Particles
                ...particles.map((p) {
                  final dx =
                      cos(p.angle) * p.speed * explodeProgress;
                  final dy =
                      sin(p.angle) * p.speed * explodeProgress;

                  return Positioned(
                    left:
                        MediaQuery.of(context).size.width / 2 + dx,
                    top:
                        MediaQuery.of(context).size.height / 2 + dy,
                    child: Opacity(
                      opacity: 1 - explodeProgress,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8C42),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }),

                // Kettlebell
                Transform.translate(
                  offset: Offset(_shake(), 0),
                  child: Transform.scale(
                    scale: 1 - (explodeProgress * 0.3),
                    child: Image.asset(
                      'assets/icon/app_icon.png',
                      width: 180,
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
}

class _Particle {
  final double angle;
  final double speed;
  final double size;

  _Particle({
    required this.angle,
    required this.speed,
    required this.size,
  });
}