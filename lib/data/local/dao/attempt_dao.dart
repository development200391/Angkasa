import 'package:sqflite/sqflite.dart';

import '../../../domain/models/enums.dart';
import '../../../domain/models/question_attempt.dart';

/// Satu soal yang masih menunggu diperbaiki.
class SoalSalah {
  const SoalSalah({
    required this.signature,
    required this.mistake,
    required this.salah,
    required this.benarBeruntun,
    required this.terakhir,
  });

  final String signature;
  final MistakeKind mistake;
  final int salah;

  /// Berapa kali benar berturut-turut sejak salah terakhir. Dua berarti
  /// soalnya lulus dan keluar dari daftar.
  final int benarBeruntun;

  final DateTime terakhir;
}

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

  /// Soal keluar dari daftar Perbaiki Kesalahan setelah benar dua kali
  /// **berturut-turut** — sekali benar bisa saja tebakan.
  static const benarUntukLulus = 2;

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

  /// Semua soal yang pernah salah, beserta berapa kali benar beruntun
  /// sesudahnya. Yang sudah lulus ikut dipulangkan supaya pemanggilnya
  /// bisa menghitung dua-duanya sekali jalan.
  Future<List<SoalSalah>> riwayatSalah() async {
    final rows = await _db.rawQuery('''
      SELECT question_signature, is_correct, mistake_kind, answered_at
      FROM question_attempts
      WHERE question_signature IN (
        SELECT question_signature FROM question_attempts WHERE is_correct = 0
      )
      ORDER BY question_signature, answered_at, id
      ''');

    final perSoal = <String, List<Map<String, Object?>>>{};
    for (final r in rows) {
      perSoal.putIfAbsent(r['question_signature']! as String, () => []).add(r);
    }

    final hasil = <SoalSalah>[];
    for (final e in perSoal.entries) {
      var salah = 0;
      var beruntun = 0;
      var jenis = MistakeKind.lainnya;
      DateTime terakhir = DateTime.fromMillisecondsSinceEpoch(0);

      for (final a in e.value) {
        final benar = (a['is_correct'] as int? ?? 0) == 1;
        if (benar) {
          beruntun++;
        } else {
          salah++;
          beruntun = 0;
          jenis = MistakeKind.values.firstWhere(
            (m) => m.name == a['mistake_kind'],
            orElse: () => MistakeKind.lainnya,
          );
        }
        terakhir =
            DateTime.tryParse(a['answered_at'] as String? ?? '') ?? terakhir;
      }

      hasil.add(
        SoalSalah(
          signature: e.key,
          mistake: jenis,
          salah: salah,
          benarBeruntun: beruntun,
          terakhir: terakhir,
        ),
      );
    }

    hasil.sort((a, b) => b.terakhir.compareTo(a.terakhir));
    return hasil;
  }

  /// Yang masih menunggu diperbaiki. Inilah angka merah di tab Latihan —
  /// satu-satunya lencana notifikasi di seluruh aplikasi.
  Future<List<SoalSalah>> menunggu() async => (await riwayatSalah())
      .where((s) => s.benarBeruntun < benarUntukLulus)
      .toList();

  /// Sudah dibetulkan dua kali berturut-turut.
  Future<int> jumlahDiperbaiki() async => (await riwayatSalah())
      .where((s) => s.benarBeruntun >= benarUntukLulus)
      .length;

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

  /// Berapa soal yang pernah dikerjakan lewat mode latihan bebas.
  /// Sesi latihan dicatat dengan `level_id` berawalan `latihan:`.
  Future<int> jumlahSoalLatihan() async {
    final r = await _db.rawQuery(
      "SELECT COUNT(*) AS n FROM question_attempts "
      "WHERE level_id LIKE 'latihan:%'",
    );
    return Sqflite.firstIntValue(r) ?? 0;
  }

  /// Jam anak paling sering menjawab soal.
  ///
  /// Inilah yang menentukan jam pemberitahuan harian — dipelajari dari
  /// kebiasaan, bukan dipatok di kode. `null` selama datanya belum cukup
  /// untuk disebut kebiasaan.
  Future<int?> jamPalingSering({int minimalJawaban = 20}) async {
    final rows = await _db.rawQuery('''
      SELECT CAST(substr(answered_at, 12, 2) AS INTEGER) AS jam,
             COUNT(*) AS n
      FROM question_attempts
      GROUP BY jam
      ORDER BY n DESC
      ''');
    if (rows.isEmpty) return null;
    final total = rows.fold<int>(0, (a, r) => a + (r['n']! as int));
    if (total < minimalJawaban) return null;
    return rows.first['jam'] as int?;
  }

  Future<void> hapusSemua() => _db.delete('question_attempts');
}
