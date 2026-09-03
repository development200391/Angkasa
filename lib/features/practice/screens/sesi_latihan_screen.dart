import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../quiz/widgets/answer_feedback.dart';
import '../../quiz/widgets/q_multiple_choice.dart';
import '../../quiz/widgets/quiz_card.dart';
import '../providers/practice_controller.dart';

/// Layar sesi untuk Latihan Cepat, Perbaiki Kesalahan, dan Tantangan
/// Harian.
///
/// Sama seperti kuis lintasan, kecuali satu hal yang disengaja: **tidak
/// ada hati**. Di sini salah tidak menghentikan apa pun, dan itulah yang
/// membuat mode Perbaiki Kesalahan sanggup dipakai anak yang memang
/// sedang kesulitan.
class SesiLatihanScreen extends ConsumerWidget {
  const SesiLatihanScreen({required this.mode, super.key});

  final PracticeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = practiceControllerProvider(mode);
    final sesi = ref.watch(provider);

    ref.listen(provider, (_, next) {
      final hasil = next.value?.hasil;
      if (hasil != null && context.mounted) {
        context.pushReplacement(Rute.hasilLatihan, extra: hasil);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: sesi.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              EmptyView(judul: 'Sesi gagal dimuat', keterangan: '$e'),
          data: (s) {
            if (s.kosong) {
              return EmptyView(
                judul: 'Belum ada soal di sini',
                keterangan: mode == PracticeMode.perbaikiKesalahan
                    ? 'Semua soal yang pernah salah sudah dibetulkan. '
                          'Bagus sekali.'
                    : 'Selesaikan satu pos dulu di tab Jelajah supaya ada '
                          'materi yang bisa dilatih.',
                ikon: Icons.check_circle_outline_rounded,
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
            final salah = s.terkunci && !s.benarTerakhir && s.hasil == null;

            return Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Bilah(
                      judul: mode.judul,
                      kemajuan: s.kemajuan,
                      nomor: s.nomor,
                      total: s.total,
                      onTutup: () => _konfirmasi(context, ref),
                    ),
                    KartuSoal(soal: soal),
                    const Spacer(),
                    AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                      padding: EdgeInsets.fromLTRB(22, 0, 22, salah ? 250 : 20),
                      child: QMultipleChoice(
                        soal: soal,
                        dipilih: s.dipilih,
                        terkunci: s.terkunci,
                        onPilih: ctl.jawab,
                      ),
                    ),
                  ],
                ),
                if (salah)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnswerFeedback(
                      soal: soal,
                      jawaban: s.dipilih ?? '',
                      terakhir: s.nomor >= s.total,
                      onLanjut: ctl.lanjut,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _konfirmasi(BuildContext context, WidgetRef ref) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Berhenti latihan?'),
        content: const Text(
          'Yang sudah dijawab tetap tercatat. Latihan tidak pernah '
          'mengurangi bintang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lanjut'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Berhenti'),
          ),
        ],
      ),
    );
    if ((keluar ?? false) && context.mounted) context.pop();
  }
}

class _Bilah extends StatelessWidget {
  const _Bilah({
    required this.judul,
    required this.kemajuan,
    required this.nomor,
    required this.total,
    required this.onTutup,
  });

  final String judul;
  final double kemajuan;
  final int nomor;
  final int total;
  final VoidCallback onTutup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onTutup,
                icon: const Icon(Icons.close_rounded, color: AppColors.ink3),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                tooltip: 'Berhenti',
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOut,
                    tween: Tween(begin: 0, end: kemajuan),
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFDDE3EC),
                      valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(judul.toUpperCase(), style: AppTextStyles.overline),
              const Spacer(),
              Text('$nomor / $total', style: AppTextStyles.overline),
            ],
          ),
        ],
      ),
    );
  }
}
