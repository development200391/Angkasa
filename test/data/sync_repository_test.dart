import 'dart:io';

import 'package:angkasa/core/services/connectivity_service.dart';
import 'package:angkasa/data/local/dao/badge_dao.dart';
import 'package:angkasa/data/local/dao/league_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/dao/sync_queue_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/repositories/sync_repository.dart';
import 'package:angkasa/domain/engine/aturan_nilai.dart';
import 'package:angkasa/domain/engine/liga_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/gateway_tiruan.dart';

/// Antrean sinkron di atas basis data sungguhan.
///
/// Yang diperiksa di sini bukan Firestore, tapi janji yang dibuat
/// antreannya: menggabungkan dirinya sendiri, tidak pernah menyentuh
/// kuota tanpa izin, dan tidak pernah menahan satu pun bintang.
void main() {
  late Database db;
  late SyncRepository sinkron;
  late SyncQueueDao antrean;
  late ProfileDao profileDao;
  late ProgressDao progressDao;
  late LeagueDao leagueDao;
  late GatewayTiruan gateway;
  late KoneksiTetap koneksi;

  final rabu = DateTime(2026, 9, 2, 10);
  final weekId = LigaRules.idMinggu(rabu);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    antrean = SyncQueueDao(db);
    profileDao = ProfileDao(db);
    progressDao = ProgressDao(db);
    leagueDao = LeagueDao(db);
    gateway = GatewayTiruan();
    koneksi = KoneksiTetap(JenisKoneksi.wifi);

    sinkron = SyncRepository(
      antreanDao: antrean,
      profileDao: profileDao,
      progressDao: progressDao,
      badgeDao: BadgeDao(db),
      leagueDao: leagueDao,
      gateway: gateway,
      koneksi: koneksi,
    );

    final p = await profileDao.ambil();
    await profileDao.simpan(
      p.copyWith(nickname: 'RoketUji', activeGradeId: 'grade-1'),
    );
  });

  tearDown(() async {
    sinkron.dispose();
    koneksi.dispose();
    await db.close();
  });

  group('antrean menggabungkan dirinya sendiri', () {
    test('sepuluh kali mengantre profil tetap menyisakan satu baris', () async {
      for (var i = 0; i < 10; i++) {
        await sinkron.antreProfil(waktu: rabu);
      }
      final isi = await antrean.menunggu();
      final profil = isi.where(
        (i) => i.entitas == SyncRepository.entitasProfil,
      );
      expect(profil.length, 1);
    });

    test('yang tersisa adalah keadaan terakhir, bukan yang pertama', () async {
      await sinkron.antreProfil(waktu: rabu);
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(totalXp: 999));
      await sinkron.antreProfil(waktu: rabu);

      final profil = (await antrean.menunggu()).firstWhere(
        (i) => i.entitas == SyncRepository.entitasProfil,
      );
      expect(profil.muatan['totalXp'], 999);
    });

    test('skor dua minggu berbeda tetap jadi dua baris', () async {
      await sinkron.antreProfil(waktu: rabu);
      await sinkron.antreProfil(waktu: rabu.add(const Duration(days: 7)));

      final skor = (await antrean.menunggu())
          .where((i) => i.entitas == SyncRepository.entitasSkor)
          .map((i) => i.kunci)
          .toSet();
      expect(skor.length, 2);
      expect(skor, contains(weekId));
    });

    test('anak yang belum punya nama tidak mengantre apa pun', () async {
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(nickname: ''));
      await sinkron.antreProfil(waktu: rabu);
      expect(await antrean.jumlah(), 0);
    });
  });

  group('kapan boleh mengirim', () {
    test('build luring tidak pernah mengirim, dan antreannya utuh', () async {
      gateway.tersedia = false;
      await sinkron.antreProfil(waktu: rabu);

      final hasil = await sinkron.kirimSekarang();
      expect(hasil.tertahan, AlasanTertahan.luring);
      expect(hasil.terkirim, 0);
      expect(await antrean.jumlah(), greaterThan(0));
    });

    test('tanpa sinyal, antreannya menunggu — tidak dibuang', () async {
      koneksi.ubah(JenisKoneksi.tidakAda);
      await sinkron.antreProfil(waktu: rabu);

      final hasil = await sinkron.kirimSekarang();
      expect(hasil.tertahan, AlasanTertahan.tidakAdaSinyal);
      expect(hasil.menunggu, greaterThan(0));
    });

    test('data seluler ditahan selama orang tua belum mengizinkan', () async {
      koneksi.ubah(JenisKoneksi.seluler);
      await sinkron.antreProfil(waktu: rabu);

      expect(
        (await sinkron.kirimSekarang()).tertahan,
        AlasanTertahan.menungguWifi,
      );

      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(syncCellular: true));
      final lagi = await sinkron.kirimSekarang();
      expect(lagi.tertahan, isNull);
      expect(lagi.terkirim, greaterThan(0));
    });

    test('"Kirim sekarang" mengabaikan syarat Wi-Fi', () async {
      koneksi.ubah(JenisKoneksi.seluler);
      await sinkron.antreProfil(waktu: rabu);
      final hasil = await sinkron.kirimSekarang(paksa: true);
      expect(hasil.terkirim, greaterThan(0));
    });

    test('Wi-Fi mengosongkan antrean sampai habis', () async {
      await sinkron.antreProfil(waktu: rabu);
      await sinkron.antreCadangan(waktu: rabu);

      final hasil = await sinkron.kirimSekarang();
      expect(hasil.menunggu, 0);
      expect(hasil.bersih, isTrue);
      expect(gateway.profil, isNotEmpty);
      expect(gateway.cadangan, isNotEmpty);
    });
  });

  group('papan peringkat bisa ditolak orang tua', () {
    test('mati sejak awal berarti skornya tidak pernah mengantre', () async {
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(leaderboardOn: false));
      await sinkron.antreProfil(waktu: rabu);

      final jenis = (await antrean.menunggu()).map((i) => i.entitas).toSet();
      expect(jenis, isNot(contains(SyncRepository.entitasSkor)));
      expect(jenis, contains(SyncRepository.entitasProfil));
    });

    test('dimatikan setelah mengantre pun kirimannya batal', () async {
      await sinkron.antreProfil(waktu: rabu);
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(leaderboardOn: false));

      await sinkron.kirimSekarang();
      expect(gateway.tulisSkorDipanggil, 0);
      expect(gateway.profil, isNotEmpty, reason: 'profil tetap terkirim');
    });
  });

  group('pembagian liga', () {
    test('mendaftar sekali, lalu nomornya disimpan di HP', () async {
      await sinkron.antreProfil(waktu: rabu);
      await sinkron.kirimSekarang();

      final catatan = await leagueDao.minggu(weekId);
      expect(catatan?.liga, 1);

      final entri = gateway.entri[weekId]!.values.first;
      expect(entri.liga, 1);
      expect(entri.nickname, 'RoketUji');
    });

    test('minggu berikutnya mendaftar lagi', () async {
      await sinkron.antreProfil(waktu: rabu);
      await sinkron.kirimSekarang();

      final depan = rabu.add(const Duration(days: 7));
      await sinkron.antreProfil(waktu: depan);
      await sinkron.kirimSekarang();

      expect(await leagueDao.minggu(LigaRules.idMinggu(depan)), isNotNull);
    });

    test('liga penuh membuka liga berikutnya', () async {
      // Ukuran dipaksa dua lewat Remote Config tiruan.
      final kecil = SyncRepository(
        antreanDao: antrean,
        profileDao: profileDao,
        progressDao: progressDao,
        badgeDao: BadgeDao(db),
        leagueDao: leagueDao,
        gateway: gateway,
        koneksi: koneksi,
        aturan: () => const AturanNilai(ukuranLiga: 2),
      );
      addTearDown(kecil.dispose);

      expect(await kecil.ligaUntukMinggu('2026-W40'), 1);
      expect(await kecil.ligaUntukMinggu('2026-W41'), 1);
      expect(await kecil.ligaUntukMinggu('2026-W42'), 2);
    });
  });

  group('kegagalan', () {
    test('yang gagal tetap mengantre dan dicoba lagi', () async {
      gateway.galatTulis = StateError('server menolak');
      await sinkron.antreProfil(waktu: rabu);

      final hasil = await sinkron.kirimSekarang();
      expect(hasil.gagal, greaterThan(0));
      expect(hasil.menunggu, greaterThan(0));

      gateway.galatTulis = null;
      final lagi = await sinkron.kirimSekarang();
      expect(lagi.menunggu, 0);
    });

    test(
      'yang selalu gagal akhirnya menyerah, tidak selamanya dicoba',
      () async {
        gateway.galatTulis = StateError('muatan ditolak aturan keamanan');
        await sinkron.antreProfil(waktu: rabu);

        for (var i = 0; i < SyncQueueDao.maksPercobaan; i++) {
          await sinkron.kirimSekarang();
        }
        expect(await antrean.jumlah(), 0);
        expect(gateway.galatTercatat, isNotEmpty, reason: 'dicatat sekali');
      },
    );
  });

  test(
    'waktu sinkron terakhir dicatat hanya kalau ada yang terkirim',
    () async {
      expect((await profileDao.ambil()).lastSyncAt, isNull);

      koneksi.ubah(JenisKoneksi.tidakAda);
      await sinkron.antreProfil(waktu: rabu);
      await sinkron.kirimSekarang();
      expect((await profileDao.ambil()).lastSyncAt, isNull);

      koneksi.ubah(JenisKoneksi.wifi);
      await sinkron.kirimSekarang();
      expect((await profileDao.ambil()).lastSyncAt, isNotNull);
    },
  );

  test(
    'XP mingguan dihitung dari Senin, bukan dari total seumur main',
    () async {
      // XP minggu lalu tidak boleh ikut terbawa ke papan minggu ini.
      await progressDao.catatHarian(
        tanggal: rabu.subtract(const Duration(days: 8)),
        xp: 500,
      );
      await progressDao.catatHarian(tanggal: rabu, xp: 40);

      await sinkron.antreProfil(waktu: rabu);
      final profil = (await antrean.menunggu()).firstWhere(
        (i) => i.entitas == SyncRepository.entitasProfil,
      );
      expect(profil.muatan['weeklyXp'], 40);
    },
  );
}
