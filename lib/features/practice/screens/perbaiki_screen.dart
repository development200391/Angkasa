import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/local/dao/attempt_dao.dart';
import '../../../data/providers.dart';
import '../../../domain/models/enums.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';

/// Perbaiki Kesalahan — layar paling penting di Tahap 2.
///
/// Semua isinya dibaca dari `question_attempts`; tidak ada satu pun data
/// baru yang perlu dikumpulkan. Dan yang membuatnya beda dari aplikasi
/// lain bukan sekadar keberadaannya, tapi pengelompokannya: **menurut
/// jenis kesalahan, bukan menurut zona**. Anak yang lupa menyimpan akan
/// lupa menyimpan di zona mana pun.
class PerbaikiScreen extends ConsumerWidget {
  const PerbaikiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(daftarSalahProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Perbaiki Kesalahan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: daftar.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyView(judul: 'Gagal memuat', keterangan: '$e'),
        data: (soal) {
          if (soal.isEmpty) {
            return const EmptyView(
              judul: 'Tidak ada yang perlu diperbaiki',
              keterangan:
                  'Semua soal yang pernah salah sudah dibetulkan dua kali '
                  'berturut-turut.',
              ikon: Icons.check_circle_outline_rounded,
            );
          }

          final kelompok = <MistakeKind, List<SoalSalah>>{};
          for (final s in soal) {
            kelompok.putIfAbsent(s.mistake, () => []).add(s);
          }
          final urut = kelompok.entries.toList()
            ..sort((a, b) => b.value.length.compareTo(a.value.length));

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.sub.copyWith(fontSize: 13.5),
                          children: [
                            TextSpan(text: '${soal.length} soal menunggu, '),
                            const TextSpan(text: 'dikelompokkan menurut '),
                            TextSpan(
                              text: 'jenis kesalahannya',
                              style: AppTextStyles.sub.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const TextSpan(text: ' — bukan menurut zona.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final e in urut) ...[
                        _KartuJenis(jenis: e.key, soal: e.value),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                  child: Column(
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AppTextStyles.caption.copyWith(fontSize: 12.5),
                          children: [
                            const TextSpan(
                              text: 'Soal keluar dari daftar setelah benar ',
                            ),
                            TextSpan(
                              text: 'dua kali berturut-turut',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink2,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        label: 'Mulai perbaiki',
                        onPressed: () => context.pushReplacement(
                          Rute.sesiLatihanUntuk(PracticeMode.perbaikiKesalahan),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _KartuJenis extends StatelessWidget {
  const _KartuJenis({required this.jenis, required this.soal});

  final MistakeKind jenis;
  final List<SoalSalah> soal;

  @override
  Widget build(BuildContext context) {
    const tampil = 3;
    final sisa = soal.length - tampil;

    return Container(
      padding: const EdgeInsets.fromLTRB(17, 16, 17, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBE2ED), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0xFFD8DFEA), offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  jenis.label,
                  style: AppTextStyles.title.copyWith(fontSize: 15.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.wrongSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${soal.length} soal',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8E2C3A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final s in soal.take(tampil))
                _PilSoal(teks: _tanpaHasil(s.signature)),
              if (sisa > 0) _PilSoal(teks: '+$sisa', samar: true),
            ],
          ),
        ],
      ),
    );
  }

  /// `17+5=?` jadi `17 + 5` — yang perlu dikenali anak soalnya, bukan
  /// tanda tangannya.
  static String _tanpaHasil(String signature) {
    final tanpa = signature.split('=').first;
    return tanpa
        .replaceAllMapped(RegExp(r'([+−×÷?])'), (m) => ' ${m.group(1)} ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _PilSoal extends StatelessWidget {
  const _PilSoal({required this.teks, this.samar = false});

  final String teks;
  final bool samar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        teks,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: samar ? AppColors.ink3 : AppColors.ink2,
          fontFeatures: const [AppTextStyles.tabular],
        ),
      ),
    );
  }
}
