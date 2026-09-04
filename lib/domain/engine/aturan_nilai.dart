/// Angka-angka yang menentukan bintang dan XP, dikumpulkan jadi satu
/// benda yang bisa diganti dari jauh.
///
/// Sampai Tahap 2 semua nilai ini konstanta di [StarCalculator]. Yang
/// berubah di Tahap 3 cuma satu hal: konstantanya pindah ke sini supaya
/// Remote Config bisa menggesernya tanpa memperbarui aplikasi. Nilai
/// bawaan di bawah **sama persis** dengan konstanta Tahap 2 — jadi
/// aplikasi tanpa jaringan, atau dengan Remote Config yang gagal
/// diambil, berhitung dengan angka yang identik.
///
/// Kenapa ini layak disetel dari jauh: ambang bintang adalah satu-satunya
/// angka yang benar-benar mengubah rasa aplikasi, dan satu-satunya cara
/// jujur menguji "apakah 8/10 terlalu ketat" adalah menggesernya untuk
/// sebagian anak lalu melihat berapa yang berhenti di pos keempat.
/// Menunggu rilis toko dua minggu untuk tiap percobaan berarti tidak
/// pernah mencobanya sama sekali.
class AturanNilai {
  const AturanNilai({
    this.ambangTigaBintang = 1.0,
    this.ambangDuaBintang = 0.8,
    this.ambangSatuBintang = 0.6,
    this.xpPos = 10,
    this.xpGerbang = 30,
    this.bonusTigaBintang = 5,
    this.xpMengulang = 2,
    this.xpTantangan = 20,
    this.heartsPerSession = 5,
    this.ukuranLiga = 30,
    this.papanPeringkatAktif = true,
  });

  /// Ambang bintang, dalam pecahan jawaban benar.
  final double ambangTigaBintang;
  final double ambangDuaBintang;
  final double ambangSatuBintang;

  final int xpPos;
  final int xpGerbang;
  final int bonusTigaBintang;
  final int xpMengulang;
  final int xpTantangan;

  final int heartsPerSession;

  /// Berapa anak dalam satu liga mingguan.
  final int ukuranLiga;

  /// Sakelar mati darurat untuk papan peringkat. Berbeda dari setelan di
  /// layar Akun & data: yang ini milik pengembang, yang itu milik orang
  /// tua, dan keduanya harus menyala supaya papan peringkat tampil.
  final bool papanPeringkatAktif;

  static const bawaan = AturanNilai();

  /// Membaca nilai dari Remote Config.
  ///
  /// Tiap nilai disaring dulu: yang di luar rentang masuk akal dibuang
  /// dan diganti bawaannya. Satu salah ketik di konsol Remote Config
  /// tidak boleh bisa membuat semua anak kehilangan bintangnya.
  factory AturanNilai.dariPeta(
    Map<String, Object?> nilai, {
    AturanNilai bawaan = AturanNilai.bawaan,
  }) {
    double pecahan(String kunci, double asal) {
      final v = _double(nilai[kunci]);
      if (v == null || v <= 0 || v > 1) return asal;
      return v;
    }

    int bulat(String kunci, int asal, {int min = 0, int maks = 1000}) {
      final v = _int(nilai[kunci]);
      if (v == null || v < min || v > maks) return asal;
      return v;
    }

    var tiga = pecahan('ambang_tiga_bintang', bawaan.ambangTigaBintang);
    var dua = pecahan('ambang_dua_bintang', bawaan.ambangDuaBintang);
    var satu = pecahan('ambang_satu_bintang', bawaan.ambangSatuBintang);

    // Ambangnya wajib menurun. Kalau urutannya rusak, **ketiganya**
    // dikembalikan ke bawaan sekaligus — bukan satu-satu. Menambal satu
    // nilai dengan bawaannya bisa menghasilkan urutan yang tetap
    // terbalik (tiga = 0,6 ditambal dua = 0,8), dan itu justru keadaan
    // yang membuat pos tidak bisa dapat bintang penuh sama sekali.
    if (!(tiga >= dua && dua >= satu)) {
      tiga = bawaan.ambangTigaBintang;
      dua = bawaan.ambangDuaBintang;
      satu = bawaan.ambangSatuBintang;
    }

    return AturanNilai(
      ambangTigaBintang: tiga,
      ambangDuaBintang: dua,
      ambangSatuBintang: satu,
      xpPos: bulat('xp_pos', bawaan.xpPos, min: 1, maks: 100),
      xpGerbang: bulat('xp_gerbang', bawaan.xpGerbang, min: 1, maks: 300),
      bonusTigaBintang: bulat(
        'bonus_tiga_bintang',
        bawaan.bonusTigaBintang,
        maks: 100,
      ),
      xpMengulang: bulat('xp_mengulang', bawaan.xpMengulang, maks: 100),
      xpTantangan: bulat('xp_tantangan', bawaan.xpTantangan, min: 1, maks: 200),
      heartsPerSession: bulat(
        'hati_per_sesi',
        bawaan.heartsPerSession,
        min: 1,
        maks: 10,
      ),
      ukuranLiga: bulat('ukuran_liga', bawaan.ukuranLiga, min: 5, maks: 100),
      papanPeringkatAktif:
          _bool(nilai['papan_peringkat_aktif']) ?? bawaan.papanPeringkatAktif,
    );
  }

  /// Nilai bawaan dalam bentuk yang diterima `setDefaults` Remote
  /// Config, supaya konsol dan aplikasi tidak pernah berbeda diam-diam.
  Map<String, Object> get sebagaiPeta => {
    'ambang_tiga_bintang': ambangTigaBintang,
    'ambang_dua_bintang': ambangDuaBintang,
    'ambang_satu_bintang': ambangSatuBintang,
    'xp_pos': xpPos,
    'xp_gerbang': xpGerbang,
    'bonus_tiga_bintang': bonusTigaBintang,
    'xp_mengulang': xpMengulang,
    'xp_tantangan': xpTantangan,
    'hati_per_sesi': heartsPerSession,
    'ukuran_liga': ukuranLiga,
    'papan_peringkat_aktif': papanPeringkatAktif,
  };

  static double? _double(Object? v) => switch (v) {
    final double d => d,
    final int i => i.toDouble(),
    final String s => double.tryParse(s),
    _ => null,
  };

  static int? _int(Object? v) => switch (v) {
    final int i => i,
    final double d => d.round(),
    final String s => int.tryParse(s),
    _ => null,
  };

  static bool? _bool(Object? v) => switch (v) {
    final bool b => b,
    'true' => true,
    'false' => false,
    _ => null,
  };
}
