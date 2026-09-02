import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/quiz_result.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';

/// Pembahasan soal yang salah.
///
/// Dikelompokkan menurut soalnya, dengan jawaban anak dan jawaban yang
/// benar bersebelahan — dan nama kesalahannya disebut, karena itu yang
/// membuat anak tahu apa yang perlu diperbaiki, bukan cuma bahwa dia
/// salah.
class ReviewScreen extends StatelessWidget {
  const ReviewScreen({required this.hasil, super.key});

  final QuizResult hasil;

  @override
  Widget build(BuildContext context) {
    final salah = hasil.wrongAnswers;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Soal yang salah'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: salah.isEmpty
          ? const EmptyView(
              judul: 'Tidak ada yang salah',
              keterangan: 'Semua soal di pos ini dijawab benar.',
              ikon: Icons.check_circle_outline_rounded,
            )
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
                      itemCount: salah.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _Kartu(jawaban: salah[i]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                    child: Column(
                      children: [
                        Text(
                          'Soal ini masuk mode Perbaiki Kesalahan.',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(height: 12),
                        PrimaryButton(
                          label: 'Selesai',
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.jawaban});

  final AnsweredQuestion jawaban;

  @override
  Widget build(BuildContext context) {
    final soal = jawaban.question;
    final jenis = soal.mistakeOf(jawaban.given);
    final diisi = jawaban.given.isEmpty ? 'kosong' : jawaban.given;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.line, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  soal.prompt,
                  style: AppTextStyles.h2.copyWith(
                    fontFeatures: const [AppTextStyles.tabular],
                  ),
                ),
              ),
              if (jenis != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.wrong.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    jenis.label,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.wrong,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Nilai(label: 'Jawabanmu', nilai: diisi, warna: AppColors.wrong),
              const SizedBox(width: 10),
              _Nilai(
                label: 'Yang benar',
                nilai: soal.answer,
                warna: AppColors.ok,
              ),
            ],
          ),
          if (soal.explanation != null) ...[
            const SizedBox(height: 12),
            Text(
              soal.explanation!,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Nilai extends StatelessWidget {
  const _Nilai({required this.label, required this.nilai, required this.warna});

  final String label;
  final String nilai;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11.5)),
            const SizedBox(height: 2),
            Text(
              nilai,
              style: AppTextStyles.numeral.copyWith(fontSize: 20, color: warna),
            ),
          ],
        ),
      ),
    );
  }
}
