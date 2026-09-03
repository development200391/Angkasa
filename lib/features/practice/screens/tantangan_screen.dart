import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/engine/streak_rules.dart';
import '../../../domain/models/daily_activity.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';
import '../widgets/api_streak.dart';

/// Tantangan Harian, dan rumah dari streak.
///
/// Pelindung streak dipakai **diam-diam** lalu diberitahukan sesudahnya.
/// Anak tidak pernah melihat rentetannya putus gara-gara satu hari sakit
/// — dan itu satu-satunya alasan pelindung ini ada.
class TantanganScreen extends ConsumerWidget {
  const TantanganScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profileProvider).value;
    final minggu = ref.watch(mingguIniProvider);
    final ringkasan = ref.watch(practiceSummaryProvider).value;
    final sudah = ringkasan?.tantanganSelesai ?? false;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: minggu.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => EmptyView(
                judul: 'Gagal memuat',
                keterangan: '$e',
                diAtasGelap: true,
              ),
              data: (hari) {
                final streak = profil?.streakCount ?? 0;
                final pelindungTersedia = StreakRules.pelindungTersedia(
                  pelindungTerakhir: profil?.streakShieldLastUsed,
                  hariIni: DateTime.now(),
                );
                final xpMinggu = hari.fold<int>(0, (a, h) => a + h.xpEarned);
                final posMinggu = hari.fold<int>(
                  0,
                  (a, h) => a + h.levelsCompleted,
                );
                final aktif = hari.where((h) => h.aktif).length;

                return Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.ink2OnSpace,
                          ),
                        ),
                        Text(
                          'Tantangan Harian',
                          style: AppTextStyles.h2.copyWith(
                            fontSize: 22,
                            color: AppColors.inkOnSpace,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const ApiStreak(size: 86),
                    const SizedBox(height: 6),
                    Text(
                      streak == 1 ? '1 hari' : '$streak hari',
                      style: AppTextStyles.h1.copyWith(
                        fontSize: 34,
                        color: AppColors.inkOnSpace,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      streak == 0
                          ? 'Belum mulai. Satu pos hari ini sudah cukup.'
                          : 'berturut-turut. Jangan putus hari ini.',
                      style: AppTextStyles.sub.copyWith(
                        fontSize: 13.5,
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                    const SizedBox(height: 22),
                    _Minggu(hari: hari),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Text(
                        pelindungTersedia
                            ? 'Pelindung streak minggu ini masih utuh — satu '
                                  'hari boleh terlewat.'
                            : 'Pelindung streak minggu ini sudah terpakai. '
                                  'Sisa 0 minggu ini.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11.5,
                          color: AppColors.ink3OnSpace,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Row(
                        children: [
                          _Kotak(nilai: '$aktif', label: 'hari aktif'),
                          const SizedBox(width: 10),
                          _Kotak(
                            nilai: '$xpMinggu',
                            label: 'XP minggu ini',
                            warna: AppColors.brandLight,
                          ),
                          const SizedBox(width: 10),
                          _Kotak(nilai: '$posMinggu', label: 'pos dikerjakan'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: Column(
                        children: [
                          _KartuSet(sudah: sudah),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            label: sudah
                                ? 'Kerjakan lagi (tanpa XP)'
                                : 'Mulai tantangan',
                            onPressed: () => context.pushReplacement(
                              Rute.sesiLatihanUntuk(
                                PracticeMode.tantanganHarian,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tujuh titik, Senin sampai Minggu. Hari yang terlewat digambar sebagai
/// lingkaran putus-putus, bukan silang merah — yang lewat sudah lewat.
class _Minggu extends StatelessWidget {
  const _Minggu({required this.hari});

  final List<DailyActivity> hari;

  @override
  Widget build(BuildContext context) {
    final tanggal = StreakRules.mingguIni(DateTime.now());
    final hariIni = StreakRules.tanggalSaja(DateTime.now());
    final aktif = {
      for (final h in hari)
        if (h.aktif) StreakRules.tanggalSaja(h.date),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (var i = 0; i < tanggal.length; i++)
            Expanded(
              child: Column(
                children: [
                  _Titik(
                    aktif: aktif.contains(tanggal[i]),
                    hariIni: tanggal[i] == hariIni,
                    depan: tanggal[i].isAfter(hariIni),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    StreakRules.hurufHari[i],
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: tanggal[i] == hariIni
                          ? AppColors.brandLight
                          : AppColors.ink3OnSpace,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Titik extends StatelessWidget {
  const _Titik({
    required this.aktif,
    required this.hariIni,
    required this.depan,
  });

  final bool aktif;
  final bool hariIni;
  final bool depan;

  @override
  Widget build(BuildContext context) {
    if (aktif) {
      return Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.36, -0.48),
            colors: [Color(0xFFFFD98A), Color(0xFFE9B24C), Color(0xFF9C5E0B)],
            stops: [0, 0.48, 1],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF040814).withValues(alpha: 0.8),
              offset: const Offset(0, 3),
              blurRadius: 7,
              spreadRadius: -2,
            ),
          ],
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 17,
          color: Color(0xFF3A2405),
        ),
      );
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: hariIni
              ? AppColors.brandLight
              : Colors.white.withValues(alpha: depan ? 0.10 : 0.16),
          width: 2,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              nilai,
              style: AppTextStyles.numeral.copyWith(
                fontSize: 21,
                color: warna ?? AppColors.inkOnSpace,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                color: AppColors.ink3OnSpace,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuSet extends StatelessWidget {
  const _KartuSet({required this.sudah});

  final bool sudah;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8B75B), Color(0xFFB77A11)],
              ),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set hari ini · 10 soal',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    color: AppColors.inkOnSpace,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Campuran dari zona yang sudah dibuka',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12.5,
                    color: AppColors.ink3OnSpace,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: sudah
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.brandLight,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              sudah ? 'selesai' : 'XP ×2',
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: sudah ? AppColors.ink3OnSpace : const Color(0xFF3A2405),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
