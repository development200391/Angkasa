import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/dashboard_repository.dart';

/// Menit belajar tujuh hari terakhir.
///
/// **Tanpa garis target.** Menambahkan garis "30 menit sehari" akan
/// membuat tiap batang yang lebih pendek terbaca sebagai kegagalan, dan
/// hari libur terbaca sebagai kemalasan. Yang ditampilkan cuma apa yang
/// terjadi; menilainya urusan orang tua, bukan urusan aplikasi ini.
///
/// Hari tanpa aktivitas tetap punya batang pendek berwarna abu — bukan
/// kosong. Ruang kosong di deret batang terbaca seperti data yang
/// hilang, bukan seperti hari yang memang libur.
class BatangMenit extends StatelessWidget {
  const BatangMenit({required this.hari, super.key});

  final List<MenitHari> hari;

  @override
  Widget build(BuildContext context) {
    final tertinggi = hari.fold(0, (a, h) => h.menit > a ? h.menit : a);
    final puncak = tertinggi == 0 ? 1 : tertinggi;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          // Tinggi kotaknya harus muat angka **plus** batang tertinggi:
          // 16 untuk teksnya, 4 jaraknya, 72 batangnya. Dulu 92 dan
          // meluber satu piksel — cukup untuk memunculkan pita kuning
          // "BOTTOM OVERFLOWED" di layar orang tua.
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final h in hari)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Slot angkanya **selalu** setinggi 18, terisi
                          // atau tidak. Membiarkan teksnya menentukan
                          // tingginya sendiri membuat kotaknya meluber
                          // begitu angkanya tiga digit atau penggunanya
                          // membesarkan ukuran teks di setelan HP —
                          // dan yang muncul di layar orang tua adalah
                          // pita kuning "BOTTOM OVERFLOWED".
                          SizedBox(
                            height: 18,
                            // Angkanya cuma ditulis di hari tertinggi.
                            // Menulisnya di tiap batang membuat deretnya
                            // penuh angka kecil yang tidak satu pun
                            // dibaca.
                            child: h.menit == tertinggi && tertinggi > 0
                                ? FittedBox(
                                    child: Text(
                                      '${h.menit}',
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: (70 * h.menit / puncak).clamp(5.0, 70.0),
                            decoration: BoxDecoration(
                              color: h.menit == 0
                                  ? const Color(0xFFDDE3EC)
                                  : AppColors.brand,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1.5, color: AppColors.line),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final h in hari)
                Expanded(
                  child: Text(
                    h.huruf,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 11,
                      color: AppColors.ink3,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
