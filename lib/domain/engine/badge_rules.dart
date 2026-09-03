/// Satu lencana di katalog.
class BadgeDef {
  const BadgeDef({
    required this.code,
    required this.nama,
    required this.keterangan,
    required this.ikon,
    required this.syarat,
  });

  final String code;
  final String nama;

  /// Kalimat syarat yang dibaca anak. Ditulis apa adanya, termasuk untuk
  /// lencana yang masih terkunci — nama dan syarat yang terbaca jauh
  /// lebih memancing daripada kotak abu tanpa keterangan.
  final String keterangan;

  /// Kunci ikon; dipetakan jadi `IconData` di lapisan UI supaya domain
  /// tidak perlu mengimpor Flutter.
  final String ikon;

  final bool Function(BadgeContext c) syarat;
}

/// Cuplikan keadaan anak saat ini. Semuanya dihitung ulang dari tabel
/// yang sudah ada — tidak ada satu pun penghitung khusus lencana.
class BadgeContext {
  const BadgeContext({
    this.posSelesai = 0,
    this.posTigaBintang = 0,
    this.totalBintang = 0,
    this.zonaTuntas = 0,
    this.planetTuntas = 0,
    this.gerbangSempurna = 0,
    this.streakSekarang = 0,
    this.streakTerbaik = 0,
    this.soalDiperbaiki = 0,
    this.kilatTerbaik = 0,
    this.tantanganSelesai = 0,
    this.soalLatihan = 0,
    this.totalXp = 0,
  });

  final int posSelesai;
  final int posTigaBintang;
  final int totalBintang;
  final int zonaTuntas;
  final int planetTuntas;
  final int gerbangSempurna;
  final int streakSekarang;
  final int streakTerbaik;
  final int soalDiperbaiki;
  final int kilatTerbaik;
  final int tantanganSelesai;
  final int soalLatihan;
  final int totalXp;
}

/// Dua puluh empat lencana, dan yang belum didapat tidak disembunyikan.
///
/// Semuanya bisa dinilai ulang dari nol kapan saja: kalau suatu hari
/// perhitungannya berubah, lencana lama tidak perlu dimigrasikan, cukup
/// dinilai lagi.
abstract final class BadgeRules {
  static const katalog = <BadgeDef>[
    // ---- kemajuan lintasan
    BadgeDef(
      code: 'pos_pertama',
      nama: 'Pos Pertama',
      keterangan: 'Selesaikan satu pos',
      ikon: 'bintang',
      syarat: _posPertama,
    ),
    BadgeDef(
      code: 'pos_10',
      nama: 'Sepuluh Pos',
      keterangan: 'Selesaikan 10 pos',
      ikon: 'jalur',
      syarat: _pos10,
    ),
    BadgeDef(
      code: 'pos_25',
      nama: 'Dua Puluh Lima',
      keterangan: 'Selesaikan 25 pos',
      ikon: 'jalur',
      syarat: _pos25,
    ),
    BadgeDef(
      code: 'pos_50',
      nama: 'Lima Puluh Pos',
      keterangan: 'Selesaikan 50 pos',
      ikon: 'jalur',
      syarat: _pos50,
    ),
    BadgeDef(
      code: 'zona_tuntas',
      nama: 'Zona Tuntas',
      keterangan: 'Tembus satu Gerbang Planet',
      ikon: 'planet',
      syarat: _zona1,
    ),
    BadgeDef(
      code: 'zona_3',
      nama: 'Tiga Zona',
      keterangan: 'Tembus tiga Gerbang Planet',
      ikon: 'planet',
      syarat: _zona3,
    ),
    BadgeDef(
      code: 'planet_tuntas',
      nama: 'Planet Tuntas',
      keterangan: 'Tuntaskan semua zona satu planet',
      ikon: 'roket',
      syarat: _planet1,
    ),

    // ---- bintang
    BadgeDef(
      code: 'bintang_50',
      nama: '50 Bintang',
      keterangan: 'Kumpulkan 50 bintang',
      ikon: 'bintang',
      syarat: _bintang50,
    ),
    BadgeDef(
      code: 'bintang_100',
      nama: '100 Bintang',
      keterangan: 'Kumpulkan 100 bintang',
      ikon: 'bintang',
      syarat: _bintang100,
    ),
    BadgeDef(
      code: 'bintang_200',
      nama: '200 Bintang',
      keterangan: 'Kumpulkan 200 bintang',
      ikon: 'bintang',
      syarat: _bintang200,
    ),

    // ---- ketelitian
    BadgeDef(
      code: 'tanpa_salah',
      nama: 'Tanpa Salah',
      keterangan: 'Satu pos tanpa satu pun jawaban salah',
      ikon: 'centang',
      syarat: _tanpaSalah,
    ),
    BadgeDef(
      code: 'sempurna_5',
      nama: 'Lima Sempurna',
      keterangan: 'Lima pos berbintang tiga',
      ikon: 'centang',
      syarat: _sempurna5,
    ),
    BadgeDef(
      code: 'sempurna_15',
      nama: 'Lima Belas Sempurna',
      keterangan: 'Lima belas pos berbintang tiga',
      ikon: 'centang',
      syarat: _sempurna15,
    ),
    BadgeDef(
      code: 'gerbang_sempurna',
      nama: 'Gerbang Sempurna',
      keterangan: 'Gerbang Planet tanpa salah',
      ikon: 'perisai',
      syarat: _gerbangSempurna,
    ),

    // ---- streak
    BadgeDef(
      code: 'streak_3',
      nama: 'Streak 3 Hari',
      keterangan: 'Main tiga hari berturut-turut',
      ikon: 'api',
      syarat: _streak3,
    ),
    BadgeDef(
      code: 'streak_7',
      nama: 'Streak 7 Hari',
      keterangan: 'Main tujuh hari berturut-turut',
      ikon: 'api',
      syarat: _streak7,
    ),
    BadgeDef(
      code: 'streak_14',
      nama: 'Streak 14 Hari',
      keterangan: 'Main dua minggu berturut-turut',
      ikon: 'api',
      syarat: _streak14,
    ),
    BadgeDef(
      code: 'streak_30',
      nama: 'Streak 30 Hari',
      keterangan: 'Main tiga puluh hari berturut-turut',
      ikon: 'api',
      syarat: _streak30,
    ),

    // ---- latihan
    BadgeDef(
      code: 'perbaiki_10',
      nama: 'Perbaiki 10',
      keterangan: 'Betulkan 10 soal yang pernah salah',
      ikon: 'perbaiki',
      syarat: _perbaiki10,
    ),
    BadgeDef(
      code: 'perbaiki_50',
      nama: 'Perbaiki 50',
      keterangan: 'Betulkan 50 soal yang pernah salah',
      ikon: 'perbaiki',
      syarat: _perbaiki50,
    ),
    BadgeDef(
      code: 'kilat_30',
      nama: 'Kilat 30',
      keterangan: '30 soal benar dalam 60 detik',
      ikon: 'kilat',
      syarat: _kilat30,
    ),
    BadgeDef(
      code: 'kilat_50',
      nama: 'Kilat 50',
      keterangan: '50 soal benar dalam 60 detik',
      ikon: 'kilat',
      syarat: _kilat50,
    ),
    BadgeDef(
      code: 'harian_7',
      nama: 'Tantangan Tujuh',
      keterangan: 'Selesaikan tujuh Tantangan Harian',
      ikon: 'kalender',
      syarat: _harian7,
    ),
    BadgeDef(
      code: 'xp_500',
      nama: '500 XP',
      keterangan: 'Kumpulkan 500 XP',
      ikon: 'xp',
      syarat: _xp500,
    ),
  ];

  static const total = 24;

  static BadgeDef? cari(String code) {
    for (final b in katalog) {
      if (b.code == code) return b;
    }
    return null;
  }

  /// Lencana yang syaratnya sudah terpenuhi tapi belum tercatat.
  static List<BadgeDef> baru(BadgeContext c, Set<String> sudahPunya) => [
    for (final b in katalog)
      if (!sudahPunya.contains(b.code) && b.syarat(c)) b,
  ];

  // Syarat ditulis sebagai fungsi tingkat atas supaya katalognya tetap
  // `const` — daftarnya jadi tidak bisa berubah saat aplikasi berjalan.
  static bool _posPertama(BadgeContext c) => c.posSelesai >= 1;
  static bool _pos10(BadgeContext c) => c.posSelesai >= 10;
  static bool _pos25(BadgeContext c) => c.posSelesai >= 25;
  static bool _pos50(BadgeContext c) => c.posSelesai >= 50;
  static bool _zona1(BadgeContext c) => c.zonaTuntas >= 1;
  static bool _zona3(BadgeContext c) => c.zonaTuntas >= 3;
  static bool _planet1(BadgeContext c) => c.planetTuntas >= 1;
  static bool _bintang50(BadgeContext c) => c.totalBintang >= 50;
  static bool _bintang100(BadgeContext c) => c.totalBintang >= 100;
  static bool _bintang200(BadgeContext c) => c.totalBintang >= 200;
  static bool _tanpaSalah(BadgeContext c) => c.posTigaBintang >= 1;
  static bool _sempurna5(BadgeContext c) => c.posTigaBintang >= 5;
  static bool _sempurna15(BadgeContext c) => c.posTigaBintang >= 15;
  static bool _gerbangSempurna(BadgeContext c) => c.gerbangSempurna >= 1;
  static bool _streak3(BadgeContext c) => c.streakTerbaik >= 3;
  static bool _streak7(BadgeContext c) => c.streakTerbaik >= 7;
  static bool _streak14(BadgeContext c) => c.streakTerbaik >= 14;
  static bool _streak30(BadgeContext c) => c.streakTerbaik >= 30;
  static bool _perbaiki10(BadgeContext c) => c.soalDiperbaiki >= 10;
  static bool _perbaiki50(BadgeContext c) => c.soalDiperbaiki >= 50;
  static bool _kilat30(BadgeContext c) => c.kilatTerbaik >= 30;
  static bool _kilat50(BadgeContext c) => c.kilatTerbaik >= 50;
  static bool _harian7(BadgeContext c) => c.tantanganSelesai >= 7;
  static bool _xp500(BadgeContext c) => c.totalXp >= 500;
}
