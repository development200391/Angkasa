import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../../domain/engine/badge_rules.dart';
import '../../../shared/widgets/loading_view.dart';
import '../widgets/badge_medal.dart';

/// Layar koleksi lencana.
///
/// Dua puluh empat lencana, dan yang belum didapat tidak disembunyikan.
/// Yang sudah dapat naik ke atas supaya koleksinya terlihat tumbuh, tapi
/// yang terkunci tetap ada di bawahnya dengan nama dan syaratnya.
class LencanaScreen extends ConsumerWidget {
  const LencanaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lencana = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Lencana'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: lencana.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyView(judul: 'Gagal memuat', keterangan: '$e'),
        data: (didapat) {
          final punya = {for (final b in didapat) b.code};
          final urut = [
            ...BadgeRules.katalog.where((b) => punya.contains(b.code)),
            ...BadgeRules.katalog.where((b) => !punya.contains(b.code)),
          ];

          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOut,
                          tween: Tween(
                            begin: 0,
                            end: punya.length / BadgeRules.total,
                          ),
                          builder: (context, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 11,
                            backgroundColor: const Color(0xFFDDE3EC),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.brand,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        '${punya.length} dari ${BadgeRules.total} terkumpul',
                        style: AppTextStyles.caption.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 22,
                          crossAxisSpacing: 10,
                          mainAxisExtent: 128,
                        ),
                    itemCount: urut.length,
                    itemBuilder: (context, i) {
                      final b = urut[i];
                      final sudah = punya.contains(b.code);
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _jelaskan(context, b, sudah),
                        child: BadgeCell(code: b.code, didapat: sudah),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                  child: Text(
                    'Lencana yang terkunci tetap ditampilkan namanya — itu '
                    'yang membuat anak tahu ada tujuan berikutnya.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _jelaskan(BuildContext context, BadgeDef def, bool sudah) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (_) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BadgeMedal(ikon: def.ikon, didapat: sudah, size: 84),
              const SizedBox(height: 16),
              Text(def.nama, style: AppTextStyles.h2),
              const SizedBox(height: 7),
              Text(
                def.keterangan,
                textAlign: TextAlign.center,
                style: AppTextStyles.sub,
              ),
              const SizedBox(height: 12),
              Text(
                sudah ? 'Sudah didapat' : 'Belum terbuka',
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: sudah ? AppColors.ok : AppColors.ink3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
