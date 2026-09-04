import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/widgets/spanduk_luring.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Empat tab di bilah bawah. Lebih dari empat terlalu ramai untuk jempol
/// anak, dan tab kelima selalu jadi tempat pembuangan fitur.
class ShellScaffold extends ConsumerWidget {
  const ShellScaffold({required this.shell, super.key});

  final StatefulNavigationShell shell;

  /// Dua tab berlatar angkasa, dua berlatar terang. Bilah bawahnya ikut,
  /// supaya tidak ada garis terang yang menempel di bawah peta.
  static const _gelap = {0, 2};

  static const _tab = <({IconData ikon, String label})>[
    (ikon: Icons.explore_rounded, label: 'Jelajah'),
    (ikon: Icons.add_circle_outline_rounded, label: 'Latihan'),
    (ikon: Icons.bar_chart_rounded, label: 'Peringkat'),
    (ikon: Icons.person_rounded, label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gelap = _gelap.contains(shell.currentIndex);

    // Waktu sinyal hilang, **hanya** tab Peringkat yang meredup. Tiga
    // tab lainnya tetap penuh warna, dan itu yang memberi tahu orang tua
    // bahwa yang berhenti cuma satu fitur — bukan aplikasinya.
    final peringkatRedup = ref.watch(peringkatRedupProvider);

    return Scaffold(
      backgroundColor: gelap ? AppColors.space : AppColors.bg,
      body: shell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: gelap ? AppColors.space : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: gelap ? AppColors.lineOnSpace : AppColors.line,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (var i = 0; i < _tab.length; i++)
                  Expanded(
                    child: _Tab(
                      ikon: _tab[i].ikon,
                      label: _tab[i].label,
                      aktif: shell.currentIndex == i,
                      gelap: gelap,
                      redup: i == 2 && peringkatRedup,
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.ikon,
    required this.label,
    required this.aktif,
    required this.gelap,
    required this.onTap,
    this.redup = false,
  });

  final IconData ikon;
  final String label;
  final bool aktif;
  final bool gelap;
  final VoidCallback onTap;

  /// Diredupkan, tapi **tetap bisa ditekan**. Tab yang mati sama sekali
  /// membuat anak menyangka fiturnya hilang; yang meredup lalu
  /// menjelaskan dirinya sendiri di dalam jauh lebih jujur.
  final bool redup;

  @override
  Widget build(BuildContext context) {
    final warna = aktif
        ? (gelap ? AppColors.brandLight : AppColors.brand)
        : (gelap ? const Color(0xFF6E7C99) : AppColors.ink3);

    return Semantics(
      selected: aktif,
      button: true,
      child: Opacity(
        opacity: redup ? 0.4 : 1,
        child: InkResponse(
          onTap: onTap,
          radius: 44,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(ikon, size: 23, color: warna),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.family,
                  fontSize: 11,
                  color: warna,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
