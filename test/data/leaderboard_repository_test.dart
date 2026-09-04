import 'dart:io';

import 'package:angkasa/data/local/dao/league_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/repositories/leaderboard_repository.dart';
import 'package:angkasa/domain/engine/aturan_nilai.dart';
import 'package:angkasa/domain/engine/liga_rules.dart';
import 'package:angkasa/domain/models/liga.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/gateway_tiruan.dart';

void main() {
  late Database db;
  late LeaderboardRepository papan;
  late LeagueDao leagueDao;
  late ProfileDao profileDao;
  late ProgressDao progressDao;
  late GatewayTiruan gateway;

  final rabu = DateTime(2026, 9, 2, 10);
  final weekId = LigaRules.idMinggu(rabu);

  EntriLiga lawan(String uid, int xp, {int liga = 1}) => EntriLiga(
    uid: uid,
    nickname: uid,
    avatarId: 'bintang',
    xp: xp,
    liga: liga,
    diperbarui: rabu,
  );

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    leagueDao = LeagueDao(db);
    profileDao = ProfileDao(db);
    progressDao = ProgressDao(db);
    gateway = GatewayTiruan();
    papan = LeaderboardRepository(
      leagueDao: leagueDao,
      profileDao: profileDao,
      progressDao: progressDao,
      gateway: gateway,
    );

    final p = await profileDao.ambil();
    await profileDao.simpan(
      p.copyWith(nickname: 'RoketUji', activeGradeId: 'grade-1'),
    );
    await leagueDao.simpan(weekId: weekId, liga: 1);
  });

  tearDown(() => db.close());

  group('kapan papan tertutup', () {
    test('build luring — dan kalimatnya bukan pesan kesalahan', () async {
      gateway.tersedia = false;
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.bisaTampil, isFalse);
      expect(hasil.tertutup, PapanTertutup.luring);
    });

    test('dimatikan orang tua', () async {
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(leaderboardOn: false));
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.tertutup, PapanTertutup.dimatikanOrangTua);
    });

    test('dimatikan dari jauh lewat Remote Config', () async {
      final dimatikan = LeaderboardRepository(
        leagueDao: leagueDao,
        profileDao: profileDao,
        progressDao: progressDao,
        gateway: gateway,
        aturan: () => const AturanNilai(papanPeringkatAktif: false),
      );
      final hasil = await dimatikan.papanSekarang(waktu: rabu);
      expect(hasil.tertutup, PapanTertutup.dimatikanPengembang);
    });

    test('belum punya nama panggilan', () async {
      final p = await profileDao.ambil();
      await profileDao.simpan(p.copyWith(nickname: ''));
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.tertutup, PapanTertutup.belumPunyaNama);
    });

    test('belum main minggu ini — bukan disalahkan ke jaringan', () async {
      await leagueDao.hapusSemua();
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.tertutup, PapanTertutup.belumMainMingguIni);
    });

    test('server gagal dibaca tidak melempar ke layar', () async {
      gateway.galatBaca = StateError('putus di tengah jalan');
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.tertutup, PapanTertutup.tidakAdaSinyal);
    });
  });

  group('papan yang terbuka', () {
    setUp(() {
      gateway.isiPapan(weekId, [
        lawan('juara', 340),
        lawan('kedua', 280),
        lawan('uid-uji', 210),
        lawan('liga-lain', 999, liga: 2),
      ]);
    });

    test('cuma memuat liga sendiri, bukan semua pemain', () async {
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.bisaTampil, isTrue);
      expect(
        hasil.papan!.entri.map((e) => e.uid),
        isNot(contains('liga-lain')),
      );
      expect(hasil.papan!.jumlahPemain, 3);
    });

    test('sudah urut, dan tahu di mana anak ini berdiri', () async {
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.papan!.entri.first.uid, 'juara');
      expect(hasil.papan!.peringkatSaya, 3);
    });

    test('sisa hari ikut dihitung untuk pil di pojok', () async {
      final hasil = await papan.papanSekarang(waktu: rabu);
      expect(hasil.sisaHari, 5);
    });
  });

  group('menyalin peringkat ke HP', () {
    test('membaca papan menyimpan peringkat minggu ini', () async {
      gateway.isiPapan(weekId, [lawan('juara', 340), lawan('uid-uji', 210)]);
      await progressDao.catatHarian(tanggal: rabu, xp: 210, posSelesai: 19);

      await papan.papanSekarang(waktu: rabu);

      final catatan = await leagueDao.minggu(weekId);
      expect(catatan?.peringkat, 2);
      expect(catatan?.pemain, 2);
      expect(catatan?.xp, 210);
      expect(catatan?.posSelesai, 19);
    });

    test('anak yang belum punya baris tidak menimpa catatan lama', () async {
      gateway.isiPapan(weekId, [lawan('juara', 340)]);
      await papan.papanSekarang(waktu: rabu);
      expect((await leagueDao.minggu(weekId))?.peringkat, 0);
    });
  });

  group('hasil akhir minggu', () {
    test('minggu lalu yang belum dilihat dipulangkan sekali', () async {
      await leagueDao.simpan(
        weekId: '2026-W35',
        liga: 1,
        peringkat: 7,
        pemain: 30,
        xp: 210,
        posSelesai: 19,
      );

      final r = await papan.ringkasanBelumDilihat(waktu: rabu);
      expect(r, isNotNull);
      expect(r!.peringkat, 7);
      expect(r.pemain, 30);

      await papan.tandaiSudahDilihat(r.weekId);
      expect(await papan.ringkasanBelumDilihat(waktu: rabu), isNull);
    });

    test('pergerakan dihitung dari minggu berperingkat sebelumnya', () async {
      await leagueDao.simpan(weekId: '2026-W34', liga: 1, peringkat: 11);
      await leagueDao.simpan(weekId: '2026-W35', liga: 1, peringkat: 7);

      final r = await papan.ringkasanBelumDilihat(waktu: rabu);
      expect(r!.peringkatSebelumnya, 11);
      expect(r.pergerakan, 4);
      expect(
        LigaRules.kalimatPergerakan(
          sekarang: r.peringkat,
          sebelumnya: r.peringkatSebelumnya,
        ),
        'Naik 4 posisi dari minggu lalu.',
      );
    });

    test(
      'minggu yang sedang berjalan tidak pernah dianggap sudah selesai',
      () async {
        await leagueDao.simpan(weekId: weekId, liga: 1, peringkat: 3);
        expect(await papan.ringkasanBelumDilihat(waktu: rabu), isNull);
      },
    );

    test('anak baru tidak dapat layar akhir minggu yang kosong', () async {
      expect(await papan.ringkasanBelumDilihat(waktu: rabu), isNull);
    });
  });
}
