import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/models/level_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/planet_orb.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/xp_badge.dart';
import '../providers/home_providers.dart';
import '../widgets/level_node.dart';
import '../widgets/level_sheet.dart';
import '../widgets/path_painter.dart';
import '../widgets/spanduk_luring.dart';
import '../widgets/starfield.dart';
import '../widgets/zona_sheet.dart';

/// Layar Jelajah — peta lintasan, dan layar pertama saat aplikasi dibuka.
///
/// Satu zona ditampilkan sekali jalan. Menampilkan seluruh planet
/// sekaligus terlihat mengesankan di tangkapan layar, tapi membuat anak
/// harus mencari posisinya sendiri tiap kali membuka aplikasi.
class JelajahScreen extends ConsumerWidget {
  const JelajahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peta = ref.watch(petaProvider);
    final profil = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: peta.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => EmptyView(
                judul: 'Peta tidak bisa dibuka',
                keterangan: '$e',
                diAtasGelap: true,
              ),
              data: (data) {
                if (data == null) return const LoadingView(diAtasGelap: true);
                final warna = AppColors.forGrade(data.grade.orderIndex);
                final pilihan = ref.watch(zonaTerpilihProvider);
                final zona =
                    (pilihan == null ? null : data.zonaDari(pilihan)) ??
                    data.zonaAktif;

                return Column(
                  children: [
                    _Bilah(
                      kelas: data.grade.label,
                      nama: data.grade.name,
                      warna: warna,
                      xp: profil?.totalXp ?? 0,
                      streak: profil?.streakCount ?? 0,
                      onPlanet: () => context.push(Rute.pilihPlanet),
                    ),
                    const SpandukLuring(),
                    if (zona != null)
                      _ChipZona(
                        judul: zona.chapter.label,
                        selesai: zona.selesai,
                        total: zona.total,
                        onTap: () => ZonaSheet.tampilkan(
                          context,
                          peta: data,
                          onPilih: (id) =>
                              ref.read(zonaTerpilihProvider.notifier).pilih(id),
                        ),
                      ),
                    Expanded(
                      child: zona == null
                          ? _PlanetKosong(nama: data.grade.name)
                          : _Lintasan(zona: zona),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Bilah extends StatelessWidget {
  const _Bilah({
    required this.kelas,
    required this.nama,
    required this.warna,
    required this.xp,
    required this.streak,
    required this.onPlanet,
  });

  final String kelas;
  final String nama;
  final Color warna;
  final int xp;
  final int streak;
  final VoidCallback onPlanet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 14),
      child: Row(
        children: [
          Expanded(
            child: PlanetChip(
              kelas: kelas,
              nama: nama,
              color: warna,
              onTap: onPlanet,
            ),
          ),
          StreakBadge(hari: streak),
          const SizedBox(width: 14),
          XpBadge(xp: xp),
        ],
      ),
    );
  }
}

class _ChipZona extends StatelessWidget {
  const _ChipZona({
    required this.judul,
    required this.selesai,
    required this.total,
    required this.onTap,
  });

  final String judul;
  final int selesai;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 4),
      child: Material(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    judul,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.family,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkOnSpace,
                    ),
                  ),
                ),
                Text(
                  '$selesai/$total pos',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.family,
                    fontSize: 12,
                    color: AppColors.ink3OnSpace,
                    fontFeatures: [AppTextStyles.tabular],
                  ),
                ),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppColors.ink3OnSpace,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Lintasan extends ConsumerWidget {
  const _Lintasan({required this.zona});

  final ChapterView zona;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pos = zona.levels;
    final dilewati = pos.where((l) => l.progress.isCompleted).length;

    return LayoutBuilder(
      builder: (context, box) {
        final titik = LintasanLayout.posisi(pos.length, box.maxWidth);
        final tinggi = LintasanLayout.tinggi(pos.length);

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: tinggi < box.maxHeight ? box.maxHeight : tinggi,
            width: box.maxWidth,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: PathPainter(titik: titik, sampaiIndeks: dilewati),
                  ),
                ),
                for (var i = 0; i < pos.length; i++)
                  Positioned(
                    left: titik[i].dx - 51,
                    top: titik[i].dy - 34,
                    width: 102,
                    child: Center(
                      child: LevelNode(
                        view: pos[i],
                        onTap: pos[i].isLocked
                            ? () => _kabarTerkunci(context)
                            : () => _bukaSheet(context, ref, pos[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _kabarTerkunci(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Selesaikan pos sebelumnya dulu untuk membukanya.'),
        ),
      );
  }

  void _bukaSheet(BuildContext context, WidgetRef ref, LevelView view) {
    LevelSheet.tampilkan(
      context,
      view: view,
      chapter: zona.chapter,
      onMulai: () {
        Navigator.of(context).pop();
        context.push(Rute.kuisUntuk(view.level.id));
      },
    );
  }
}

class _PlanetKosong extends StatelessWidget {
  const _PlanetKosong({required this.nama});

  final String nama;

  @override
  Widget build(BuildContext context) {
    return EmptyView(
      judul: '$nama belum bisa didarati',
      keterangan:
          'Materi kelas ini datang di tahap berikutnya. Sementara ini, '
          'pilih Planet Mula atau Planet Puluh.',
      diAtasGelap: true,
      aksi: SizedBox(
        width: 220,
        child: PrimaryButton(
          label: 'Pilih planet lain',
          onPressed: () => context.push(Rute.pilihPlanet),
        ),
      ),
    );
  }
}
