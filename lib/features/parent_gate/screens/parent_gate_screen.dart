import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/engine/difficulty_config.dart';
import '../../../domain/engine/question_generator.dart';
import '../../../domain/models/enums.dart';
import '../../quiz/widgets/q_multiple_choice.dart';

/// Gerbang Orang Tua.
///
/// Muncul sebelum Pengaturan, pembelian, dan setiap tautan yang keluar
/// dari aplikasi. Syarat kategori Kids di App Store dan Families Policy
/// di Play — dan dipasang sejak Tahap 1 justru karena itu: menambahkan
/// gerbang belakangan berarti membongkar navigasi yang sudah jadi.
class ParentGateScreen extends StatefulWidget {
  const ParentGateScreen({required this.tujuan, super.key});

  /// Rute yang dibuka kalau jawabannya benar.
  final String tujuan;

  @override
  State<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends State<ParentGateScreen> {
  static final _generator = QuestionGenerator(random: Random());

  /// Perkalian dua angka di atas lima: masih hitungan biasa untuk orang
  /// dewasa, tapi di luar jangkauan anak kelas satu sampai tiga.
  static const _konfigurasi = DifficultyConfig(
    operations: [Operation.kali],
    minOperand: 6,
    maxOperand: 9,
    formats: [QuestionFormat.pilihanGanda],
    optionCount: 3,
    visualAid: VisualAid.tidakAda,
  );

  late var _soal = _generator.single(_konfigurasi);

  String? _dipilih;
  bool _salah = false;

  void _jawab(String label) {
    if (_soal.isCorrect(label)) {
      context.pushReplacement(widget.tujuan);
      return;
    }
    // Salah berarti soal baru, bukan kesempatan kedua untuk soal yang
    // sama — menebak sampai benar bukan gerbang.
    setState(() {
      _salah = true;
      _dipilih = null;
      _soal = _generator.single(_konfigurasi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.ink3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 22, 32, 0),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      size: 34,
                      color: AppColors.ink2,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text('Halaman untuk orang tua', style: AppTextStyles.h2),
                  const SizedBox(height: 9),
                  Text(
                    'Jawab dulu untuk memastikan yang membuka orang dewasa.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sub,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(vertical: 26),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: AppColors.line, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                _soal.prompt,
                textAlign: TextAlign.center,
                style: AppTextStyles.question.copyWith(fontSize: 34),
              ),
            ),
            if (_salah)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  'Belum tepat. Ini soal baru.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.wrong),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 22, 32, 0),
              child: QMultipleChoice(
                soal: _soal,
                dipilih: _dipilih,
                tinggi: 58,
                onPilih: _jawab,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 26),
              child: Text(
                'Gerbang ini muncul sebelum Pengaturan, pembelian, dan '
                'setiap tautan yang keluar dari aplikasi.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
