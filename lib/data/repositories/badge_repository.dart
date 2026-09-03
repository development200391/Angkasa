import '../../domain/engine/badge_rules.dart';
import '../../domain/models/badge.dart';
import '../local/dao/attempt_dao.dart';
import '../local/dao/badge_dao.dart';
import '../local/dao/level_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';

/// Menilai ulang seluruh katalog lencana dari keadaan sekarang.
///
/// Tidak ada satu pun penghitung khusus lencana di basis data: semuanya
/// dihitung ulang dari `level_progress`, `question_attempts`,
/// `daily_activity`, dan `user_profile`. Kalau syarat sebuah lencana
/// suatu hari diperbaiki, tidak ada yang perlu dimigrasikan — cukup
/// dinilai lagi.
class BadgeRepository {
  BadgeRepository({
    required BadgeDao badgeDao,
    required LevelDao levelDao,
    required ProgressDao progressDao,
    required ProfileDao profileDao,
    required AttemptDao attemptDao,
  }) : _badge = badgeDao,
       _level = levelDao,
       _progress = progressDao,
       _profile = profileDao,
       _attempt = attemptDao;

  final BadgeDao _badge;
  final LevelDao _level;
  final ProgressDao _progress;
  final ProfileDao _profile;
  final AttemptDao _attempt;

  Future<List<EarnedBadge>> semua() => _badge.semua();

  Future<Set<String>> kode() => _badge.kode();

  Future<BadgeContext> keadaan() async {
    final progres = await _progress.semua();
    final profil = await _profile.ambil();

    var posSelesai = 0;
    var tigaBintang = 0;
    var bintang = 0;
    for (final p in progres.values) {
      if (p.stars > 0) posSelesai++;
      if (p.stars == 3) tigaBintang++;
      bintang += p.stars;
    }

    var zonaTuntas = 0;
    var planetTuntas = 0;
    var gerbangSempurna = 0;
    for (final g in await _level.semuaGrade()) {
      final zona = await _level.chapters(g.id);
      if (zona.isEmpty) continue;
      var tuntasDiPlanet = 0;
      for (final z in zona) {
        final pos = await _level.levels(z.id);
        final gerbang = pos.where((l) => l.isBoss).toList();
        if (gerbang.isEmpty) continue;
        final lulus = gerbang.every((l) => (progres[l.id]?.stars ?? 0) > 0);
        if (lulus) {
          zonaTuntas++;
          tuntasDiPlanet++;
        }
        for (final l in gerbang) {
          if ((progres[l.id]?.stars ?? 0) == 3) gerbangSempurna++;
        }
      }
      if (tuntasDiPlanet == zona.length) planetTuntas++;
    }

    return BadgeContext(
      posSelesai: posSelesai,
      posTigaBintang: tigaBintang,
      totalBintang: bintang,
      zonaTuntas: zonaTuntas,
      planetTuntas: planetTuntas,
      gerbangSempurna: gerbangSempurna,
      streakSekarang: profil.streakCount,
      streakTerbaik: profil.streakBest,
      soalDiperbaiki: await _attempt.jumlahDiperbaiki(),
      kilatTerbaik: profil.blitzBest,
      tantanganSelesai: await _progress.jumlahTantangan(),
      soalLatihan: await _attempt.jumlahSoalLatihan(),
      totalXp: profil.totalXp,
    );
  }

  /// Lencana yang baru saja terpenuhi, sudah tersimpan. Dipanggil
  /// sesudah tiap sesi — layar hasil tinggal menampilkan yang kembali.
  Future<List<BadgeDef>> nilaiUlang({DateTime? waktu}) async {
    final baru = BadgeRules.baru(await keadaan(), await _badge.kode());
    if (baru.isEmpty) return const [];
    await _badge.simpan(baru.map((b) => b.code), waktu ?? DateTime.now());
    return baru;
  }

  Future<void> hapusSemua() => _badge.hapusSemua();
}
