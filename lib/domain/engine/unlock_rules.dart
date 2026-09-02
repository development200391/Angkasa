import '../models/chapter.dart';
import '../models/level.dart';
import '../models/level_progress.dart';

/// Apa saja yang terbuka setelah satu sesi selesai.
class UnlockOutcome {
  const UnlockOutcome({
    this.levelIds = const [],
    this.chapterIds = const [],
    this.gradeIds = const [],
  });

  /// Pos yang berubah dari terkunci jadi terbuka.
  final List<String> levelIds;

  /// Zona yang gerbangnya baru saja ditembus.
  final List<String> chapterIds;

  /// Planet berikutnya, kalau syarat 70% zona sudah terpenuhi.
  final List<String> gradeIds;

  bool get isEmpty =>
      levelIds.isEmpty && chapterIds.isEmpty && gradeIds.isEmpty;
}

/// Empat aturan unlock, ditulis persis seperti di README.
///
/// 1. **Pos berikutnya** terbuka kalau pos sekarang dapat ≥ 1 bintang.
/// 2. **Gerbang Planet** terbuka kalau semua pos di zona itu sudah lulus.
/// 3. **Zona berikutnya** terbuka kalau Gerbang Planet dijawab benar ≥ 80%.
/// 4. **Planet berikutnya** terbuka kalau ≥ 70% zona di planet sekarang
///    selesai — *atau* dipilih manual lewat menu Pilih Planet.
///
/// Aturan keempat yang menentukan aplikasinya dipakai atau tidak: anak
/// kelas 4 tidak akan mau mulai dari `2 + 3`, jadi planet selalu bisa
/// dipilih tangan lewat [pilihManual].
abstract final class UnlockRules {
  /// Ambang lulus Gerbang Planet: 12 dari 15.
  static const ambangGerbang = 0.8;

  /// Ambang buka planet berikutnya.
  static const ambangPlanet = 0.7;

  /// Aturan 1 dan 2 — dipakai setelah sebuah pos selesai dikerjakan.
  ///
  /// [levelsZona] harus sudah urut menurut `orderIndex`.
  static UnlockOutcome setelahPos({
    required Level selesai,
    required int stars,
    required List<Level> levelsZona,
    required Map<String, LevelProgress> progres,
  }) {
    if (stars <= 0) return const UnlockOutcome();

    final terbuka = <String>[];
    final urut = [...levelsZona]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final i = urut.indexWhere((l) => l.id == selesai.id);

    // Aturan 1 — pos berikutnya.
    if (i >= 0 && i + 1 < urut.length) {
      final berikutnya = urut[i + 1];
      if (!berikutnya.isBoss && !_terbuka(progres, berikutnya.id)) {
        terbuka.add(berikutnya.id);
      }
    }

    // Aturan 2 — Gerbang Planet, kalau semua pos biasa sudah lulus.
    final gerbang = urut.where((l) => l.isBoss);
    for (final g in gerbang) {
      if (_terbuka(progres, g.id)) continue;
      final semuaLulus = urut
          .where((l) => !l.isBoss)
          .every((l) => l.id == selesai.id || (progres[l.id]?.stars ?? 0) > 0);
      if (semuaLulus) terbuka.add(g.id);
    }

    return UnlockOutcome(levelIds: terbuka);
  }

  /// Aturan 3 dan 4 — dipakai setelah Gerbang Planet dikerjakan.
  ///
  /// [chaptersPlanet] harus sudah urut menurut `orderIndex`, dan
  /// [levelPertamaZona] memetakan id zona ke pos pertamanya.
  static UnlockOutcome setelahGerbang({
    required Chapter zona,
    required int benar,
    required int total,
    required List<Chapter> chaptersPlanet,
    required Map<String, String> levelPertamaZona,
    required Set<String> zonaSelesai,
    required String? gradeBerikutnyaId,
  }) {
    if (total <= 0 || benar / total < ambangGerbang) {
      return const UnlockOutcome();
    }

    final urut = [...chaptersPlanet]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final i = urut.indexWhere((c) => c.id == zona.id);

    final levelIds = <String>[];
    final chapterIds = <String>[];

    // Aturan 3 — zona berikutnya.
    if (i >= 0 && i + 1 < urut.length) {
      final berikutnya = urut[i + 1];
      chapterIds.add(berikutnya.id);
      final pos = levelPertamaZona[berikutnya.id];
      if (pos != null) levelIds.add(pos);
    }

    // Aturan 4 — planet berikutnya.
    final selesai = {...zonaSelesai, zona.id};
    final rasio = urut.isEmpty
        ? 0.0
        : urut.where((c) => selesai.contains(c.id)).length / urut.length;
    final gradeIds = <String>[
      if (rasio >= ambangPlanet && gradeBerikutnyaId != null) gradeBerikutnyaId,
    ];

    return UnlockOutcome(
      levelIds: levelIds,
      chapterIds: chapterIds,
      gradeIds: gradeIds,
    );
  }

  /// Aturan 4, jalur manual. Anak kelas 4 boleh langsung ke Planet Pecah
  /// sejak onboarding, dan boleh pindah kapan saja lewat Profil.
  static bool pilihManual() => true;

  /// Pos pertama sebuah zona selalu terbuka begitu zonanya terbuka —
  /// kalau tidak, anak melihat lintasan yang seluruhnya digembok.
  static bool posPertamaTerbuka(Level level) => level.orderIndex == 1;

  static bool _terbuka(Map<String, LevelProgress> progres, String levelId) =>
      progres[levelId]?.isUnlocked ?? false;
}
