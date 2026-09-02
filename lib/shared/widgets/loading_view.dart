import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Semua data ada di perangkat, jadi menunggu di sini selalu singkat.
/// Yang ditampilkan cuma satu lingkaran, tanpa kalimat "memuat" yang
/// akan hilang sebelum sempat terbaca.
class LoadingView extends StatelessWidget {
  const LoadingView({this.diAtasGelap = false, super.key});

  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: diAtasGelap ? AppColors.brandLight : AppColors.brand,
        ),
      ),
    );
  }
}

/// Layar kosong yang tetap menjelaskan apa yang terjadi dan apa yang
/// bisa dilakukan — bukan sekadar ruang putih.
class EmptyView extends StatelessWidget {
  const EmptyView({
    required this.judul,
    this.keterangan,
    this.ikon = Icons.rocket_launch_rounded,
    this.aksi,
    this.diAtasGelap = false,
    super.key,
  });

  final String judul;
  final String? keterangan;
  final IconData ikon;
  final Widget? aksi;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    final ink = diAtasGelap ? AppColors.inkOnSpace : AppColors.ink;
    final ink2 = diAtasGelap ? AppColors.ink2OnSpace : AppColors.ink2;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ikon, size: 44, color: ink2),
            const SizedBox(height: 18),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: AppTextStyles.h2.copyWith(color: ink),
            ),
            if (keterangan != null) ...[
              const SizedBox(height: 9),
              Text(
                keterangan!,
                textAlign: TextAlign.center,
                style: AppTextStyles.sub.copyWith(color: ink2),
              ),
            ],
            if (aksi != null) ...[const SizedBox(height: 22), aksi!],
          ],
        ),
      ),
    );
  }
}
