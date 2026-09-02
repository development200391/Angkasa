import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/question.dart';

/// Bantuan visual sumbu S3 pada tingkat termudah: benda nyata.
///
/// Dua apel, tanda tambah, tiga apel. Anak yang belum bisa membaca
/// lambang pun masih bisa menjawab soal pertama — dan itu memang
/// tugasnya pos pertama.
class BendaRow extends StatelessWidget {
  const BendaRow({required this.soal, super.key});

  final Question soal;

  static const _maks = 10;

  @override
  Widget build(BuildContext context) {
    if (soal.left > _maks || soal.right > _maks) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(child: _Kelompok(jumlah: soal.left)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            soal.operation.lambang,
            style: AppTextStyles.h1.copyWith(
              fontSize: 28,
              color: AppColors.ink3,
            ),
          ),
        ),
        Flexible(child: _Kelompok(jumlah: soal.right)),
      ],
    );
  }
}

class _Kelompok extends StatelessWidget {
  const _Kelompok({required this.jumlah});

  final int jumlah;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        for (var i = 0; i < jumlah; i++)
          SvgPicture.asset(AppAssets.apel, width: 34, height: 34),
      ],
    );
  }
}
