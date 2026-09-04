import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../domain/models/liga.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';
import '../widgets/podium.dart';

/// Tab Peringkat — Liga Mingguan.
///
/// **Bukan peringkat global.** Tiga puluh pemain per liga, dan semuanya
/// direset tiap Senin. Peringkat global berarti ada anak yang jadi nomor
/// 40.000 dan tidak pernah bergerak seumur pemakaian; dengan liga kecil,
/// posisi terburuk pun cuma bertahan tujuh hari.
///
/// Layar ini punya lima keadaan tertutup, dan semuanya ditulis apa
/// adanya. Yang paling sering terjadi — belum ada sinyal — bukan pesan
/// kesalahan: seluruh materi belajar tetap jalan, dan itu kalimat
/// pertama yang dibaca anak di sini.
class PeringkatScreen extends ConsumerWidget {
  const PeringkatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasil = ref.watch(papanLigaProvider);

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 70)),
          SafeArea(
            bottom: false,
            child: hasil.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => const _Tertutup(PapanTertutup.tidakAdaSinyal),
              data: (h) => h.bisaTampil
                  ? _Papan(papan: h.papan!, sisaHari: h.sisaHari)
                  : _Tertutup(h.tertutup!),
            ),
          ),
        ],
      ),
    );
  }
}

class _Papan extends StatelessWidget {
  const _Papan({required this.papan, required this.sisaHari});

  final PapanLiga papan;
  final int sisaHari;

  @override
  Widget build(BuildContext context) {
    final saya = papan.sayaEntri;
    final peringkatSaya = papan.peringkatSaya;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liga Mingguan',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 22,
                        color: AppColors.inkOnSpace,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${papan.jumlahPemain} pemain sekelasmu',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink3OnSpace,
                      ),
                    ),
                  ],
                ),
              ),
              _Pil(sisaHari == 1 ? 'Besok berganti' : '$sisaHari hari lagi'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Podium(tiga: papan.podium, uidSaya: papan.uidSaya),
        ),
        // Baris sendiri sengaja **tidak** ikut di daftar ini: ia sudah
        // ditempel permanen di bawah. Menampilkannya dua kali membuat
        // anak menghitung dirinya dua kali, dan nomornya tetap utuh
        // karena yang dipakai indeks aslinya — 4, lalu 6, dengan 5
        // menempel di bawah.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            children: [
              for (final (i, e) in papan.entri.indexed)
                if (i >= 3 && e.uid != papan.uidSaya)
                  BarisPeringkat(posisi: i + 1, entri: e),
            ],
          ),
        ),

        // Barisnya sendiri selalu menempel di bawah, sekalipun anak ada
        // di peringkat 28 dan daftarnya sudah tergulung jauh. Yang
        // dicari anak pertama kali di layar ini adalah dirinya sendiri.
        Container(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          decoration: BoxDecoration(
            color: AppColors.space.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: AppColors.lineOnSpace)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                if (saya != null && peringkatSaya != null)
                  BarisPeringkat(posisi: peringkatSaya, entri: saya, saya: true)
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Selesaikan satu pos minggu ini supaya namamu muncul '
                      'di sini.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Ligamu berganti tiap Senin. Tidak ada yang bertahan di '
                  'posisi terakhir lebih dari seminggu.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.ink3OnSpace,
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pil extends StatelessWidget {
  const _Pil(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      teks,
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.inkOnSpace,
      ),
    ),
  );
}

/// Keadaan tertutup.
///
/// Tiap alasan dapat kalimatnya sendiri, dan tidak satu pun berbunyi
/// seperti kerusakan. Yang perlu dipahami anak — dan orang tua yang
/// membaca dari balik bahunya — cuma satu: pelajarannya tidak ikut
/// berhenti.
class _Tertutup extends ConsumerWidget {
  const _Tertutup(this.alasan);

  final PapanTertutup alasan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (ikon, judul, isi) = switch (alasan) {
      PapanTertutup.luring => (
        Icons.cloud_off_rounded,
        'Belum tersambung',
        'Liga mingguan butuh sambungan internet. Semua pos, latihan, dan '
            'bintangmu tetap jalan tanpa itu.',
      ),
      PapanTertutup.dimatikanOrangTua => (
        Icons.shield_moon_rounded,
        'Papan peringkat dimatikan',
        'Orang tua mematikannya di Pengaturan. Tidak ada satu pun materi '
            'yang ikut terkunci — semuanya tetap terbuka.',
      ),
      PapanTertutup.dimatikanPengembang => (
        Icons.construction_rounded,
        'Sedang ditutup sementara',
        'Liga mingguan sedang tidak dijalankan. Coba lagi nanti; '
            'progresmu tetap tersimpan.',
      ),
      PapanTertutup.tidakAdaSinyal => (
        Icons.wifi_off_rounded,
        'Tidak ada sinyal',
        'XP-mu tetap dihitung dan akan terkirim sendiri begitu tersambung '
            'lagi. Tidak ada yang hilang.',
      ),
      PapanTertutup.belumMainMingguIni => (
        Icons.rocket_launch_rounded,
        'Ligamu belum dimulai',
        'Selesaikan satu pos minggu ini, dan namamu langsung muncul di '
            'papan. Liganya berganti tiap Senin.',
      ),
      PapanTertutup.belumPunyaNama => (
        Icons.badge_outlined,
        'Belum punya nama panggilan',
        'Papan peringkat menampilkan nama panggilan. Pilih satu dulu di '
            'Profil.',
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Peringkat',
            style: AppTextStyles.h1.copyWith(color: AppColors.inkOnSpace),
          ),
          const Spacer(),
          Icon(ikon, size: 52, color: AppColors.ink3OnSpace),
          const SizedBox(height: 18),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: AppTextStyles.h2.copyWith(color: AppColors.inkOnSpace),
          ),
          const SizedBox(height: 10),
          Text(
            isi,
            textAlign: TextAlign.center,
            style: AppTextStyles.sub.copyWith(color: AppColors.ink2OnSpace),
          ),
          const Spacer(),
          if (alasan == PapanTertutup.belumPunyaNama)
            PrimaryButton(
              label: 'Pilih nama panggilan',
              onPressed: () => context.push(Rute.namaPanggilan),
            )
          else if (alasan == PapanTertutup.belumMainMingguIni)
            PrimaryButton(
              label: 'Mulai satu pos',
              onPressed: () => context.go(Rute.jelajah),
            )
          else
            SecondaryButton(
              label: 'Kembali ke lintasan',
              diAtasGelap: true,
              onPressed: () => context.go(Rute.jelajah),
            ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}
