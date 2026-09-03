import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/question.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pressable_3d.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';
import '../providers/practice_controller.dart';

/// Kilat 60 Detik.
///
/// Pilihan disusun **dua kolom** supaya jempol tidak berpindah jauh, dan
/// cincin waktunya ikut memendek — bukan cuma angkanya. Di mode secepat
/// ini, waktu yang cuma tertulis tidak sempat dibaca.
class KilatScreen extends ConsumerWidget {
  const KilatScreen({super.key});

  static const _mode = PracticeMode.kilat60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = practiceControllerProvider(_mode);
    final sesi = ref.watch(provider);

    ref.listen(provider, (_, next) {
      final hasil = next.value?.hasil;
      if (hasil != null && context.mounted) {
        context.pushReplacement(Rute.hasilLatihan, extra: hasil);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 70)),
          SafeArea(
            child: sesi.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => EmptyView(
                judul: 'Kilat gagal dimuat',
                keterangan: '$e',
                diAtasGelap: true,
              ),
              data: (s) {
                if (s.kosong) {
                  return EmptyView(
                    judul: 'Belum ada materi',
                    keterangan:
                        'Selesaikan satu pos dulu supaya ada soal yang bisa '
                        'dikebut.',
                    diAtasGelap: true,
                    aksi: SizedBox(
                      width: 200,
                      child: PrimaryButton(
                        label: 'Kembali',
                        onPressed: () => context.pop(),
                      ),
                    ),
                  );
                }

                final ctl = ref.read(provider.notifier);
                final soal = s.sekarang;
                final sisa = s.sisaDetik ?? 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => ctl.hentikan(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.ink3OnSpace,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 34,
                              minHeight: 34,
                            ),
                            tooltip: 'Berhenti',
                          ),
                          const Spacer(),
                          _Pil(
                            teks: '${s.benar} benar',
                            latar: Colors.white.withValues(alpha: 0.09),
                            warna: AppColors.inkOnSpace,
                          ),
                          if (s.beruntun >= 2) ...[
                            const SizedBox(width: 9),
                            _Pil(
                              teks: 'beruntun ×${s.beruntun}',
                              latar: AppColors.brandLight,
                              warna: const Color(0xFF3A2405),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _CincinWaktu(
                      sisa: sisa,
                      total: PracticeController.detikKilat,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      soal.prompt,
                      style: AppTextStyles.question.copyWith(
                        fontSize: 44,
                        color: AppColors.inkOnSpace,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                      child: _OpsiDuaKolom(
                        soal: soal,
                        dipilih: s.dipilih,
                        terkunci: s.terkunci,
                        onPilih: ctl.jawab,
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

class _Pil extends StatelessWidget {
  const _Pil({required this.teks, required this.latar, required this.warna});

  final String teks;
  final Color latar;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teks,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: warna,
        ),
      ),
    );
  }
}

/// Cincin hitungan mundur. Angkanya tabular supaya tidak bergoyang tiap
/// detik, dan cincinnya memerah di sepuluh detik terakhir.
class _CincinWaktu extends StatelessWidget {
  const _CincinWaktu({required this.sisa, required this.total});

  final int sisa;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            curve: Curves.linear,
            tween: Tween(begin: sisa / total, end: sisa / total),
            builder: (context, v, _) => CustomPaint(
              size: const Size.square(176),
              painter: _CincinPainter(rasio: v, mendesak: sisa <= 10),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$sisa',
                style: AppTextStyles.question.copyWith(
                  fontSize: 52,
                  color: AppColors.inkOnSpace,
                ),
              ),
              Text(
                'detik',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  color: AppColors.ink3OnSpace,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CincinPainter extends CustomPainter {
  const _CincinPainter({required this.rasio, required this.mendesak});

  final double rasio;
  final bool mendesak;

  @override
  void paint(Canvas canvas, Size size) {
    final pusat = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 14;
    final rect = Rect.fromCircle(center: pusat, radius: r);

    canvas.drawCircle(
      pusat,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..color = Colors.white.withValues(alpha: 0.09),
    );

    if (rasio <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * rasio,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: mendesak
              ? const [Color(0xFFF08C7A), AppColors.wrong]
              : const [Color(0xFFFFD98A), AppColors.brand],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _CincinPainter oldDelegate) =>
      oldDelegate.rasio != rasio || oldDelegate.mendesak != mendesak;
}

/// Empat opsi dalam dua kolom.
class _OpsiDuaKolom extends StatelessWidget {
  const _OpsiDuaKolom({
    required this.soal,
    required this.dipilih,
    required this.terkunci,
    required this.onPilih,
  });

  final Question soal;
  final String? dipilih;
  final bool terkunci;
  final ValueChanged<String> onPilih;

  @override
  Widget build(BuildContext context) {
    final opsi = soal.options;
    return GridView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 76,
      ),
      itemCount: opsi.length,
      itemBuilder: (context, i) {
        final o = opsi[i];
        final ditandai = terkunci && o.label == dipilih;

        final isi = ditandai
            ? (o.isCorrect
                  ? const [Color(0xFFEFF9F5), Color(0xFFD8EEE6)]
                  : const [Color(0xFFFEF2F3), Color(0xFFF7DCE0)])
            : const [Color(0xFFFFFFFF), Color(0xFFF2F5FA)];

        return Pressable3D(
          onPressed: terkunci ? null : () => onPilih(o.label),
          height: 70,
          depth: 6,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isi,
          ),
          border: Border.all(
            color: ditandai
                ? (o.isCorrect
                      ? const Color(0xFF3E9B7C)
                      : const Color(0xFFC95565))
                : const Color(0xFFD6DDE8),
            width: 1.5,
          ),
          bodyColor: const Color(0xFFD2D9E5),
          highlight: false,
          child: Center(child: Text(o.label, style: AppTextStyles.option)),
        );
      },
    );
  }
}
