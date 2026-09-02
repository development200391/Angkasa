import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/level_view.dart';
import '../../../shared/widgets/star_rating.dart';

/// Daftar zona satu planet.
///
/// Zona yang belum terbuka tetap ditampilkan dengan judulnya. Anak boleh
/// tahu apa yang menunggu di depan — yang dikunci cuma jalan masuknya.
class ZonaSheet extends StatelessWidget {
  const ZonaSheet({required this.peta, required this.onPilih, super.key});

  final PetaPlanet peta;
  final void Function(String chapterId) onPilih;

  static Future<void> tampilkan(
    BuildContext context, {
    required PetaPlanet peta,
    required void Function(String chapterId) onPilih,
  }) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: const Color(0x8C080D1A),
    isScrollControlled: true,
    builder: (_) => ZonaSheet(peta: peta, onPilih: onPilih),
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text(peta.grade.name, style: AppTextStyles.h2),
                  const Spacer(),
                  Text(
                    '${peta.totalStars} bintang',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                shrinkWrap: true,
                itemCount: peta.chapters.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final z = peta.chapters[i];
                  final bintang = z.levels.fold(0, (a, l) => a + l.stars);
                  return _BarisZona(
                    zona: z,
                    bintang: bintang,
                    onTap: z.terbuka
                        ? () {
                            onPilih(z.chapter.id);
                            Navigator.of(context).pop();
                          }
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarisZona extends StatelessWidget {
  const _BarisZona({
    required this.zona,
    required this.bintang,
    required this.onTap,
  });

  final ChapterView zona;
  final int bintang;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final terkunci = onTap == null;
    return Material(
      color: AppColors.bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: terkunci
                      ? AppColors.line
                      : AppColors.fromHex(zona.chapter.color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: terkunci
                    ? const Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: AppColors.lock,
                      )
                    : Text(
                        '${zona.chapter.orderIndex}',
                        style: AppTextStyles.numeral.copyWith(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zona.chapter.title,
                      style: AppTextStyles.title.copyWith(
                        color: terkunci ? AppColors.ink3 : AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${zona.selesai}/${zona.total} pos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              if (!terkunci)
                StarRating(
                  stars: (bintang / (zona.total * 3) * 3).round(),
                  size: 15,
                  gap: 1,
                  diAtasGelap: false,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
