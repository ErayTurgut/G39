import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InteractiveBodyMap extends StatelessWidget {
  final Map<String, double> intensity;

  const InteractiveBodyMap({
    Key? key,
    required this.intensity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.45,
      child: Stack(
        children: [
          SvgPicture.asset(
            "assets/body/body_front.svg",
            fit: BoxFit.contain,
          ),
          CustomPaint(
            size: Size.infinite,
            painter: _HeatPainter(intensity),
          ),
        ],
      ),
    );
  }
}

class _HeatPainter extends CustomPainter {
  final Map<String, double> intensity;

  _HeatPainter(this.intensity);

  Color _color(double value) {
    if (value <= 0) return Colors.transparent;

    return Color.lerp(
      Colors.orange.withOpacity(0.35),
      Colors.redAccent,
      value.clamp(0, 1),
    )!.withOpacity(0.55);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        10,
      );

    /// CHEST
    if ((intensity["chest"] ?? 0) > 0) {
      paint.color = _color(intensity["chest"]!);

      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width * 0.34,
          size.height * 0.22,
          size.width * 0.66,
          size.height * 0.35,
          const Radius.circular(18),
        ),
        paint,
      );
    }

    /// ARMS
    if ((intensity["arms"] ?? 0) > 0) {
      paint.color = _color(intensity["arms"]!);

      /// LEFT ARM
      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width * 0.12,
          size.height * 0.22,
          size.width * 0.26,
          size.height * 0.50,
          const Radius.circular(14),
        ),
        paint,
      );

      /// RIGHT ARM
      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width * 0.74,
          size.height * 0.22,
          size.width * 0.88,
          size.height * 0.50,
          const Radius.circular(14),
        ),
        paint,
      );
    }

    /// LEGS
    if ((intensity["legs"] ?? 0) > 0) {
      paint.color = _color(intensity["legs"]!);

      /// LEFT LEG
      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width * 0.40,
          size.height * 0.55,
          size.width * 0.48,
          size.height * 0.92,
          const Radius.circular(14),
        ),
        paint,
      );

      /// RIGHT LEG
      canvas.drawRRect(
        RRect.fromLTRBR(
          size.width * 0.52,
          size.height * 0.55,
          size.width * 0.60,
          size.height * 0.92,
          const Radius.circular(14),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}