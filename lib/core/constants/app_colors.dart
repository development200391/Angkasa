import 'package:flutter/material.dart';

/// Palet Angkasa. Nilainya persis sama dengan tabel Warna di README dan
/// dengan variabel CSS di `design/ui.html` — kalau salah satu berubah,
/// ketiganya harus ikut berubah.
abstract final class AppColors {
  // ---- merek
  static const brand = Color(0xFFC07C12);
  static const brandLight = Color(0xFFE9B24C);

  // ---- latar
  static const space = Color(0xFF0E1730);
  static const space2 = Color(0xFF16213C);
  static const bg = Color(0xFFECEFF5);
  static const surface = Color(0xFFFFFFFF);

  // ---- teks
  static const ink = Color(0xFF121A2B);
  static const ink2 = Color(0xFF535F77);
  static const ink3 = Color(0xFF8490A4);
  static const line = Color(0xFFD3DAE5);

  // ---- teks di atas latar angkasa
  static const inkOnSpace = Color(0xFFEAF0FB);
  static const ink2OnSpace = Color(0xFF94A3C0);
  static const ink3OnSpace = Color(0xFF8B9AB8);
  static const lineOnSpace = Color(0x1AFFFFFF);

  // ---- status
  static const ok = Color(0xFF256F5A);
  static const okSoft = Color(0xFFE1F0EB);
  static const wrong = Color(0xFFB23A48);
  static const wrongSoft = Color(0xFFFBE7E9);
  static const lock = Color(0xFF96A0B2);
  static const flame = Color(0xFFE9863A);

  // ---- planet, satu warna per kelas (mengisi kolom `chapters.color`)
  static const mula = Color(0xFF4FA3D9);
  static const puluh = Color(0xFF3E9E77);
  static const kali = Color(0xFFE08A2E);
  static const pecah = Color(0xFF8A6BC4);
  static const ukur = Color(0xFFD2624C);
  static const ruang = Color(0xFF4B5DB0);

  static const planet = <Color>[mula, puluh, kali, pecah, ukur, ruang];

  /// Warna planet untuk kelas 1–6. Di luar rentang itu dikembalikan [mula].
  static Color forGrade(int gradeNumber) {
    if (gradeNumber < 1 || gradeNumber > planet.length) return mula;
    return planet[gradeNumber - 1];
  }

  /// `#RRGGBB` dari basis data jadi [Color].
  static Color fromHex(String hex) {
    final v = hex.replaceFirst('#', '');
    return Color(int.parse(v.length == 6 ? 'FF$v' : v, radix: 16));
  }

  // ---- gradien dan bayangan tombol utama (lihat .btn.primary di ui.html)
  static const primaryButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFE6A945), Color(0xFFC98216), Color(0xFFA96A0D)],
    stops: [0.0, 0.44, 1.0],
  );
  static const primaryButtonBody = Color(0xFF7E4E07);
  static const wrongButtonBody = Color(0xFF8B2A36);
}
