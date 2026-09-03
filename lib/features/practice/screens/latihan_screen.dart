import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/models/enums.dart';
import '../widgets/mode_tile.dart';

/// Tab Latihan.
///
/// Empat mode bebas yang tidak mengubah progres lintasan. Angka merah di
/// Perbaiki Kesalahan adalah **satu-satunya lencana notifikasi** di
/// seluruh aplikasi — kalau ada di mana-mana, tidak ada yang berarti.
class LatihanScreen extends ConsumerWidget {
  const LatihanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ringkasan = ref.watch(practiceSummaryProvider).value;
    final menunggu = ringkasan?.menunggu ?? 0;
    final rekor = ringkasan?.rekorKilat ?? 0;
    final tantanganSelesai = ringkasan?.tantanganSelesai ?? false;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(practiceSummaryProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            children: [
              Text('Latihan', style: AppTextStyles.h1.copyWith(fontSize: 24)),
              const SizedBox(height: 5),
              Text(
                'Main sepuasnya. Bintang di lintasan tidak berubah.',
                style: AppTextStyles.sub.copyWith(fontSize: 13.5),
              ),
              const SizedBox(height: 20),

              ModeTile(
                ikon: Icons.bolt_rounded,
                gradien: const [Color(0xFF6FB6E6), Color(0xFF3C87BE)],
                judul: 'Latihan Cepat',
                isi: '10 soal acak dari zona yang sudah dibuka',
                onTap: () => context.push(
                  Rute.sesiLatihanUntuk(PracticeMode.latihanCepat),
                ),
              ),
              const SizedBox(height: 13),

              ModeTile(
                ikon: Icons.refresh_rounded,
                gradien: const [Color(0xFFD9707F), Color(0xFFA93044)],
                judul: 'Perbaiki Kesalahan',
                isi: menunggu == 0
                    ? 'Belum ada soal yang perlu diulang'
                    : 'Soal yang pernah kamu jawab salah',
                pil: menunggu == 0 ? null : '$menunggu',
                warnaPil: AppColors.wrong,
                warnaTeksPil: Colors.white,
                garis: menunggu == 0 ? null : const Color(0xFFE6B9BF),
                onTap: menunggu == 0 ? null : () => context.push(Rute.perbaiki),
              ),
              const SizedBox(height: 13),

              ModeTile(
                ikon: Icons.calendar_month_rounded,
                gradien: const [Color(0xFFE8B75B), Color(0xFFB77A11)],
                judul: 'Tantangan Harian',
                isi: tantanganSelesai
                    ? 'Sudah selesai hari ini. Sampai besok!'
                    : 'Satu set tiap hari, XP dobel',
                pil: tantanganSelesai ? 'selesai' : 'XP ×2',
                warnaPil: tantanganSelesai
                    ? AppColors.okSoft
                    : const Color(0xFFFBEBD0),
                warnaTeksPil: tantanganSelesai
                    ? AppColors.ok
                    : const Color(0xFF8A5A0B),
                onTap: () => context.push(Rute.tantangan),
              ),
              const SizedBox(height: 13),

              ModeTile(
                ikon: Icons.timer_rounded,
                gradien: const [Color(0xFF5FBE9C), Color(0xFF20785E)],
                judul: 'Kilat 60 Detik',
                isi: rekor == 0
                    ? 'Hitung sebanyak mungkin dalam 60 detik'
                    : 'Rekormu $rekor soal benar',
                onTap: () => context.push(Rute.kilat),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
