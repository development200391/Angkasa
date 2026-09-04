import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../data/remote/remote_models.dart';
import '../../../shared/widgets/primary_button.dart';
import '../widgets/daftar_data.dart';

/// Layar 21 · Simpan progres.
///
/// Login sepenuhnya opsional dan **tidak pernah menghalangi belajar**.
/// Layarnya cuma bisa dibuka dari balik Gerbang Orang Tua, dan isinya
/// disebutkan apa adanya sebelum orang tua menekan apa pun — dua daftar
/// pendek, satu hijau dan satu merah, sebelum tombolnya.
///
/// Tombol utamanya menyalakan cadangan lewat **akun anonim**: tidak ada
/// surel yang diminta, tidak ada layar masuk, dan tidak ada satu pun
/// data pribadi yang berpindah. Itu sudah cukup untuk menjaga progres
/// dari HP yang dipakai ulang; menautkannya ke akun Google baru perlu
/// kalau HP-nya benar-benar diganti.
class SimpanProgresScreen extends ConsumerStatefulWidget {
  const SimpanProgresScreen({super.key});

  @override
  ConsumerState<SimpanProgresScreen> createState() => _State();
}

/// Pekerjaan yang sedang berjalan, kalau ada.
///
/// Bukan sekadar `bool`: dua tombol di layar ini memanggil server, dan
/// keduanya harus mati selama salah satunya bekerja. Tapi tulisan
/// "Menyimpan…" cuma benar untuk satu di antaranya — memasangnya di
/// tombol cadangan waktu yang berjalan sebenarnya penautan Google adalah
/// memberi tahu orang tua sesuatu yang tidak sedang terjadi.
enum _Kerja { cadangan, google }

class _State extends ConsumerState<SimpanProgresScreen> {
  _Kerja? _kerja;
  String? _pesan;

  bool get _bekerja => _kerja != null;

  Future<void> _nyalakan() async {
    setState(() {
      _kerja = _Kerja.cadangan;
      _pesan = null;
    });
    final berhasil = await ref
        .read(accountRepositoryProvider)
        .nyalakanCadangan();
    await ref.read(profileProvider.notifier).muatUlang();
    if (!mounted) return;

    setState(() {
      _kerja = null;
      _pesan = berhasil
          ? null
          : 'Belum berhasil. Coba lagi setelah tersambung Wi-Fi.';
    });
    if (berhasil && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadangan menyala. Progres tersimpan.')),
      );
      context.pop();
    }
  }

  /// Menautkan akun Google.
  ///
  /// Lima akhir, lima jawaban yang berbeda — dan yang paling penting
  /// bukan yang berhasil. Akun Google yang sudah dipakai HP lain
  /// **bukan galat**: itu justru keadaan yang membuat fitur ini ada.
  /// Jawaban yang benar di situ adalah membuka layar Pulihkan progres,
  /// bukan menampilkan tulisan merah.
  ///
  /// Dua akhir sisanya dipisah karena saran yang benar berbeda: HP tanpa
  /// akun Google perlu disuruh menambahkan akun, bukan "coba lagi
  /// nanti" — nanti pun hasilnya sama.
  Future<void> _tautkan() async {
    setState(() {
      _kerja = _Kerja.google;
      _pesan = null;
    });
    final hasil = await ref.read(accountRepositoryProvider).tautkanGoogle();
    await ref.read(profileProvider.notifier).muatUlang();
    ref.invalidate(keadaanAkunProvider);
    if (!mounted) return;
    setState(() => _kerja = null);

    switch (hasil) {
      case HasilTaut.berhasil:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun tertaut. Progres bisa dipindah ke HP baru.'),
          ),
        );
      case HasilTaut.sudahDipakaiAkunLain:
        ref.invalidate(pilihanPemulihanProvider);
        context.push(Rute.pulihkanProgres);
      case HasilTaut.dibatalkan:
        // Sengaja diam. Orang tua menutup lembar akun, dan tidak ada
        // satu pun hal yang salah untuk dilaporkan.
        break;
      case HasilTaut.tidakAdaAkunDiHp:
        setState(
          () => _pesan =
              'Belum ada akun Google di HP ini. Tambahkan lewat Setelan '
              'HP, lalu coba lagi.',
        );
      case HasilTaut.gagal:
        setState(() => _pesan = 'Belum berhasil menautkan. Coba lagi nanti.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final akun = ref.watch(keadaanAkunProvider).value;
    final nama = ref.watch(profileProvider).value?.namaTampil ?? 'anak';
    final sudahMenyala =
        akun?.tersambung == true && akun?.terakhirSinkron != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Simpan progres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
                children: [
                  Center(
                    child: Container(
                      width: 78,
                      height: 78,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const RadialGradient(
                          center: Alignment(-0.36, -0.48),
                          radius: 1,
                          colors: [
                            Color(0xFF2A3A62),
                            Color(0xFF131C33),
                            Color(0xFF0A1122),
                          ],
                          stops: [0, 0.7, 1],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0C1428)
                                .withValues(alpha: 0.55),
                            offset: const Offset(0, 8),
                            blurRadius: 16,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        size: 34,
                        color: AppColors.brandLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    sudahMenyala
                        ? 'Progres $nama sudah dicadangkan'
                        : 'Pindah ke HP baru nanti?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sudahMenyala
                        ? 'Salinannya diperbarui sendiri tiap kali $nama '
                              'selesai main dan HP-nya tersambung Wi-Fi.'
                        : 'Sekarang progres $nama cuma ada di HP ini. Kalau '
                              'HP hilang atau diganti, semuanya ikut hilang.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sub,
                  ),
                  const SizedBox(height: 26),
                  const DaftarDataRingkas(),
                  if (_pesan != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _pesan!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.wrong,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              child: Column(
                children: [
                  PrimaryButton(
                    label: switch (_kerja) {
                      _Kerja.cadangan => 'Menyimpan…',
                      _ when sudahMenyala => 'Simpan sekarang',
                      _ => 'Nyalakan cadangan',
                    },
                    onPressed: _bekerja || akun?.tersambung != true
                        ? null
                        : _nyalakan,
                  ),
                  const SizedBox(height: 11),
                  _BarisGoogle(
                    bisa: akun?.bisaMasukGoogle ?? false,
                    sudah: akun?.anonim == false,
                    onTap: _bekerja ? null : _tautkan,
                  ),
                  const SizedBox(height: 11),
                  SecondaryButton(
                    label: 'Nanti saja',
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Akun milik orang tua, bukan anak. Layar ini hanya '
                    'muncul di balik Gerbang Orang Tua.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Menautkan akun Google.
///
/// Sengaja bukan tombol utama. Cadangan lewat akun anonim sudah menjaga
/// progres dari HP yang dipakai ulang tanpa meminta satu pun data
/// pribadi; menautkan Google cuma perlu kalau HP-nya benar-benar
/// diganti. Menaruhnya sebagai tombol besar akan membuat orang tua
/// mengira ia wajib, dan meminta surel yang tidak dibutuhkan.
///
/// Waktu [bisa] `false`, yang ditampilkan bukan tombol mati tanpa
/// keterangan tapi barisnya beserta alasannya — sebuah tombol yang pasti
/// gagal ditekan lebih buruk daripada satu kalimat jujur.
class _BarisGoogle extends StatelessWidget {
  const _BarisGoogle({required this.bisa, required this.sudah, this.onTap});

  final bool bisa;
  final bool sudah;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final aktif = bisa && !sudah;

    return Opacity(
      opacity: bisa ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: aktif ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD6DDE8), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  sudah ? Icons.check_circle_rounded : Icons.link_rounded,
                  size: 21,
                  color: sudah ? AppColors.ok : AppColors.ink2,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sudah ? 'Akun Google tertaut' : 'Tautkan akun Google',
                        style: AppTextStyles.title,
                      ),
                      const SizedBox(height: 2),
                      Text(switch ((sudah, bisa)) {
                        (true, _) =>
                          'Progres bisa dipulihkan di HP baru dengan '
                              'akun yang sama.',
                        (false, true) =>
                          'Untuk memindahkan progres ke HP lain.',
                        (false, false) =>
                          'Menyala setelah proyek Firebase disiapkan. '
                              'Cadangan di atas sudah jalan tanpa ini.',
                      }, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (aktif)
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: AppColors.ink3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
