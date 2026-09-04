import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../domain/models/enums.dart';
import '../../../domain/models/gambar.dart';
import '../../../domain/models/question.dart';

/// Baca soal yang ditulis tangan.
///
/// Tabel `static_questions` sudah ada sejak skema v1 dan kosong sampai
/// sekarang — sengaja: menambah tabel ke basis data yang sudah dipakai
/// anak selalu lebih mahal daripada menyiapkannya di awal. Tahap 4 baru
/// mengisinya, karena di sinilah materinya berhenti bisa dibangkitkan.
///
/// Isinya **tidak pernah ditulis dari aplikasi**. Sama seperti `levels`
/// dan `chapters`, ia diisi sekali oleh `SeedRunner` dan sesudah itu
/// hanya dibaca; tidak ada satu pun `insert` di kelas ini.
class StaticQuestionDao {
  StaticQuestionDao(this._db);

  final Database _db;

  /// Seluruh soal tertulis untuk satu pos, dalam urutan yang ditulis
  /// penulisnya.
  ///
  /// Urutannya bukan detail: soal cerita disusun dari satu langkah ke
  /// dua langkah, dan mengacaknya membuat anak bertemu soal tersulit
  /// waktu ia baru mengerti bentuknya. Yang diacak posisi pilihan
  /// jawabannya, bukan urutan soalnya.
  Future<List<Question>> untukPos(String levelId) async {
    final rows = await _db.query(
      'static_questions',
      where: 'level_id = ?',
      whereArgs: [levelId],
      orderBy: 'order_index, id',
    );
    return rows.map(_soal).toList();
  }

  /// Berapa soal tertulis yang dipunyai sebuah pos. Dipakai perakit
  /// sesi untuk tahu berapa sisa yang perlu dibangkitkan.
  Future<int> jumlah(String levelId) async {
    final r = await _db.rawQuery(
      'SELECT COUNT(*) c FROM static_questions WHERE level_id = ?',
      [levelId],
    );
    return (r.first['c'] as int?) ?? 0;
  }

  /// Pos mana saja yang punya soal tertulis, sekali query.
  ///
  /// Dipakai layar peta untuk menandai pos bergambar tanpa menembak
  /// satu query per pos — 250 pos berarti 250 perjalanan ke SQLite di
  /// tengah animasi peta.
  Future<Set<String>> posBersoalTertulis() async {
    final rows = await _db.rawQuery(
      'SELECT DISTINCT level_id FROM static_questions',
    );
    return {for (final r in rows) r['level_id'] as String};
  }

  Question _soal(Map<String, Object?> r) {
    final opsi = _opsi(r['options_json'] as String?);
    final jawaban = r['answer'] as String;

    return Question(
      // Soal tertulis memakai id-nya sendiri sebagai tanda tangan.
      // Bentuk baku `7+5=?` tidak berlaku di sini — dua soal cerita
      // bisa punya angka yang sama persis dan tetap berbeda soalnya,
      // dan mode Perbaiki Kesalahan harus bisa memanggil kembali yang
      // benar-benar dikerjakan anak.
      signature: r['id'] as String,
      format: QuestionFormat.dariNama(r['format'] as String),
      prompt: r['prompt'] as String,
      answer: jawaban,
      options: opsi,
      // Tiga sumbu di bawah milik soal yang dibangkitkan. Soal tertulis
      // tidak punya operasi tunggal — "sisa uang setelah beli 3 pensil"
      // adalah kali lalu kurang — jadi diisi nilai netral dan tidak
      // dipakai siapa pun. Yang membedakannya justru [format].
      operation: Operation.tambah,
      left: 0,
      right: 0,
      result: int.tryParse(jawaban.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0,
      visualAid: VisualAid.tidakAda,
      explanation: r['explanation'] as String?,
      imageAsset: r['image_asset'] as String?,
      gambar: Gambar.dariJson(r['figure_json']),
    );
  }

  /// Membaca pilihan jawaban beserta nama kesalahan tiap pengecoh.
  ///
  /// Bentuknya `[{"label":"Rp 3.500","mistake":"langkahTerlewat"},…]`.
  /// Nama kesalahan yang tidak dikenali jatuh ke [MistakeKind.lainnya]
  /// alih-alih melempar — berkas konten yang salah ketik di satu baris
  /// tidak boleh membuat seluruh pos gagal dibuka.
  List<AnswerOption> _opsi(String? json) {
    if (json == null || json.trim().isEmpty) return const [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return [
        for (final o in list)
          if (o is Map<String, dynamic>)
            AnswerOption(
              label: '${o['label']}',
              isCorrect: o['isCorrect'] == true,
              mistake: o['isCorrect'] == true
                  ? null
                  : MistakeKind.dariNama(o['mistake'] as String?),
            ),
      ];
    } catch (_) {
      return const [];
    }
  }
}
