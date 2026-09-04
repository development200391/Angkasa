import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Satu hal yang menunggu dikirim.
class ItemAntrean {
  const ItemAntrean({
    required this.id,
    required this.entitas,
    required this.kunci,
    required this.muatan,
    required this.dibuat,
    this.percobaan = 0,
    this.galatTerakhir,
  });

  final int id;

  /// Jenis data: `profil`, `skor`, atau `cadangan`.
  final String entitas;

  /// Pembeda di dalam satu jenis — misalnya `2026-W36` untuk skor
  /// mingguan. Kosong untuk yang cuma ada satu.
  final String kunci;

  final Map<String, Object?> muatan;
  final DateTime dibuat;
  final int percobaan;
  final String? galatTerakhir;
}

/// Antrean kiriman ke Firestore.
///
/// Tabelnya dibuat sejak skema versi 1 dan dibiarkan kosong dua tahap
/// penuh. Isinya baru berarti sekarang, dan bentuknya menjawab satu
/// pertanyaan: apa yang terjadi kalau anak main seminggu penuh tanpa
/// sinyal?
///
/// Jawabannya ada di indeks unik `(entity, entity_key)`. Menulis profil
/// dua ratus kali selama seminggu itu tetap menyisakan **satu** baris,
/// yang isinya keadaan terakhir — karena keadaan terakhirlah satu-satunya
/// yang benar. Antrean yang menyimpan tiap perubahan berarti dua ratus
/// penulisan Firestore yang saling menimpa, dan tagihan yang tidak ada
/// hubungannya dengan manfaatnya.
class SyncQueueDao {
  SyncQueueDao(this._db);

  final Database _db;

  /// Batas percobaan sebelum sebuah baris menyerah dan dibuang.
  ///
  /// Ada satu jenis kegagalan yang tidak akan pernah sembuh dengan
  /// dicoba lagi: muatan yang ditolak aturan keamanan Firestore. Tanpa
  /// batas, baris itu akan dicoba tiap kali aplikasi dibuka sampai HP-nya
  /// diganti.
  static const maksPercobaan = 8;

  Future<void> antre({
    required String entitas,
    String kunci = '',
    required Map<String, Object?> muatan,
    DateTime? waktu,
  }) async {
    await _db.insert('sync_queue', {
      'entity': entitas,
      'entity_key': kunci,
      'payload_json': jsonEncode(muatan),
      'created_at': (waktu ?? DateTime.now()).toIso8601String(),
      'attempts': 0,
      'last_error': null,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Semua yang menunggu, yang paling lama menunggu lebih dulu.
  Future<List<ItemAntrean>> menunggu({int batas = 50}) async {
    final rows = await _db.query(
      'sync_queue',
      orderBy: 'created_at, id',
      limit: batas,
    );
    return rows.map(_dari).toList();
  }

  Future<int> jumlah() async {
    final r = await _db.rawQuery('SELECT COUNT(*) AS n FROM sync_queue');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  Future<void> selesai(int id) =>
      _db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);

  /// Menandai satu percobaan yang gagal.
  ///
  /// Mengembalikan `true` kalau barisnya dibuang karena sudah menyerah,
  /// supaya pemanggilnya bisa mencatat itu ke Crashlytics sekali saja.
  Future<bool> gagal(int id, Object galat) async {
    final rows = await _db.query(
      'sync_queue',
      columns: ['attempts'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return false;

    final percobaan = (rows.first['attempts'] as int? ?? 0) + 1;
    if (percobaan >= maksPercobaan) {
      await selesai(id);
      return true;
    }
    await _db.update(
      'sync_queue',
      {
        'attempts': percobaan,
        'last_error': galat.toString().substring(
          0,
          galat.toString().length.clamp(0, 300),
        ),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return false;
  }

  Future<void> hapusSemua() => _db.delete('sync_queue');

  static ItemAntrean _dari(Map<String, Object?> r) => ItemAntrean(
    id: r['id']! as int,
    entitas: r['entity']! as String,
    kunci: r['entity_key'] as String? ?? '',
    muatan:
        jsonDecode(r['payload_json']! as String) as Map<String, Object?>? ??
        const {},
    dibuat:
        DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
    percobaan: r['attempts'] as int? ?? 0,
    galatTerakhir: r['last_error'] as String?,
  );
}
