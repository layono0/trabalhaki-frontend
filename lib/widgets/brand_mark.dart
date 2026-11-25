import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared geometric Trabalhaki Match-T brand emblem (synced 1:1 with Web BrandMark.tsx).
class TrabalhakiBrandIcon extends StatelessWidget {
  final double size;
  final bool inverted;

  const TrabalhakiBrandIcon({
    super.key,
    this.size = 38,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MatchTEmblemPainter(
          backgroundColor: AppColors.primary,
          borderOpacity: inverted ? 0.22 : 0.14,
        ),
      ),
    );
  }
}

class _MatchTEmblemPainter extends CustomPainter {
  final Color backgroundColor;
  final double borderOpacity;

  const _MatchTEmblemPainter({
    required this.backgroundColor,
    required this.borderOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 32.0;
    final sy = size.height / 32.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Outer rounded tile (32x32, rx=9)
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 32, 32),
        const Radius.circular(9),
      ),
      bgPaint,
    );

    // Subtle translucent specular border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: borderOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0.5, 0.5, 31, 31),
        const Radius.circular(8.5),
      ),
      borderPaint,
    );

    // Geometric rounded white "T" stem (exact SVG path coordinates from BrandMark.tsx)
    final tPaint = Paint()..color = Colors.white;
    final tPath = Path()
      ..moveTo(7, 10)
      ..cubicTo(7, 8.89543, 7.89543, 8, 9, 8)
      ..lineTo(16, 8)
      ..cubicTo(17.1046, 8, 18, 8.89543, 18, 10)
      ..lineTo(18, 22)
      ..cubicTo(18, 23.1046, 17.1046, 24, 16, 24)
      ..cubicTo(14.8954, 24, 14, 23.1046, 14, 22)
      ..lineTo(14, 12)
      ..lineTo(9, 12)
      ..cubicTo(7.89543, 12, 7, 11.1046, 7, 10)
      ..close();
    canvas.drawPath(tPath, tPaint);

    // Signal Mint locking match spark pill
    final sparkPaint = Paint()..color = AppColors.secondary;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 8, 5, 4),
        const Radius.circular(2),
      ),
      sparkPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MatchTEmblemPainter oldDelegate) =>
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.borderOpacity != borderOpacity;
}

class TrabalhakiBrandMark extends StatelessWidget {
  final bool inverted;
  final double iconSize;
  final double fontSize;

  const TrabalhakiBrandMark({
    super.key,
    this.inverted = false,
    this.iconSize = 36,
    this.fontSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TrabalhakiBrandIcon(size: iconSize, inverted: inverted),
        const SizedBox(width: 10),
        Text(
          'Trabalhaki',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: inverted ? Colors.white : AppColors.ink,
            letterSpacing: -0.7,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}
