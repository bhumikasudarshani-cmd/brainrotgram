import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// The same brain-and-play mark used by the website.
class BrandMark extends StatelessWidget {
  final double size;
  final Color ink;
  const BrandMark({super.key, this.size = 32, this.ink = AppColors.plum});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: CustomPaint(size: Size.square(size), painter: _BrainPainter(ink)));
}

class _BrainPainter extends CustomPainter {
  final Color ink;
  const _BrainPainter(this.ink);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final brain = Path()
      ..moveTo(22, 9)
      ..cubicTo(16, 2, 5, 9, 9, 16)
      ..cubicTo(1, 19, 4, 31, 11, 31)
      ..cubicTo(9, 40, 20, 45, 25, 38)
      ..cubicTo(33, 45, 43, 37, 39, 30)
      ..cubicTo(48, 26, 45, 14, 38, 13)
      ..cubicTo(37, 4, 26, 1, 22, 9)
      ..close();
    canvas.drawPath(brain, Paint()..color = AppColors.coral);
    canvas.drawPath(
        brain,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6
          ..strokeJoin = StrokeJoin.round);
    canvas.drawPath(
        Path()
          ..moveTo(21, 17)
          ..lineTo(33, 24)
          ..lineTo(21, 31)
          ..close(),
        Paint()..color = ink);
    canvas.drawPath(
        Path()
          ..moveTo(13, 16)
          ..cubicTo(18, 16, 19, 12, 18, 9)
          ..moveTo(10, 27)
          ..cubicTo(16, 25, 18, 28, 17, 33),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _BrainPainter oldDelegate) =>
      oldDelegate.ink != ink;
}
