import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/planet_orb.dart';

/// Batang mendatar untuk dua daftar di dashboard orang tua: kemajuan
/// per planet, dan jenis kesalahan yang paling sering.
///
/// **Semua batang satu warna.** Panjangnya yang membawa angka, bukan
/// warnanya — memberi tiap baris warna berbeda menyiratkan kategorinya
/// berbeda, padahal yang dibandingkan justru besarnya. Angkanya juga
/// tetap ditulis di kanan, jadi baris ini bisa dibaca tanpa mengukur
/// apa pun dengan mata.
class BatangMendatar extends StatelessWidget {
  const BatangMendatar({
    required this.label,
    required this.nilai,
    required this.pecahan,
    this.titik,
    super.key,
  });

  final String label;

  /// Ditulis apa adanya di kanan: `36/36`, `12×`.
  final String nilai;

  /// 0–1.
  final double pecahan;

  /// Titik warna kecil sebelum labelnya, untuk baris planet. Ini
  /// **penanda identitas**, bukan skala — planetnya memang punya warna
  /// sendiri di seluruh aplikasi, dan mengenalinya di sini membuat
  /// barisnya tidak perlu dibaca dua kali.
  final Color? titik;

  static const _warna = AppColors.brand;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (titik != null) ...[
              PlanetOrb(color: titik!, size: 14, bayangan: false),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(fontSize: 13.5),
              ),
            ),
            Text(
              nilai,
              style: AppTextStyles.title.copyWith(
                fontSize: 13.5,
                fontFeatures: const [AppTextStyles.tabular],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: pecahan.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: const Color(0xFFE7EBF2),
            valueColor: const AlwaysStoppedAnimation(_warna),
          ),
        ),
      ],
    ),
  );
}

/// Pil status penguasaan: **ikon + tulisan + warna sekaligus**.
///
/// Tidak pernah warna saja. Sekitar satu dari dua belas laki-laki buta
/// warna merah-hijau, dan bapak yang membuka layar ini harus bisa
/// membedakan "Dikuasai" dari "Perlu latihan" tanpa melihat warnanya.
class PilStatus extends StatelessWidget {
  const PilStatus({
    required this.teks,
    required this.ikon,
    required this.warna,
    required this.latar,
    super.key,
  });

  final String teks;
  final IconData ikon;
  final Color warna;
  final Color latar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: latar,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ikon, size: 13, color: warna),
        const SizedBox(width: 6),
        Text(
          teks,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: warna,
          ),
        ),
      ],
    ),
  );
}
