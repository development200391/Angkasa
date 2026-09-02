import 'package:flutter/material.dart';

/// Tata letak lintasan: di mana tiap pos berdiri.
///
/// Polanya berkelok kiri–kanan dengan jarak tetap ke bawah. Nilai
/// pecahannya diambil langsung dari `design/ui.html` supaya lintasannya
/// jatuh persis seperti di rancangan.
abstract final class LintasanLayout {
  static const _x = <double>[0.236, 0.626, 0.687, 0.431, 0.246, 0.513];

  /// Jaraknya harus lebih tinggi dari bola pos **beserta** label di
  /// bawahnya — kalau tidak, pil MULAI menabrak pos berikutnya.
  static const jarakVertikal = 112.0;
  static const atas = 66.0;
  static const bawah = 84.0;

  static double tinggi(int jumlah) =>
      atas + (jumlah - 1).clamp(0, 999) * jarakVertikal + bawah;

  static List<Offset> posisi(int jumlah, double lebar) => [
    for (var i = 0; i < jumlah; i++)
      Offset(_x[i % _x.length] * lebar, atas + i * jarakVertikal),
  ];
}

/// Lintasan roket: garis putus-putus yang menghubungkan pos.
///
/// Titiknya digambar satu per satu di sepanjang kurva, bukan dengan
/// `dashArray` — Flutter tidak punya itu, dan menghitungnya sendiri juga
/// yang membuat jaraknya tetap rapi di lebar layar mana pun.
class PathPainter extends CustomPainter {
  const PathPainter({
    required this.titik,
    required this.sampaiIndeks,
    this.warnaAktif = const Color(0x29FFFFFF),
    this.warnaPasif = const Color(0x14FFFFFF),
  });

  /// Posisi tiap pos.
  final List<Offset> titik;

  /// Sampai pos ke berapa lintasannya sudah dilewati. Ruas sesudahnya
  /// digambar lebih redup — jalannya tetap terlihat, tapi jelas belum
  /// ditempuh.
  final int sampaiIndeks;

  final Color warnaAktif;
  final Color warnaPasif;

  @override
  void paint(Canvas canvas, Size size) {
    if (titik.length < 2) return;

    for (var i = 0; i < titik.length - 1; i++) {
      final jalur = _ruas(titik[i], titik[i + 1]);
      final dilewati = i < sampaiIndeks;
      _titikTitik(
        canvas,
        jalur,
        warna: dilewati ? warnaAktif : warnaPasif,
        radius: dilewati ? 4 : 3.4,
      );
    }
  }

  /// Satu ruas antar pos, melengkung lewat dua titik kendali vertikal.
  static Path _ruas(Offset a, Offset b) {
    final d = (b.dy - a.dy) * 0.55;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy + d, b.dx, b.dy - d, b.dx, b.dy);
  }

  void _titikTitik(
    Canvas canvas,
    Path jalur, {
    required Color warna,
    required double radius,
  }) {
    const jarak = 19.0;
    final bayangan = Paint()..color = const Color(0x8C060B18);
    final cat = Paint()..color = warna;

    for (final ukur in jalur.computeMetrics()) {
      // Mulai dari 30 supaya titik pertama tidak tertimpa bola pos.
      for (var d = 30.0; d < ukur.length - 26; d += jarak) {
        final p = ukur.getTangentForOffset(d)?.position;
        if (p == null) continue;
        canvas.drawCircle(p.translate(0, 3), radius, bayangan);
        canvas.drawCircle(p, radius, cat);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) =>
      oldDelegate.sampaiIndeks != sampaiIndeks ||
      oldDelegate.titik.length != titik.length ||
      oldDelegate.titik.first != titik.first;
}
