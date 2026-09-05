import 'dart:io';

import 'package:angkasa/data/local/dao/attempt_dao.dart';
import 'package:angkasa/data/local/dao/badge_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/repositories/badge_repository.dart';
import 'package:angkasa/data/repositories/practice_repository.dart';
import 'package:angkasa/data/repositories/progress_repository.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/question.dart';
import 'package:angkasa/domain/models/quiz_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Alur retensi Tahap 2 di atas basis data sungguhan.
///
/// Yang diperiksa bukan SQL-nya, tapi janjinya: latihan tidak pernah
/// menyentuh bintang, soal keluar dari daftar perbaikan setelah benar
/// dua kali berturut-turut, Tantangan Harian cuma sekali sehari, dan
/// streak ikut naik dari latihan.
void main() {
  late Database db;
  late PracticeRepository practice;
  late ProgressRepository progres;
  late ProgressDao progressDao;
  late ProfileDao profileDao;
  late AttemptDao attemptDao;
  late LevelDao levelDao;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    levelDao = LevelDao(db);
    progressDao = ProgressDao(db);
    profileDao = ProfileDao(db);
    attemptDao = AttemptDao(db);
    final badge = BadgeRepository(
      badgeDao: BadgeDao(db),
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: profileDao,
      attemptDao: attemptDao,
    );
    progres = ProgressRepository(
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: profileDao,
      attemptDao: attemptDao,
      badgeRepository: badge,
    );
    practice = PracticeRepository(
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: profileDao,
      attemptDao: attemptDao,
      progressRepository: progres,
      badgeRepository: badge,
    );

    // Anak sudah memilih Planet Mula dan membuka pos pertama.
    final profil = await profileDao.ambil();
    await profileDao.simpan(
      profil.copyWith(nickname: 'Uji', activeGradeId: 'grade-1'),
    );
  });

  tearDown(() => db.close());

  Question soal(String signature) => Question(
    signature: signature,
    format: QuestionFormat.pilihanGanda,
    prompt: signature,
    answer: '22',
    options: const [
      AnswerOption(label: '12', mistake: MistakeKind.lupaMenyimpan),
      AnswerOption(label: '22', isCorrect: true),
    ],
    operation: Operation.tambah,
    left: 17,
    right: 5,
    result: 22,
  );

  AnsweredQuestion jawab(String signature, {required bool benar}) =>
      AnsweredQuestion(
        question: soal(signature),
        given: benar ? '22' : '12',
        isCorrect: benar,
      );

  test(
    'latihan cepat membangkitkan soal dari zona yang sudah dibuka',
    () async {
      final soal = await practice.latihanCepat();
      expect(soal.length, 10);
      expect(
        soal.every((s) => s.format == QuestionFormat.pilihanGanda),
        isTrue,
      );
      expect(soal.every((s) => s.visualAid == VisualAid.tidakAda), isTrue);
    },
  );

  test('planet tanpa pos terbuka tidak memaksa soal muncul', () async {
    // Dulu uji ini memakai grade-3 karena planetnya memang kosong.
    // Sejak Tahap 4 seluruh planet berisi, jadi keadaan yang diuji
    // harus dibuat sengaja: planet yang punya pos tapi belum satu pun
    // terbuka. Latihan Cepat mengambil dari materi yang **sudah
    // dilewati**; menariknya dari pos yang belum dibuka berarti
    // menyodorkan soal yang belum pernah diajarkan.
    final profil = await profileDao.ambil();
    await profileDao.simpan(profil.copyWith(activeGradeId: 'grade-4'));
    await db.update(
      'level_progress',
      {'is_unlocked': 0},
      where: 'level_id LIKE ?',
      whereArgs: ['l-4-%'],
    );
    expect(await practice.latihanCepat(), isEmpty);
  });

  test('latihan tidak pernah menyentuh bintang di lintasan', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    await progres.simpanSesi(
      level: pos1,
      hasil: const QuizResult(
        levelId: 'l-1-1-1',
        correct: 10,
        total: 10,
        stars: 3,
        xpEarned: 0,
        durationSeconds: 60,
      ),
    );

    await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: false)],
      detik: 30,
    );

    final peta = await progres.peta('grade-1');
    expect(peta.levelDari('l-1-1-1')!.stars, 3);
    expect(peta.totalStars, 3);
  });

  test(
    'soal keluar dari daftar setelah benar dua kali berturut-turut',
    () async {
      await practice.simpanSesi(
        mode: PracticeMode.latihanCepat,
        jawaban: [jawab('17+5=?', benar: false)],
        detik: 10,
      );
      expect((await practice.daftarSalah()).length, 1);

      await practice.simpanSesi(
        mode: PracticeMode.perbaikiKesalahan,
        jawaban: [jawab('17+5=?', benar: true)],
        detik: 10,
      );
      expect((await practice.daftarSalah()).length, 1, reason: 'baru sekali');

      await practice.simpanSesi(
        mode: PracticeMode.perbaikiKesalahan,
        jawaban: [jawab('17+5=?', benar: true)],
        detik: 10,
      );
      expect(await practice.daftarSalah(), isEmpty);
      expect(await attemptDao.jumlahDiperbaiki(), 1);
    },
  );

  test('salah lagi mengembalikan soal ke daftar', () async {
    for (final benar in [false, true, true]) {
      await practice.simpanSesi(
        mode: PracticeMode.perbaikiKesalahan,
        jawaban: [jawab('17+5=?', benar: benar)],
        detik: 5,
      );
    }
    expect(await practice.daftarSalah(), isEmpty);

    await practice.simpanSesi(
      mode: PracticeMode.perbaikiKesalahan,
      jawaban: [jawab('17+5=?', benar: false)],
      detik: 5,
    );
    expect((await practice.daftarSalah()).length, 1);
  });

  test('mode perbaiki merakit ulang soal dari tanda tangannya', () async {
    await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: false)],
      detik: 10,
    );
    final soal = await practice.perbaikiKesalahan();
    expect(soal.length, 1);
    expect(soal.first.signature, '17+5=?');
    expect(soal.first.answer, '22');
  });

  test(
    'Tantangan Harian: set yang sama sepanjang hari, beda esok hari',
    () async {
      final hariIni = DateTime(2026, 9, 2);
      final a = await practice.tantanganHarian(hariIni: hariIni);
      final b = await practice.tantanganHarian(hariIni: hariIni);
      final besok = await practice.tantanganHarian(
        hariIni: hariIni.add(const Duration(days: 1)),
      );

      expect(a.map((s) => s.signature), b.map((s) => s.signature));
      expect(
        a.map((s) => s.signature).join(),
        isNot(besok.map((s) => s.signature).join()),
      );
    },
  );

  test('Tantangan Harian: XP dobel cuma untuk set pertama hari itu', () async {
    final hariIni = DateTime(2026, 9, 2, 10);
    final pertama = await practice.simpanSesi(
      mode: PracticeMode.tantanganHarian,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 60,
      waktu: hariIni,
    );
    expect(pertama.xp, 20);
    expect(await practice.tantanganSudahSelesai(hariIni: hariIni), isTrue);

    final kedua = await practice.simpanSesi(
      mode: PracticeMode.tantanganHarian,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 60,
      waktu: hariIni.add(const Duration(hours: 2)),
    );
    expect(kedua.xp, 0);
  });

  test('Kilat 60 menyimpan rekor terbaik saja', () async {
    final pertama = await practice.simpanSesi(
      mode: PracticeMode.kilat60,
      jawaban: [for (var i = 0; i < 9; i++) jawab('$i+1=?', benar: true)],
      detik: 60,
    );
    expect(pertama.rekorBaru, isTrue);
    expect(pertama.xp, 3);
    expect((await profileDao.ambil()).blitzBest, 9);

    final kedua = await practice.simpanSesi(
      mode: PracticeMode.kilat60,
      jawaban: [jawab('1+1=?', benar: true)],
      detik: 60,
    );
    expect(kedua.rekorBaru, isFalse);
    expect((await profileDao.ambil()).blitzBest, 9);
  });

  test('latihan ikut menjaga streak', () async {
    final senin = DateTime(2026, 8, 31, 9);
    await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 40,
      waktu: senin,
    );
    expect((await profileDao.ambil()).streakCount, 1);

    final selasa = senin.add(const Duration(days: 1));
    final hasil = await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 40,
      waktu: selasa,
    );
    expect(hasil.streak, 2);
    expect((await profileDao.ambil()).streakBest, 2);
  });

  test('hari yang bolong ditambal pelindung mingguan', () async {
    final senin = DateTime(2026, 8, 31, 9);
    await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 40,
      waktu: senin,
    );
    // Selasa absen, Rabu main lagi.
    final rabu = senin.add(const Duration(days: 2));
    final hasil = await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: true)],
      detik: 40,
      waktu: rabu,
    );
    expect(hasil.pelindungTerpakai, isTrue);
    expect(hasil.streak, 2);
  });

  test('ringkasan tab Latihan menghitung yang menunggu dan rekornya', () async {
    await practice.simpanSesi(
      mode: PracticeMode.latihanCepat,
      jawaban: [jawab('17+5=?', benar: false), jawab('28+6=?', benar: false)],
      detik: 30,
    );
    final r = await practice.ringkasan();
    expect(r.menunggu, 2);
    expect(r.tantanganSelesai, isFalse);
    expect(r.rekorKilat, 0);
  });

  test('lencana pertama terbuka dari latihan, dan tidak dobel', () async {
    final hasil = await practice.simpanSesi(
      mode: PracticeMode.kilat60,
      jawaban: [for (var i = 0; i < 31; i++) jawab('$i+1=?', benar: true)],
      detik: 60,
    );
    expect(hasil.lencanaBaru, contains('kilat_30'));

    final lagi = await practice.simpanSesi(
      mode: PracticeMode.kilat60,
      jawaban: [jawab('1+1=?', benar: true)],
      detik: 60,
    );
    expect(lagi.lencanaBaru, isNot(contains('kilat_30')));
  });

  test('jam pengingat dipelajari dari jam menjawab soal', () async {
    // Belum cukup data: belum ada yang bisa disebut kebiasaan.
    expect(await attemptDao.jamPalingSering(), isNull);

    for (var i = 0; i < 25; i++) {
      await practice.simpanSesi(
        mode: PracticeMode.latihanCepat,
        jawaban: [jawab('$i+1=?', benar: true)],
        detik: 10,
        waktu: DateTime(2026, 9, 2, 19, 30),
      );
    }
    expect(await attemptDao.jamPalingSering(), 19);
  });
}
