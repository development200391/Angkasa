import 'dart:math';

import '../../domain/engine/difficulty_config.dart';
import '../../domain/engine/question_generator.dart';
import '../../domain/engine/star_calculator.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/question.dart';
import '../../domain/models/question_attempt.dart';
import '../../domain/models/quiz_result.dart';
import '../local/dao/attempt_dao.dart';
import '../local/dao/level_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';
import 'badge_repository.dart';
import 'progress_repository.dart';

/// Isi tab Latihan hari ini.
class PracticeSummary {
  const PracticeSummary({
    required this.menunggu,
    required this.tantanganSelesai,
    required this.rekorKilat,
  });

  /// Soal yang menunggu diperbaiki — angka merah di tab Latihan.
  final int menunggu;

  final bool tantanganSelesai;
  final int rekorKilat;
}

/// Hasil satu sesi latihan bebas.
class PracticeOutcome {
  const PracticeOutcome({
    required this.mode,
    required this.benar,
    required this.total,
    required this.xp,
    required this.streak,
    required this.pelindungTerpakai,
    required this.rekorBaru,
    this.lencanaBaru = const [],
  });

  final PracticeMode mode;
  final int benar;
  final int total;
  final int xp;
  final int streak;
  final bool pelindungTerpakai;

  /// Rekor Kilat 60 Detik terpecahkan.
  final bool rekorBaru;
  final List<String> lencanaBaru;
}

/// Empat mode latihan bebas.
///
/// **Tidak satu pun menyentuh `level_progress`.** Bintang di lintasan
/// tidak bisa naik maupun turun dari sini, dan itu yang membuat anak
/// berani mencoba: latihan adalah tempat yang aman untuk salah.
///
/// Semuanya berdiri di atas data Tahap 1 — `difficulty_config` untuk
/// membangkitkan soal, `question_attempts` untuk tahu apa yang pernah
/// salah, `daily_activity` untuk tahu hari ini sudah main atau belum.
class PracticeRepository {
  PracticeRepository({
    required LevelDao levelDao,
    required ProgressDao progressDao,
    required ProfileDao profileDao,
    required AttemptDao attemptDao,
    required ProgressRepository progressRepository,
    required BadgeRepository badgeRepository,
    QuestionGenerator? generator,
  }) : _level = levelDao,
       _progress = progressDao,
       _profile = profileDao,
       _attempt = attemptDao,
       _progressRepo = progressRepository,
       _badge = badgeRepository,
       _generator = generator ?? QuestionGenerator();

  final LevelDao _level;
  final ProgressDao _progress;
  final ProfileDao _profile;
  final AttemptDao _attempt;
  final ProgressRepository _progressRepo;
  final BadgeRepository _badge;
  final QuestionGenerator _generator;

  Future<PracticeSummary> ringkasan({DateTime? hariIni}) async {
    final profil = await _profile.ambil();
    final hari = await _progress.hari(hariIni ?? DateTime.now());
    return PracticeSummary(
      menunggu: (await _attempt.menunggu()).length,
      tantanganSelesai: hari?.challengeDone ?? false,
      rekorKilat: profil.blitzBest,
    );
  }

  // ------------------------------------------------------- Latihan Cepat
  /// Soal acak dari zona yang **sudah dibuka** saja. Latihan tidak
  /// pernah memperkenalkan materi yang belum pernah dilihat anak.
  Future<List<Question>> latihanCepat({
    int jumlah = 10,
    Random? acak,
    QuestionGenerator? generator,
  }) async {
    final config = await _configTerbuka();
    if (config.isEmpty) return const [];
    final r = acak ?? Random();
    final gen = generator ?? _generator;
    final soal = <Question>[];
    final dipakai = <String>{};
    var putaran = 0;
    while (soal.length < jumlah && putaran < jumlah * 40) {
      putaran++;
      final c = config[r.nextInt(config.length)];
      final q = gen.single(_untukLatihan(c));
      if (!dipakai.add(q.signature)) continue;
      soal.add(q);
    }
    return soal;
  }

  // -------------------------------------------------- Perbaiki Kesalahan
  Future<List<SoalSalah>> daftarSalah() => _attempt.menunggu();

  /// Soal dibangun ulang dari tanda tangannya. Tidak ada satu pun soal
  /// yang disimpan — modenya nyaris gratis, dan itu memang alasannya
  /// dikerjakan lebih dulu di antara delapan layar Tahap 2.
  Future<List<Question>> perbaikiKesalahan({int jumlah = 10}) async {
    final menunggu = await _attempt.menunggu();
    final soal = <Question>[];
    for (final s in menunggu) {
      final q = _generator.dariSignature(s.signature);
      if (q != null) soal.add(q);
      if (soal.length >= jumlah) break;
    }
    return soal;
  }

  // -------------------------------------------------- Tantangan Harian
  /// Set hari ini. Sama untuk seluruh hari itu karena **acak maupun
  /// generatornya** diberi benih dari tanggalnya — kalau cuma pemilihan
  /// posnya yang dibenihi, angkanya tetap berubah tiap kali dibuka dan
  /// anak bisa mengulang sampai dapat set yang gampang.
  Future<List<Question>> tantanganHarian({DateTime? hariIni}) async {
    final t = hariIni ?? DateTime.now();
    final benih = t.year * 10000 + t.month * 100 + t.day;
    return latihanCepat(
      acak: Random(benih),
      generator: QuestionGenerator(random: Random(benih)),
    );
  }

  Future<bool> tantanganSudahSelesai({DateTime? hariIni}) async =>
      (await _progress.hari(hariIni ?? DateTime.now()))?.challengeDone ?? false;

  // -------------------------------------------------- Kilat 60 Detik
  /// Soal untuk satu ronde kilat. Dibuat berlebih di depan supaya tidak
  /// ada jeda membangkitkan soal di tengah hitungan mundur.
  Future<List<Question>> soalKilat({int jumlah = 60}) async {
    final config = await _configTerbuka();
    if (config.isEmpty) return const [];
    final r = Random();
    return [
      for (var i = 0; i < jumlah; i++)
        _generator.single(_untukLatihan(config[r.nextInt(config.length)])),
    ];
  }

  // ------------------------------------------------------------ simpan
  Future<PracticeOutcome> simpanSesi({
    required PracticeMode mode,
    required List<AnsweredQuestion> jawaban,
    required int detik,
    DateTime? waktu,
  }) async {
    final sekarang = waktu ?? DateTime.now();
    final benar = jawaban.where((a) => a.isCorrect).length;

    await _attempt.catat([
      for (final a in jawaban)
        QuestionAttempt(
          levelId: mode.catatanId,
          questionSignature: a.question.signature,
          isCorrect: a.isCorrect,
          timeMs: a.timeMs,
          answeredAt: sekarang,
          mistake: a.isCorrect ? null : a.question.mistakeOf(a.given),
        ),
    ]);

    var xp = StarCalculator.xpLatihan(mode, benar);
    if (mode == PracticeMode.tantanganHarian) {
      // XP dobel cuma untuk set pertama hari itu; mengulangnya boleh,
      // tapi tidak menambah XP lagi.
      if (await tantanganSudahSelesai(hariIni: sekarang)) {
        xp = 0;
      } else {
        await _progress.tandaiTantangan(sekarang);
      }
    }

    var rekorBaru = false;
    if (mode == PracticeMode.kilat60) {
      final profil = await _profile.ambil();
      if (benar > profil.blitzBest) {
        await _profile.simpan(profil.copyWith(blitzBest: benar));
        rekorBaru = true;
      }
    }

    // Latihan ikut menjaga streak: satu sesi latihan hari ini sudah
    // cukup untuk menyebut hari itu aktif.
    final streak = await _progressRepo.catatAktivitas(
      xp: xp,
      detik: detik,
      hitungStreak: jawaban.isNotEmpty,
      waktu: sekarang,
    );

    final lencana = await _badge.nilaiUlang(waktu: sekarang);

    return PracticeOutcome(
      mode: mode,
      benar: benar,
      total: jawaban.length,
      xp: xp,
      streak: streak.streak,
      pelindungTerpakai: streak.pelindungTerpakai,
      rekorBaru: rekorBaru,
      lencanaBaru: [for (final b in lencana) b.code],
    );
  }

  // ----------------------------------------------------------- bantuan
  /// Konfigurasi dari semua pos yang sudah terbuka di planet aktif.
  Future<List<DifficultyConfig>> _configTerbuka() async {
    final profil = await _profile.ambil();
    final gradeId = profil.activeGradeId;
    if (gradeId == null) return const [];

    final progres = await _progress.semua();
    final hasil = <DifficultyConfig>[];
    for (final z in await _level.chapters(gradeId)) {
      for (final l in await _level.levels(z.id)) {
        if (l.isBoss) continue;
        if (!(progres[l.id]?.isUnlocked ?? false)) continue;
        hasil.add(l.difficultyConfig);
      }
    }
    return hasil;
  }

  /// Bentuk soal latihan selalu sama apa pun posnya: pilihan ganda empat
  /// opsi, tanpa bantuan visual dan tanpa timer sendiri. Latihan menguji
  /// yang sudah dipelajari, jadi perancahnya dilepas — dan mengetik di
  /// papan angka terlalu lambat untuk mode secepat Kilat 60.
  DifficultyConfig _untukLatihan(DifficultyConfig c) => c.copyWith(
    formats: const [QuestionFormat.pilihanGanda],
    optionCount: 4,
    visualAid: VisualAid.tidakAda,
    timeLimitSeconds: null,
  );
}
