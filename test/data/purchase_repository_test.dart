import 'dart:io';

import 'package:angkasa/data/local/dao/entitlement_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/remote/purchase_gateway.dart';
import 'package:angkasa/data/repositories/purchase_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/toko_tiruan.dart';

/// Hak beli, di atas basis data sungguhan.
///
/// Yang diperiksa di sini bukan Play Billing — itu tidak bisa diuji
/// tanpa toko. Yang dijaga dua janji yang, kalau dilanggar, langsung
/// merugikan orang yang sudah membayar:
///
/// **Membayar tidak pernah jadi syarat belajar.** Planet Mula dan Puluh
/// terbuka penuh selamanya, apa pun keadaan toko.
///
/// **Kegagalan toko tidak pernah mencabut hak.** Play yang tidak bisa
/// dihubungi tidak boleh membuat planet yang sudah dibeli terkunci lagi.
void main() {
  late Database db;
  late PurchaseRepository beli;
  late EntitlementDao hakDao;
  late TokoTiruan toko;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    hakDao = EntitlementDao(db);
    toko = TokoTiruan();
    beli = PurchaseRepository(
      hakDao: hakDao,
      levelDao: LevelDao(db),
      gateway: toko,
    );
  });

  tearDown(() => db.close());

  group('membayar tidak pernah jadi syarat belajar', () {
    test('dua planet pertama terbuka walau belum dibeli', () async {
      expect(await beli.bolehDibuka('grade-1'), isTrue);
      expect(await beli.bolehDibuka('grade-2'), isTrue);
    });

    test('dua planet pertama tetap terbuka walau tokonya mati', () async {
      toko.tersedia = false;
      toko.galat = StateError('Play tidak bisa dihubungi');
      expect(await beli.bolehDibuka('grade-1'), isTrue);
      expect(await beli.bolehDibuka('grade-2'), isTrue);
    });

    test('empat planet berikutnya terkunci sebelum dibeli', () async {
      for (final id in ['grade-3', 'grade-4', 'grade-5', 'grade-6']) {
        expect(await beli.bolehDibuka(id), isFalse, reason: id);
      }
    });
  });

  group('membeli', () {
    test('yang berhasil membuka keempatnya dan tersimpan di HP', () async {
      expect(await beli.beli(), HasilBeli.berhasil);

      for (final id in ['grade-3', 'grade-4', 'grade-5', 'grade-6']) {
        expect(await beli.bolehDibuka(id), isTrue, reason: id);
      }
      final hak = await hakDao.ambil(PurchaseRepository.kodeProduk);
      expect(hak, isNotNull);
      expect(hak!.sumber, 'play');
    });

    test('yang dibatalkan tidak menyimpan apa pun', () async {
      toko.hasilBeli = HasilBeli.dibatalkan;
      expect(await beli.beli(), HasilBeli.dibatalkan);
      expect(await beli.sudahBeli(), isFalse);
    });

    test('yang tertunda belum membuka — tapi juga bukan gagal', () async {
      // Pembayaran lewat transfer atau gerai. Membukanya sekarang
      // berarti memberikan barang sebelum dibayar; menyebutnya gagal
      // membuat orang tua membayar dua kali.
      toko.hasilBeli = HasilBeli.tertunda;
      expect(await beli.beli(), HasilBeli.tertunda);
      expect(await beli.sudahBeli(), isFalse);
    });

    test('toko yang melempar dijawab gagal, bukan meledak', () async {
      toko.galat = StateError('sambungan putus');
      expect(await beli.beli(), HasilBeli.gagal);
      expect(await beli.sudahBeli(), isFalse);
    });
  });

  group('memulihkan', () {
    test('pembelian di akun toko dipulihkan beserta nomor pesanannya', () async {
      toko.riwayat = [
        PembelianDaring(
          produkId: PurchaseRepository.kodeProduk,
          waktu: DateTime(2026, 5, 1),
          orderId: 'GPA.1234',
          terverifikasi: true,
        ),
      ];

      expect(await beli.pulihkan(), isTrue);
      final hak = await hakDao.ambil(PurchaseRepository.kodeProduk);
      expect(hak!.orderId, 'GPA.1234');
      expect(hak.sumber, 'pemulihan');
      expect(hak.terverifikasi, isTrue);
    });

    test('akun tanpa pembelian dijawab apa adanya', () async {
      expect(await beli.pulihkan(), isFalse);
    });

    test('toko yang melempar tidak mencabut hak yang sudah ada', () async {
      // Inti janji kedua. Orang tua yang sudah membayar lalu membuka
      // aplikasi di tempat tanpa sinyal tidak boleh menemukan
      // planetnya terkunci lagi.
      await beli.beli();
      expect(await beli.sudahBeli(), isTrue);

      toko.galat = StateError('jaringan mati');
      expect(await beli.pulihkan(), isTrue);
      expect(await beli.bolehDibuka('grade-5'), isTrue);
    });

    test('pembelian produk lain diabaikan', () async {
      toko.riwayat = [
        PembelianDaring(produkId: 'produk_lain', waktu: DateTime(2026, 5, 1)),
      ];
      expect(await beli.pulihkan(), isFalse);
    });
  });

  group('layar Galaksi', () {
    test('enam planet, empat terkunci sebelum dibeli', () async {
      final g = await beli.galaksi();
      expect(g.planet.length, 6);
      expect(g.terbuka, 2);
      expect(g.sudahBeli, isFalse);
    });

    test('jumlah pos berbayar dihitung dari isinya, bukan diketik', () async {
      // Angka yang diketik di layar penjualan akan basi pada penambahan
      // pos pertama — dan janji yang meleset di layar berbayar adalah
      // jenis kesalahan yang paling mahal.
      final g = await beli.galaksi();
      expect(g.posBerbayar, 172);
    });

    test('harga datang dari toko, tidak pernah dari kode', () async {
      toko.harga = 'Rp 55.000';
      expect((await beli.galaksi()).produk?.harga, 'Rp 55.000');
    });

    test('produk yang belum aktif di Play tidak dikarang harganya', () async {
      // Layarnya menyembunyikan tombol beli alih-alih menampilkan angka
      // yang berbeda dari lembar pembayaran.
      toko.produkAda = false;
      final g = await beli.galaksi();
      expect(g.produk, isNull);
      expect(g.tokoAda, isTrue);
    });

    test('sesudah dibeli, harganya tidak ditanyakan lagi', () async {
      await beli.beli();
      final g = await beli.galaksi();
      expect(g.sudahBeli, isTrue);
      expect(g.produk, isNull);
      expect(g.terbuka, 6);
    });

    test('build tanpa toko tetap menampilkan keenam planetnya', () async {
      // Isinya tetap bisa dinilai orang tua walau pembeliannya tidak
      // tersedia — itu seluruh guna layar ini.
      toko.tersedia = false;
      final g = await beli.galaksi();
      expect(g.planet.length, 6);
      expect(g.tokoAda, isFalse);
      expect(g.planet.where((p) => p.jumlahPos > 0).length, 6);
    });
  });
}
