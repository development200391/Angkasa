import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/engine/star_calculator.dart';
import '../../../domain/models/quiz_result.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../home/widgets/starfield.dart';

/// Layar hasil pos.
///
/// Bintang diberikan dari **akurasi, bukan kecepatan** — anak yang
/// berpikir lama tapi benar tidak boleh kalah dari yang menebak cepat.
class ResultScreen extends ConsumerStatefulWidget {
  const ResultScreen({required this.hasil, super.key});

  final QuizResult hasil;

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.hasil.isPassed) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.hasil;
    final peta = ref.watch(petaProvider).value;
    final view = peta?.levelDari(h.levelId);
    final judul = view?.level.displayTitle ?? 'Pos';

    // Pos berikutnya yang terbuka, kalau ada — tombol utamanya
    // mengantar langsung ke sana, bukan memulangkan ke peta.
    final berikutnya = h.unlockedLevelIds.isEmpty
        ? null
        : h.unlockedLevelIds.first;
    final labelBerikutnya = berikutnya == null
        ? null
        : peta?.levelDari(berikutnya)?.level.displayTitle;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _kePeta();
      },
      child: Scaffold(
        backgroundColor: AppColors.space,
        body: Stack(
          children: [
            const Positioned.fill(child: Starfield()),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                emissionFrequency: 0.06,
                numberOfParticles: 14,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.22,
                colors: const [
                  AppColors.brandLight,
                  AppColors.mula,
                  AppColors.puluh,
                  AppColors.ukur,
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 46),
                    _Bintang(stars: h.stars),
                    const SizedBox(height: 26),
                    Text(
                      h.isPassed ? '$judul selesai!' : 'Belum lulus',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.inkOnSpace,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      h.outOfHearts
                          ? 'Hatinya habis. Pos ini bisa diulang kapan saja.'
                          : StarCalculator.pesan(h.stars),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sub.copyWith(
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      children: [
                        _Kotak(
                          nilai: '${h.correct}/${h.total}',
                          label: 'benar',
                        ),
                        const SizedBox(width: 10),
                        _Kotak(
                          nilai: '+${h.xpEarned}',
                          label: 'XP',
                          warna: AppColors.brandLight,
                        ),
                        const SizedBox(width: 10),
                        _Kotak(nilai: h.durationLabel, label: 'waktu'),
                      ],
                    ),
                    if (h.unlockedNextChapter) ...[
                      const SizedBox(height: 18),
                      const _KabarZona(),
                    ],
                    const Spacer(),
                    PrimaryButton(
                      label: labelBerikutnya != null
                          ? 'Lanjut ke $labelBerikutnya'
                          : (h.isPassed ? 'Kembali ke peta' : 'Coba lagi'),
                      onPressed: () {
                        if (berikutnya != null) {
                          context.pushReplacement(Rute.kuisUntuk(berikutnya));
                        } else if (h.isPassed) {
                          _kePeta();
                        } else {
                          context.pushReplacement(Rute.kuisUntuk(h.levelId));
                        }
                      },
                    ),
                    const SizedBox(height: 11),
                    if (h.wrongAnswers.isNotEmpty)
                      SecondaryButton(
                        label: 'Lihat ${h.wrongAnswers.length} soal yang salah',
                        diAtasGelap: true,
                        onPressed: () =>
                            context.push(Rute.pembahasan, extra: h),
                      )
                    else
                      SecondaryButton(
                        label: 'Kembali ke peta',
                        diAtasGelap: true,
                        onPressed: _kePeta,
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

  void _kePeta() => context.go(Rute.jelajah);
}

/// Tiga bintang, yang tengah lebih besar. Yang didapat muncul dengan
/// hentakan kecil satu per satu — satu-satunya animasi di layar ini.
class _Bintang extends StatelessWidget {
  const _Bintang({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    Widget satu(int i) {
      final besar = i == 1;
      final terisi = i < stars;
      final w = besar ? 100.0 : 74.0;
      final bintang = Padding(
        padding: EdgeInsets.only(bottom: besar ? 10 : 0),
        child: StarIcon(terisi: terisi, size: w),
      );
      if (!terisi) return bintang;
      return bintang
          .animate()
          .scale(
            begin: const Offset(0.4, 0.4),
            end: const Offset(1, 1),
            duration: 340.ms,
            delay: (140 * i).ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 180.ms, delay: (140 * i).ms);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        satu(0),
        const SizedBox(width: 6),
        satu(1),
        const SizedBox(width: 6),
        satu(2),
      ],
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

class _KabarZona extends StatelessWidget {
  const _KabarZona();

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
          const Icon(
            Icons.lock_open_rounded,
            size: 18,
            color: AppColors.brandLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gerbang tembus — zona berikutnya sudah terbuka.',
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
