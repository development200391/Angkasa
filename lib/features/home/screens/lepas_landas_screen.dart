import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/home_providers.dart';
import '../widgets/roket.dart';
import '../widgets/starfield.dart';

/// Lepas landas ke planet berikutnya.
///
/// Satu-satunya animasi panjang di aplikasi ini, dan cuma muncul enam
/// kali seumur pemakaian — justru itu yang membuatnya diingat. Kalau
/// animasi sepanjang ini muncul tiap pos selesai, di hari ketiga anak
/// sudah menekan lewat tanpa melihat.
///
/// Tidak ada satu pun berkas animasi: roket, api, dan planetnya digambar
/// `CustomPainter`, jadi warna planet baru tidak pernah butuh aset baru.
class LepasLandasScreen extends ConsumerStatefulWidget {
  const LepasLandasScreen({required this.gradeId, super.key});

  /// Planet tujuan.
  final String gradeId;

  @override
  ConsumerState<LepasLandasScreen> createState() => _LepasLandasScreenState();
}

class _LepasLandasScreenState extends ConsumerState<LepasLandasScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _berangkat = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _lepasLandas() async {
    if (_berangkat) return;
    setState(() => _berangkat = true);
    ref.read(audioServiceProvider).lepasLandas();
    await _c.forward();
    if (!mounted) return;

    await ref.read(profileProvider.notifier).gantiPlanet(widget.gradeId);
    ref.read(zonaTerpilihProvider.notifier).ikutiProgres();
    if (mounted) context.go(Rute.jelajah);
  }

  @override
  Widget build(BuildContext context) {
    final planets = ref.watch(planetsProvider);
    final petaLama = ref.watch(petaProvider).value;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 110)),
          planets.when(
            loading: () => const LoadingView(diAtasGelap: true),
            error: (e, _) => EmptyView(
              judul: 'Gagal memuat planet',
              keterangan: '$e',
              diAtasGelap: true,
            ),
            data: (daftar) {
              final tujuan = daftar.where((g) => g.id == widget.gradeId);
              if (tujuan.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) context.go(Rute.jelajah);
                });
                return const SizedBox.shrink();
              }
              final planetBaru = tujuan.first;
              final warnaBaru = AppColors.forGrade(planetBaru.orderIndex);
              final warnaLama = petaLama == null
                  ? AppColors.mula
                  : AppColors.forGrade(petaLama.grade.orderIndex);
              final bintang = petaLama?.totalStars ?? 0;
              final pos =
                  petaLama?.chapters.fold<int>(0, (a, c) => a + c.total) ?? 0;

              return AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _AdeganPainter(
                          maju: Curves.easeInCubic.transform(_c.value),
                          warnaLama: warnaLama,
                          warnaBaru: warnaBaru,
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Opacity(
                        opacity: (1 - _c.value * 2.2).clamp(0, 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 150),
                              Text(
                                petaLama == null
                                    ? 'PLANET TUNTAS'
                                    : '${petaLama.grade.name.toUpperCase()} '
                                          'TUNTAS',
                                style: AppTextStyles.overline.copyWith(
                                  letterSpacing: 1.8,
                                  color: AppColors.brandLight,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Menuju\n${planetBaru.name}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.h1.copyWith(
                                  fontSize: 30,
                                  color: AppColors.inkOnSpace,
                                ),
                              ),
                              const SizedBox(height: 11),
                              Text(
                                '$pos pos, $bintang bintang. Sekarang '
                                'materinya naik satu tingkat.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.sub.copyWith(
                                  fontSize: 14,
                                  color: AppColors.ink2OnSpace,
                                ),
                              ),
                              const Spacer(),
                              PrimaryButton(
                                label: 'Lepas landas',
                                onPressed: _berangkat ? null : _lepasLandas,
                              ),
                              const SizedBox(height: 12),
                              if (!_berangkat)
                                TextButton(
                                  onPressed: () => context.go(Rute.jelajah),
                                  child: Text(
                                    'Nanti saja',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.ink3OnSpace,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Adegan lepas landas: planet asal di bawah menjauh, planet tujuan di
/// atas membesar, roket di tengah dengan semburan api dan garis
/// kecepatan yang memanjang seiring dorongan.
class _AdeganPainter extends CustomPainter {
  const _AdeganPainter({
    required this.maju,
    required this.warnaLama,
    required this.warnaBaru,
  });

  /// 0 = diam menunggu, 1 = sudah sampai.
  final double maju;
  final Color warnaLama;
  final Color warnaBaru;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Planet tujuan: mendekat dan membesar.
    _bola(
      canvas,
      Offset(w * 0.73, h * 0.16 + maju * h * 0.16),
      w * 0.12 + maju * w * 0.5,
      warnaBaru,
    );

    // Planet asal: tertinggal ke bawah.
    _bola(
      canvas,
      Offset(w * 0.19, h * 0.96 + maju * h * 0.35),
      w * 0.29,
      warnaLama,
      opasitas: (0.55 - maju * 0.55).clamp(0, 1),
    );

    // Garis kecepatan memanjang seiring dorongan.
    final garis = Paint()
      ..color = AppColors.brandLight.withValues(alpha: 0.35 + maju * 0.3)
      ..strokeCap = StrokeCap.round;
    final acak = Random(11);
    for (var i = 0; i < 14; i++) {
      final x = acak.nextDouble() * w;
      final y = acak.nextDouble() * h;
      final panjang = 20 + acak.nextDouble() * 40 + maju * 220;
      garis.strokeWidth = 1.6 + acak.nextDouble() * 1.4;
      canvas.drawLine(Offset(x, y), Offset(x, y + panjang), garis);
    }

    // Roket: naik pelan lalu melesat.
    final pusat = Offset(w * 0.45, h * 0.54 - maju * h * 0.42);
    final api = 1.0 + maju * 2.4;

    canvas.drawCircle(
      pusat,
      w * 0.38,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.brandLight.withValues(alpha: 0.3),
            AppColors.brandLight.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: pusat, radius: w * 0.38)),
    );

    RoketPainter.gambarApi(canvas, pusat, w * 0.24, api);
    RoketPainter.gambarRoket(canvas, pusat, w * 0.24);
  }

  void _bola(
    Canvas canvas,
    Offset pusat,
    double r,
    Color warna, {
    double opasitas = 1,
  }) {
    if (r <= 0) return;
    final rect = Rect.fromCircle(center: pusat, radius: r);
    canvas.drawCircle(
      pusat,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.32, -0.44),
          radius: 0.9,
          colors: [
            Color.lerp(warna, Colors.white, 0.35)!.withValues(alpha: opasitas),
            warna.withValues(alpha: opasitas),
            Color.lerp(warna, Colors.black, 0.6)!.withValues(alpha: opasitas),
          ],
          stops: const [0, 0.48, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AdeganPainter oldDelegate) =>
      oldDelegate.maju != maju;
}
