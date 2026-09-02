import 'dart:math';

import 'package:flutter/material.dart';

/// Latar bintang untuk semua layar berlatar angkasa.
///
/// Seednya tetap: bintangnya harus berada di tempat yang sama tiap kali
/// layar dibangun ulang. Bintang yang berpindah sendiri saat sheet
/// dibuka membuat layarnya terasa goyah, dan itu langsung terlihat di HP
/// yang sering me-rebuild.
class Starfield extends StatelessWidget {
  const Starfield({this.jumlah = 90, this.seed = 7, super.key});

  final int jumlah;
  final int seed;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _StarfieldPainter(jumlah: jumlah, seed: seed),
        ),
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  _StarfieldPainter({required this.jumlah, required this.seed});

  final int jumlah;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final acak = Random(seed);
    final cat = Paint();
    for (var i = 0; i < jumlah; i++) {
      final x = acak.nextDouble() * size.width;
      final y = acak.nextDouble() * size.height;
      final r = 0.7 + acak.nextDouble() * 0.9;
      // Tiga tingkat terang saja; lebih dari itu jadi berisik dan
      // menarik perhatian dari lintasannya.
      final terang = acak.nextInt(3);
      cat.color = switch (terang) {
        0 => const Color(0xFF1E2740),
        1 => const Color(0xFF26314F),
        _ => const Color(0xFF3A4767),
      };
      canvas.drawCircle(Offset(x, y), r, cat);
    }
  }

  @override
  bool shouldRepaint(covariant _StarfieldPainter oldDelegate) =>
      oldDelegate.jumlah != jumlah || oldDelegate.seed != seed;
}
