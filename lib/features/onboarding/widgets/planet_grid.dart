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
    super.key,
  });

  final List<Grade> planets;
  final String? terpilih;
  final ValueChanged<Grade> onPilih;

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
    required this.onTap,
  });

  final Grade grade;
  final Color warna;
  final bool terpilih;
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
            color: Colors.white.withValues(alpha: terpilih ? 0.06 : 0.045),
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
