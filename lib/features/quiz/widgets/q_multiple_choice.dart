import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/question.dart';
import '../../../shared/widgets/pressable_3d.dart';

/// Pilihan ganda.
///
/// Opsinya urut menaik, tidak diacak posisinya, dan tiap pengecoh
/// datang dari kesalahan yang punya nama. Sesudah dijawab, yang benar
/// tetap ditandai hijau walaupun anak memilih yang lain — supaya yang
/// terakhir dilihat adalah jawaban yang betul.
class QMultipleChoice extends StatelessWidget {
  const QMultipleChoice({
    required this.soal,
    required this.onPilih,
    this.dipilih,
    this.terkunci = false,
    this.tinggi = 64,
    super.key,
  });

  final Question soal;
  final ValueChanged<String> onPilih;
  final String? dipilih;
  final bool terkunci;
  final double tinggi;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final o in soal.options)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Opsi(
              label: o.label,
              tinggi: tinggi,
              keadaan: _keadaan(o),
              onTap: terkunci ? null : () => onPilih(o.label),
            ),
          ),
      ],
    );
  }

  _Keadaan _keadaan(AnswerOption o) {
    if (!terkunci) return _Keadaan.biasa;
    if (o.isCorrect) return _Keadaan.benar;
    if (o.label == dipilih) return _Keadaan.salah;
    return _Keadaan.redup;
  }
}

enum _Keadaan { biasa, benar, salah, redup }

class _Opsi extends StatelessWidget {
  const _Opsi({
    required this.label,
    required this.keadaan,
    required this.tinggi,
    this.onTap,
  });

  final String label;
  final _Keadaan keadaan;
  final double tinggi;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (isi, garis, badan, teks) = switch (keadaan) {
      _Keadaan.benar => (
        const [Color(0xFFEFF9F5), Color(0xFFD8EEE6)],
        const Color(0xFF3E9B7C),
        const Color(0xFFA8CFBF),
        const Color(0xFF1C5B49),
      ),
      _Keadaan.salah => (
        const [Color(0xFFFEF2F3), Color(0xFFF7DCE0)],
        const Color(0xFFC95565),
        const Color(0xFFE5B2BA),
        const Color(0xFF8E2C3A),
      ),
      _ => (
        const [Color(0xFFFFFFFF), Color(0xFFF2F5FA)],
        const Color(0xFFD6DDE8),
        const Color(0xFFD2D9E5),
        AppColors.ink,
      ),
    };

    final ikon = switch (keadaan) {
      _Keadaan.benar => Icons.check_rounded,
      _Keadaan.salah => Icons.close_rounded,
      _ => null,
    };

    return Opacity(
      opacity: keadaan == _Keadaan.redup ? 0.45 : 1,
      child: Pressable3D(
        onPressed: onTap,
        height: tinggi,
        depth: 6,
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isi,
        ),
        border: Border.all(color: garis, width: 1.5),
        bodyColor: badan,
        dropShadow: BoxShadow(
          color: const Color(0xFF1C2840).withValues(alpha: 0.4),
          offset: const Offset(0, 11),
          blurRadius: 15,
          spreadRadius: -8,
        ),
        highlight: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.option.copyWith(
                color: teks,
                fontSize: tinggi < 62 ? 23 : 26,
              ),
            ),
            if (ikon != null) ...[
              const SizedBox(width: 12),
              Icon(ikon, size: 22, color: teks),
            ],
          ],
        ),
      ),
    );
  }
}
