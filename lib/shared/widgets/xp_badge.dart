import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'star_rating.dart';

/// Penghitung XP di bilah atas peta. Angkanya tabular — kalau tidak,
/// tulisannya bergeser tiap kali XP bertambah.
class XpBadge extends StatelessWidget {
  const XpBadge({required this.xp, this.size = 14, super.key});

  final int xp;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$xp XP',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const StarIcon(size: 17),
          const SizedBox(width: 5),
          Text(
            '$xp',
            style: TextStyle(
              fontFamily: AppTextStyles.family,
              fontSize: size,
              fontWeight: FontWeight.w600,
              color: AppColors.brandLight,
              fontFeatures: const [AppTextStyles.tabular],
            ),
          ),
        ],
      ),
    );
  }
}

/// Penghitung streak. Isinya belum dihitung sampai Tahap 2; di Tahap 1
/// angkanya tetap dipasang supaya tata letak bilah atas tidak berubah
/// waktu fiturnya datang.
class StreakBadge extends StatelessWidget {
  const StreakBadge({required this.hari, super.key});

  final int hari;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Streak $hari hari',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            size: 17,
            color: AppColors.flame,
          ),
          const SizedBox(width: 4),
          Text(
            '$hari',
            style: const TextStyle(
              fontFamily: AppTextStyles.family,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.flame,
              fontFeatures: [AppTextStyles.tabular],
            ),
          ),
        ],
      ),
    );
  }
}
