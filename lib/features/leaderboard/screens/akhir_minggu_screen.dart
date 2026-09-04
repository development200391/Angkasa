import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/engine/liga_rules.dart';
import '../../../domain/models/liga.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';

/// Layar 18 · Akhir minggu.
///
/// **Yang ditonjolkan pergerakannya, bukan posisinya.** "Naik 4" tetap
/// enak dibaca oleh anak di peringkat 25; "Peringkat 25" saja tidak.
/// Itu satu keputusan tata letak yang menentukan apakah layar ini terasa
/// seperti perayaan atau seperti rapor.
///
/// Muncul sekali per minggu, dan sekali saja: [LeaderboardRepository]
/// menandainya sudah dilihat begitu layar ini ditutup.
class AkhirMingguScreen extends ConsumerStatefulWidget {
  const AkhirMingguScreen({required this.ringkasan, super.key});

  final RingkasanMinggu ringkasan;

  @override
  ConsumerState<AkhirMingguScreen> createState() => _AkhirMingguScreenState();
}

class _AkhirMingguScreenState extends ConsumerState<AkhirMingguScreen> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    // Perayaannya cuma untuk yang naik atau bertahan di sepuluh besar.
    // Confetti untuk anak yang baru turun sepuluh posisi terasa seperti
    // ejekan.
    final gerak = widget.ringkasan.pergerakan ?? 0;
    if (gerak > 0 || widget.ringkasan.peringkat <= 10) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Menutup layar, apa pun yang terjadi pada penandaannya.
  ///
  /// Menandai "sudah dilihat" itu penting supaya layar ini tidak muncul
  /// dua kali — tapi tidak sepenting keluar dari sini. Kalau penandaannya
  /// gagal dan tombolnya ikut mati, anak terkurung di layar perayaan
  /// tanpa jalan keluar; layar yang muncul dua kali jauh lebih ringan
  /// akibatnya.
  Future<void> _tutup() async {
    try {
      await ref
          .read(leaderboardRepositoryProvider)
          .tandaiSudahDilihat(widget.ringkasan.weekId);
      ref.invalidate(ringkasanMingguProvider);
    } catch (_) {
      // Sengaja diabaikan — lihat alasannya di atas.
    }
    if (mounted) context.go(Rute.peringkat);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.ringkasan;
    final gerak = r.pergerakan;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (sudah, _) {
        if (!sudah) _tutup();
      },
      child: Scaffold(
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
                  AppColors.mula,
                  AppColors.puluh,
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    _Medali(peringkat: r.peringkat),
                    const SizedBox(height: 24),
                    Text(
                      'Peringkat ${r.peringkat}',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.inkOnSpace,
                        fontFeatures: const [AppTextStyles.tabular],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      'dari ${r.pemain} pemain di ligamu minggu ini.\n'
                      '${LigaRules.kalimatPergerakan(sekarang: r.peringkat, sebelumnya: r.peringkatSebelumnya)}',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.sub.copyWith(
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        _Ubin(
                          angka: '${r.xp}',
                          label: 'XP minggu ini',
                          warna: AppColors.brandLight,
                        ),
                        const SizedBox(width: 10),
                        _Ubin(
                          angka: gerak == null
                              ? '—'
                              : (gerak > 0 ? '+$gerak' : '$gerak'),
                          label: 'posisi',
                          warna: switch (gerak) {
                            null => AppColors.ink2OnSpace,
                            > 0 => const Color(0xFF4FBE9B),
                            < 0 => const Color(0xFFD98A94),
                            _ => AppColors.inkOnSpace,
                          },
                        ),
                        const SizedBox(width: 10),
                        _Ubin(
                          angka: '${r.posSelesai}',
                          label: 'pos selesai',
                          warna: AppColors.inkOnSpace,
                        ),
                      ],
                    ),
                    const Spacer(flex: 3),
                    Text(
                      'Liga baru dimulai Senin pagi.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink3OnSpace,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(label: 'Oke', onPressed: _tutup),
                    ),
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

class _Medali extends StatelessWidget {
  const _Medali({required this.peringkat});

  final int peringkat;

  @override
  Widget build(BuildContext context) => Container(
    width: 136,
    height: 136,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        center: Alignment(-0.32, -0.44),
        radius: 0.9,
        colors: [Color(0xFFF3CB7C), Color(0xFFE0A63F), Color(0xFF8E5709)],
        stops: [0, 0.46, 1],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF060B18).withValues(alpha: 0.6),
          offset: const Offset(0, 10),
          blurRadius: 22,
          spreadRadius: -6,
        ),
      ],
    ),
    child: Text(
      '$peringkat',
      style: AppTextStyles.h1.copyWith(
        fontSize: 54,
        height: 1,
        color: const Color(0xFF5A3606),
        fontFeatures: const [AppTextStyles.tabular],
      ),
    ),
  );
}

class _Ubin extends StatelessWidget {
  const _Ubin({required this.angka, required this.label, required this.warna});

  final String angka;
  final String label;
  final Color warna;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text(
            angka,
            style: AppTextStyles.numeral.copyWith(fontSize: 21, color: warna),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
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
