import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/grade.dart';
import '../../../shared/widgets/planet_orb.dart';

/// Enam planet dalam dua kolom.
///
/// Kelas dipilih sendiri, bukan dikunci berurutan — anak kelas 4 tidak
/// akan mau mulai dari `2 + 3`. Planet yang belum berisi tetap
/// ditampilkan dengan penanda "segera", bukan disembunyikan, supaya
/// daftarnya tidak terlihat berhenti di kelas 2.
class PlanetGrid extends StatelessWidget {
  const PlanetGrid({
    required this.planets,
    required this.terpilih,
    required this.onPilih,
    this.sudahBeli = false,
    super.key,
  });

  final List<Grade> planets;
  final String? terpilih;
  final ValueChanged<Grade> onPilih;

  /// Planet berbayar tetap **bisa ditekan** walau belum dibeli — yang
  /// terjadi sesudahnya membawa ke layar penjualannya, bukan diam.
  /// Kartu yang tidak merespons sentuhan terbaca sebagai aplikasi
  /// rusak, bukan sebagai "ini berbayar".
  final bool sudahBeli;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 13,
        crossAxisSpacing: 13,
        childAspectRatio: 1.28,
      ),
      itemCount: planets.length,
      itemBuilder: (context, i) {
        final g = planets[i];
        return _Kartu(
          grade: g,
          warna: AppColors.forGrade(g.orderIndex),
          terpilih: g.id == terpilih,
          terkunci: g.requiresPurchase && !sudahBeli,
          onTap: () => onPilih(g),
        );
      },
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.grade,
    required this.warna,
    required this.terpilih,
    required this.terkunci,
    required this.onTap,
  });

  final Grade grade;
  final Color warna;
  final bool terpilih;
  final bool terkunci;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: terpilih,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: terkunci ? 0.03 : (terpilih ? 0.06 : 0.045),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: terpilih ? AppColors.brandLight : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PlanetOrb(
                color: warna,
                size: 42,
                terpilih: terpilih,
                bayangan: false,
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    grade.label,
                    style: AppTextStyles.title.copyWith(
                      fontSize: 15.5,
                      color: AppColors.inkOnSpace,
                    ),
                  ),
                  if (!grade.isUnlocked) ...[
                    const SizedBox(width: 7),
                    const _PilSegera(),
                  ] else if (terkunci) ...[
                    const SizedBox(width: 7),
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 15,
                      color: AppColors.ink3OnSpace,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                grade.name,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12.5,
                  color: AppColors.ink3OnSpace,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PilSegera extends StatelessWidget {
  const _PilSegera();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'segera',
        style: AppTextStyles.caption.copyWith(
          fontSize: 10.5,
          color: AppColors.ink3OnSpace,
        ),
      ),
    );
  }
}
