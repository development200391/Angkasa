/// Skema versi 1 — sepuluh tabel.
///
/// Empat tabel pertama adalah **konten**: di-seed sekali saat pertama
/// buka dan hampir tidak pernah berubah. Enam sisanya milik pengguna dan
/// sering ditulis. Pemisahan itu yang nanti membuat pemulihan progres di
/// HP baru sederhana: yang perlu dipulihkan cuma kelompok kedua.
const migrationV1 = <String>[
  // ------------------------------------------------------------ konten
  '''
  CREATE TABLE grades (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    order_index INTEGER NOT NULL,
    icon        TEXT NOT NULL,
    is_unlocked INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE chapters (
    id          TEXT PRIMARY KEY,
    grade_id    TEXT NOT NULL REFERENCES grades(id),
    title       TEXT NOT NULL,
    icon        TEXT NOT NULL,
    color       TEXT NOT NULL,
    order_index INTEGER NOT NULL
  )
  ''',
  'CREATE INDEX idx_chapters_grade ON chapters(grade_id, order_index)',
  '''
  CREATE TABLE levels (
    id                TEXT PRIMARY KEY,
    chapter_id        TEXT NOT NULL REFERENCES chapters(id),
    order_index       INTEGER NOT NULL,
    title             TEXT NOT NULL,
    type              TEXT NOT NULL DEFAULT 'practice',
    difficulty_config TEXT NOT NULL,
    xp_reward         INTEGER NOT NULL DEFAULT 10
  )
  ''',
  'CREATE INDEX idx_levels_chapter ON levels(chapter_id, order_index)',
  '''
  CREATE TABLE static_questions (
    id          TEXT PRIMARY KEY,
    level_id    TEXT NOT NULL REFERENCES levels(id),
    format      TEXT NOT NULL,
    prompt      TEXT NOT NULL,
    image_asset TEXT,
    options_json TEXT,
    answer      TEXT NOT NULL,
    explanation TEXT
  )
  ''',
  'CREATE INDEX idx_static_questions_level ON static_questions(level_id)',

  // ---------------------------------------------------- milik pengguna
  '''
  CREATE TABLE user_profile (
    id               INTEGER PRIMARY KEY,
    nickname         TEXT NOT NULL DEFAULT '',
    avatar_id        TEXT NOT NULL DEFAULT 'roket',
    active_grade_id  TEXT,
    total_xp         INTEGER NOT NULL DEFAULT 0,
    streak_count     INTEGER NOT NULL DEFAULT 0,
    streak_last_date TEXT,
    sound_on         INTEGER NOT NULL DEFAULT 1,
    firebase_uid     TEXT
  )
  ''',
  '''
  CREATE TABLE level_progress (
    level_id           TEXT PRIMARY KEY REFERENCES levels(id),
    stars              INTEGER NOT NULL DEFAULT 0,
    best_score         INTEGER NOT NULL DEFAULT 0,
    attempts           INTEGER NOT NULL DEFAULT 0,
    first_completed_at TEXT,
    last_played_at     TEXT,
    is_unlocked        INTEGER NOT NULL DEFAULT 0
  )
  ''',
  // `mistake_kind` menyimpan nama kesalahan yang ditiru pengecoh yang
  // dipilih anak. Itulah yang mengubah tabel ini dari catatan nilai jadi
  // data diagnosa — dan yang dibaca mode Perbaiki Kesalahan (Tahap 2)
  // serta dashboard orang tua (Tahap 4).
  '''
  CREATE TABLE question_attempts (
    id                 INTEGER PRIMARY KEY AUTOINCREMENT,
    level_id           TEXT NOT NULL,
    question_signature TEXT NOT NULL,
    is_correct         INTEGER NOT NULL,
    time_ms            INTEGER NOT NULL DEFAULT 0,
    answered_at        TEXT NOT NULL,
    mistake_kind       TEXT
  )
  ''',
  'CREATE INDEX idx_attempts_level ON question_attempts(level_id)',
  'CREATE INDEX idx_attempts_salah ON question_attempts(is_correct, answered_at)',
  '''
  CREATE TABLE daily_activity (
    date             TEXT PRIMARY KEY,
    xp_earned        INTEGER NOT NULL DEFAULT 0,
    levels_completed INTEGER NOT NULL DEFAULT 0,
    seconds_played   INTEGER NOT NULL DEFAULT 0
  )
  ''',
  '''
  CREATE TABLE badges (
    code        TEXT PRIMARY KEY,
    unlocked_at TEXT NOT NULL
  )
  ''',
  // Kosong sampai Tahap 3. Dibuat sekarang supaya perubahan skema
  // pertama setelah rilis tidak jatuh di tabel yang paling ramai.
  '''
  CREATE TABLE sync_queue (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    entity       TEXT NOT NULL,
    payload_json TEXT NOT NULL,
    created_at   TEXT NOT NULL
  )
  ''',
];
