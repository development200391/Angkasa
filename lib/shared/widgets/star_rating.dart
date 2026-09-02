import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/app_assets.dart';

/// Bintang bersegi sepuluh sisi, tiap sisi diberi terang berbeda sesuai
/// arah cahaya dari kiri-atas. Itu satu-satunya aset gambar di layar ini
/// — bola pos, planet, dan tombol semuanya digambar langsung oleh
/// Flutter.
class StarIcon extends StatelessWidget {
  const StarIcon({
    this.terisi = true,
    this.diAtasGelap = true,
    this.gembok = false,
    this.size = 20,
    super.key,
  });

  final bool terisi;
  final bool diAtasGelap;
  final bool gembok;
  final double size;

  @override
  Widget build(BuildContext context) {
    final aset = gembok
        ? AppAssets.starGembok
        : terisi
        ? AppAssets.starEmas
        : diAtasGelap
        ? AppAssets.starKosongGelap
        : AppAssets.starKosongTerang;

    // Rasio bintangnya 100 × 104 — bayangan bawahnya ikut di dalam
    // viewBox, jadi tingginya sedikit lebih dari lebarnya.
    return SvgPicture.asset(aset, width: size, height: size * 1.04);
  }
}

/// Tiga bintang berjajar. Dipakai sheet detail pos, kartu pos di
/// lintasan, dan layar hasil.
class StarRating extends StatelessWidget {
  const StarRating({
    required this.stars,
    this.total = 3,
    this.size = 20,
    this.gap = 3,
    this.diAtasGelap = true,
    super.key,
  });

  final int stars;
  final int total;
  final double size;
  final double gap;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$stars dari $total bintang',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            ExcludeSemantics(
              child: StarIcon(
                terisi: i < stars,
                diAtasGelap: diAtasGelap,
                size: size,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
