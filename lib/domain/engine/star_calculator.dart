import '../models/enums.dart';
import '../models/level.dart';

/// Bintang, XP, dan nyawa — tiga sistem terpisah dengan tugas berbeda.
/// Bintang mengukur penguasaan, XP mengukur usaha, nyawa mengatur tempo.
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

  static int stars({required int correct, required int total}) {
    if (total <= 0) return 0;
    final rasio = correct / total;
    if (rasio >= ambangTigaBintang) return 3;
    if (rasio >= ambangDuaBintang) return 2;
    if (rasio >= ambangSatuBintang) return 1;
    return 0;
  }

  /// XP satu sesi.
  ///
  /// | Kejadian | XP |
  /// |---|---|
  /// | Menyelesaikan pos baru | 10 (30 untuk Gerbang Planet) |
  /// | Bonus bintang tiga | +5 |
  /// | Mengulang pos yang sudah lulus | 2 |
  static int xp({
    required Level level,
    required int stars,
    required bool sudahPernahLulus,
  }) {
    if (stars == 0) return 0;
    if (sudahPernahLulus) return xpMengulang;
    return level.xpReward + (stars == 3 ? bonusTigaBintang : 0);
  }

  static const bonusTigaBintang = 5;
  static const xpMengulang = 2;

  /// XP bawaan sebuah pos menurut jenisnya.
  static int xpReward(LevelType type) =>
      type == LevelType.boss ? xpGerbang : xpPos;

  static const xpPos = 10;
  static const xpGerbang = 30;

  /// Kalimat di layar hasil. Nadanya berbeda untuk tiap jumlah bintang:
  /// yang belum lulus tidak boleh terdengar seperti hukuman.
  static String pesan(int stars) => switch (stars) {
    3 => 'Sempurna! Pos ini sudah dikuasai.',
    2 => 'Dua bintang. Kerjakan lagi untuk dapat tiga.',
    1 => 'Lulus tipis. Pos berikutnya sudah terbuka.',
    _ => 'Belum lulus kali ini. Coba sekali lagi, ya.',
  };
}
