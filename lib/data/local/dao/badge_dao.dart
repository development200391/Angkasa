import 'package:sqflite/sqflite.dart';

import '../../../domain/models/badge.dart';

/// Tabel `badges`: kode lencana dan tanggalnya, tidak lebih.
class BadgeDao {
  BadgeDao(this._db);

  final Database _db;

  Future<List<EarnedBadge>> semua() async {
    final rows = await _db.query('badges', orderBy: 'unlocked_at');
    return rows
        .map(
          (r) => EarnedBadge(
            code: r['code']! as String,
            unlockedAt:
                DateTime.tryParse(r['unlocked_at']! as String) ??
                DateTime.now(),
          ),
        )
        .toList();
  }

  Future<Set<String>> kode() async {
    final rows = await _db.query('badges', columns: ['code']);
    return {for (final r in rows) r['code']! as String};
  }

  /// Menyimpan lencana baru. `ignore` supaya menilai ulang seluruh
  /// katalog kapan saja tidak pernah mengubah tanggal yang sudah ada —
  /// tanggal dapat lencana itu kenangan, bukan data turunan.
  Future<void> simpan(Iterable<String> kode, DateTime waktu) async {
    if (kode.isEmpty) return;
    final batch = _db.batch();
    for (final c in kode) {
      batch.insert('badges', {
        'code': c,
        'unlocked_at': waktu.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  Future<void> hapusSemua() => _db.delete('badges');
}
