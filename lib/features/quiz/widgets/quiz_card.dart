import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/question.dart';
import 'benda_row.dart';
import 'gambar_soal.dart';
import 'number_line.dart';

/// Kartu soal: bantuan visual di atas atau di bawah, kalimat
/// matematikanya di tengah.
///
/// Dipakai layar kuis lintasan **dan** ketiga mode latihan, supaya soal
/// yang sama tidak pernah terlihat berbeda tergantung dari mana anak
/// membukanya.
class KartuSoal extends StatelessWidget {
  const KartuSoal({
    required this.soal,
    this.diAtasGelap = false,
    this.ukuranTeks,
    super.key,
  });

  final Question soal;
  final bool diAtasGelap;
  final double? ukuranTeks;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: diAtasGelap
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: diAtasGelap
            ? null
            : const [BoxShadow(color: AppColors.line, offset: Offset(0, 2))],
      ),
      child: Column(
        children: [
          if (soal.visualAid == VisualAid.benda) ...[
            BendaRow(soal: soal),
            const SizedBox(height: 20),
          ],
          // Gambar soal (geometri, statistik, cerita) di atas
          // kalimatnya — sama seperti bantuan visual benda. Anak
          // melihat dulu apa yang dibicarakan, baru membaca apa yang
          // ditanyakan.
          if (soal.gambar != null) ...[
            GambarSoal(gambar: soal.gambar!, diAtasGelap: diAtasGelap),
            const SizedBox(height: 18),
          ],
          Text(
            soal.prompt,
            // Soal cerita dibaca sebagai kalimat, jadi rata kiri. Rata
            // tengah membuat tiap baris mulai di tempat berbeda, dan
            // anak yang baru lancar membaca kehilangan barisnya.
            textAlign: soal.format == QuestionFormat.cerita
                ? TextAlign.start
                : TextAlign.center,
            style: AppTextStyles.question.copyWith(
              fontSize:
                  ukuranTeks ??
                  (soal.format == QuestionFormat.cerita ? 19 : null),
              height: soal.format == QuestionFormat.cerita ? 1.5 : null,
              fontWeight: soal.format == QuestionFormat.cerita
                  ? FontWeight.w400
                  : null,
              color: diAtasGelap ? AppColors.inkOnSpace : AppColors.ink,
            ),
          ),
          if (soal.visualAid == VisualAid.garisBilangan &&
              soal.gambar == null) ...[
            const SizedBox(height: 18),
            NumberLine(soal: soal),
          ],
        ],
      ),
    );
  }
}
