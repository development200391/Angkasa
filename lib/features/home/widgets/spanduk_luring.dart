import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';

/// Layar 20 · Luring.
///
/// Spanduk yang muncul di atas lintasan waktu sinyal hilang. Kalimatnya
/// dipilih dengan hati-hati, dan yang penting bukan yang pertama:
///
/// > **Semua materi tetap jalan. Progres disimpan di HP.**
///
/// Orang tua yang melihat ikon Wi-Fi tercoret di aplikasi belajar akan
/// menganggap aplikasinya rusak — kecuali kalimat berikutnya menjelaskan
/// bahwa tidak ada yang berhenti. Angka "3 antre" di sebelah kanan ada
/// karena alasan yang sama: menyebut jumlahnya membuat "nanti terkirim"
/// terdengar seperti janji yang bisa diperiksa.
///
/// Spanduknya tidak pernah muncul di build luring penuh. Di sana tidak
/// ada sinyal yang bisa hilang, dan mengabarkan ketiadaan sesuatu yang
/// memang tidak pernah ada cuma membingungkan.
class SpandukLuring extends ConsumerWidget {
  const SpandukLuring({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gateway = ref.watch(remoteGatewayProvider);
    if (!gateway.tersedia) return const SizedBox.shrink();

    final koneksi = ref.watch(koneksiProvider).value;
    if (koneksi == null || koneksi.tersambung) return const SizedBox.shrink();

    final antre = ref.watch(antreanProvider).value ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 2, 18, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 21,
            color: AppColors.ink3OnSpace,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tidak ada sinyal',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 13.5,
                    color: AppColors.inkOnSpace,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Semua materi tetap jalan. Progres disimpan di HP.',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.ink3OnSpace,
                  ),
                ),
              ],
            ),
          ),
          if (antre > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.brandLight.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$antre antre',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandLight,
                  fontFeatures: const [AppTextStyles.tabular],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Apakah tab Peringkat perlu diredupkan.
///
/// Hanya tab itu yang meredup, dan itu memang seluruh maksudnya: yang
/// hilang waktu sinyal putus persis satu fitur, dan tiga tab lainnya
/// tetap penuh warna untuk membuktikannya.
final peringkatRedupProvider = Provider<bool>((ref) {
  if (!ref.watch(remoteGatewayProvider).tersedia) return false;
  final koneksi = ref.watch(koneksiProvider).value;
  return koneksi != null && !koneksi.tersambung;
});
