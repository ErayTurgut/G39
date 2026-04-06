import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MuscleHeatmap extends StatelessWidget {
  final Map<String, double> intensity;

  const MuscleHeatmap({super.key, required this.intensity});

  Color _color(double value) {
    if (value <= 0) return const Color(0xffcccccc);
    return Color.lerp(const Color(0xffffcccc), Colors.red, value.clamp(0, 1))!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          SvgPicture.asset(
            "assets/models/body_front.svg",
            fit: BoxFit.contain,
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _HeatPainter(intensity, _color),
            ),
          )
        ],
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  final Map<String, double> intensity;
  final Color Function(double) color;

  _HeatPainter(this.intensity, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    if (intensity["chest"] != null) {
      paint.color = color(intensity["chest"]!);
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.25,
            size.width * 0.3, size.height * 0.12),
        paint,
      );
    }

    if (intensity["arms"] != null) {
      paint.color = color(intensity["arms"]!);

      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.12, size.height * 0.25,
            size.width * 0.18, size.height * 0.3),
        paint,
      );

      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.7, size.height * 0.25,
            size.width * 0.18, size.height * 0.3),
        paint,
      );
    }

    if (intensity["legs"] != null) {
      paint.color = color(intensity["legs"]!);
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.55,
            size.width * 0.3, size.height * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}