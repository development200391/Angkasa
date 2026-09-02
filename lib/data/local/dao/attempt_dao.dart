import 'package:sqflite/sqflite.dart';

import '../../../domain/models/enums.dart';
import '../../../domain/models/question_attempt.dart';

/// Catatan tiap soal yang pernah dijawab.
///
/// Ditulis sejak soal pertama walaupun pembacanya baru datang nanti:
/// mode Perbaiki Kesalahan di Tahap 2 dan dashboard orang tua di Tahap 4
/// keduanya berdiri di atas tabel ini. Karena tiap pengecoh punya nama,
/// isinya bukan sekadar nilai, tapi jenis kesalahannya.
///
/// Tabel ini **tidak pernah** disinkronkan ke Firestore: ribuan baris per
/// anak, tidak berguna secara daring, dan langsung membengkakkan tagihan.
class AttemptDao {
  AttemptDao(this._db);

  final Database _db;

  Future<void> catat(Iterable<QuestionAttempt> percobaan) async {
    if (percobaan.isEmpty) return;
    final batch = _db.batch();
    for (final a in percobaan) {
      batch.insert('question_attempts', {
        'level_id': a.levelId,
        'question_signature': a.questionSignature,
        'is_correct': a.isCorrect ? 1 : 0,
        'time_ms': a.timeMs,
        'answered_at': a.answeredAt.toIso8601String(),
        'mistake_kind': a.mistake?.name,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Soal yang pernah dijawab salah dan belum benar dua kali sesudahnya.
  /// Dipakai mode Perbaiki Kesalahan (Tahap 2); di Tahap 1 sudah bisa
  /// dipanggil untuk menghitung lencana angka merahnya.
  Future<List<String>> tandaSalah({int batas = 50}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT question_signature,
             SUM(CASE WHEN is_correct = 0 THEN 1 ELSE 0 END) AS salah,
             SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) AS benar
      FROM question_attempts
      GROUP BY question_signature
      HAVING salah > 0 AND benar < 2
      ORDER BY MAX(answered_at) DESC
      LIMIT ?
      ''',
      [batas],
    );
    return rows.map((r) => r['question_signature']! as String).toList();
  }

  /// Berapa kali tiap jenis kesalahan terjadi. Ini yang nanti membuat
  /// layar statistik bisa berkata "sering lupa menyimpan" alih-alih
  /// "nilai 60".
  Future<Map<MistakeKind, int>> ringkasanKesalahan() async {
    final rows = await _db.rawQuery('''
      SELECT mistake_kind, COUNT(*) AS n
      FROM question_attempts
      WHERE is_correct = 0 AND mistake_kind IS NOT NULL
      GROUP BY mistake_kind
      ORDER BY n DESC
      ''');
    return {
      for (final r in rows)
        MistakeKind.values.firstWhere(
          (m) => m.name == r['mistake_kind'],
          orElse: () => MistakeKind.lainnya,
        ): r['n']! as int,
    };
  }

  Future<int> jumlahSalah() async {
    final r = await _db.rawQuery(
      'SELECT COUNT(DISTINCT question_signature) AS n '
      'FROM question_attempts WHERE is_correct = 0',
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> hapusSemua() => _db.delete('question_attempts');
}
