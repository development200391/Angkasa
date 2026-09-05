/// Satu-satunya pintu ke toko aplikasi.
///
/// Bentuknya sengaja sama persis dengan `RemoteGateway`: sebuah
/// antarmuka, sebuah implementasi sungguhan yang mengimpor
/// `in_app_purchase`, dan sebuah implementasi luring yang benar-benar
/// tidak menyentuh apa pun. Alasannya juga sama — **kalau tokonya mati,
/// aplikasinya harus tetap jalan.**
///
/// Bedanya satu, dan itu penting: kegagalan di sini tidak pernah boleh
/// *mengurangi* apa yang sudah dimiliki anak. Toko dipanggil untuk
/// menambah hak, tidak pernah untuk mencabutnya; yang menyimpan hak
/// adalah `EntitlementDao` di HP.
library;

/// Produk yang dijual, beserta harganya dalam mata uang setempat.
///
/// Harganya **selalu** diambil dari toko, tidak pernah ditulis di kode.
/// "Rp 49.000" yang dipatok di aplikasi akan salah begitu Play
/// mengubah kurs, mengenakan pajak daerah, atau menjalankan promo — dan
/// harga yang berbeda antara layar dan lembar pembayaran adalah alasan
/// pembatalan yang paling mahal.
class ProdukBeli {
  const ProdukBeli({
    required this.id,
    required this.harga,
    required this.judul,
  });

  final String id;

  /// Sudah diformat toko, mis. `Rp 49.000,00`.
  final String harga;
  final String judul;
}

/// Bagaimana usaha membeli berakhir.
enum HasilBeli {
  berhasil,

  /// Orang tua menutup lembar pembayaran. Bukan kegagalan, dan tidak
  /// pantas dijawab pesan galat apa pun.
  dibatalkan,

  /// Dibayar lewat cara yang butuh waktu — transfer bank, gerai. Play
  /// mengirimkan hasilnya belakangan, mungkin berjam-jam kemudian.
  /// Layarnya harus mengatakan itu, bukan diam seolah gagal.
  tertunda,

  /// Toko tidak tersedia sama sekali: build luring, atau perangkat
  /// tanpa Play Store.
  tidakAdaToko,

  gagal,
}

/// Satu pembelian yang dikenali toko.
class PembelianDaring {
  const PembelianDaring({
    required this.produkId,
    required this.waktu,
    this.orderId,
    this.terverifikasi = false,
  });

  final String produkId;
  final DateTime waktu;
  final String? orderId;
  final bool terverifikasi;
}

abstract interface class PurchaseGateway {
  /// `false` di build luring dan di perangkat tanpa toko. Layar yang
  /// membacanya menampilkan keadaan apa adanya, bukan pesan kesalahan.
  bool get tersedia;

  Future<void> siapkan();

  /// `null` kalau produknya tidak ditemukan di toko — yang berarti
  /// belum dikonfigurasi, bukan berarti gratis.
  Future<ProdukBeli?> produk(String id);

  Future<HasilBeli> beli(String id);

  /// Seluruh pembelian yang diakui toko untuk akun ini.
  ///
  /// Dipakai tombol "Pulihkan pembelian" **dan** dipanggil diam-diam
  /// saat aplikasi dibuka: orang tua yang ganti HP tidak seharusnya
  /// perlu tahu ada tombol yang harus ditekan.
  Future<List<PembelianDaring>> pulihkan();

  Future<void> tutup();
}

/// Implementasi tanpa toko.
///
/// Bukan tiruan untuk uji — inilah yang dipakai `flutter run` tanpa
/// argumen apa pun, dan yang dipakai seluruh berkas uji. Semuanya
/// memulangkan "tidak ada" tanpa melempar.
class GatewayBeliLuring implements PurchaseGateway {
  const GatewayBeliLuring();

  @override
  bool get tersedia => false;

  @override
  Future<void> siapkan() async {}

  @override
  Future<ProdukBeli?> produk(String id) async => null;

  @override
  Future<HasilBeli> beli(String id) async => HasilBeli.tidakAdaToko;

  @override
  Future<List<PembelianDaring>> pulihkan() async => const [];

  @override
  Future<void> tutup() async {}
}
