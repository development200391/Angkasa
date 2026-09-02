import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/content_repository.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../quiz/widgets/q_multiple_choice.dart';

/// Tes penempatan: delapan soal lintas kelas, boleh dilewati.
///
/// Hasilnya menentukan planet mana yang dibuka dan berapa zona pertama
/// yang langsung ditandai selesai — menghemat anak yang sudah bisa dari
/// dua puluh pos yang membosankan. Tidak ada nilai, tidak ada bintang,
/// dan tidak ada hati: ini bukan ujian, cuma penunjuk arah.
class PenempatanScreen extends ConsumerStatefulWidget {
  const PenempatanScreen({
    required this.onSelesai,
    required this.onLewati,
    super.key,
  });

  /// Dipanggil dengan id planet tempat anak sebaiknya mulai.
  final ValueChanged<String> onSelesai;
  final VoidCallback onLewati;

  @override
  ConsumerState<PenempatanScreen> createState() => _PenempatanScreenState();
}

class _PenempatanScreenState extends ConsumerState<PenempatanScreen> {
  late final Future<List<SoalPenempatan>> _soal = ref
      .read(contentRepositoryProvider)
      .soalPenempatan();

  int _index = 0;
  final _benar = <SoalPenempatan>[];
  String? _dipilih;
  bool _terkunci = false;

  Future<void> _jawab(List<SoalPenempatan> daftar, String label) async {
    if (_terkunci) return;
    final item = daftar[_index];
    final benar = item.soal.isCorrect(label);
    setState(() {
      _dipilih = label;
      _terkunci = true;
      if (benar) _benar.add(item);
    });

    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;

    if (_index + 1 >= daftar.length) {
      await _terapkan();
      return;
    }
    setState(() {
      _index++;
      _dipilih = null;
      _terkunci = false;
    });
  }

  /// Planet tempat anak ditaruh: yang tertinggi di antara soal yang
  /// dijawab benar. Kalau tidak ada yang benar sama sekali, mulai dari
  /// planet pertama — tanpa satu pun kalimat yang menyebutnya gagal.
  Future<void> _terapkan() async {
    final progres = ref.read(progressRepositoryProvider);
    final planets = await ref.read(contentRepositoryProvider).planets();
    final berisi = planets.where((g) => g.isUnlocked).toList();
    final gradeId = _benar.isEmpty ? berisi.first.id : _benar.last.gradeId;

    await progres.terapkanPenempatan(
      gradeId: gradeId,
      chapterIdBenar: _benar
          .where((s) => s.gradeId == gradeId)
          .map((s) => s.chapterId)
          .toList(),
    );
    if (mounted) widget.onSelesai(gradeId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SoalPenempatan>>(
      future: _soal,
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView(diAtasGelap: true);
        final daftar = snap.data!;
        if (daftar.isEmpty) {
          widget.onLewati();
          return const LoadingView(diAtasGelap: true);
        }
        final item = daftar[_index];

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'TES PENEMPATAN · ${_index + 1} DARI ${daftar.length}',
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.ink3OnSpace,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Jawab sebisanya',
                style: AppTextStyles.h1.copyWith(color: AppColors.inkOnSpace),
              ),
              const SizedBox(height: 8),
              Text(
                'Yang tidak bisa dilewati saja. Tes ini cuma menentukan '
                'mulai dari mana.',
                style: AppTextStyles.sub.copyWith(color: AppColors.ink2OnSpace),
              ),
              const SizedBox(height: 26),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 26),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  item.soal.prompt,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.question.copyWith(
                    color: AppColors.inkOnSpace,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              QMultipleChoice(
                soal: item.soal,
                dipilih: _dipilih,
                terkunci: _terkunci,
                tinggi: 58,
                onPilih: (label) => _jawab(daftar, label),
              ),
              const SizedBox(height: 4),
              GhostButton(
                label: 'Lewati tes ini',
                diAtasGelap: true,
                onPressed: widget.onLewati,
              ),
            ],
          ),
        );
      },
    );
  }
}
