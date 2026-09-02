import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Bola planet.
///
/// Dua `RadialGradient` bertumpuk dengan titik cahaya digeser ke
/// kiri-atas, ditambah elips gelap tipis di bawahnya sebagai bayangan.
/// Tidak ada satu pun berkas gambar di sini — kalau warna planetnya
/// berubah, tidak ada aset yang perlu dirender ulang.
class PlanetOrb extends StatelessWidget {
  const PlanetOrb({
    required this.color,
    this.size = 42,
    this.terpilih = false,
    this.bayangan = true,
    super.key,
  });

  final Color color;
  final double size;
  final bool terpilih;
  final bool bayangan;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * (bayangan ? 1.18 : 1),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (bayangan)
            Positioned(
              bottom: 0,
              child: Container(
                width: size * 0.82,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: const Color(0xFF060B18).withValues(alpha: 0.45),
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(size * 0.41, size * 0.08),
                  ),
                ),
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.32, -0.44),
                radius: 0.9,
                colors: [
                  color,
                  color,
                  Color.lerp(color, Colors.black, 0.36)!,
                  Color.lerp(color, Colors.black, 0.55)!,
                ],
                stops: const [0, 0.3, 0.88, 1],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF040814).withValues(alpha: 0.75),
                  offset: const Offset(0, 4),
                  blurRadius: 9,
                  spreadRadius: -3,
                ),
                if (terpilih)
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    spreadRadius: 5,
                  ),
              ],
            ),
            child: CustomPaint(painter: _KilauPainter()),
          ),
        ],
      ),
    );
  }
}

/// Titik cahaya kecil di kiri-atas. Yang membuat bolanya terbaca bulat
/// bukan gradiennya saja, tapi kilau yang tidak sepusat dengan bolanya.
class _KilauPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width * 0.34, size.height * 0.28),
      width: size.width * 0.45,
      height: size.height * 0.32,
    );
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(-0.49);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.drawOval(
      rect,
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KilauPainter oldDelegate) => false;
}

/// Chip planet di pojok kiri atas peta: bola kecil, kelas, dan nama.
class PlanetChip extends StatelessWidget {
  const PlanetChip({
    required this.kelas,
    required this.nama,
    required this.color,
    this.onTap,
    super.key,
  });

  final String kelas;
  final String nama;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlanetOrb(color: color, size: 27, bayangan: false),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kelas,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.1,
                    color: AppColors.ink3OnSpace,
                  ),
                ),
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkOnSpace,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
