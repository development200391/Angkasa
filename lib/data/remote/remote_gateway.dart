import '../../domain/engine/aturan_nilai.dart';
import '../../domain/models/liga.dart';
import 'remote_models.dart';

/// Satu-satunya pintu ke dunia luar.
///
/// Seluruh kode Firebase di proyek ini berhenti di balik antarmuka ini.
/// Alasannya bukan kerapian: **kalau Firebase mati, aplikasinya harus
/// tetap jalan persis seperti Tahap 2** — dan satu-satunya cara
/// membuktikan itu adalah punya implementasi kedua yang benar-benar
/// tidak menyentuh jaringan, lalu menjalankan seluruh uji di atasnya.
///
/// Konsekuensi yang lebih penting lagi: tidak ada satu pun layar,
/// repositori, atau uji yang boleh mengimpor `firebase_*`. Kalau suatu
/// hari Firebase diganti, yang berubah cuma satu berkas.
abstract interface class RemoteGateway {
  /// `true` kalau Firebase benar-benar dikonfigurasi dan siap dipakai.
  ///
  /// `false` di seluruh build luring — dan itu keadaan bawaan, bukan
  /// keadaan galat. Layar yang membaca ini menampilkan keadaan "belum
  /// tersambung" apa adanya, bukan pesan kesalahan.
  bool get tersedia;

  /// `true` kalau `GOOGLE_SERVER_CLIENT_ID` terisi dan Firebase menyala.
  /// Selama `false`, layar Simpan progres menyebutkan alasannya apa
  /// adanya alih-alih menyodorkan tombol mati.
  bool get bisaMasukGoogle;

  String? get uid;

  /// Menyalakan Firebase. Aman dipanggil berkali-kali, dan aman gagal:
  /// kegagalannya cuma membuat [tersedia] tetap `false`.
  Future<void> siapkan();

  Future<AkunDaring?> masukAnonim();

  /// Menautkan akun anonim yang sedang berjalan ke akun Google, tanpa
  /// kehilangan uid-nya — jadi papan peringkat dan cadangan tetap milik
  /// anak yang sama.
  ///
  /// Tidak melempar untuk keadaan yang sudah diramalkan: pembatalan dan
  /// akun yang sudah dipakai HP lain dipulangkan sebagai [HasilTaut],
  /// bukan sebagai galat. Keduanya keadaan wajar, dan memperlakukannya
  /// sebagai kerusakan membuat layar di atasnya menampilkan pesan merah
  /// untuk sesuatu yang tidak salah.
  Future<TautanAkun> tautkanGoogle();

  Future<void> keluar();

  // ------------------------------------------------------------ tulis
  Future<void> tulisProfil(ProfilDaring profil);
  Future<void> tulisCadangan(CadanganProgres cadangan);
  Future<void> tulisSkor({required String weekId, required EntriLiga entri});

  /// Mendaftarkan anak ini ke sebuah liga minggu itu, lalu mengembalikan
  /// nomornya. Dipanggil sekali seminggu, dan hasilnya disimpan lokal.
  Future<int> daftarkanLiga({required String weekId, required int ukuran});

  // ------------------------------------------------------------- baca
  Future<List<EntriLiga>> bacaPapan({
    required String weekId,
    required int liga,
    required int batas,
  });

  Future<ProfilDaring?> bacaProfil();
  Future<CadanganProgres?> bacaCadangan();

  /// Menghapus seluruh data anak ini di server. Dipanggil dari layar
  /// Akun & data, dan tidak menyentuh apa pun di HP.
  Future<void> hapusSemuaData();

  // ----------------------------------------------------------- setelan
  /// Nilai dari Remote Config. Selalu mengembalikan sesuatu: kalau
  /// pengambilannya gagal, yang dipulangkan adalah bawaan yang sama
  /// dengan Tahap 2.
  Future<AturanNilai> aturanNilai();

  // ---------------------------------------------------------- laporan
  Future<void> catatGalat(Object galat, StackTrace jejak, {bool fatal});

  /// Keterangan tambahan yang ikut terkirim bersama laporan galat.
  /// Tidak pernah berisi apa pun yang bisa menunjuk ke anak tertentu.
  Future<void> setPenanda(String kunci, Object nilai);
}

/// Implementasi tanpa jaringan.
///
/// Bukan tiruan untuk uji — inilah yang benar-benar dipakai aplikasi
/// waktu `OFFLINE_ONLY=true`, yaitu bawaan `flutter run` tanpa argumen
/// apa pun dan bawaan seluruh berkas uji. Semuanya mengembalikan
/// "kosong" tanpa melempar, karena tidak tersambung bukan kesalahan
/// yang perlu ditangani siapa pun.
class GatewayLuring implements RemoteGateway {
  const GatewayLuring();

  @override
  bool get tersedia => false;

  @override
  bool get bisaMasukGoogle => false;

  @override
  String? get uid => null;

  @override
  Future<void> siapkan() async {}

  @override
  Future<AkunDaring?> masukAnonim() async => null;

  @override
  Future<TautanAkun> tautkanGoogle() async => const TautanAkun(HasilTaut.gagal);

  @override
  Future<void> keluar() async {}

  @override
  Future<void> tulisProfil(ProfilDaring profil) async {}

  @override
  Future<void> tulisCadangan(CadanganProgres cadangan) async {}

  @override
  Future<void> tulisSkor({
    required String weekId,
    required EntriLiga entri,
  }) async {}

  @override
  Future<int> daftarkanLiga({
    required String weekId,
    required int ukuran,
  }) async => 0;

  @override
  Future<List<EntriLiga>> bacaPapan({
    required String weekId,
    required int liga,
    required int batas,
  }) async => const [];

  @override
  Future<ProfilDaring?> bacaProfil() async => null;

  @override
  Future<CadanganProgres?> bacaCadangan() async => null;

  @override
  Future<void> hapusSemuaData() async {}

  @override
  Future<AturanNilai> aturanNilai() async => AturanNilai.bawaan;

  @override
  Future<void> catatGalat(
    Object galat,
    StackTrace jejak, {
    bool fatal = false,
  }) async {}

  @override
  Future<void> setPenanda(String kunci, Object nilai) async {}
}
