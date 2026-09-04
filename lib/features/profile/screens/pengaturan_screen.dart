import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../shared/widgets/loading_view.dart';

/// Pengaturan — hanya bisa dibuka lewat Gerbang Orang Tua.
///
/// Isinya sengaja pendek. Yang belum ada di Tahap 1 disebutkan apa
/// adanya beserta tahapnya, bukan disembunyikan: orang tua yang membaca
/// halaman ini sedang menilai apakah aplikasinya jujur.
class PengaturanScreen extends ConsumerWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profil = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Rute.profil),
        ),
      ),
      body: profil.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyView(judul: 'Gagal memuat', keterangan: '$e'),
        data: (p) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          children: [
            _Kartu(
              children: [
                SwitchListTile.adaptive(
                  value: p.soundOn,
                  onChanged: (v) =>
                      ref.read(profileProvider.notifier).setSuara(v),
                  title: Text('Suara', style: AppTextStyles.title),
                  subtitle: Text(
                    'Efek suara benar, salah, dan naik level.',
                    style: AppTextStyles.caption,
                  ),
                  activeThumbColor: AppColors.brand,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                const Divider(indent: 16, endIndent: 16),
                SwitchListTile.adaptive(
                  value: p.notifOn,
                  onChanged: (v) => _setPemberitahuan(context, ref, v),
                  title: Text('Pengingat harian', style: AppTextStyles.title),
                  subtitle: Text(
                    p.notifHour == null
                        ? 'Satu pemberitahuan lokal per hari. Jamnya '
                              'menyesuaikan kebiasaan main.'
                        : 'Satu pemberitahuan lokal per hari, sekitar pukul '
                              '${p.notifHour}.00 — dipelajari dari kebiasaan '
                              'main.',
                    style: AppTextStyles.caption,
                  ),
                  activeThumbColor: AppColors.brand,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Kartu(
              children: [
                ListTile(
                  title: Text('Akun & data', style: AppTextStyles.title),
                  subtitle: Text(
                    'Papan peringkat, cadangan progres, dan daftar persis '
                    'apa yang dikirim keluar.',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.ink3,
                  ),
                  onTap: () => context.push(Rute.akunData),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Kartu(
              children: [
                ListTile(
                  title: Text('Tanpa iklan', style: AppTextStyles.title),
                  subtitle: Text(
                    'Bukan "iklan sopan" — memang tidak ada satu pun, dan '
                    'tidak akan ditambahkan diam-diam.',
                    style: AppTextStyles.caption,
                  ),
                  trailing: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.ok,
                  ),
                ),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  title: Text('Jalan tanpa sinyal', style: AppTextStyles.title),
                  subtitle: Text(
                    AppConfig.offlineOnly
                        ? 'Seluruh materi ada di perangkat. Tidak ada data '
                              'yang dikirim keluar sama sekali.'
                        : 'Papan peringkat memakai jaringan. Seluruh materi '
                              'belajar tetap ada di perangkat dan jalan '
                              'tanpa sinyal.',
                    style: AppTextStyles.caption,
                  ),
                  trailing: Icon(
                    AppConfig.offlineOnly
                        ? Icons.check_circle_rounded
                        : Icons.cloud_outlined,
                    color: AppConfig.offlineOnly
                        ? AppColors.ok
                        : AppColors.ink3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Kartu(
              children: [
                ListTile(
                  title: Text(
                    'Mulai dari awal',
                    style: AppTextStyles.title.copyWith(color: AppColors.wrong),
                  ),
                  subtitle: Text(
                    'Menghapus semua bintang, XP, dan catatan jawaban.',
                    style: AppTextStyles.caption,
                  ),
                  onTap: () => _konfirmasiReset(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 26),
            Center(
              child: Text(
                AppConfig.daringAktif
                    ? 'Angkasa · Tahap 3 · luring dulu, daring belakangan'
                    : 'Angkasa · Tahap 3 · luring penuh',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Izin pemberitahuan baru diminta saat setelannya benar-benar
  /// dinyalakan — bukan saat aplikasi pertama dibuka.
  Future<void> _setPemberitahuan(
    BuildContext context,
    WidgetRef ref,
    bool nyala,
  ) async {
    final layanan = ref.read(notificationServiceProvider);
    if (nyala) {
      final izin = await layanan.mintaIzin();
      if (!izin) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pemberitahuan ditolak di setelan HP. Nyalakan dari sana '
                'kalau berubah pikiran.',
              ),
            ),
          );
        }
        return;
      }
    }
    await ref.read(profileRepositoryProvider).setPemberitahuan(nyala);
    await ref.read(profileProvider.notifier).muatUlang();
    await ref.read(pengingatHarianProvider.future);
  }

  Future<void> _konfirmasiReset(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus semua progres?'),
        content: const Text(
          'Bintang, XP, dan catatan jawaban akan hilang dan tidak bisa '
          'dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (yakin != true) return;

    await ref.read(progressRepositoryProvider).resetProgres();
    await ref.read(profileRepositoryProvider).resetProfil();
    ref.invalidate(petaProvider);
    await ref.read(profileProvider.notifier).muatUlang();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Progres dihapus. Lintasan dimulai lagi.'),
        ),
      );
    }
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: AppColors.line, offset: Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}
