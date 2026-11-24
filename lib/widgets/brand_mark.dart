import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared geometric Trabalhaki brand emblem (matches Web BrandMark.tsx).
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted ? Colors.white.withValues(alpha: 0.16) : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: inverted
            ? Border.all(color: Colors.white.withValues(alpha: 0.25))
            : null,
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.62,
          height: size * 0.62,
          child: CustomPaint(painter: _BrandEmblemPainter()),
        ),
      ),
    );
  }
}

class _BrandEmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    canvas.save();
    canvas.scale(sx, sy);

    // Back card
    final backPaint = Paint()..color = Colors.white.withValues(alpha: 0.36);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 3.5, 11, 13.5),
        const Radius.circular(3),
      ),
      backPaint,
    );

    // Front card
    final frontPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 7, 11, 13.5),
        const Radius.circular(3),
      ),
      frontPaint,
    );

    // Match check inside front card
    final checkPaint = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(13, 13.75)
      ..lineTo(14.75, 15.5)
      ..lineTo(18.25, 11.75);
    canvas.drawPath(path, checkPaint);

    // Mint intersection node
    final dotPaint = Paint()..color = AppColors.secondary;
    canvas.drawCircle(const Offset(8.5, 7.5), 2.25, dotPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
