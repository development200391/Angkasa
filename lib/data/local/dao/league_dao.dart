import 'package:sqflite/sqflite.dart';

/// Catatan liga satu minggu, dilihat dari HP ini.
class CatatanMinggu {
  const CatatanMinggu({
    required this.weekId,
    this.liga = 0,
    this.peringkat = 0,
    this.pemain = 0,
    this.xp = 0,
    this.posSelesai = 0,
    this.sudahDilihat = false,
  });

  final String weekId;
  final int liga;
  final int peringkat;
  final int pemain;
  final int xp;
  final int posSelesai;

  /// Apakah layar Akhir minggu untuk minggu ini sudah pernah tampil.
  final bool sudahDilihat;

  bool get punyaPeringkat => peringkat > 0;
}

/// Satu baris per minggu, menyimpan di mana anak ini berdiri.
///
/// Alasannya satu dan cukup: **liga yang sudah ditutup tidak bisa
/// ditanya lagi.** Senin pagi server sudah pindah ke `weekId` baru, dan
/// peringkat akhir minggu lalu tidak ada di mana pun kecuali di sini.
/// Tanpa tabel ini, layar Akhir minggu tidak punya angka dan "naik 4
/// posisi" tidak bisa dihitung sama sekali.
class LeagueDao {
  LeagueDao(this._db);

  final Database _db;

  Future<CatatanMinggu?> minggu(String weekId) async {
    final rows = await _db.query(
      'league_week',
      where: 'week_id = ?',
      whereArgs: [weekId],
      limit: 1,
    );
    return rows.isEmpty ? null : _dari(rows.first);
  }

  /// Menyimpan keadaan terkini satu minggu.
  ///
  /// Nilai yang tidak diberikan dibiarkan apa adanya — pemanggil yang
  /// cuma tahu nomor liganya tidak perlu ikut menebak peringkatnya.
  Future<void> simpan({
    required String weekId,
    int? liga,
    int? peringkat,
    int? pemain,
    int? xp,
    int? posSelesai,
    bool? sudahDilihat,
  }) async {
    await _db.insert('league_week', {
      'week_id': weekId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    final ubah = <String, Object?>{
      'league': ?liga,
      'rank': ?peringkat,
      'players': ?pemain,
      'xp': ?xp,
      'levels': ?posSelesai,
      if (sudahDilihat != null) 'seen': sudahDilihat ? 1 : 0,
    };
    if (ubah.isEmpty) return;
    await _db.update(
      'league_week',
      ubah,
      where: 'week_id = ?',
      whereArgs: [weekId],
    );
  }

  /// Minggu terakhir yang sudah lewat dan peringkatnya belum pernah
  /// ditampilkan — inilah yang memicu layar Akhir minggu.
  Future<CatatanMinggu?> belumDilihatSebelum(String weekIdSekarang) async {
    final rows = await _db.query(
      'league_week',
      where: 'seen = 0 AND rank > 0 AND week_id < ?',
      whereArgs: [weekIdSekarang],
      orderBy: 'week_id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _dari(rows.first);
  }

  /// Minggu berperingkat tepat sebelum [weekId] — dipakai menghitung
  /// pergerakan "naik 4 posisi".
  Future<CatatanMinggu?> sebelum(String weekId) async {
    final rows = await _db.query(
      'league_week',
      where: 'week_id < ? AND rank > 0',
      whereArgs: [weekId],
      orderBy: 'week_id DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : _dari(rows.first);
  }

  Future<void> hapusSemua() => _db.delete('league_week');

  static CatatanMinggu _dari(Map<String, Object?> r) => CatatanMinggu(
    weekId: r['week_id']! as String,
    liga: r['league'] as int? ?? 0,
    peringkat: r['rank'] as int? ?? 0,
    pemain: r['players'] as int? ?? 0,
    xp: r['xp'] as int? ?? 0,
    posSelesai: r['levels'] as int? ?? 0,
    sudahDilihat: (r['seen'] as int? ?? 0) == 1,
  );
}
