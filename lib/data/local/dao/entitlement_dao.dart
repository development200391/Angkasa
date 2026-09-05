import 'package:sqflite/sqflite.dart';

/// Satu hak yang sudah dimiliki.
class Hak {
  const Hak({
    required this.kode,
    required this.dibeli,
    required this.sumber,
    this.orderId,
    this.terverifikasi = false,
  });

  final String kode;
  final DateTime dibeli;

  /// `play`, `appstore`, atau `pemulihan`.
  final String sumber;

  /// Id pesanan dari toko. Yang ditanyakan pertama kali kalau ada yang
  /// menagih bukti pembelian.
  final String? orderId;

  final bool terverifikasi;
}

/// Hak beli yang tersimpan di HP.
///
/// **Sumber kebenarannya di sini, bukan di toko.** Anak yang sudah
/// dibayari harus tetap bisa membuka planetnya di dalam angkot tanpa
/// sinyal — sama seperti seluruh bagian lain aplikasi ini. Play Store
/// dipanggil untuk *menambah* hak, tidak pernah untuk mencabutnya.
///
/// Konsekuensi yang disengaja: menghapus data aplikasi menghapus hak
/// yang tersimpan, dan orang tua harus menekan "Pulihkan pembelian".
/// Itu sebabnya kalimat pemulihan ditulis besar di layar Pembelian
/// berhasil, bukan disembunyikan di FAQ.
class EntitlementDao {
  EntitlementDao(this._db);

  final Database _db;

  /// Kode hak untuk membuka keempat planet berbayar. Sama persis dengan
  /// id produk di Play Console — dua tempat, satu nama, supaya tidak
  /// ada penerjemahan yang bisa salah.
  static const semuaPlanet = 'semua_planet';

  Future<bool> punya(String kode) async {
    final rows = await _db.query(
      'entitlements',
      where: 'code = ?',
      whereArgs: [kode],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<List<Hak>> semua() async {
    final rows = await _db.query('entitlements', orderBy: 'purchased_at');
    return rows.map(_hak).toList();
  }

  Future<Hak?> ambil(String kode) async {
    final rows = await _db.query(
      'entitlements',
      where: 'code = ?',
      whereArgs: [kode],
      limit: 1,
    );
    return rows.isEmpty ? null : _hak(rows.first);
  }

  /// Menyimpan hak. Aman dipanggil berkali-kali untuk pembelian yang
  /// sama — Play Store mengirimkan ulang pembelian lama tiap kali
  /// aplikasi dibuka, dan tiap kali "Pulihkan pembelian" ditekan.
  Future<void> simpan(Hak hak) => _db.insert('entitlements', {
    'code': hak.kode,
    'purchased_at': hak.dibeli.toIso8601String(),
    'source': hak.sumber,
    'order_id': hak.orderId,
    'verified': hak.terverifikasi ? 1 : 0,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  /// Dipakai **hanya** oleh tombol "Mulai dari awal" di Pengaturan.
  ///
  /// Tidak pernah dipanggil karena toko bilang sesuatu. Hak yang hilang
  /// diam-diam karena jaringan bermasalah adalah cara tercepat mengubah
  /// orang tua yang sudah membayar jadi orang tua yang menulis ulasan
  /// bintang satu.
  Future<void> hapusSemua() => _db.delete('entitlements');

  Hak _hak(Map<String, Object?> r) => Hak(
    kode: r['code']! as String,
    dibeli: DateTime.parse(r['purchased_at']! as String),
    sumber: r['source']! as String,
    orderId: r['order_id'] as String?,
    terverifikasi: (r['verified'] as int? ?? 0) == 1,
  );
}
