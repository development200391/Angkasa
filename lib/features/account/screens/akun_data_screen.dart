import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../data/repositories/sync_repository.dart';
import '../../../shared/widgets/loading_view.dart';

/// Layar 23 · Akun & data.
///
/// **Papan peringkat adalah fitur yang bisa dimatikan.** Kalau
/// mematikannya ikut mengunci materi, orang tua akan merasa disandera —
/// dan yang paling sering terjadi bukan mereka menyalakannya kembali,
/// tapi mereka mencopot aplikasinya. Karena itu tiap sakelar di layar
/// ini cuma menyentuh **apa yang dikirim keluar**, tidak satu pun
/// menyentuh apa yang bisa dipelajari.
class AkunDataScreen extends ConsumerWidget {
  const AkunDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final akun = ref.watch(keadaanAkunProvider);
    final profil = ref.watch(profileProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Akun & data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: akun.when(
        loading: () => const LoadingView(),
        error: (e, _) => EmptyView(judul: 'Gagal memuat', keterangan: '$e'),
        data: (a) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
          children: [
            _StatusSinkron(akun: a),
            const SizedBox(height: 20),
            const _Label('AKUN'),
            _Baris(
              judul: 'Jenis akun',
              keterangan: a.tersambung
                  ? (a.anonim
                        ? 'Anonim — dibuat otomatis, tanpa email'
                        : a.email!)
                  : 'Belum ada — aplikasi berjalan sepenuhnya luring',
            ),
            _Baris(
              judul: 'Simpan progres',
              keterangan: 'Cadangan ke server, untuk HP yang diganti',
              onTap: () => context.push(Rute.simpanProgres),
            ),

            // Barisnya cuma ada kalau memang ada dua progres yang bisa
            // saling menimpa. Menampilkannya terus-menerus mengundang
            // orang tua membuka satu-satunya layar di aplikasi ini yang
            // bisa menghapus data — tanpa ada yang perlu dipilih.
            if (ref.watch(pilihanPemulihanProvider).value != null)
              _Baris(
                judul: 'Ada dua progres',
                keterangan: 'Progres di HP ini berbeda dengan yang tersimpan',
                onTap: () => context.push(Rute.pulihkanProgres),
              ),
            const SizedBox(height: 20),
            const _Label('DATA'),
            _Sakelar(
              judul: 'Ikut papan peringkat',
              keterangan: 'Nama panggilan & XP terlihat pemain lain',
              nilai: profil?.leaderboardOn ?? true,
              onUbah: (v) async {
                await ref.read(accountRepositoryProvider).setPapanPeringkat(v);
                await ref.read(profileProvider.notifier).muatUlang();
                ref.invalidate(papanLigaProvider);
              },
            ),
            _Sakelar(
              judul: 'Sinkron lewat data seluler',
              keterangan: 'Mati = hanya lewat Wi-Fi',
              nilai: profil?.syncCellular ?? false,
              onUbah: (v) async {
                await ref.read(accountRepositoryProvider).setSinkronSeluler(v);
                await ref.read(profileProvider.notifier).muatUlang();
              },
            ),
            _Baris(
              judul: 'Data yang dikirim',
              onTap: () => context.push(Rute.dataDikirim),
            ),
            _Baris(
              judul: 'Hapus data di server',
              merah: true,
              onTap: () => _konfirmasiHapus(context, ref),
            ),
            const SizedBox(height: 26),
            Text(
              'Mematikan papan peringkat tidak menghentikan apa pun di dalam '
              'aplikasi. Semua materi tetap terbuka.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapus(BuildContext context, WidgetRef ref) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus data di server?'),
        content: const Text(
          'Salinan di server dihapus dan pengiriman berhenti. Bintang, XP, '
          'dan lencana di HP ini tidak ikut terhapus — semuanya tetap ada.',
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

    await ref.read(accountRepositoryProvider).hapusDataServer();
    await ref.read(profileProvider.notifier).muatUlang();
    ref
      ..invalidate(keadaanAkunProvider)
      ..invalidate(papanLigaProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data di server dihapus. Progres di HP tetap utuh.'),
        ),
      );
    }
  }
}

class _StatusSinkron extends ConsumerWidget {
  const _StatusSinkron({required this.akun});

  final KeadaanAkun akun;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (warna, ikon, judul, isi) = switch (akun) {
      _ when !akun.tersambung => (
        AppColors.ink3,
        Icons.cloud_off_rounded,
        'Luring penuh',
        'Tidak ada satu pun data yang dikirim keluar dari HP ini.',
      ),
      _ when akun.menunggu > 0 => (
        AppColors.brand,
        Icons.schedule_rounded,
        '${akun.menunggu} menunggu dikirim',
        'Terkirim sendiri begitu ada Wi-Fi. Tidak ada yang hilang.',
      ),
      _ => (
        AppColors.ok,
        Icons.check_rounded,
        'Tersinkron',
        '${_kapan(akun.terakhirSinkron)} · tidak ada yang mengantre',
      ),
    };

    return Container(
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
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(warna, Colors.white, 0.28)!,
                  Color.lerp(warna, Colors.black, 0.2)!,
                ],
              ),
            ),
            child: Icon(ikon, size: 22, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul, style: AppTextStyles.title.copyWith(fontSize: 15)),
                const SizedBox(height: 2),
                Text(isi, style: AppTextStyles.caption),
              ],
            ),
          ),
          if (akun.tersambung && akun.menunggu > 0)
            TextButton(
              onPressed: () async {
                final hasil = await ref
                    .read(syncRepositoryProvider)
                    .kirimSekarang(paksa: true);
                ref.invalidate(keadaanAkunProvider);
                if (context.mounted) _kabarkan(context, hasil);
              },
              child: const Text('Kirim'),
            ),
        ],
      ),
    );
  }

  static void _kabarkan(BuildContext context, HasilSinkron hasil) {
    final pesan = switch (hasil.tertahan) {
      AlasanTertahan.luring => 'Belum tersambung ke server.',
      AlasanTertahan.tidakAdaSinyal => 'Tidak ada sinyal. Dicoba lagi nanti.',
      AlasanTertahan.menungguWifi => 'Menunggu Wi-Fi.',
      AlasanTertahan.belumMasuk => 'Belum bisa masuk ke akun.',
      null =>
        hasil.terkirim > 0
            ? '${hasil.terkirim} terkirim.'
            : 'Tidak ada yang perlu dikirim.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  static String _kapan(DateTime? waktu) {
    if (waktu == null) return 'Belum pernah';
    final menit = DateTime.now().difference(waktu).inMinutes;
    if (menit < 1) return 'Baru saja';
    if (menit < 60) return '$menit menit lalu';
    final jam = menit ~/ 60;
    if (jam < 24) return '$jam jam lalu';
    return '${jam ~/ 24} hari lalu';
  }
}

class _Label extends StatelessWidget {
  const _Label(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      teks,
      style: AppTextStyles.caption.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.62,
      ),
    ),
  );
}

class _Baris extends StatelessWidget {
  const _Baris({
    required this.judul,
    this.keterangan,
    this.onTap,
    this.merah = false,
  });

  final String judul;
  final String? keterangan;
  final VoidCallback? onTap;
  final bool merah;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15,
                    color: merah ? AppColors.wrong : AppColors.ink,
                  ),
                ),
                if (keterangan != null) ...[
                  const SizedBox(height: 2),
                  Text(keterangan!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: merah ? const Color(0xFFD9909A) : const Color(0xFFA9B3C4),
            ),
        ],
      ),
    ),
  );
}

class _Sakelar extends StatelessWidget {
  const _Sakelar({
    required this.judul,
    required this.keterangan,
    required this.nilai,
    required this.onUbah,
  });

  final String judul;
  final String keterangan;
  final bool nilai;
  final ValueChanged<bool> onUbah;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(judul, style: AppTextStyles.body.copyWith(fontSize: 15)),
              const SizedBox(height: 2),
              Text(keterangan, style: AppTextStyles.caption),
            ],
          ),
        ),
        Switch.adaptive(
          value: nilai,
          onChanged: onUbah,
          activeThumbColor: AppColors.brand,
        ),
      ],
    ),
  );
}
