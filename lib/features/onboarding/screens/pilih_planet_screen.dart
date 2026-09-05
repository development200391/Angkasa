import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/providers/home_providers.dart';
import '../../home/widgets/starfield.dart';
import '../widgets/planet_grid.dart';

/// Ganti planet kapan saja.
///
/// Ini jalur manual aturan unlock keempat, dan aturan itu yang
/// menentukan aplikasinya dipakai atau tidak: yang dikunci bertahap
/// cukup pos di dalam zona, bukan kelasnya.
class PilihPlanetScreen extends ConsumerStatefulWidget {
  const PilihPlanetScreen({super.key});

  @override
  ConsumerState<PilihPlanetScreen> createState() => _PilihPlanetScreenState();
}

class _PilihPlanetScreenState extends ConsumerState<PilihPlanetScreen> {
  String? _terpilih;

  @override
  Widget build(BuildContext context) {
    final planets = ref.watch(planetsProvider);
    final aktif = ref.watch(profileProvider).value?.activeGradeId;
    final terpilih = _terpilih ?? aktif;
    final sudahBeli = ref.watch(sudahBeliProvider).value ?? false;

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: planets.when(
              loading: () => const LoadingView(diAtasGelap: true),
              error: (e, _) => EmptyView(
                judul: 'Data planet tidak terbaca',
                keterangan: '$e',
                diAtasGelap: true,
              ),
              data: (daftar) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.ink2OnSpace,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pindah planet',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.inkOnSpace,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Progres di planet lama tidak hilang. Bintangnya '
                      'menunggu di sana.',
                      style: AppTextStyles.sub.copyWith(
                        color: AppColors.ink2OnSpace,
                      ),
                    ),
                    const SizedBox(height: 24),
                    PlanetGrid(
                      planets: daftar,
                      terpilih: terpilih,
                      sudahBeli: sudahBeli,
                      // Menekan planet berbayar membawa ke layar
                      // penjualannya, bukan tidak melakukan apa-apa.
                      // Kartu yang diam waktu disentuh terbaca sebagai
                      // aplikasi rusak.
                      onPilih: (g) {
                        if (g.requiresPurchase && !sudahBeli) {
                          context.push(Rute.galaksi);
                          return;
                        }
                        setState(() => _terpilih = g.id);
                      },
                    ),
                    const SizedBox(height: 26),
                    PrimaryButton(
                      label: 'Berangkat',
                      onPressed: terpilih == null || terpilih == aktif
                          ? null
                          : () async {
                              await ref
                                  .read(profileProvider.notifier)
                                  .gantiPlanet(terpilih);
                              ref
                                  .read(zonaTerpilihProvider.notifier)
                                  .ikutiProgres();
                              if (context.mounted) context.pop();
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
