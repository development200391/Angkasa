import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/repositories/practice_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';
import '../../profile/widgets/badge_medal.dart';
import '../widgets/api_streak.dart';

/// Hasil satu sesi latihan.
///
/// Tidak ada bintang di sini — latihan memang tidak mengubah lintasan.
/// Yang ditampilkan cuma yang benar-benar berubah: berapa benar, XP,
/// streak, dan lencana yang baru terbuka.
class HasilLatihanScreen extends StatelessWidget {
  const HasilLatihanScreen({required this.hasil, super.key});

  final PracticeOutcome hasil;

  @override
  Widget build(BuildContext context) {
    final judul = switch (hasil.mode) {
      PracticeMode.kilat60 => hasil.rekorBaru ? 'Rekor baru!' : 'Waktu habis',
      PracticeMode.tantanganHarian => 'Tantangan selesai',
      _ => 'Latihan selesai',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Rute.latihan);
      },
      child: Scaffold(
        backgroundColor: AppColors.space,
        body: Stack(
          children: [
            const Positioned.fill(child: Starfield()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    if (hasil.streak > 0) ...[
                      const ApiStreak(size: 72),
                      const SizedBox(height: 10),
                      Text(
                        'Streak ${hasil.streak} hari',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.brandLight,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Text(
                      judul,
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 28,
                        color: AppColors.inkOnSpace,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      hasil.mode.judul,
                      style: AppTextStyles.sub.copyWith(
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _Kotak(
                          nilai: hasil.mode == PracticeMode.kilat60
                              ? '${hasil.benar}'
                              : '${hasil.benar}/${hasil.total}',
                          label: 'benar',
                        ),
                        const SizedBox(width: 10),
                        _Kotak(
                          nilai: '+${hasil.xp}',
                          label: 'XP',
                          warna: AppColors.brandLight,
                        ),
                      ],
                    ),
                    if (hasil.pelindungTerpakai) ...[
                      const SizedBox(height: 16),
                      const _Kabar(
                        ikon: Icons.shield_moon_outlined,
                        teks:
                            'Satu hari terlewat, tapi pelindung streak '
                            'terpakai otomatis.',
                      ),
                    ],
                    if (hasil.lencanaBaru.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _LencanaBaru(kode: hasil.lencanaBaru),
                    ],
                    const Spacer(),
                    PrimaryButton(
                      label: 'Selesai',
                      onPressed: () => context.go(Rute.latihan),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({required this.nilai, required this.label, this.warna});

  final String nilai;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              nilai,
              style: AppTextStyles.numeral.copyWith(
                color: warna ?? AppColors.inkOnSpace,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 12,
                color: AppColors.ink3OnSpace,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kabar extends StatelessWidget {
  const _Kabar({required this.ikon, required this.teks});

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.brandLight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(ikon, size: 18, color: AppColors.brandLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teks,
              style: AppTextStyles.body.copyWith(
                fontSize: 13.5,
                color: AppColors.brandLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lencana baru muncul dengan hentakan kecil. Ini satu-satunya kejutan
/// di layar hasil latihan, jadi boleh sedikit berlebihan.
class _LencanaBaru extends StatelessWidget {
  const _LencanaBaru({required this.kode});

  final List<String> kode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          kode.length == 1 ? 'Lencana baru' : '${kode.length} lencana baru',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.brandLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (var i = 0; i < kode.length; i++)
              BadgeCell(code: kode[i], didapat: true, size: 60)
                  .animate()
                  .scale(
                    begin: const Offset(0.4, 0.4),
                    end: const Offset(1, 1),
                    duration: 380.ms,
                    delay: (160 * i).ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 200.ms, delay: (160 * i).ms),
          ],
        ),
      ],
    );
  }
}
