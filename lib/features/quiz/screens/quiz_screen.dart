import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/loading_view.dart';
import '../providers/quiz_controller.dart';
import '../providers/quiz_state.dart';
import '../widgets/answer_feedback.dart';
import '../widgets/heart_bar.dart';
import '../widgets/q_input.dart';
import '../widgets/q_multiple_choice.dart';
import '../widgets/quiz_card.dart';

/// Layar kuis: sepuluh soal, lima hati, dan tidak ada apa pun lain di
/// layar yang bisa ditekan. Setiap elemen tambahan di sini adalah satu
/// alasan tambahan untuk berhenti di tengah.
class QuizScreen extends ConsumerWidget {
  const QuizScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = quizControllerProvider(levelId);
    final sesi = ref.watch(provider);

    // Begitu hasilnya tersimpan, layar ini diganti — bukan ditumpuk,
    // supaya tombol kembali dari layar hasil tidak pernah jatuh lagi ke
    // tengah kuis yang sudah selesai.
    ref.listen(provider, (_, next) {
      final hasil = next.value?.hasil;
      if (hasil != null && context.mounted) {
        context.pushReplacement(Rute.hasil, extra: hasil);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: sesi.when(
          loading: () => const LoadingView(),
          error: (e, _) => EmptyView(
            judul: 'Pos ini tidak bisa dibuka',
            keterangan: '$e',
            aksi: TextButton(
              onPressed: () => context.pop(),
              child: const Text('Kembali ke peta'),
            ),
          ),
          data: (s) => _Isi(state: s, levelId: levelId),
        ),
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.state, required this.levelId});

  final QuizState state;
  final String levelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(quizControllerProvider(levelId).notifier);
    final soal = state.soal;
    final salah = state.terkunci && !state.benarTerakhir && state.hasil == null;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BilahAtas(state: state, onTutup: () => _konfirmasiKeluar(context)),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
              child: Row(
                children: [
                  Text(
                    'SOAL ${state.nomor} DARI ${state.total}',
                    style: AppTextStyles.overline,
                  ),
                  const Spacer(),
                  if (state.sisaDetik != null) _Waktu(detik: state.sisaDetik!),
                ],
              ),
            ),
            KartuSoal(soal: soal),
            const Spacer(),
            if (soal.format == QuestionFormat.pilihanGanda)
              // Waktu sheet pembahasan naik, opsinya ikut naik. Jawaban
              // yang barusan ditekan harus tetap terlihat bersebelahan
              // dengan yang benar — di situlah anak membandingkannya.
              AnimatedPadding(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.fromLTRB(22, 0, 22, salah ? 250 : 20),
                child: QMultipleChoice(
                  soal: soal,
                  dipilih: state.dipilih,
                  terkunci: state.terkunci,
                  onPilih: ctl.pilihOpsi,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                child: Column(
                  children: [
                    JawabanBox(
                      isi: state.input,
                      benar: state.terkunci ? state.benarTerakhir : null,
                    ),
                    const SizedBox(height: 16),
                    Keypad(
                      aktif: !state.terkunci,
                      onAngka: ctl.ketik,
                      onHapus: ctl.hapusAngka,
                      onKirim: ctl.kirimIsian,
                    ),
                  ],
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
              jawaban: state.dipilih ?? '',
              terakhir: state.habisNyawa || state.nomor >= state.total,
              onLanjut: ctl.lanjut,
            ),
          ),
      ],
    );
  }

  Future<void> _konfirmasiKeluar(BuildContext context) async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari pos ini?'),
        content: const Text(
          'Jawaban yang sudah diisi tidak disimpan, dan bintangnya tidak '
          'berkurang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Lanjut mengerjakan'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if ((keluar ?? false) && context.mounted) context.pop();
  }
}

class _BilahAtas extends StatelessWidget {
  const _BilahAtas({required this.state, required this.onTutup});

  final QuizState state;
  final VoidCallback onTutup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onTutup,
            icon: const Icon(Icons.close_rounded, color: AppColors.ink3),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
            tooltip: 'Keluar',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                tween: Tween(begin: 0, end: state.kemajuan),
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFDDE3EC),
                  valueColor: const AlwaysStoppedAnimation(AppColors.brand),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          HeartBar(sisa: state.hearts),
        ],
      ),
    );
  }
}

/// Sumbu S6. Angkanya tabular dan berubah warna di sepuluh detik
/// terakhir — tanpa itu, timer cuma terbaca sebagai hiasan.
class _Waktu extends StatelessWidget {
  const _Waktu({required this.detik});

  final int detik;

  @override
  Widget build(BuildContext context) {
    final mendesak = detik <= 10;
    return Row(
      children: [
        Icon(
          Icons.timer_outlined,
          size: 16,
          color: mendesak ? AppColors.wrong : AppColors.ink3,
        ),
        const SizedBox(width: 5),
        Text(
          '$detik',
          style: AppTextStyles.overline.copyWith(
            color: mendesak ? AppColors.wrong : AppColors.ink3,
          ),
        ),
      ],
    );
  }
}
