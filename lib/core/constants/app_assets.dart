/// Jalur berkas aset. Dikumpulkan di satu tempat supaya salah ketik
/// ketahuan saat menulis kode, bukan saat aplikasi jalan.
abstract final class AppAssets {
  static const _img = 'assets/images';

  /// Bintang bersegi sepuluh sisi — satu-satunya aset gambar di layar kuis
  /// dan peta. Geometrinya dihasilkan `design/make3d.py`.
  static const starEmas = '$_img/star_emas.svg';
  static const starKosongGelap = '$_img/star_kosong_gelap.svg';
  static const starKosongTerang = '$_img/star_kosong_terang.svg';
  static const starGembok = '$_img/star_gembok.svg';

  /// Ikon roket, dipakai splash. Salinan dari `docs/icon/` supaya
  /// berkas rilis toko aplikasi tidak ikut masuk ke dalam APK.
  static const logo = '$_img/logo.svg';

  /// Benda untuk bantuan visual sumbu S3 tingkat termudah.
  static const apel = '$_img/apel.svg';

  static const seedDir = 'lib/data/local/database/seed/content';
  static const seedFiles = <String>[
    '$seedDir/planet_mula.json',
    '$seedDir/planet_puluh.json',
  ];
}
