/// Skema versi 3 — Tahap 3 (daring ringan).
///
/// Tabel `sync_queue` sudah dibuat sejak versi 1 dan dibiarkan kosong
/// selama dua tahap. Sekarang ia akhirnya dipakai, dan yang perlu
/// ditambahkan cuma tiga kolom yang tidak mungkin ditebak dari awal:
/// kunci untuk menggabungkan antrean, penghitung percobaan, dan pesan
/// galat terakhir.
///
/// Satu tabel benar-benar baru, `league_week`, dan alasannya spesifik:
/// papan peringkat minggu lalu **tidak bisa dihitung ulang** dari data
/// lokal mana pun. Begitu Senin lewat, liga itu sudah ditutup di server;
/// kalau peringkat akhirnya tidak disalin ke HP saat itu juga, layar
/// Akhir minggu tidak punya angka untuk ditampilkan dan pergerakan
/// "naik 4 posisi" jadi mustahil dihitung.
const migrationV3 = <String>[
  // --------------------------------------------------- setelan orang tua
  // Papan peringkat bisa dimatikan tanpa mengunci satu pun materi. Nyala
  // secara bawaan, tapi baru berarti apa-apa setelah Firebase disiapkan.
  'ALTER TABLE user_profile ADD COLUMN leaderboard_on INTEGER NOT NULL '
      'DEFAULT 1',

  // Mati = sinkron hanya lewat Wi-Fi. Bawaannya mati: kuota orang tua
  // bukan milik kita, dan tidak ada satu pun fitur yang rusak karena
  // menunggu Wi-Fi berikutnya.
  'ALTER TABLE user_profile ADD COLUMN sync_cellular INTEGER NOT NULL '
      'DEFAULT 0',

  'ALTER TABLE user_profile ADD COLUMN last_sync_at TEXT',

  // Terisi hanya kalau orang tua menautkan akun Google. Tetap kosong
  // untuk akun anonim, yang merupakan keadaan bawaan seluruh pengguna.
  'ALTER TABLE user_profile ADD COLUMN account_email TEXT',

  // ------------------------------------------------------------ antrean
  'ALTER TABLE sync_queue ADD COLUMN entity_key TEXT NOT NULL DEFAULT ""',
  'ALTER TABLE sync_queue ADD COLUMN attempts INTEGER NOT NULL DEFAULT 0',
  'ALTER TABLE sync_queue ADD COLUMN last_error TEXT',

  // Kunci unik inilah yang membuat antrean menggabungkan dirinya
  // sendiri: menulis profil sepuluh kali sebelum sinyal kembali tetap
  // menyisakan satu baris, yang isinya keadaan terakhir. Tanpa ini,
  // seminggu luring berarti ratusan penulisan Firestore yang semuanya
  // ditimpa penulisan berikutnya.
  'CREATE UNIQUE INDEX idx_sync_queue_kunci ON sync_queue(entity, entity_key)',

  // -------------------------------------------------------------- liga
  '''
  CREATE TABLE league_week (
    week_id  TEXT PRIMARY KEY,
    league   INTEGER NOT NULL DEFAULT 0,
    rank     INTEGER NOT NULL DEFAULT 0,
    players  INTEGER NOT NULL DEFAULT 0,
    xp       INTEGER NOT NULL DEFAULT 0,
    levels   INTEGER NOT NULL DEFAULT 0,
    seen     INTEGER NOT NULL DEFAULT 0
  )
  ''',
];
