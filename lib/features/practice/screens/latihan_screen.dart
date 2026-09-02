import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Tab Latihan.
///
/// Keempat modenya datang di Tahap 2 — semuanya berdiri di atas data
/// yang **sudah** dikumpulkan Tahap 1 (`question_attempts` dan
/// `daily_activity`), jadi yang kurang cuma layarnya. Daftarnya
/// ditampilkan sekarang supaya jelas apa yang sedang dibangun, bukan
/// diganti dengan tab kosong.
class LatihanScreen extends StatelessWidget {
  const LatihanScreen({super.key});

  static const _mode =
      <({IconData ikon, Color warna, String judul, String isi})>[
        (
          ikon: Icons.bolt_rounded,
          warna: AppColors.brand,
          judul: 'Latihan Cepat',
          isi: '10 soal acak dari semua zona yang sudah dibuka',
        ),
        (
          ikon: Icons.build_rounded,
          warna: AppColors.wrong,
          judul: 'Perbaiki Kesalahan',
          isi: 'Soal yang pernah dijawab salah, diulang sampai benar dua kali',
        ),
        (
          ikon: Icons.today_rounded,
          warna: AppColors.puluh,
          judul: 'Tantangan Harian',
          isi: 'Satu set 10 soal per hari, XP dobel',
        ),
        (
          ikon: Icons.timer_rounded,
          warna: AppColors.pecah,
          judul: 'Kilat 60 Detik',
          isi: 'Hitung sebanyak mungkin dalam 60 detik',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
          children: [
            Text('Latihan', style: AppTextStyles.h1),
            const SizedBox(height: 8),
            Text(
              'Empat mode bebas yang tidak mengubah progres lintasan. '
              'Datang di Tahap 2.',
              style: AppTextStyles.sub,
            ),
            const SizedBox(height: 22),
            for (final m in _mode)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Opacity(
                  opacity: 0.6,
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: AppColors.line, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: m.warna.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(m.ikon, color: m.warna, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.judul, style: AppTextStyles.title),
                              const SizedBox(height: 2),
                              Text(m.isi, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: AppColors.ink3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
