import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/planet_orb.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';

/// Layar 32 · Pembelian berhasil.
///
/// **Cara memulihkan pembelian ditulis di sini**, bukan disembunyikan
/// di FAQ. Itu pertanyaan pertama orang tua saat ganti HP, dan
/// menjawabnya di layar yang pasti dibaca — tepat setelah membayar —
/// jauh lebih murah daripada menjawabnya satu per satu lewat surel.
class PembelianBerhasilScreen extends ConsumerStatefulWidget {
  const PembelianBerhasilScreen({super.key});

  @override
  ConsumerState<PembelianBerhasilScreen> createState() => _State();
}

class _State extends ConsumerState<PembelianBerhasilScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))
      ..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galaksi = ref.watch(galaksiProvider).value;
    final berbayar =
        galaksi?.planet.where((p) => p.grade.requiresPurchase).toList() ??
        const [];
    final rincian = ref.watch(rincianBeliProvider).value;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 90)),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 14,
              gravity: 0.22,
              colors: const [
                AppColors.brandLight,
                AppColors.pecah,
                AppColors.ukur,
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final p in berbayar)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: PlanetOrb(
                            color: AppColors.forGrade(p.grade.orderIndex),
                            size: 58,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Empat planet\nterbuka!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.inkOnSpace,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    '${galaksi?.posBerbayar ?? 172} pos baru menunggu, '
                    'sampai kelas 6.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sub.copyWith(
                      color: AppColors.ink2OnSpace,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Column(
                      children: [
                        _Baris(kiri: 'Berlaku', kanan: 'Selamanya'),
                        if (rincian?.orderId != null) ...[
                          const SizedBox(height: 8),
                          _Baris(
                            kiri: 'Nomor pesanan',
                            kanan: rincian!.orderId!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  PrimaryButton(
                    label: 'Mulai jelajah',
                    onPressed: () => context.go(Rute.jelajah),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    'Pembelian tersimpan di akun Google Play.\n'
                    'Bisa dipulihkan gratis di HP lain dengan akun yang sama.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      height: 1.55,
                      color: AppColors.ink3OnSpace,
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

class _Baris extends StatelessWidget {
  const _Baris({required this.kiri, required this.kanan});

  final String kiri;
  final String kanan;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        kiri,
        style: AppTextStyles.caption.copyWith(
          fontSize: 14,
          color: AppColors.ink2OnSpace,
        ),
      ),
      Flexible(
        child: Text(
          kanan,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.title.copyWith(
            fontSize: 14,
            color: AppColors.inkOnSpace,
          ),
        ),
      ),
    ],
  );
}
