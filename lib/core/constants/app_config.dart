/// Setelan lingkungan.
///
/// Semuanya dibaca lewat `--dart-define` saat build. Bawaannya luring
/// penuh, jadi `flutter run` tanpa argumen apa pun menjalankan aplikasi
/// persis seperti yang dipasang anak dari Play Store di Tahap 1 dan 2:
/// tanpa satu pun panggilan jaringan.
///
/// Cara memberikan nilainya sekaligus:
///
/// ```bash
/// flutter run --dart-define-from-file=env.json
/// ```
///
/// `--dart-define-from-file` bawaan Flutter, jadi tidak ada paket
/// pembaca `.env` yang perlu dipasang — dan yang lebih penting, tidak
/// ada berkas setelan yang ikut jadi aset di dalam APK. Contohnya ada
/// di `env.contoh.json`; `env.json` sendiri tidak masuk git.
abstract final class AppConfig {
  /// `true` berarti tidak ada satu pun panggilan jaringan, sekalipun
  /// kunci Firebase di bawah terisi. Sakelar ini menang atas semuanya.
  static const offlineOnly = bool.fromEnvironment(
    'OFFLINE_ONLY',
    defaultValue: true,
  );

  // ------------------------------------------------------- Firebase
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const firebaseSenderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  /// Alamat Firebase Emulator Suite, misalnya `10.0.2.2` dari emulator
  /// Android. Diisi hanya saat mengembangkan; kalau terisi, aplikasi
  /// **tidak pernah** menyentuh proyek Firebase sungguhan.
  static const firebaseEmulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
  );

  /// Keempat nilai ini wajib ada semua. Setengah terisi lebih berbahaya
  /// daripada kosong: Firebase akan menyala lalu gagal di tempat yang
  /// tidak jelas.
  static bool get firebaseLengkap =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;

  /// Apakah aplikasi ini boleh menyentuh jaringan sama sekali.
  static bool get daringAktif => !offlineOnly && firebaseLengkap;

  /// Papan peringkat butuh tiga izin sekaligus: build ini daring,
  /// sakelar ini menyala, dan orang tua tidak mematikannya di layar
  /// Akun & data. Yang ketiga diperiksa di repositori, bukan di sini.
  static const enableLeaderboard = bool.fromEnvironment(
    'ENABLE_LEADERBOARD',
    defaultValue: true,
  );

  /// Menautkan akun Google butuh OAuth client ID dari proyek Firebase
  /// sungguhan. Selama kosong, layar Simpan progres menyebutkan itu apa
  /// adanya alih-alih menampilkan tombol yang pasti gagal ditekan.
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );
}
