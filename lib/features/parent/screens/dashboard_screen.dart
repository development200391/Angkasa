import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/loading_view.dart';
import '../widgets/batang_menit.dart';
import '../widgets/batang_mendatar.dart';

/// Layar 30 · Dashboard orang tua.
///
/// **Menit belajar dipakai apa adanya, tanpa target harian.** Memasang
/// target di layar orang tua terdengar membantu dan berujung jadi
/// tekanan buat anaknya — "kamu baru 8 menit" adalah kalimat yang
/// diciptakan oleh angka target, bukan oleh anak yang malas.
///
/// Yang ditampilkan cuma yang bisa ditindaklanjuti tanpa menghakimi:
/// berapa lama, seberapa tepat, dan sudah sampai mana. Sisanya ada di
/// layar Jenis kesalahan, dan itulah yang benar-benar berguna.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(ringkasanOrtuProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          data.value == null
              ? 'Minggu ini'
              : '${data.value!.nama} · minggu ini',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: data.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              EmptyView(judul: 'Belum bisa dibaca', keterangan: '$e'),
          data: (r) => ListView(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
            children: [
              Row(
                children: [
                  _Ubin(angka: '${r.posSelesai}', label: 'pos selesai'),
                  const SizedBox(width: 10),
                  _Ubin(
                    // Tanda hubung, bukan "0%". Anak yang sedang libur
                    // bukan anak yang menjawab nol persen benar, dan
                    // angka nol di layar orang tua terbaca sebagai
                    // tuduhan.
                    angka: r.persenBenar == null ? '—' : '${r.persenBenar}%',
                    label: 'jawaban benar',
                    warna: r.persenBenar == null ? null : AppColors.ok,
                  ),
                  const SizedBox(width: 10),
                  _Ubin(angka: '${r.menitMingguIni}', label: 'menit'),
                ],
              ),
              const SizedBox(height: 24),
              Text('Menit belajar per hari', style: AppTextStyles.title),
              const SizedBox(height: 11),
              BatangMenit(hari: r.perHari),
              if (r.planet.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Kemajuan per planet', style: AppTextStyles.title),
                const SizedBox(height: 13),
                for (final p in r.planet)
                  BatangMendatar(
                    label: p.nama,
                    nilai: '${p.selesai}/${p.total}',
                    pecahan: p.pecahan,
                    titik: AppColors.forGrade(p.urutan),
                  ),
              ],
              const SizedBox(height: 8),
              _TautanKesalahan(onTap: () => context.push(Rute.jenisKesalahan)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ubin extends StatelessWidget {
  const _Ubin({required this.angka, required this.label, this.warna});

  final String angka;
  final String label;
  final Color? warna;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            angka,
            style: AppTextStyles.h2.copyWith(fontSize: 23, color: warna),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    ),
  );
}

class _TautanKesalahan extends StatelessWidget {
  const _TautanKesalahan({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Lihat '),
                    TextSpan(
                      text: 'jenis kesalahan',
                      style: AppTextStyles.title.copyWith(fontSize: 14),
                    ),
                    const TextSpan(text: ' yang paling sering diulang'),
                  ],
                ),
                style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    ),
  );
}
