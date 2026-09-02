import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/question.dart';
import '../../../shared/widgets/primary_button.dart';

/// Sheet yang muncul begitu jawabannya salah.
///
/// Salah tidak cuma ditandai merah: pembahasannya muncul saat itu juga,
/// dan soalnya masuk mode Perbaiki Kesalahan. Menunda pembahasan sampai
/// akhir sesi berarti anak sudah lupa apa yang tadi dipikirkannya.
class AnswerFeedback extends StatelessWidget {
  const AnswerFeedback({
    required this.soal,
    required this.jawaban,
    required this.onLanjut,
    this.terakhir = false,
    super.key,
  });

  final Question soal;
  final String jawaban;
  final VoidCallback onLanjut;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    final jenis = soal.mistakeOf(jawaban);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.wrongSoft,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.wrong,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Belum tepat',
                            style: AppTextStyles.h2.copyWith(
                              fontSize: 18,
                              color: AppColors.wrong,
                            ),
                          ),
                          if (jenis != null) ...[
                            const SizedBox(width: 8),
                            _Pil(label: jenis.label),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        soal.explanation ??
                            'Jawaban yang benar ${soal.answer}.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14.5,
                          color: const Color(0xFF7A3540),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton.salah(
              label: terakhir ? 'Lihat hasil' : 'Lanjut',
              onPressed: onLanjut,
            ),
          ],
        ),
      ),
    );
  }
}

/// Nama kesalahannya, bukan cuma tandanya. Kalimat inilah yang nanti
/// diringkas jadi "sering lupa menyimpan" di dashboard orang tua.
class _Pil extends StatelessWidget {
  const _Pil({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.wrong.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.wrong,
        ),
      ),
    );
  }
}
