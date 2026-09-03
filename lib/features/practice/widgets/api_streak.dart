import 'package:flutter/material.dart';

/// Api streak.
///
/// Digambar langsung, bukan aset: bentuknya sama dengan ikon api di
/// bilah atas peta, cuma lebih besar dan bergradien — dan kalau warnanya
/// suatu hari berubah, tidak ada berkas yang perlu dirender ulang.
class ApiStreak extends StatelessWidget {
  const ApiStreak({this.size = 86, this.redup = false, super.key});

  final double size;

  /// Streak yang sedang putus digambar pucat, bukan hilang — apinya
  /// tetap di tempatnya, menunggu dinyalakan lagi.
  final bool redup;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ApiPainter(redup: redup)),
    );
  }
}

class _ApiPainter extends CustomPainter {
  const _ApiPainter({required this.redup});

  final bool redup;

  /// Jalur api dari `design/ui.html`, dalam kotak 24 × 24.
  static final _luar = Path()
    ..moveTo(12, 2)
    ..cubicTo(13, 6, 9, 7, 9, 10)
    ..arcToPoint(const Offset(15, 10), radius: const Radius.circular(3))
    ..cubicTo(15, 9, 14.6, 8, 14.6, 8)
    ..cubicTo(16.6, 9.5, 18, 11.6, 18, 14)
    ..arcToPoint(const Offset(6, 14), radius: const Radius.circular(6))
    ..cubicTo(6, 9.5, 10, 7.5, 12, 2)
    ..close();

  static final _dalam = Path()
    ..moveTo(12, 12.5)
    ..cubicTo(12.6, 14.5, 10.6, 15.1, 10.6, 16.6)
    ..arcToPoint(const Offset(13.6, 16.6), radius: const Radius.circular(1.5))
    ..cubicTo(13.6, 16, 13.4, 15.6, 13.4, 15.6)
    ..cubicTo(14.4, 16.4, 15, 17.4, 15, 18.6)
    ..arcToPoint(const Offset(9, 18.6), radius: const Radius.circular(3))
    ..cubicTo(9, 16.4, 11, 15.4, 12, 12.5)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);

    final rect = const Rect.fromLTWH(0, 0, 24, 24);
    canvas.drawPath(
      _luar,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.24, -0.4),
          radius: 0.76,
          colors: redup
              ? const [Color(0xFF6B7793), Color(0xFF48536C), Color(0xFF2B3348)]
              : const [Color(0xFFFFD98A), Color(0xFFE9863A), Color(0xFFA83B12)],
          stops: const [0, 0.46, 1],
        ).createShader(rect),
    );

    canvas.drawPath(
      _dalam,
      Paint()
        ..color = (redup ? const Color(0xFF95A1BC) : const Color(0xFFFFE7B0))
            .withValues(alpha: 0.85),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ApiPainter oldDelegate) =>
      oldDelegate.redup != redup;
}
