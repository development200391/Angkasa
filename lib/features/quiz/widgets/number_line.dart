import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/question.dart';

/// Garis bilangan — tingkat tengah sumbu S3.
///
/// Bantuannya sudah tidak menghitung untuk anak seperti gambar benda,
/// tapi masih menunjukkan **arah**: maju untuk tambah, mundur untuk
/// kurang. Itu jembatan terakhir sebelum angka telanjang.
class NumberLine extends StatelessWidget {
  const NumberLine({required this.soal, super.key});

  final Question soal;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: CustomPaint(
        size: Size.infinite,
        painter: _NumberLinePainter(soal: soal),
      ),
    );
  }
}

class _NumberLinePainter extends CustomPainter {
  _NumberLinePainter({required this.soal});

  final Question soal;

  @override
  void paint(Canvas canvas, Size size) {
    const kiri = 10.0;
    final kanan = size.width - 10;
    const y = 70.0;
    final maks = soal.numberLineMax;
    double x(int n) => kiri + (kanan - kiri) * (n.clamp(0, maks) / maks);

    final garis = Paint()
      ..color = const Color(0xFFC6CEDC)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(kiri, y), Offset(kanan, y), garis);

    // Tanda tetap: nol, tengah, dan batas atas. Lebih dari itu, garisnya
    // jadi penuh angka dan berhenti menolong.
    for (final n in {0, maks ~/ 2, maks}) {
      canvas.drawLine(
        Offset(x(n), y - 6),
        Offset(x(n), y + 6),
        Paint()
          ..color = const Color(0xFFC6CEDC)
          ..strokeWidth = 2,
      );
      _teks(canvas, '$n', Offset(x(n), y + 10), AppColors.ink3, 11);
    }

    final mundur = soal.operation == Operation.kurang;
    final mulai = soal.left;
    final akhir = soal.result;

    _tanda(canvas, x(mulai), y, AppColors.brand, '$mulai');
    _tanda(canvas, x(akhir), y, AppColors.ok, '$akhir');

    // Lompatannya digambar melengkung di atas garis, dengan mata panah
    // di ujungnya supaya arahnya tidak perlu dibaca dari angkanya.
    final a = x(mulai), b = x(akhir);
    final busur = Path()
      ..moveTo(a, y - 8)
      ..quadraticBezierTo((a + b) / 2, y - 58, b, y - 8);
    _putusPutus(
      canvas,
      busur,
      Paint()
        ..color = AppColors.brand
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round,
    );
    _panah(canvas, Offset(b, y - 8), mundur);

    _teks(
      canvas,
      '${mundur ? "−" : "+"}${soal.right}',
      Offset((a + b) / 2, y - 56),
      AppColors.brand,
      12,
      tebal: true,
    );
  }

  void _tanda(Canvas canvas, double x, double y, Color warna, String label) {
    canvas.drawLine(
      Offset(x, y - 8),
      Offset(x, y + 8),
      Paint()
        ..color = warna
        ..strokeWidth = 2.6,
    );
    _teks(canvas, label, Offset(x, y + 10), warna, 11, tebal: true);
  }

  void _panah(Canvas canvas, Offset ujung, bool mundur) {
    final arah = mundur ? -1.0 : 1.0;
    final p = Path()
      ..moveTo(ujung.dx - 5 * arah, ujung.dy - 6)
      ..lineTo(ujung.dx + 3 * arah, ujung.dy + 1)
      ..lineTo(ujung.dx - 6 * arah, ujung.dy + 5)
      ..close();
    canvas.drawPath(p, Paint()..color = AppColors.brand);
  }

  void _putusPutus(Canvas canvas, Path path, Paint cat) {
    const isi = 5.0, kosong = 6.0;
    for (final m in path.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, (d + isi).clamp(0, m.length)), cat);
        d += isi + kosong;
      }
    }
  }

  void _teks(
    Canvas canvas,
    String isi,
    Offset pusat,
    Color warna,
    double ukuran, {
    bool tebal = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: isi,
        style: TextStyle(
          fontFamily: AppTextStyles.family,
          fontSize: ukuran,
          color: warna,
          fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
          fontFeatures: const [AppTextStyles.tabular],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pusat.dx - tp.width / 2, pusat.dy));
  }

  @override
  bool shouldRepaint(covariant _NumberLinePainter oldDelegate) =>
      oldDelegate.soal.signature != soal.signature;
}
