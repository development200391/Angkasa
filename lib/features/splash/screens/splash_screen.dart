import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../home/widgets/starfield.dart';

/// Layar pertama. Tugasnya cuma satu: menunggu profil terbaca lalu
/// memutuskan ke mana.
///
/// Basis datanya sudah dibuka sebelum `runApp`, jadi layar ini biasanya
/// cuma lewat sekejap — dan itu memang targetnya. Aplikasi anak yang
/// menahan splash tiga detik terasa lambat, bukan mewah.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(profileProvider, (_, next) {
      final profil = next.value;
      if (profil == null || !context.mounted) return;
      context.go(profil.sudahOnboarding ? Rute.jelajah : Rute.onboarding);
    });

    // Kalau profilnya sudah tersedia sebelum listener terpasang.
    final profil = ref.watch(profileProvider).value;
    if (profil != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(profil.sudahOnboarding ? Rute.jelajah : Rute.onboarding);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield(jumlah: 70)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  AppAssets.logo,
                  width: 96,
                  height: 96,
                  placeholderBuilder: (_) =>
                      const SizedBox(width: 96, height: 96),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: AppTextStyles.family,
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      TextSpan(
                        text: 'Angka',
                        style: TextStyle(color: AppColors.brandLight),
                      ),
                      TextSpan(
                        text: 'sa',
                        style: TextStyle(color: AppColors.inkOnSpace),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
