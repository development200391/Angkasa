import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_config.dart';
import 'purchase_gateway.dart';

/// Satu-satunya berkas di proyek ini yang mengimpor `in_app_purchase`.
///
/// Kalau berkas ini dihapus, sisa aplikasinya tetap dikompilasi dan
/// tetap jalan — [GatewayBeliLuring] menggantikannya tanpa satu pun
/// layar yang perlu tahu. Pola yang sama persis dengan `FirebaseGateway`,
/// dan alasannya juga sama.
///
/// **Tidak ada satu pun harga yang ditulis di sini.** Harga datang dari
/// toko, sudah diformat dalam mata uang setempat.
class PlayGateway implements PurchaseGateway {
  PlayGateway();

  final _toko = InAppPurchase.instance;

  bool _siap = false;
  StreamSubscription<List<PurchaseDetails>>? _aliran;

  /// Pembelian yang datang lewat aliran, ditunggu oleh [beli] dan
  /// [pulihkan]. Play mengirimkan hasilnya lewat stream, bukan sebagai
  /// nilai balik — termasuk pembelian lama tiap kali aplikasi dibuka.
  final _masuk = StreamController<PurchaseDetails>.broadcast();

  static const _batasWaktu = Duration(seconds: 12);

  @override
  bool get tersedia => _siap;

  @override
  Future<void> siapkan() async {
    if (_siap) return;
    // Sakelar luring menang atas segalanya, sama seperti pada Firebase.
    if (AppConfig.offlineOnly) return;

    try {
      if (!await _toko.isAvailable()) {
        debugPrint('Angkasa/beli: toko tidak tersedia di perangkat ini');
        return;
      }

      _aliran = _toko.purchaseStream.listen((daftar) {
        for (final p in daftar) {
          _masuk.add(p);
          // **Selalu diselesaikan.** Pembelian yang tidak pernah
          // di-`complete` akan dikirim ulang Play tiap kali aplikasi
          // dibuka, selamanya — dan di beberapa perangkat akhirnya
          // dikembalikan otomatis ke pembelinya.
          if (p.pendingCompletePurchase) {
            unawaited(_toko.completePurchase(p));
          }
        }
      }, onError: (Object e) => debugPrint('Angkasa/beli: aliran galat — $e'));

      _siap = true;
    } catch (e, s) {
      debugPrint('Angkasa/beli: gagal menyiapkan toko — $e');
      debugPrintStack(stackTrace: s);
      _siap = false;
    }
  }

  @override
  Future<ProdukBeli?> produk(String id) async {
    if (!_siap) return null;
    try {
      final hasil = await _toko.queryProductDetails({id}).timeout(_batasWaktu);
      if (hasil.notFoundIDs.contains(id) || hasil.productDetails.isEmpty) {
        // Hampir selalu berarti produknya belum aktif di Play Console,
        // atau aplikasinya belum diunggah ke satu pun jalur rilis.
        // Ditulis lugas supaya tidak dikira galat jaringan.
        debugPrint('Angkasa/beli: produk "$id" tidak ada di toko');
        return null;
      }
      final p = hasil.productDetails.first;
      return ProdukBeli(id: p.id, harga: p.price, judul: p.title);
    } catch (e, s) {
      debugPrint('Angkasa/beli: gagal membaca produk — $e');
      debugPrintStack(stackTrace: s);
      return null;
    }
  }

  @override
  Future<HasilBeli> beli(String id) async {
    if (!_siap) return HasilBeli.tidakAdaToko;

    final ProductDetails rincian;
    try {
      final hasil = await _toko.queryProductDetails({id}).timeout(_batasWaktu);
      if (hasil.productDetails.isEmpty) return HasilBeli.tidakAdaToko;
      rincian = hasil.productDetails.first;
    } catch (e) {
      debugPrint('Angkasa/beli: $e');
      return HasilBeli.gagal;
    }

    // Hasilnya datang lewat aliran, bukan dari nilai balik
    // `buyNonConsumable`. Pendengarnya dipasang **sebelum** lembar
    // pembayaran dibuka — kalau sesudah, pembelian yang selesai sangat
    // cepat sudah lewat sebelum ada yang mendengarkan.
    final tunggu = _masuk.stream
        .firstWhere((p) => p.productID == id)
        .timeout(
          const Duration(minutes: 5),
          onTimeout: () => throw TimeoutException('menunggu terlalu lama'),
        );

    try {
      final dimulai = await _toko.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: rincian),
      );
      if (!dimulai) return HasilBeli.gagal;

      final p = await tunggu;
      return switch (p.status) {
        PurchaseStatus.purchased ||
        PurchaseStatus.restored => HasilBeli.berhasil,
        PurchaseStatus.pending => HasilBeli.tertunda,
        PurchaseStatus.canceled => HasilBeli.dibatalkan,
        PurchaseStatus.error => HasilBeli.gagal,
      };
    } on TimeoutException {
      // Bukan gagal: pembayaran lewat transfer atau gerai memang butuh
      // waktu, dan hasilnya akan datang sendiri ke aliran nanti.
      return HasilBeli.tertunda;
    } catch (e, s) {
      debugPrint('Angkasa/beli: $e');
      debugPrintStack(stackTrace: s);
      return HasilBeli.gagal;
    }
  }

  @override
  Future<List<PembelianDaring>> pulihkan() async {
    if (!_siap) return const [];

    final terkumpul = <PembelianDaring>[];
    final selesai = Completer<void>();
    final langganan = _masuk.stream.listen((p) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        terkumpul.add(
          PembelianDaring(
            produkId: p.productID,
            waktu: DateTime.tryParse(p.transactionDate ?? '') ?? DateTime.now(),
            orderId: p.purchaseID,
            terverifikasi: p.verificationData.serverVerificationData.isNotEmpty,
          ),
        );
      }
    });

    try {
      await _toko.restorePurchases();
      // Play mengirim pembelian lama satu per satu tanpa penanda
      // "sudah habis". Jendela pendek ini yang menampungnya; kalau ada
      // yang datang terlambat, ia tetap masuk lewat aliran dan
      // tersimpan pada pembukaan aplikasi berikutnya.
      await Future.any([
        selesai.future,
        Future<void>.delayed(const Duration(seconds: 4)),
      ]);
    } catch (e, s) {
      debugPrint('Angkasa/beli: gagal memulihkan — $e');
      debugPrintStack(stackTrace: s);
    } finally {
      await langganan.cancel();
    }
    return terkumpul;
  }

  @override
  Future<void> tutup() async {
    await _aliran?.cancel();
    await _masuk.close();
    _siap = false;
  }
}
