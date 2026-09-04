import 'streak_rules.dart';

/// Aturan liga mingguan.
///
/// **Liga tiga puluh pemain, bukan peringkat global.** Peringkat global
/// berarti ada anak yang jadi nomor 40.000 dan tidak pernah bergerak
/// seumur pemakaian; tidak ada satu pun kalimat penyemangat yang bisa
/// menutupi itu. Dengan liga kecil yang direset tiap Senin, posisi
/// terburuk pun cuma bertahan tujuh hari.
///
/// Semua di berkas ini murni perhitungan tanggal dan angka — tidak ada
/// Firebase, tidak ada basis data, jadi seluruhnya bisa diuji tanpa
/// menyalakan apa pun.
abstract final class LigaRules {
  /// Penanda minggu, dipakai jadi `weekId` di Firestore.
  ///
  /// Memakai penomoran ISO 8601: minggu dimulai Senin, dan minggu ke-1
  /// adalah minggu yang memuat hari Kamis pertama tahun itu. Konsekuensi
  /// yang membuatnya layak dipakai: minggu di pergantian tahun tidak
  /// pernah terbelah jadi dua liga. 29 Desember 2025 dan 1 Januari 2026
  /// jatuh di minggu yang sama, dan keduanya menghasilkan `2026-W01`.
  static String idMinggu(DateTime waktu) {
    final hari = StreakRules.tanggalSaja(waktu);
    // Kamis di minggu yang sama menentukan tahun ISO-nya.
    final kamis = hari.add(Duration(days: 4 - hari.weekday));
    final awalTahun = DateTime(kamis.year, 1, 1);
    final nomor = (kamis.difference(awalTahun).inDays / 7).floor() + 1;
    return '${kamis.year}-W${nomor.toString().padLeft(2, '0')}';
  }

  /// Senin pukul 00.00 di minggu [waktu] — awal liga yang sedang jalan.
  static DateTime awalLiga(DateTime waktu) => StreakRules.awalMinggu(waktu);

  /// Senin pukul 00.00 berikutnya — saat liga sekarang ditutup dan yang
  /// baru dimulai.
  static DateTime akhirLiga(DateTime waktu) =>
      awalLiga(waktu).add(const Duration(days: 7));

  /// Berapa hari lagi liga berganti, dibulatkan ke atas.
  ///
  /// Senin pagi berarti 7, Minggu malam berarti 1. Tidak pernah 0 —
  /// "0 hari lagi" tidak berarti apa pun untuk anak, sementara "1 hari
  /// lagi" masih mendorongnya main sore ini.
  static int sisaHari(DateTime sekarang) {
    final sisa = akhirLiga(sekarang).difference(sekarang);
    final hari = (sisa.inMinutes / (60 * 24)).ceil();
    return hari < 1 ? 1 : hari;
  }

  static String kalimatSisa(DateTime sekarang) {
    final n = sisaHari(sekarang);
    return n == 1 ? 'Besok berganti' : '$n hari lagi';
  }

  /// Nomor liga untuk anggota ke-[urutan] minggu itu (dihitung dari 0).
  ///
  /// Pembagiannya sesederhana mungkin dan sengaja begitu: tiga puluh
  /// pendaftar pertama masuk liga 1, tiga puluh berikutnya liga 2, dan
  /// seterusnya. Tidak ada penjodohan menurut kemampuan di tahap ini —
  /// itu butuh data yang belum ada, dan menebaknya lebih buruk daripada
  /// mengakui belum tahu.
  static int ligaUntuk(int urutan, {int ukuran = 30}) =>
      urutan ~/ (ukuran < 1 ? 1 : ukuran) + 1;

  /// Menyusun peringkat dari daftar yang belum urut.
  ///
  /// XP terbesar di atas. Kalau seri, yang lebih dulu mencapainya menang
  /// — jadi anak yang sudah selesai Rabu tidak bisa disalip Minggu malam
  /// oleh angka yang sama persis. Nama panggilan jadi pemutus terakhir
  /// supaya urutannya tetap sama tiap kali dihitung ulang.
  static List<T> urutkan<T>(
    Iterable<T> entri, {
    required int Function(T) xp,
    required DateTime Function(T) diperbarui,
    required String Function(T) nama,
  }) {
    final urut = [...entri];
    urut.sort((a, b) {
      final selisih = xp(b).compareTo(xp(a));
      if (selisih != 0) return selisih;
      final waktu = diperbarui(a).compareTo(diperbarui(b));
      if (waktu != 0) return waktu;
      return nama(a).compareTo(nama(b));
    });
    return urut;
  }

  /// Kalimat pergerakan untuk layar akhir minggu.
  ///
  /// Yang ditonjolkan pergerakannya, bukan posisinya: "Naik 4" tetap
  /// enak dibaca oleh anak di peringkat 25, sementara "Peringkat 25"
  /// saja tidak.
  static String kalimatPergerakan({required int sekarang, int? sebelumnya}) {
    if (sebelumnya == null || sebelumnya <= 0) {
      return 'Liga pertamamu.';
    }
    final selisih = sebelumnya - sekarang;
    if (selisih > 0) return 'Naik $selisih posisi dari minggu lalu.';
    if (selisih < 0) return 'Turun ${-selisih} posisi dari minggu lalu.';
    return 'Posisi yang sama dengan minggu lalu.';
  }
}
