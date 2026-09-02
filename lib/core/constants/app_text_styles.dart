import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografi Angkasa. Satu typeface untuk seluruh aplikasi: **Fredoka**,
/// dibundel di `assets/fonts/` supaya tidak pernah butuh jaringan.
///
/// Semua angka yang berubah saat dilihat — skor, penghitung soal, timer,
/// sisa hati — wajib memakai [tabular]. Angka yang bergoyang tiap detik
/// terlihat murah, dan di layar kuis efeknya langsung terasa.
abstract final class AppTextStyles {
  static const family = 'Fredoka';

  static const tabular = FontFeature.tabularFigures();

  static const _base = TextStyle(fontFamily: family, color: AppColors.ink);

  /// Judul layar. 26 px, seperti `.h1` di ui.html.
  static const h1 = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.26,
  );

  /// Judul bagian. 20 px, seperti `.h2`.
  static const h2 = TextStyle(
    fontFamily: family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const title = TextStyle(
    fontFamily: family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  /// Keterangan di bawah judul. `.sub`.
  static const sub = TextStyle(
    fontFamily: family,
    fontSize: 14.5,
    height: 1.5,
    color: AppColors.ink2,
  );

  static const body = TextStyle(fontFamily: family, fontSize: 15, height: 1.45);

  static const caption = TextStyle(
    fontFamily: family,
    fontSize: 12.5,
    height: 1.4,
    color: AppColors.ink3,
  );

  /// Label huruf besar berjarak, mis. `SOAL 3 DARI 10`.
  static const overline = TextStyle(
    fontFamily: family,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.78,
    color: AppColors.ink3,
    fontFeatures: [tabular],
  );

  /// Teks soal. 38 px dan tabular — panjang barisnya tidak boleh bergeser
  /// waktu `9` berubah jadi `10`.
  static const question = TextStyle(
    fontFamily: family,
    fontSize: 38,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.76,
    fontFeatures: [tabular],
  );

  /// Angka di dalam tombol pilihan ganda.
  static const option = TextStyle(
    fontFamily: family,
    fontSize: 26,
    fontWeight: FontWeight.w600,
    fontFeatures: [tabular],
  );

  /// Angka besar: skor, XP, sisa waktu.
  static const numeral = TextStyle(
    fontFamily: family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    fontFeatures: [tabular],
  );

  static const button = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.17,
  );

  static TextTheme textTheme(Color ink, Color ink2) => TextTheme(
    displayLarge: question.copyWith(color: ink),
    headlineLarge: h1.copyWith(color: ink),
    headlineMedium: h2.copyWith(color: ink),
    titleMedium: title.copyWith(color: ink),
    bodyLarge: body.copyWith(color: ink),
    bodyMedium: _base.copyWith(fontSize: 14.5, height: 1.5, color: ink2),
    labelLarge: button.copyWith(color: ink),
    labelSmall: overline,
  );
}
