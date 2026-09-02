import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Enam avatar tetap.
///
/// Bukan foto dan bukan unggahan: aplikasi anak yang menerima gambar
/// dari galeri langsung membawa urusan moderasi dan izin penyimpanan
/// yang tidak sebanding hasilnya.
abstract final class Avatar {
  static const daftar = <({String id, IconData ikon, Color warna})>[
    (id: 'roket', ikon: Icons.rocket_launch_rounded, warna: AppColors.brand),
    (id: 'bintang', ikon: Icons.star_rounded, warna: AppColors.brandLight),
    (id: 'bulan', ikon: Icons.nightlight_round, warna: AppColors.mula),
    (id: 'planet', ikon: Icons.public_rounded, warna: AppColors.puluh),
    (id: 'satelit', ikon: Icons.satellite_alt_rounded, warna: AppColors.pecah),
    (id: 'komet', ikon: Icons.auto_awesome_rounded, warna: AppColors.ukur),
  ];

  static ({String id, IconData ikon, Color warna}) cari(String id) {
    for (final a in daftar) {
      if (a.id == id) return a;
    }
    return daftar.first;
  }
}

class AvatarGrid extends StatelessWidget {
  const AvatarGrid({required this.terpilih, required this.onPilih, super.key});

  final String terpilih;
  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
      ),
      itemCount: Avatar.daftar.length,
      itemBuilder: (context, i) {
        final a = Avatar.daftar[i];
        final aktif = a.id == terpilih;
        return Semantics(
          selected: aktif,
          button: true,
          label: a.id,
          child: InkWell(
            onTap: () => onPilih(a.id),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: aktif ? 0.08 : 0.045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: aktif ? AppColors.brandLight : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(a.ikon, size: 38, color: a.warna),
            ),
          ),
        );
      },
    );
  }
}

/// Avatar bulat untuk bilah profil.
class AvatarBulat extends StatelessWidget {
  const AvatarBulat({required this.id, this.size = 64, super.key});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final a = Avatar.cari(id);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: a.warna.withValues(alpha: 0.16),
        border: Border.all(color: a.warna, width: 2),
      ),
      child: Icon(a.ikon, size: size * 0.5, color: a.warna),
    );
  }
}

/// Bentuk kecil dipakai di daftar; disatukan di sini supaya gaya
/// avatarnya tidak bercabang dua.
class AvatarLabel extends StatelessWidget {
  const AvatarLabel({required this.id, required this.nama, super.key});

  final String id;
  final String nama;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AvatarBulat(id: id, size: 40),
        const SizedBox(width: 12),
        Text(nama, style: AppTextStyles.title),
      ],
    );
  }
}
