import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/purchase_repository.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/planet_orb.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';

/// Layar 25 · Galaksi.
///
/// **Planet terkunci tetap menampilkan materinya.** Jumlah posnya, dan
/// satu baris tentang isinya — "Pecahan, luas & sudut". Orang tua bisa
/// menilai apa yang dijual sebelum membayar.
///
/// Menjual kotak tertutup memang menaikkan konversi sesaat. Yang
/// dihasilkannya sesudah itu: pengembalian dana, ulasan bintang satu,
/// dan orang yang tidak akan pernah mencoba lagi. Untuk aplikasi yang
/// dijual sekali seumur hidup, itu perhitungan yang jelas rugi.
class GalaksiScreen extends ConsumerWidget {
  const GalaksiScreen({super.key});

  /// Satu baris tentang isi tiap planet. Ditulis di sini, bukan diambil
  /// dari judul zona — yang dibaca orang tua sebelum membayar harus
  /// kalimat yang memang ditujukan kepadanya.
  static const isiPlanet = <String, String>{
    'grade-1': 'Bilangan dan penjumlahan dasar',
    'grade-2': 'Nilai tempat, menyimpan & meminjam',
    'grade-3': 'Perkalian & pembagian',
    'grade-4': 'Pecahan, luas & keliling',
    'grade-5': 'Desimal, persen, diagram',
    'grade-6': 'Bilangan bulat, statistik',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galaksi = ref.watch(galaksiProvider);

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: galaksi.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => EmptyView(
                judul: 'Daftar planet tidak terbaca',
                keterangan: '$e',
                diAtasGelap: true,
              ),
              data: (g) => _Isi(galaksi: g),
            ),
          ),
        ],
      ),
    );
  }
}

class _Isi extends ConsumerWidget {
  const _Isi({required this.galaksi});

  final Galaksi galaksi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produk = galaksi.produk;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 14),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.inkOnSpace,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Galaksi',
                    style: AppTextStyles.h2.copyWith(
                      color: AppColors.inkOnSpace,
                    ),
                  ),
                  Text(
                    '${galaksi.terbuka} dari ${galaksi.planet.length} '
                    'planet terbuka',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.ink2OnSpace,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: galaksi.planet.length,
            itemBuilder: (context, i) =>
                _KartuPlanet(planet: galaksi.planet[i]),
          ),
        ),
        // Tombol beli **hanya** muncul kalau tokonya benar-benar
        // memberi harga. Harga yang dikarang di aplikasi akan berbeda
        // dari lembar pembayaran begitu ada pajak daerah atau promo —
        // dan selisih itu alasan pembatalan yang paling mahal.
        if (produk != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              children: [
                PrimaryButton(
                  label: 'Buka 4 planet · ${produk.harga}',
                  onPressed: () => context.push(Rute.bukaPlanet),
                ),
                const SizedBox(height: 9),
                Text(
                  'Sekali bayar, bukan langganan.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink2OnSpace,
                  ),
                ),
              ],
            ),
          )
        else if (!galaksi.sudahBeli)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              galaksi.tokoAda
                  ? 'Harga belum bisa dibaca dari Play Store. '
                        'Coba lagi nanti.'
                  : 'Pembelian belum tersedia di versi ini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.ink3OnSpace,
              ),
            ),
          ),
      ],
    );
  }
}

class _KartuPlanet extends StatelessWidget {
  const _KartuPlanet({required this.planet});

  final PlanetTerkunci planet;

  @override
  Widget build(BuildContext context) {
    final g = planet.grade;
    final warna = AppColors.forGrade(g.orderIndex);

    return Opacity(
      // Diredupkan, bukan disembunyikan atau diselimuti. Isinya tetap
      // terbaca — itu seluruh gunanya layar ini.
      opacity: planet.terkunci ? 0.66 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlanetOrb(color: warna, size: 44),
                const SizedBox(height: 10),
                Text(
                  g.name,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    color: AppColors.inkOnSpace,
                  ),
                ),
                Text(
                  '${g.label} · ${planet.jumlahPos} pos',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.ink3OnSpace,
                  ),
                ),
                const Spacer(),
                Text(
                  GalaksiScreen.isiPlanet[g.id] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    color: AppColors.ink2OnSpace,
                  ),
                ),
              ],
            ),
            if (planet.terkunci)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.space.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: AppColors.ink2OnSpace,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
