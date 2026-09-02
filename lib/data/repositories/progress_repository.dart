import '../../domain/engine/star_calculator.dart';
import '../../domain/engine/unlock_rules.dart';
import '../../domain/models/level.dart';
import '../../domain/models/level_progress.dart';
import '../../domain/models/level_view.dart';
import '../../domain/models/question_attempt.dart';
import '../../domain/models/quiz_result.dart';
import '../local/dao/attempt_dao.dart';
import '../local/dao/level_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';

/// Semua yang berhubungan dengan **kemajuan anak**: bintang, XP, dan
/// pos apa saja yang terbuka.
///
/// Di sinilah keempat aturan unlock benar-benar dijalankan; layar cuma
/// menampilkan hasilnya.
class ProgressRepository {
  ProgressRepository({
    required LevelDao levelDao,
    required ProgressDao progressDao,
    required ProfileDao profileDao,
    required AttemptDao attemptDao,
  }) : _level = levelDao,
       _progress = progressDao,
       _profile = profileDao,
       _attempt = attemptDao;

  final LevelDao _level;
  final ProgressDao _progress;
  final ProfileDao _profile;
  final AttemptDao _attempt;

  /// Seluruh isi satu planet beserta progresnya — sekali baca untuk
  /// seluruh layar Jelajah.
  Future<PetaPlanet> peta(String gradeId) async {
    final grade = await _level.grade(gradeId);
    final zonaList = await _level.chapters(gradeId);
    final progres = await _progress.semua();

    final chapters = <ChapterView>[];
    var bintang = 0;
    for (final z in zonaList) {
      final posList = await _level.levels(z.id);
      final views = [
        for (final p in posList)
          LevelView(
            level: p,
            progress: progres[p.id] ?? LevelProgress(levelId: p.id),
          ),
      ];
      bintang += views.fold(0, (a, v) => a + v.stars);
      chapters.add(ChapterView(chapter: z, levels: views));
    }

    return PetaPlanet(
      grade:
          grade ??
          (throw StateError('Planet $gradeId tidak ada di basis data')),
      chapters: chapters,
      totalStars: bintang,
    );
  }

  /// Menyimpan satu sesi: bintang, XP, aturan unlock, catatan harian,
  /// dan tiap soal yang dijawab.
  ///
  /// Urutannya penting — bintang dulu, baru unlock, karena aturan 2
  /// membaca bintang pos yang barusan selesai.
  Future<QuizResult> simpanSesi({
    required Level level,
    required QuizResult hasil,
    DateTime? waktu,
  }) async {
    final sekarang = waktu ?? DateTime.now();
    final sebelum = await _progress.untukLevel(level.id);
    final sudahPernahLulus = (sebelum?.stars ?? 0) > 0;

    await _progress.simpanHasil(
      levelId: level.id,
      stars: hasil.stars,
      score: hasil.correct,
      waktu: sekarang,
    );

    await _attempt.catat([
      for (final a in hasil.answers)
        QuestionAttempt(
          levelId: level.id,
          questionSignature: a.question.signature,
          isCorrect: a.isCorrect,
          timeMs: a.timeMs,
          answeredAt: sekarang,
          mistake: a.isCorrect ? null : a.question.mistakeOf(a.given),
        ),
    ]);

    final xp = StarCalculator.xp(
      level: level,
      stars: hasil.stars,
      sudahPernahLulus: sudahPernahLulus,
    );
    if (xp > 0) await _profile.tambahXp(xp);

    await _progress.catatHarian(
      tanggal: sekarang,
      xp: xp,
      posSelesai: hasil.isPassed && !sudahPernahLulus ? 1 : 0,
      detik: hasil.durationSeconds,
    );

    final terbuka = await _terapkanUnlock(level: level, hasil: hasil);

    return hasil.copyWith(
      xpEarned: xp,
      isNewBest: hasil.stars > (sebelum?.stars ?? 0),
      unlockedLevelIds: terbuka.levelIds,
      unlockedNextChapter: terbuka.chapterIds.isNotEmpty,
    );
  }

  Future<UnlockOutcome> _terapkanUnlock({
    required Level level,
    required QuizResult hasil,
  }) async {
    final progres = await _progress.semua();
    final sezona = await _level.levels(level.chapterId);

    // Aturan 1 dan 2.
    final dariPos = UnlockRules.setelahPos(
      selesai: level,
      stars: hasil.stars,
      levelsZona: sezona,
      progres: progres,
    );
    await _progress.buka(dariPos.levelIds);
    if (!level.isBoss) return dariPos;

    // Aturan 3 dan 4 — hanya setelah Gerbang Planet.
    final zona = await _level.chapter(level.chapterId);
    if (zona == null) return dariPos;

    final semuaZona = await _level.chapters(zona.gradeId);
    final pertamaZona = <String, String>{};
    final zonaSelesai = <String>{};
    for (final z in semuaZona) {
      final posList = await _level.levels(z.id);
      if (posList.isNotEmpty) pertamaZona[z.id] = posList.first.id;
      final gerbang = posList.where((l) => l.isBoss);
      if (gerbang.isNotEmpty &&
          gerbang.every((g) => (progres[g.id]?.stars ?? 0) > 0)) {
        zonaSelesai.add(z.id);
      }
    }

    final semuaPlanet = await _level.semuaGrade();
    final i = semuaPlanet.indexWhere((g) => g.id == zona.gradeId);
    final berikutnya = (i >= 0 && i + 1 < semuaPlanet.length)
        ? semuaPlanet[i + 1].id
        : null;

    final dariGerbang = UnlockRules.setelahGerbang(
      zona: zona,
      benar: hasil.correct,
      total: hasil.total,
      chaptersPlanet: semuaZona,
      levelPertamaZona: pertamaZona,
      zonaSelesai: zonaSelesai,
      gradeBerikutnyaId: berikutnya,
    );
    await _progress.buka(dariGerbang.levelIds);
    for (final g in dariGerbang.gradeIds) {
      await _level.bukaGrade(g);
    }

    return UnlockOutcome(
      levelIds: [...dariPos.levelIds, ...dariGerbang.levelIds],
      chapterIds: dariGerbang.chapterIds,
      gradeIds: dariGerbang.gradeIds,
    );
  }

  /// Hasil tes penempatan: zona sebelum yang terakhir dijawab benar
  /// ditandai selesai, dan pos pertama sesudahnya dibuka.
  Future<void> terapkanPenempatan({
    required String gradeId,
    required List<String> chapterIdBenar,
  }) async {
    if (chapterIdBenar.isEmpty) return;
    final zona = await _level.chapters(gradeId);
    final indeksTerjauh = zona.lastIndexWhere(
      (z) => chapterIdBenar.contains(z.id),
    );
    if (indeksTerjauh < 0) return;

    final selesai = <String>[];
    for (var i = 0; i < indeksTerjauh; i++) {
      final posList = await _level.levels(zona[i].id);
      selesai.addAll(posList.map((l) => l.id));
    }
    await _progress.tandaiSelesai(selesai);

    final posBerikut = await _level.levels(zona[indeksTerjauh].id);
    if (posBerikut.isNotEmpty) await _progress.buka([posBerikut.first.id]);
  }

  /// Menghapus seluruh progres, lalu membuka lagi pos pertama tiap
  /// planet — kalau tidak, anak kembali ke lintasan yang seluruhnya
  /// digembok dan tidak ada satu pun pintu masuk.
  Future<void> resetProgres() async {
    await _progress.hapusSemua();
    await _attempt.hapusSemua();
    for (final g in await _level.semuaGrade()) {
      final zona = await _level.chapters(g.id);
      if (zona.isEmpty) continue;
      final posList = await _level.levels(zona.first.id);
      if (posList.isNotEmpty) await _progress.buka([posList.first.id]);
    }
  }
}
