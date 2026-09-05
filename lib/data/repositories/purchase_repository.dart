import '../../domain/models/grade.dart';
import '../local/dao/entitlement_dao.dart';
import '../local/dao/level_dao.dart';
import '../remote/purchase_gateway.dart';

/// Keadaan satu planet di mata anak dan orang tua.
class PlanetTerkunci {
  const PlanetTerkunci({
    required this.grade,
    required this.terkunci,
    required this.jumlahPos,
  });

  final Grade grade;

  /// Perlu dibayar **dan** belum dibayar.
  final bool terkunci;

  final int jumlahPos;
}

/// Isi layar Galaksi.
class Galaksi {
  const Galaksi({
    required this.planet,
    required this.produk,
    required this.sudahBeli,
    required this.tokoAda,
  });

  final List<PlanetTerkunci> planet;

  /// `null` kalau tokonya tidak bisa ditanya. Layarnya menyembunyikan
  /// tombol belinya alih-alih menampilkan harga yang dikarang.
  final ProdukBeli? produk;

  final bool sudahBeli;
  final bool tokoAda;

  int get terbuka => planet.where((p) => !p.terkunci).length;

  /// Berapa pos yang ada di balik pembayaran. Dipakai layar paywall,
  /// dan dihitung dari isi sungguhan — bukan angka yang diketik di
  /// layar dan basi pada penambahan pos pertama.
  int get posBerbayar => planet
      .where((p) => p.grade.requiresPurchase)
      .fold(0, (a, p) => a + p.jumlahPos);
}

/// Hak beli: menyimpannya, memulihkannya, dan menjawab satu pertanyaan
/// yang dipakai seluruh aplikasi — planet ini boleh dibuka atau tidak.
///
/// **Satu aturan menjalar ke seluruh kelas ini: membayar tidak pernah
/// jadi syarat belajar.** Planet Mula dan Puluh — 78 pos, kelas 1 dan
/// 2 — tetap terbuka penuh selamanya, termasuk seluruh mode latihan,
/// papan peringkat, dan lencana. Yang dijual isinya yang baru, bukan
/// akses ke aplikasinya.
///
/// Aturan kedua yang sama kerasnya: **kegagalan toko tidak pernah
/// mencabut hak.** Kalau Play tidak bisa dihubungi, yang sudah dibeli
/// tetap terbuka; hak tersimpan di HP dan toko cuma dipakai untuk
/// menambahnya.
class PurchaseRepository {
  PurchaseRepository({
    required EntitlementDao hakDao,
    required LevelDao levelDao,
    required this.gateway,
  }) : _hak = hakDao,
       _level = levelDao;

  final EntitlementDao _hak;
  final LevelDao _level;
  final PurchaseGateway gateway;

  static const kodeProduk = EntitlementDao.semuaPlanet;

  Future<bool> sudahBeli() => _hak.punya(kodeProduk);

  /// Planet ini boleh dimainkan?
  ///
  /// Planet yang tidak berbayar selalu `true` — tidak peduli keadaan
  /// toko, jaringan, atau apa pun.
  Future<bool> bolehDibuka(String gradeId) async {
    final g = await _level.grade(gradeId);
    if (g == null) return false;
    if (!g.requiresPurchase) return true;
    return sudahBeli();
  }

  Future<Galaksi> galaksi() async {
    final planet = await _level.semuaGrade();
    final beli = await sudahBeli();

    final daftar = <PlanetTerkunci>[];
    for (final g in planet) {
      daftar.add(
        PlanetTerkunci(
          grade: g,
          terkunci: g.requiresPurchase && !beli,
          jumlahPos: await _level.jumlahPos(g.id),
        ),
      );
    }

    // Harga ditanyakan ke toko, tidak pernah ditulis di kode. Kalau
    // tokonya diam, `produk` tetap `null` dan layarnya menyembunyikan
    // tombol belinya — harga karangan yang berbeda dari lembar
    // pembayaran adalah alasan pembatalan yang paling mahal.
    final produk = beli ? null : await gateway.produk(kodeProduk);

    return Galaksi(
      planet: daftar,
      produk: produk,
      sudahBeli: beli,
      tokoAda: gateway.tersedia,
    );
  }

  /// Membeli. Tidak pernah melempar.
  Future<HasilBeli> beli() async {
    try {
      final hasil = await gateway.beli(kodeProduk);
      if (hasil == HasilBeli.berhasil) {
        await _hak.simpan(
          Hak(
            kode: kodeProduk,
            dibeli: DateTime.now(),
            sumber: 'play',
            terverifikasi: true,
          ),
        );
      }
      return hasil;
    } catch (_) {
      return HasilBeli.gagal;
    }
  }

  /// Memulihkan pembelian dari akun toko.
  ///
  /// Mengembalikan `true` kalau sesudahnya hak itu dimiliki — termasuk
  /// kalau memang **sudah** dimiliki sebelum tombolnya ditekan. Orang
  /// tua yang menekan "Pulihkan pembelian" ingin tahu apakah planetnya
  /// terbuka, bukan apakah ada baris baru yang tertulis.
  ///
  /// Dipanggil juga diam-diam saat aplikasi dibuka: orang tua yang
  /// ganti HP tidak seharusnya perlu tahu ada tombol yang harus
  /// ditekan.
  Future<bool> pulihkan() async {
    try {
      for (final p in await gateway.pulihkan()) {
        if (p.produkId != kodeProduk) continue;
        await _hak.simpan(
          Hak(
            kode: p.produkId,
            dibeli: p.waktu,
            sumber: 'pemulihan',
            orderId: p.orderId,
            terverifikasi: p.terverifikasi,
          ),
        );
      }
    } catch (_) {
      // Sengaja ditelan. Gagal menghubungi toko tidak boleh terlihat
      // seperti "kamu belum pernah membeli" — yang dipulangkan di bawah
      // tetap keadaan sebenarnya di HP ini.
    }
    return sudahBeli();
  }

  /// Rincian pembelian untuk layar Akun & data.
  Future<Hak?> rincian() => _hak.ambil(kodeProduk);
}
