import '../models/enums.dart';
import '../models/level.dart';
import 'aturan_nilai.dart';

/// Bintang, XP, dan nyawa — tiga sistem terpisah dengan tugas berbeda.
/// Bintang mengukur penguasaan, XP mengukur usaha, nyawa mengatur tempo.
///
/// Angkanya sendiri tinggal di [AturanNilai], supaya Remote Config bisa
/// menggesernya di Tahap 3. Tiap fungsi di bawah menerima aturan itu
/// dengan bawaan [AturanNilai.bawaan] — yang isinya persis konstanta
/// Tahap 2, jadi pemanggil yang tidak peduli jaringan tidak perlu
/// berubah sama sekali.
abstract final class StarCalculator {
  /// Lima hati per sesi. Bukan nyawa global yang mengisi ulang sendiri:
  /// model itu memblokir anak dari belajar dan mendorong pembelian, dua
  /// hal yang disorot langsung oleh Google Play Families Policy.
  static const heartsPerSession = 5;

  /// Ambang bintang, dalam persen jawaban benar.
  ///
  /// | Hasil | Bintang |
  /// |---|---|
  /// | 10/10 | ★★★ |
  /// | 8–9/10 | ★★ |
  /// | 6–7/10 | ★ |
  /// | < 6/10 | belum lulus |
  static const ambangTigaBintang = 1.0;
  static const ambangDuaBintang = 0.8;
  static const ambangSatuBintang = 0.6;

  static int stars({
    required int correct,
    required int total,
    AturanNilai aturan = AturanNilai.bawaan,
  }) {
    if (total <= 0) return 0;
    final rasio = correct / total;
    if (rasio >= aturan.ambangTigaBintang) return 3;
    if (rasio >= aturan.ambangDuaBintang) return 2;
    if (rasio >= aturan.ambangSatuBintang) return 1;
    return 0;
  }

  /// XP satu sesi.
  ///
  /// | Kejadian | XP |
  /// |---|---|
  /// | Menyelesaikan pos baru | 10 (30 untuk Gerbang Planet) |
  /// | Bonus bintang tiga | +5 |
  /// | Mengulang pos yang sudah lulus | 2 |
  ///
  /// [Level.xpReward] yang tersimpan di basis data tetap dipakai untuk
  /// pos biasa; Remote Config cuma menggeser besaran bawaannya lewat
  /// [AturanNilai.xpGerbang] dan bonusnya, supaya konten yang sudah
  /// di-seed tidak perlu ditulis ulang.
  static int xp({
    required Level level,
    required int stars,
    required bool sudahPernahLulus,
    AturanNilai aturan = AturanNilai.bawaan,
  }) {
    if (stars == 0) return 0;
    if (sudahPernahLulus) return aturan.xpMengulang;
    final dasar = level.isBoss ? aturan.xpGerbang : level.xpReward;
    return dasar + (stars == 3 ? aturan.bonusTigaBintang : 0);
  }

  static const bonusTigaBintang = 5;
  static const xpMengulang = 2;

  /// XP bawaan sebuah pos menurut jenisnya.
  static int xpReward(LevelType type) =>
      type == LevelType.boss ? xpGerbang : xpPos;

  static const xpPos = 10;
  static const xpGerbang = 30;

  /// XP mode latihan bebas.
  ///
  /// Sengaja lebih kecil daripada XP lintasan: latihan itu pemanasan dan
  /// perbaikan, bukan jalan pintas menaikkan angka. Satu-satunya yang
  /// besar adalah Tantangan Harian, dan itu memang alasannya ada —
  /// sekali sehari, XP dobel.
  static int xpLatihan(
    PracticeMode mode,
    int benar, {
    AturanNilai aturan = AturanNilai.bawaan,
  }) => switch (mode) {
    PracticeMode.latihanCepat => benar ~/ 2,
    PracticeMode.perbaikiKesalahan => benar ~/ 2,
    PracticeMode.kilat60 => benar ~/ 3,
    PracticeMode.tantanganHarian => aturan.xpTantangan,
  };

  /// 10 XP dasar, dikali dua.
  static const xpTantangan = 20;

  /// Kalimat di layar hasil. Nadanya berbeda untuk tiap jumlah bintang:
  /// yang belum lulus tidak boleh terdengar seperti hukuman.
  static String pesan(int stars) => switch (stars) {
    3 => 'Sempurna! Pos ini sudah dikuasai.',
    2 => 'Dua bintang. Kerjakan lagi untuk dapat tiga.',
    1 => 'Lulus tipis. Pos berikutnya sudah terbuka.',
    _ => 'Belum lulus kali ini. Coba sekali lagi, ya.',
  };
}
