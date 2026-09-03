/// Skema versi 2 — Tahap 2 (retensi).
///
/// Tidak ada tabel baru. Streak, Tantangan Harian, dan Perbaiki
/// Kesalahan semuanya berdiri di atas data yang sudah dikumpulkan Tahap
/// 1; yang bertambah cuma beberapa kolom untuk hal yang memang tidak
/// bisa dihitung ulang dari catatan lama:
///
/// - kapan pelindung streak terakhir terpakai (tidak terekam di mana pun),
/// - rekor Kilat 60 Detik (bukan turunan `level_progress`),
/// - apakah Tantangan Harian hari ini sudah dikerjakan,
/// - jam pemberitahuan yang dipelajari dari `daily_activity`.
const migrationV2 = <String>[
  // Streak terpanjang disimpan terpisah dari streak berjalan: lencana
  // "Streak 30 Hari" tidak boleh hilang cuma karena rentetannya putus.
  'ALTER TABLE user_profile ADD COLUMN streak_best INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE user_profile ADD COLUMN streak_shield_last_used TEXT',
  'ALTER TABLE user_profile ADD COLUMN blitz_best INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE user_profile ADD COLUMN notif_on INTEGER NOT NULL DEFAULT 1',

  // Jam pemberitahuan dipelajari dari jam anak biasanya main, bukan
  // dipatok di kode. `null` berarti belum cukup data — pakai bawaan.
  'ALTER TABLE user_profile ADD COLUMN notif_hour INTEGER',

  'ALTER TABLE daily_activity ADD COLUMN challenge_done INTEGER NOT NULL '
      'DEFAULT 0',
];
