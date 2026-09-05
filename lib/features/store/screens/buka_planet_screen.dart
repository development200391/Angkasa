import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../data/remote/purchase_gateway.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/planet_orb.dart';
import '../../../shared/widgets/primary_button.dart';

/// Layar 26 · Buka semua planet.
///
/// **Beli sekali, bukan langganan.** Konversi langganan untuk aplikasi
/// anak di Indonesia rendah, dan beban dukungannya — pembatalan,
/// tagihan yang tidak dikenali, pengembalian dana — tidak sepadan untuk
/// pengembang tunggal.
///
/// Yang ditulis besar di kartunya bukan cuma harganya, tapi kalimat
/// "tidak ada yang perlu dibatalkan". Itu keberatan pertama orang tua
/// terhadap apa pun yang dibeli di dalam aplikasi, dan menjawabnya
/// sebelum ditanya lebih murah daripada menjawabnya di kolom ulasan.
class BukaPlanetScreen extends ConsumerStatefulWidget {
  const BukaPlanetScreen({super.key});

  @override
  ConsumerState<BukaPlanetScreen> createState() => _State();
}

enum _Kerja { beli, pulihkan }

class _State extends ConsumerState<BukaPlanetScreen> {
  _Kerja? _kerja;
  String? _pesan;

  bool get _bekerja => _kerja != null;

  Future<void> _selesai() async {
    ref
      ..invalidate(galaksiProvider)
      ..invalidate(sudahBeliProvider)
      ..invalidate(planetsProvider);
  }

  Future<void> _beli() async {
    setState(() {
      _kerja = _Kerja.beli;
      _pesan = null;
    });
    final hasil = await ref.read(purchaseRepositoryProvider).beli();
    await _selesai();
    if (!mounted) return;
    setState(() => _kerja = null);

    switch (hasil) {
      case HasilBeli.berhasil:
        context.pushReplacement(Rute.pembelianBerhasil);
      case HasilBeli.tertunda:
        // Bukan gagal. Pembayaran lewat transfer atau gerai memang
        // butuh waktu, dan orang tua yang membaca "gagal" akan mencoba
        // membayar dua kali.
        setState(
          () => _pesan =
              'Pembayaran sedang diproses. Planetnya terbuka sendiri '
              'begitu pembayarannya selesai — tidak perlu membayar lagi.',
        );
      case HasilBeli.dibatalkan:
        break;
      case HasilBeli.tidakAdaToko:
        setState(
          () => _pesan = 'Pembelian belum tersedia di versi aplikasi ini.',
        );
      case HasilBeli.gagal:
        setState(
          () => _pesan = 'Pembelian belum berhasil. Belum ada yang ditagih.',
        );
    }
  }

  Future<void> _pulihkan() async {
    setState(() {
      _kerja = _Kerja.pulihkan;
      _pesan = null;
    });
    final punya = await ref.read(purchaseRepositoryProvider).pulihkan();
    await _selesai();
    if (!mounted) return;
    setState(() => _kerja = null);

    if (punya) {
      context.pushReplacement(Rute.pembelianBerhasil);
    } else {
      setState(
        () => _pesan =
            'Tidak ada pembelian yang ditemukan di akun Google Play ini. '
            'Pastikan HP-nya memakai akun yang sama dengan waktu membeli.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final galaksi = ref.watch(galaksiProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Buka semua planet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: galaksi.when(
          loading: () => const LoadingView(),
          error: (e, _) => EmptyView(judul: 'Tidak terbaca', keterangan: '$e'),
          data: (g) {
            final produk = g.produk;
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 12),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final p in g.planet.where(
                            (p) => p.grade.requiresPurchase,
                          ))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: PlanetOrb(
                                color: AppColors.forGrade(p.grade.orderIndex),
                                size: 50,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Jumlah posnya dihitung dari isi sungguhan, bukan
                      // diketik. Angka yang diketik di layar penjualan
                      // akan basi pada penambahan pos pertama, dan
                      // janji yang meleset di layar berbayar adalah
                      // jenis kesalahan yang paling mahal.
                      _Poin('${g.posBerbayar} pos baru untuk kelas 3 sampai 6'),
                      const _Poin(
                        'Soal cerita, geometri, dan statistik — bukan cuma '
                        'hitung',
                      ),
                      const _Poin(
                        'Dashboard orang tua — jenis kesalahan, bukan cuma '
                        'nilai',
                      ),
                      const _Poin('Kilat 60 Detik tanpa batas'),
                      const SizedBox(height: 22),
                      _KartuHarga(harga: produk?.harga),
                      if (_pesan != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _pesan!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.ink2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                  child: Column(
                    children: [
                      PrimaryButton(
                        label: _kerja == _Kerja.beli
                            ? 'Memproses…'
                            : 'Beli sekarang',
                        onPressed: _bekerja || produk == null ? null : _beli,
                      ),
                      const SizedBox(height: 6),
                      SecondaryButton(
                        label: _kerja == _Kerja.pulihkan
                            ? 'Mencari…'
                            : 'Pulihkan pembelian',
                        onPressed: _bekerja || !g.tokoAda ? null : _pulihkan,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Poin extends StatelessWidget {
  const _Poin(this.teks);

  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.check_rounded, size: 19, color: AppColors.ok),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(teks, style: AppTextStyles.body.copyWith(height: 1.45)),
        ),
      ],
    ),
  );
}

class _KartuHarga extends StatelessWidget {
  const _KartuHarga({required this.harga});

  /// `null` kalau toko tidak memberi harga. Yang ditampilkan keadaan
  /// apa adanya — bukan angka yang dikarang aplikasi.
  final String? harga;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE6C88A), width: 1.5),
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFDF8), Color(0xFFFDF3DF)],
      ),
    ),
    child: Column(
      children: [
        Text(
          harga ?? 'Harga belum terbaca',
          textAlign: TextAlign.center,
          style: AppTextStyles.h1.copyWith(
            fontSize: harga == null ? 20 : 32,
            color: const Color(0xFF8A5A0B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          harga == null
              ? 'Coba lagi setelah tersambung internet.'
              : 'sekali bayar · berlaku selamanya',
          textAlign: TextAlign.center,
          style: AppTextStyles.caption.copyWith(
            fontSize: 13.5,
            color: const Color(0xFF8A5A0B),
          ),
        ),
        if (harga != null) ...[
          const SizedBox(height: 10),
          Text(
            'Bukan langganan. Tidak ada tagihan bulanan,\n'
            'tidak ada yang perlu dibatalkan.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(height: 1.5),
          ),
        ],
      ],
    ),
  );
}
