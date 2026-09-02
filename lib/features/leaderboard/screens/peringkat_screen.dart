import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../home/widgets/starfield.dart';
import '../../onboarding/widgets/avatar_grid.dart';

/// Tab Peringkat.
///
/// Papan peringkat baru menyala di Tahap 3, karena butuh Firebase — dan
/// Tahap 1 sengaja dirilis tanpa satu baris pun kode Firebase. Yang
/// ditampilkan sekarang adalah XP milik anak sendiri: angka yang sama
/// yang nanti dikirim ke liga mingguan.
class PeringkatScreen extends ConsumerWidget {
  const PeringkatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 70)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Peringkat',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.inkOnSpace,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Liga mingguan 30 pemain menyala di Tahap 3. Bukan '
                    'peringkat global — supaya semua orang punya peluang '
                    'naik minggu depan.',
                    style: AppTextStyles.sub.copyWith(
                      color: AppColors.ink2OnSpace,
                    ),
                  ),
                  const SizedBox(height: 26),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        AvatarBulat(id: profil?.avatarId ?? 'roket', size: 48),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profil?.nickname.isNotEmpty ?? false
                                    ? profil!.nickname
                                    : 'Penjelajah',
                                style: AppTextStyles.title.copyWith(
                                  color: AppColors.inkOnSpace,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'XP-mu minggu ini',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.ink3OnSpace,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${profil?.totalXp ?? 0}',
                          style: AppTextStyles.numeral.copyWith(
                            color: AppColors.brandLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
