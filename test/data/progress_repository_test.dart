import 'dart:io';

import 'package:angkasa/data/local/dao/attempt_dao.dart';
import 'package:angkasa/data/local/dao/badge_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/repositories/badge_repository.dart';
import 'package:angkasa/data/repositories/profile_repository.dart';
import 'package:angkasa/data/repositories/progress_repository.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/question.dart';
import 'package:angkasa/domain/models/quiz_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Uji alur simpan-sesi dari ujung ke ujung, di atas basis data sungguhan
/// (SQLite in-memory) dengan konten seed yang sungguhan juga.
///
/// Yang diperiksa bukan SQL-nya, tapi janji produknya: bintang tidak
/// pernah turun, pos berikutnya benar-benar terbuka, dan tiap jawaban
/// salah benar-benar tercatat beserta nama kesalahannya.
void main() {
  late Database db;
  late ProgressRepository repo;
  late LevelDao levelDao;
  late ProgressDao progressDao;
  late AttemptDao attemptDao;
  late BadgeRepository badgeRepo;

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
    attemptDao = AttemptDao(db);
    badgeRepo = BadgeRepository(
      badgeDao: BadgeDao(db),
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: ProfileDao(db),
      attemptDao: attemptDao,
    );
    repo = ProgressRepository(
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: ProfileDao(db),
      attemptDao: attemptDao,
      badgeRepository: badgeRepo,
    );
  });

  tearDown(() => db.close());

  QuizResult hasil({
    required String levelId,
    required int benar,
    int total = 10,
    List<AnsweredQuestion> jawaban = const [],
  }) => QuizResult(
    levelId: levelId,
    correct: benar,
    total: total,
    stars: benar == total
        ? 3
        : benar >= 8
        ? 2
        : benar >= 6
        ? 1
        : 0,
    xpEarned: 0,
    durationSeconds: 120,
    answers: jawaban,
  );

  test('seed mengisi dua planet berisi dan enam planet terdaftar', () async {
    final planets = await levelDao.semuaGrade();
    expect(planets.length, 6);
    expect(planets.where((g) => g.isUnlocked).length, 2);
    expect(await levelDao.jumlahPos('grade-1'), 36);
    expect(await levelDao.jumlahPos('grade-2'), 42);
  });

  test('hanya pos pertama zona pertama yang terbuka di awal', () async {
    final peta = await repo.peta('grade-1');
    final terbuka = peta.chapters
        .expand((c) => c.levels)
        .where((l) => !l.isLocked)
        .toList();
    expect(terbuka.length, 1);
    expect(terbuka.single.level.id, 'l-1-1-1');
  });

  test('lulus satu pos membuka pos berikutnya dan menambah XP', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    final tersimpan = await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 9),
    );

    expect(tersimpan.stars, 2);
    expect(tersimpan.xpEarned, 10);
    expect(tersimpan.unlockedLevelIds, contains('l-1-1-2'));

    final peta = await repo.peta('grade-1');
    expect(peta.levelDari('l-1-1-2')!.isLocked, isFalse);
    expect(peta.totalStars, 2);
  });

  test('bintang tidak pernah turun waktu pos diulang', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 10),
    );
    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 6),
    );

    final progres = await progressDao.untukLevel(pos1.id);
    expect(progres!.stars, 3);
    expect(progres.attempts, 2);
  });

  test('mengulang pos yang sudah lulus cuma dapat 2 XP', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 8),
    );
    final kedua = await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 10),
    );
    expect(kedua.xpEarned, 2);
  });

  test('belum lulus tidak membuka apa pun', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    final tersimpan = await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 4),
    );
    expect(tersimpan.stars, 0);
    expect(tersimpan.unlockedLevelIds, isEmpty);
    expect((await repo.peta('grade-1')).levelDari('l-1-1-2')!.isLocked, isTrue);
  });

  test('Gerbang Planet baru terbuka setelah lima pos biasa lulus', () async {
    for (var i = 1; i <= 5; i++) {
      final pos = (await levelDao.level('l-1-1-$i'))!;
      final tersimpan = await repo.simpanSesi(
        level: pos,
        hasil: hasil(levelId: pos.id, benar: 10),
      );
      if (i < 5) {
        expect(tersimpan.unlockedLevelIds, isNot(contains('l-1-1-6')));
      } else {
        expect(tersimpan.unlockedLevelIds, contains('l-1-1-6'));
      }
    }
  });

  test('gerbang lulus 80% membuka zona berikutnya', () async {
    for (var i = 1; i <= 5; i++) {
      final pos = (await levelDao.level('l-1-1-$i'))!;
      await repo.simpanSesi(
        level: pos,
        hasil: hasil(levelId: pos.id, benar: 10),
      );
    }
    final gerbang = (await levelDao.level('l-1-1-6'))!;
    final tersimpan = await repo.simpanSesi(
      level: gerbang,
      hasil: hasil(levelId: gerbang.id, benar: 12, total: 15),
    );

    expect(tersimpan.xpEarned, 30);
    expect(tersimpan.unlockedNextChapter, isTrue);
    expect(
      (await repo.peta('grade-1')).levelDari('l-1-2-1')!.isLocked,
      isFalse,
    );
  });

  test('gerbang di bawah 80% tidak membuka zona berikutnya', () async {
    for (var i = 1; i <= 5; i++) {
      final pos = (await levelDao.level('l-1-1-$i'))!;
      await repo.simpanSesi(
        level: pos,
        hasil: hasil(levelId: pos.id, benar: 10),
      );
    }
    final gerbang = (await levelDao.level('l-1-1-6'))!;
    final tersimpan = await repo.simpanSesi(
      level: gerbang,
      hasil: hasil(levelId: gerbang.id, benar: 11, total: 15),
    );
    expect(tersimpan.unlockedNextChapter, isFalse);
    expect((await repo.peta('grade-1')).levelDari('l-1-2-1')!.isLocked, isTrue);
  });

  test('tiap jawaban salah tercatat beserta nama kesalahannya', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    const soal = Question(
      signature: '17+5=?',
      format: QuestionFormat.pilihanGanda,
      prompt: '17 + 5 = ?',
      answer: '22',
      options: [
        AnswerOption(label: '12', mistake: MistakeKind.lupaMenyimpan),
        AnswerOption(label: '22', isCorrect: true),
      ],
      operation: Operation.tambah,
      left: 17,
      right: 5,
      result: 22,
    );

    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(
        levelId: pos1.id,
        benar: 9,
        jawaban: const [
          AnsweredQuestion(question: soal, given: '12', isCorrect: false),
        ],
      ),
    );

    expect(await attemptDao.jumlahSalah(), 1);
    expect(
      (await attemptDao.menunggu()).map((s) => s.signature),
      contains('17+5=?'),
    );
    expect(await attemptDao.ringkasanKesalahan(), {
      MistakeKind.lupaMenyimpan: 1,
    });
  });

  test('reset progres mengembalikan lintasan ke pintu masuknya', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 10),
    );
    await repo.resetProgres();

    final peta = await repo.peta('grade-1');
    expect(peta.totalStars, 0);
    expect(peta.levelDari('l-1-1-1')!.isLocked, isFalse);
    expect(peta.levelDari('l-1-1-2')!.isLocked, isTrue);
    expect(await attemptDao.jumlahSalah(), 0);
  });

  test('ganti planet tidak menghapus progres planet lama', () async {
    final pos1 = (await levelDao.level('l-1-1-1'))!;
    await repo.simpanSesi(
      level: pos1,
      hasil: hasil(levelId: pos1.id, benar: 10),
    );

    final profil = ProfileRepository(ProfileDao(db));
    await profil.gantiPlanet('grade-2');
    expect((await profil.ambil()).activeGradeId, 'grade-2');

    // Bintang di planet lama menunggu di sana, tidak ikut pindah.
    expect((await repo.peta('grade-1')).totalStars, 3);
    expect((await repo.peta('grade-2')).totalStars, 0);
  });

  test('tes penempatan menandai zona sebelumnya selesai', () async {
    await repo.terapkanPenempatan(
      gradeId: 'grade-1',
      chapterIdBenar: ['c-1-1', 'c-1-2', 'c-1-3'],
    );

    final peta = await repo.peta('grade-1');
    expect(peta.zonaDari('c-1-1')!.selesai, 6);
    expect(peta.zonaDari('c-1-2')!.selesai, 6);
    expect(peta.zonaDari('c-1-3')!.selesai, 0);
    expect(peta.levelDari('l-1-3-1')!.isLocked, isFalse);
  });
}
