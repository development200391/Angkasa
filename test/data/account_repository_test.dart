import 'dart:io';

import 'package:angkasa/core/services/connectivity_service.dart';
import 'package:angkasa/data/local/dao/badge_dao.dart';
import 'package:angkasa/data/local/dao/league_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/dao/sync_queue_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/remote/remote_models.dart';
import 'package:angkasa/data/repositories/account_repository.dart';
import 'package:angkasa/data/repositories/sync_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../support/gateway_tiruan.dart';

void main() {
  late Database db;
  late AccountRepository akun;
  late SyncRepository sinkron;
  late ProfileDao profileDao;
  late ProgressDao progressDao;
  late BadgeDao badgeDao;
  late SyncQueueDao antrean;
  late GatewayTiruan gateway;
  late KoneksiTetap koneksi;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    profileDao = ProfileDao(db);
    progressDao = ProgressDao(db);
    badgeDao = BadgeDao(db);
    antrean = SyncQueueDao(db);
    gateway = GatewayTiruan();
    koneksi = KoneksiTetap(JenisKoneksi.wifi);

    sinkron = SyncRepository(
      antreanDao: antrean,
      profileDao: profileDao,
      progressDao: progressDao,
      badgeDao: badgeDao,
      leagueDao: LeagueDao(db),
      gateway: gateway,
      koneksi: koneksi,
    );
    akun = AccountRepository(
      profileDao: profileDao,
      progressDao: progressDao,
      levelDao: LevelDao(db),
      badgeDao: badgeDao,
      antreanDao: antrean,
      gateway: gateway,
      sinkron: sinkron,
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

  group('nama panggilan', () {
    test('yang lolos disimpan dan ikut mengantre', () async {
      final hasil = await akun.gantiNama('BintangKecil');
      expect(hasil.boleh, isTrue);
      expect((await profileDao.ambil()).nickname, 'BintangKecil');
      expect(await antrean.jumlah(), greaterThan(0));
    });

    test('yang ditolak tidak menyentuh apa pun', () async {
      final hasil = await akun.gantiNama('Rafa081234567');
      expect(hasil.boleh, isFalse);
      expect(hasil.alasan, isNotNull);
      expect((await profileDao.ambil()).nickname, 'RoketUji');
      expect(await antrean.jumlah(), 0);
    });
  });

  group('menyalakan cadangan', () {
    test('masuk anonim, lalu menyalin progres dan lencana', () async {
      await progressDao.simpanHasil(
        levelId: 'l-1-1-1',
        stars: 3,
        score: 10,
        waktu: DateTime(2026, 9, 2),
      );
      await badgeDao.simpan(['pos_pertama'], DateTime(2026, 9, 2));

      expect(await akun.nyalakanCadangan(), isTrue);

      final tersimpan = gateway.cadangan['uid-uji']!;
      expect(tersimpan.pos['l-1-1-1'], '3,10');
      expect(tersimpan.lencana, contains('pos_pertama'));
      expect((await profileDao.ambil()).firebaseUid, 'uid-uji');
    });

    test('build luring tidak berpura-pura berhasil', () async {
      gateway.tersedia = false;
      expect(await akun.nyalakanCadangan(), isFalse);
      expect(gateway.cadangan, isEmpty);
    });
  });

  group('menautkan akun Google', () {
    test('yang berhasil menyimpan surelnya dan mempertahankan uid', () async {
      // Inti seluruh fitur ini: uid-nya **tidak berubah**. Kalau berubah,
      // cadangan yang sudah ada di server jadi milik akun yang tidak
      // akan pernah dijangkau lagi dari HP mana pun.
      await akun.nyalakanCadangan();
      expect((await profileDao.ambil()).firebaseUid, 'uid-uji');

      gateway.tautan = const TautanAkun(
        HasilTaut.berhasil,
        akun: AkunDaring(uid: 'uid-uji', email: 'ortu@contoh.com'),
      );

      expect(await akun.tautkanGoogle(), HasilTaut.berhasil);
      final p = await profileDao.ambil();
      expect(p.firebaseUid, 'uid-uji');
      expect(p.accountEmail, 'ortu@contoh.com');
      expect(p.akunAnonim, isFalse);
    });

    test('yang dibatalkan tidak mengubah apa pun', () async {
      await akun.nyalakanCadangan();
      gateway.tautan = const TautanAkun(HasilTaut.dibatalkan);

      expect(await akun.tautkanGoogle(), HasilTaut.dibatalkan);
      final p = await profileDao.ambil();
      expect(p.accountEmail, isNull);
      expect(p.akunAnonim, isTrue);
    });

    test(
      'akun yang sudah dipakai HP lain tidak menimpa progres apa pun',
      () async {
        // Keadaan yang paling menentukan. Progres di HP ini harus utuh
        // sampai orang tua memilih di layar Pulihkan progres — mengirim
        // di sini berarti menghapus progres HP lama tanpa seorang pun
        // pernah menyetujuinya.
        await progressDao.simpanHasil(
          levelId: 'l-1-1-1',
          stars: 3,
          score: 10,
          waktu: DateTime(2026, 9, 2),
        );
        gateway.tautan = const TautanAkun(
          HasilTaut.sudahDipakaiAkunLain,
          akun: AkunDaring(uid: 'uid-hp-lama', email: 'ortu@contoh.com'),
        );

        expect(await akun.tautkanGoogle(), HasilTaut.sudahDipakaiAkunLain);

        // Akunnya berpindah, progresnya tidak.
        final p = await profileDao.ambil();
        expect(p.firebaseUid, 'uid-hp-lama');
        expect(p.accountEmail, 'ortu@contoh.com');
        expect((await progressDao.semua())['l-1-1-1']?.stars, 3);
        expect(gateway.cadangan['uid-hp-lama'], isNull);
      },
    );

    test(
      'gateway yang melempar dilaporkan sebagai gagal, bukan meledak',
      () async {
        gateway.galatTulis = StateError('sambungan putus');
        gateway.tautan = const TautanAkun(HasilTaut.berhasil);

        expect(await akun.tautkanGoogle(), HasilTaut.berhasil);
        expect((await profileDao.ambil()).accountEmail, isNull);
      },
    );

    test('build luring tidak pernah menawarkan tombolnya', () async {
      gateway.tersedia = false;
      gateway.bisaMasukGoogle = true;
      expect((await akun.keadaan()).bisaMasukGoogle, isFalse);
    });
  });

  group('dua progres', () {
    Future<void> siapkanKeduanya() async {
      await progressDao.simpanHasil(
        levelId: 'l-1-1-1',
        stars: 2,
        score: 8,
        waktu: DateTime(2026, 9, 2),
      );
      gateway.profil['uid-uji'] = ProfilDaring(
        nickname: 'AstroLama',
        avatarId: 'bintang',
        gradeLevel: 'grade-2',
        totalXp: 890,
        streakCount: 12,
        weeklyXp: 120,
        lastSyncAt: DateTime(2026, 8, 12),
        platform: 'android',
      );
      gateway.cadangan['uid-uji'] = CadanganProgres(
        pos: const {'l-1-1-1': '3,10', 'l-1-1-2': '1,6'},
        lencana: const ['pos_pertama', 'streak_3'],
        diperbarui: DateTime(2026, 8, 12),
      );
    }

    test('layarnya cuma muncul kalau dua-duanya berisi', () async {
      expect(await akun.pilihanPemulihan(), isNull, reason: 'akun kosong');

      await siapkanKeduanya();
      final pilihan = await akun.pilihanPemulihan();
      expect(pilihan, isNotNull);
      expect(pilihan!.diHpIni.posSelesai, 1);
      expect(pilihan.diAkun.posSelesai, 2);
      expect(pilihan.diAkun.totalXp, 890);
    });

    test('HP kosong tidak dianggap keputusan yang harus diambil', () async {
      gateway.profil['uid-uji'] = ProfilDaring(
        nickname: 'AstroLama',
        avatarId: 'bintang',
        gradeLevel: 'grade-2',
        totalXp: 890,
        streakCount: 12,
        weeklyXp: 0,
        lastSyncAt: DateTime(2026, 8, 12),
        platform: 'android',
      );
      gateway.cadangan['uid-uji'] = CadanganProgres(
        pos: const {'l-1-1-1': '3,10'},
        lencana: const [],
        diperbarui: DateTime(2026, 8, 12),
      );
      expect(await akun.pilihanPemulihan(), isNull);
    });

    test('memilih akun menimpa progres di HP sampai habis', () async {
      await siapkanKeduanya();
      expect(await akun.pulihkanDariAkun(), isTrue);

      final progres = await progressDao.semua();
      expect(progres['l-1-1-1']!.stars, 3);
      expect(progres['l-1-1-2']!.stars, 1);

      final profil = await profileDao.ambil();
      expect(profil.nickname, 'AstroLama');
      expect(profil.totalXp, 890);
      expect(profil.activeGradeId, 'grade-2');
      expect(await badgeDao.kode(), {'pos_pertama', 'streak_3'});
    });

    test(
      'pos yang tidak ada di pemasangan ini dibuang, bukan melempar',
      () async {
        gateway.profil['uid-uji'] = ProfilDaring(
          nickname: 'AstroLama',
          avatarId: 'bintang',
          gradeLevel: 'grade-1',
          totalXp: 10,
          streakCount: 0,
          weeklyXp: 0,
          lastSyncAt: DateTime(2026, 8, 12),
          platform: 'android',
        );
        gateway.cadangan['uid-uji'] = CadanganProgres(
          // Pos dari Planet Kali, yang baru datang di Tahap 4.
          pos: const {'l-1-1-1': '2,9', 'l-3-9-9': '3,10'},
          lencana: const [],
          diperbarui: DateTime(2026, 8, 12),
        );

        expect(await akun.pulihkanDariAkun(), isTrue);
        final progres = await progressDao.semua();
        expect(progres.containsKey('l-1-1-1'), isTrue);
        expect(progres.containsKey('l-3-9-9'), isFalse);
      },
    );

    test('memilih HP ini mengirim ulang isinya ke server', () async {
      await siapkanKeduanya();
      expect(await akun.pertahankanYangDiHp(), isTrue);
      expect(gateway.cadangan['uid-uji']!.pos['l-1-1-1'], '2,8');
      expect(gateway.profil['uid-uji']!.nickname, 'RoketUji');
    });
  });

  group('hapus data di server', () {
    test('server dikosongkan, HP tidak disentuh sama sekali', () async {
      await progressDao.simpanHasil(
        levelId: 'l-1-1-1',
        stars: 3,
        score: 10,
        waktu: DateTime(2026, 9, 2),
      );
      await badgeDao.simpan(['pos_pertama'], DateTime(2026, 9, 2));
      await akun.nyalakanCadangan();
      expect(gateway.cadangan, isNotEmpty);

      await akun.hapusDataServer();

      expect(gateway.profil, isEmpty);
      expect(gateway.cadangan, isEmpty);
      expect(await antrean.jumlah(), 0);

      // Yang di HP tetap utuh — itu persis yang dijanjikan tulisan
      // tombolnya.
      expect((await progressDao.semua())['l-1-1-1']!.stars, 3);
      expect(await badgeDao.kode(), {'pos_pertama'});

      final profil = await profileDao.ambil();
      expect(profil.leaderboardOn, isFalse);
      expect(profil.firebaseUid, isNull);
      expect(profil.totalXp, isNot(-1));
    });
  });

  group('keadaan akun', () {
    test('luring disebut luring, bukan galat', () async {
      gateway.tersedia = false;
      final k = await akun.keadaan();
      expect(k.tersambung, isFalse);
      expect(k.bisaMasukGoogle, isFalse);
    });

    test('menghitung yang mengantre', () async {
      await sinkron.antreProfil(waktu: DateTime(2026, 9, 2));
      expect((await akun.keadaan()).menunggu, greaterThan(0));
    });
  });

  group('daftar Data yang dikirim', () {
    test('tiap field dokumen pengguna punya barisnya di layar', () {
      // Ini uji yang paling sering diremehkan dan paling mahal kalau
      // terlewat: layar Data yang dikirim harus sama persis dengan
      // deklarasi Data safety di Play Console.
      const dikirim = ProfilDaring.fieldnya;
      final peta = ProfilDaring(
        nickname: '',
        avatarId: '',
        gradeLevel: null,
        totalXp: 0,
        streakCount: 0,
        weeklyXp: 0,
        lastSyncAt: DateTime(2026, 1, 1),
        platform: '',
      ).sebagaiPeta;
      expect(peta.keys.toSet(), dikirim.toSet());
    });

    test('dua daftar di layar tidak pernah kosong dan tidak beririsan', () {
      expect(AccountRepository.yangDikirim, isNotEmpty);
      expect(AccountRepository.tidakPernahDikirim, isNotEmpty);
      expect(
        AccountRepository.yangDikirim.toSet().intersection(
          AccountRepository.tidakPernahDikirim.toSet(),
        ),
        isEmpty,
      );
    });

    test('jawaban tiap soal disebut lugas sebagai yang tidak dikirim', () {
      expect(
        AccountRepository.tidakPernahDikirim.join(' ').toLowerCase(),
        contains('jawaban'),
      );
      expect(
        AccountRepository.tidakPernahDikirim.join(' ').toLowerCase(),
        contains('id iklan'),
      );
    });
  });
}
