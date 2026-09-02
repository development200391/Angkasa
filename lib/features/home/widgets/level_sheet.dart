import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/chapter.dart';
import '../../../domain/models/level_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/star_rating.dart';

/// Sheet detail pos.
///
/// Yang ditawarkan disebutkan **sebelum** anak masuk: berapa soal,
/// berapa lama, dan berapa XP-nya. Sesi yang panjangnya tidak diketahui
/// adalah sesi yang gampang ditinggalkan di tengah.
class LevelSheet extends StatelessWidget {
  const LevelSheet({
    required this.view,
    required this.chapter,
    required this.onMulai,
    super.key,
  });

  final LevelView view;
  final Chapter chapter;
  final VoidCallback onMulai;

  static Future<void> tampilkan(
    BuildContext context, {
    required LevelView view,
    required Chapter chapter,
    required VoidCallback onMulai,
  }) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: const Color(0x8C080D1A),
    isScrollControlled: true,
    builder: (_) => LevelSheet(view: view, chapter: chapter, onMulai: onMulai),
  );

  @override
  Widget build(BuildContext context) {
    final level = view.level;
    final cfg = level.difficultyConfig;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.brand,
                    shape: BoxShape.circle,
                  ),
                  child: level.isBoss
                      ? const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 26,
                        )
                      : Text(
                          '${level.orderIndex}',
                          style: AppTextStyles.numeral.copyWith(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(level.displayTitle, style: AppTextStyles.h2),
                      const SizedBox(height: 2),
                      Text(
                        chapter.label,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13.5,
                          color: AppColors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StarRating(
                  stars: view.stars,
                  size: 34,
                  gap: 9,
                  diAtasGelap: false,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _Kotak(nilai: '${cfg.questionCount}', label: 'soal'),
                const SizedBox(width: 10),
                _Kotak(nilai: '± ${cfg.perkiraanMenit}', label: 'menit'),
                const SizedBox(width: 10),
                _Kotak(nilai: '+${level.xpReward}', label: 'XP'),
              ],
            ),
            if (cfg.timeLimitSeconds != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    size: 18,
                    color: AppColors.ink3,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'Ada batas waktu ${cfg.timeLimitSeconds} detik per soal.',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              label: view.progress.isCompleted ? 'Kerjakan lagi' : 'Mulai',
              onPressed: onMulai,
            ),
          ],
        ),
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({required this.nilai, required this.label});

  final String nilai;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(nilai, style: AppTextStyles.numeral.copyWith(fontSize: 19)),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
