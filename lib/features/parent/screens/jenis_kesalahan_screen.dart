import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../shared/widgets/loading_view.dart';
import '../widgets/batang_mendatar.dart';

/// Layar 31 · Jenis kesalahan.
///
/// Inilah saat `question_attempts` membayar dirinya sendiri. Tabel itu
/// sudah mencatat nama kekeliruan tiap jawaban salah sejak soal pertama
/// di Tahap 1 — tiga tahap sebelum ada satu pun layar yang membacanya.
///
/// Bedanya dengan rapor: **"lupa menyimpan, 12 kali" bisa dilatih;
/// "nilai 84" tidak.** Orang tua yang membaca angka 84 tidak tahu harus
/// berbuat apa selain menyuruh belajar lebih rajin. Yang membaca
/// kalimat di bawah tiap batang tahu persis apa yang harus ditanyakan.
class JenisKesalahanScreen extends ConsumerWidget {
  const JenisKesalahanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(jenisKesalahanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Jenis kesalahan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: data.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              EmptyView(judul: 'Belum bisa dibaca', keterangan: '$e'),
          data: (r) => r.totalSoal == 0
              ? const EmptyView(
                  judul: 'Belum ada yang bisa dihitung',
                  keterangan:
                      'Layar ini terisi sendiri setelah beberapa pos '
                      'dikerjakan. Tidak ada yang perlu disiapkan.',
                )
              : _Isi(ringkas: r),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({required this.ringkas});

  final RingkasanKesalahan ringkas;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
    children: [
      Text(
        'Dari ${ringkas.totalSoal} soal yang ${ringkas.nama} kerjakan '
        'bulan ini.',
        style: AppTextStyles.sub.copyWith(fontSize: 13.5),
      ),
      const SizedBox(height: 18),

      if (ringkas.kesalahan.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.okSoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            'Belum ada kekeliruan yang berulang. Yang salah tersebar, '
            'tidak mengikuti satu pola tertentu.',
            style: AppTextStyles.body.copyWith(
              fontSize: 14,
              color: AppColors.ok,
              height: 1.5,
            ),
          ),
        )
      else
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (final k in ringkas.kesalahan.take(5))
                BatangMendatar(
                  label: k.jenis.label,
                  nilai: '${k.jumlah}×',
                  pecahan: k.jumlah / ringkas.terbanyak,
                ),
            ],
          ),
        ),

      // Penjelasan kekeliruan yang paling sering. Satu saja, bukan
      // lima: orang tua yang diberi lima hal untuk diperbaiki tidak
      // memperbaiki satu pun.
      if (ringkas.kesalahan.isNotEmpty) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.okSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yang paling sering: ${ringkas.kesalahan.first.jenis.label}',
                style: AppTextStyles.title.copyWith(
                  fontSize: 14,
                  color: AppColors.ok,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ringkas.kesalahan.first.jenis.penjelasan,
                style: AppTextStyles.body.copyWith(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.ink2,
                ),
              ),
            ],
          ),
        ),
      ],

      if (ringkas.zona.isNotEmpty) ...[
        const SizedBox(height: 24),
        Text('Penguasaan per zona', style: AppTextStyles.title),
        const SizedBox(height: 6),
        for (final z in ringkas.zona) _BarisZona(zona: z),
      ],

      const SizedBox(height: 24),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E7F0)),
        ),
        child: Text(
          'Angka ini dihitung dari catatan jawaban di HP ini dan '
          'tidak pernah dikirim ke server.',
          style: AppTextStyles.caption.copyWith(
            fontSize: 13,
            height: 1.55,
            color: AppColors.ink2,
          ),
        ),
      ),
    ],
  );
}

class _BarisZona extends StatelessWidget {
  const _BarisZona({required this.zona});

  final ZonaPenguasaan zona;

  @override
  Widget build(BuildContext context) {
    // Ikon, tulisan, dan warna sekaligus — tidak pernah warna saja.
    final (ikon, warna, latar) = switch (zona.tingkat) {
      Penguasaan.dikuasai => (
        Icons.check_rounded,
        const Color(0xFF0C6B45),
        const Color(0xFFE2F4EC),
      ),
      Penguasaan.cukup => (
        Icons.info_outline_rounded,
        const Color(0xFF8A5A0B),
        const Color(0xFFFBEFD6),
      ),
      Penguasaan.perluLatihan => (
        Icons.priority_high_rounded,
        const Color(0xFF8E2C3A),
        const Color(0xFFFAE7EA),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                zona.judul,
                style: AppTextStyles.body.copyWith(fontSize: 14.5),
              ),
            ),
          ),
          PilStatus(
            teks: zona.tingkat.label,
            ikon: ikon,
            warna: warna,
            latar: latar,
          ),
        ],
      ),
    );
  }
}
