import 'package:sqflite/sqflite.dart';

import '../../../domain/models/level_progress.dart';

/// Tulis-baca progres pos, dan catatan aktivitas harian.
class ProgressDao {
  ProgressDao(this._db);

  final Database _db;

  Future<Map<String, LevelProgress>> semua() async {
    final rows = await _db.query('level_progress');
    return {for (final r in rows) r['level_id']! as String: _dari(r)};
  }

  Future<LevelProgress?> untukLevel(String levelId) async {
    final rows = await _db.query(
      'level_progress',
      where: 'level_id = ?',
      whereArgs: [levelId],
      limit: 1,
    );
    return rows.isEmpty ? null : _dari(rows.first);
  }

  /// Simpan hasil satu sesi.
  ///
  /// Bintang disimpan yang **terbaik** dan tidak pernah turun —
  /// mengulang pos yang sudah bintang tiga tidak bisa merusak apa pun.
  Future<LevelProgress> simpanHasil({
    required String levelId,
    required int stars,
    required int score,
    required DateTime waktu,
  }) async {
    final lama = await untukLevel(levelId);
    final baru = LevelProgress(
      levelId: levelId,
      stars: stars > (lama?.stars ?? 0) ? stars : (lama?.stars ?? 0),
      bestScore: score > (lama?.bestScore ?? 0)
          ? score
          : (lama?.bestScore ?? 0),
      attempts: (lama?.attempts ?? 0) + 1,
      firstCompletedAt: lama?.firstCompletedAt ?? (stars > 0 ? waktu : null),
      lastPlayedAt: waktu,
      isUnlocked: true,
    );
    await _db.insert('level_progress', {
      'level_id': baru.levelId,
      'stars': baru.stars,
      'best_score': baru.bestScore,
      'attempts': baru.attempts,
      'first_completed_at': baru.firstCompletedAt?.toIso8601String(),
      'last_played_at': baru.lastPlayedAt?.toIso8601String(),
      'is_unlocked': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return baru;
  }

  Future<void> buka(Iterable<String> levelIds) async {
    if (levelIds.isEmpty) return;
    final batch = _db.batch();
    for (final id in levelIds) {
      batch.insert('level_progress', {
        'level_id': id,
        'is_unlocked': 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      batch.update(
        'level_progress',
        {'is_unlocked': 1},
        where: 'level_id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Menandai sekumpulan pos langsung selesai — dipakai hasil tes
  /// penempatan, supaya anak yang sudah bisa tidak dipaksa melewati dua
  /// puluh pos yang membosankan.
  Future<void> tandaiSelesai(Iterable<String> levelIds, {int stars = 1}) async {
    if (levelIds.isEmpty) return;
    final sekarang = DateTime.now().toIso8601String();
    final batch = _db.batch();
    for (final id in levelIds) {
      batch.insert('level_progress', {
        'level_id': id,
        'stars': stars,
        'best_score': 0,
        'attempts': 0,
        'first_completed_at': sekarang,
        'last_played_at': sekarang,
        'is_unlocked': 1,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> hapusSemua() => _db.delete('level_progress');

  // ------------------------------------------------------ harian
  /// Satu baris per tanggal. Tahap 2 membaca tabel ini untuk streak dan
  /// Tantangan Harian; di Tahap 1 tugasnya cuma mencatat.
  Future<void> catatHarian({
    required DateTime tanggal,
    int xp = 0,
    int posSelesai = 0,
    int detik = 0,
  }) async {
    final kunci = _tanggal(tanggal);
    await _db.insert('daily_activity', {
      'date': kunci,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await _db.rawUpdate(
      '''
      UPDATE daily_activity SET
        xp_earned = xp_earned + ?,
        levels_completed = levels_completed + ?,
        seconds_played = seconds_played + ?
      WHERE date = ?
      ''',
      [xp, posSelesai, detik, kunci],
    );
  }

  static String _tanggal(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static LevelProgress _dari(Map<String, Object?> r) => LevelProgress(
    levelId: r['level_id']! as String,
    stars: r['stars'] as int? ?? 0,
    bestScore: r['best_score'] as int? ?? 0,
    attempts: r['attempts'] as int? ?? 0,
    firstCompletedAt: _waktu(r['first_completed_at']),
    lastPlayedAt: _waktu(r['last_played_at']),
    isUnlocked: (r['is_unlocked'] as int? ?? 0) == 1,
  );

  static DateTime? _waktu(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}
