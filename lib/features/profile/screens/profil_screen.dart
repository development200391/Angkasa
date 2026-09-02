import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/models/level_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/star_rating.dart';
import '../../onboarding/widgets/avatar_grid.dart';

/// Tab Profil: avatar, statistik, pilih planet, dan pintu ke Pengaturan
/// lewat Gerbang Orang Tua.
///
/// Gembok kecil di baris Pengaturan menandakan gerbang itu ada di
/// baliknya — anak jadi tahu sebelum menekannya, bukan sesudah.
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profileProvider);
    final peta = ref.watch(petaProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: profil.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              EmptyView(judul: 'Profil tidak terbaca', keterangan: '$e'),
          data: (p) {
            final posSelesai =
                peta?.chapters.fold<int>(0, (a, c) => a + c.selesai) ?? 0;
            final totalPos =
                peta?.chapters.fold<int>(0, (a, c) => a + c.total) ?? 0;

            return ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              children: [
                Row(
                  children: [
                    AvatarBulat(id: p.avatarId, size: 68),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.nickname.isEmpty ? 'Penjelajah' : p.nickname,
                            style: AppTextStyles.h1.copyWith(fontSize: 24),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            peta == null
                                ? 'Belum memilih planet'
                                : '${peta.grade.label} · ${peta.grade.name}',
                            style: AppTextStyles.sub,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _Statistik(
                      nilai: '${p.totalXp}',
                      label: 'XP',
                      warna: AppColors.brand,
                    ),
                    const SizedBox(width: 10),
                    _Statistik(
                      nilai: '${peta?.totalStars ?? 0}',
                      label: 'bintang',
                    ),
                    const SizedBox(width: 10),
                    _Statistik(
                      nilai: '$posSelesai/$totalPos',
                      label: 'pos selesai',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _Baris(
                  ikon: Icons.public_rounded,
                  judul: 'Pilih planet',
                  keterangan: 'Ganti kelas kapan saja',
                  onTap: () => context.push(Rute.pilihPlanet),
                ),
                _Baris(
                  ikon: Icons.emoji_events_outlined,
                  judul: 'Lencana',
                  keterangan: 'Datang di Tahap 2',
                  aktif: false,
                ),
                _Baris(
                  ikon: Icons.settings_outlined,
                  judul: 'Pengaturan',
                  keterangan: 'Di balik Gerbang Orang Tua',
                  gembok: true,
                  onTap: () =>
                      context.push(Rute.gerbangOrtu, extra: Rute.pengaturan),
                ),
                const SizedBox(height: 26),
                if (peta != null) _RingkasanZona(peta: peta),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Statistik extends StatelessWidget {
  const _Statistik({required this.nilai, required this.label, this.warna});

  final String nilai;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: AppColors.line, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Text(
              nilai,
              style: AppTextStyles.numeral.copyWith(
                color: warna ?? AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.ikon,
    required this.judul,
    required this.keterangan,
    this.onTap,
    this.gembok = false,
    this.aktif = true,
  });

  final IconData ikon;
  final String judul;
  final String keterangan;
  final VoidCallback? onTap;
  final bool gembok;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: aktif ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              child: Row(
                children: [
                  Icon(ikon, size: 22, color: AppColors.ink2),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(judul, style: AppTextStyles.title),
                        const SizedBox(height: 2),
                        Text(keterangan, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (gembok)
                    const Icon(
                      Icons.lock_rounded,
                      size: 16,
                      color: AppColors.ink3,
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.ink3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingkasanZona extends StatelessWidget {
  const _RingkasanZona({required this.peta});

  final PetaPlanet peta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Zona di planet ini', style: AppTextStyles.title),
        const SizedBox(height: 12),
        for (final z in peta.chapters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    z.chapter.title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: z.terbuka ? AppColors.ink : AppColors.ink3,
                    ),
                  ),
                ),
                Text(
                  '${z.selesai}/${z.total}',
                  style: AppTextStyles.caption.copyWith(
                    fontFeatures: const [AppTextStyles.tabular],
                  ),
                ),
                const SizedBox(width: 10),
                StarRating(
                  stars: z.tuntas ? 3 : (z.selesai > 0 ? 1 : 0),
                  size: 13,
                  gap: 1,
                  diAtasGelap: false,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
