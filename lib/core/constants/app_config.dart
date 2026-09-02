/// Setelan lingkungan.
///
/// Dibaca dari `--dart-define` saat build. Bawaannya luring penuh, jadi
/// `flutter run` tanpa argumen apa pun menjalankan aplikasi persis
/// seperti yang dipasang anak dari Play Store di Tahap 1.
///
/// Pembaca `.env` baru dipasang di Tahap 3, waktu nilai-nilai ini mulai
/// menentukan sesuatu; sampai saat itu, menambah paket untuk membaca
/// berkas yang isinya belum dipakai cuma menambah beban.
abstract final class AppConfig {
  /// `true` berarti tidak ada satu pun panggilan jaringan. Di Tahap 1
  /// nilainya memang selalu `true` — Firebase belum ada di proyek ini.
  static const offlineOnly = bool.fromEnvironment(
    'OFFLINE_ONLY',
    defaultValue: true,
  );

  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  /// Papan peringkat menyala di Tahap 3, dan tetap bisa dimatikan orang
  /// tua tanpa mengunci satu pun materi belajar.
  static const enableLeaderboard = bool.fromEnvironment('ENABLE_LEADERBOARD');
}
