/// Hasil perhitungan streak untuk satu hari aktif.
class StreakOutcome {
  const StreakOutcome({
    required this.streak,
    required this.pelindungTerpakai,
    required this.putus,
    required this.hariBaru,
  });

  final int streak;

  /// Pelindung mingguan dipakai diam-diam untuk menambal satu hari yang
  /// terlewat. Anak diberi tahu **sesudahnya**, bukan diminta izin.
  final bool pelindungTerpakai;

  /// Rentetan benar-benar putus dan dimulai lagi dari satu.
  final bool putus;

  /// Hari ini baru dihitung sekarang (bukan sesi kedua di hari yang sama).
  final bool hariBaru;
}

/// Aturan streak.
///
/// Streak dihitung dari hari berturut-turut menyelesaikan minimal satu
/// pos, dengan **satu pelindung gratis per minggu** yang terpakai
/// otomatis.
///
/// Kehilangan streak tiga puluh hari gara-gara satu hari sakit adalah
/// alasan klasik anak berhenti membuka aplikasi — dan itu satu-satunya
/// alasan pelindung ini ada. Bukan mata uang, tidak bisa dibeli, dan
/// tidak pernah ditawarkan sebagai pembelian.
abstract final class StreakRules {
  /// Satu pelindung per minggu kalender.
  static const pelindungPerMinggu = 1;

  static StreakOutcome perbarui({
    required int streakSekarang,
    required DateTime? terakhirAktif,
    required DateTime? pelindungTerakhir,
    required DateTime hariIni,
  }) {
    final ini = tanggalSaja(hariIni);

    if (terakhirAktif == null) {
      return const StreakOutcome(
        streak: 1,
        pelindungTerpakai: false,
        putus: false,
        hariBaru: true,
      );
    }

    final lalu = tanggalSaja(terakhirAktif);
    final jarak = ini.difference(lalu).inDays;

    // Sesi kedua di hari yang sama tidak menambah apa pun.
    if (jarak <= 0) {
      return StreakOutcome(
        streak: streakSekarang,
        pelindungTerpakai: false,
        putus: false,
        hariBaru: false,
      );
    }

    if (jarak == 1) {
      return StreakOutcome(
        streak: streakSekarang + 1,
        pelindungTerpakai: false,
        putus: false,
        hariBaru: true,
      );
    }

    // Persis satu hari bolong, dan pelindung minggu ini belum terpakai.
    if (jarak == 2 &&
        pelindungTersedia(pelindungTerakhir: pelindungTerakhir, hariIni: ini)) {
      return StreakOutcome(
        streak: streakSekarang + 1,
        pelindungTerpakai: true,
        putus: false,
        hariBaru: true,
      );
    }

    return const StreakOutcome(
      streak: 1,
      pelindungTerpakai: false,
      putus: true,
      hariBaru: true,
    );
  }

  /// Pelindung menyala lagi tiap awal minggu, bukan tiap tujuh hari
  /// sejak terakhir dipakai — supaya anak bisa menghitungnya sendiri.
  static bool pelindungTersedia({
    required DateTime? pelindungTerakhir,
    required DateTime hariIni,
  }) {
    if (pelindungTerakhir == null) return true;
    return !samaMinggu(pelindungTerakhir, hariIni);
  }

  /// Senin sebagai awal minggu — sama dengan reset papan peringkat di
  /// Tahap 3, jadi anak cuma perlu mengingat satu hari.
  static DateTime awalMinggu(DateTime d) {
    final t = tanggalSaja(d);
    return t.subtract(Duration(days: t.weekday - DateTime.monday));
  }

  static bool samaMinggu(DateTime a, DateTime b) =>
      awalMinggu(a) == awalMinggu(b);

  static DateTime tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Tujuh hari terakhir, urut dari Senin. Dipakai deretan titik di
  /// layar Tantangan Harian.
  static List<DateTime> mingguIni(DateTime hariIni) {
    final senin = awalMinggu(hariIni);
    return [for (var i = 0; i < 7; i++) senin.add(Duration(days: i))];
  }

  static const hurufHari = ['S', 'S', 'R', 'K', 'J', 'S', 'M'];
}
