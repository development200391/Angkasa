/// Skema versi 4 — konten berbayar dan soal yang tidak bisa
/// dibangkitkan.
///
/// Dua perubahan, dan keduanya lahir dari keputusan yang sama: **materi
/// kelas 3 sampai 6 tidak bisa dibuat generator.** Pecahan, luas, dan
/// modus butuh konteks yang dipilih tangan, dan begitu soalnya ditulis
/// tangan ia butuh tempat menyimpan gambarnya — lalu begitu isinya
/// sebanyak itu, ia jadi hal pertama yang layak dijual.
const migrationV4 = <String>[
  // --------------------------------------------------------- gambar
  // Bukan `image_asset`. Berkas gambar untuk tiap soal geometri berarti
  // ratusan PNG di dalam APK, dan tidak satu pun bisa ikut berubah
  // kalau ukurannya diganti. Yang disimpan di sini **datanya** —
  // `{"jenis":"persegiPanjang","panjang":8,"lebar":5}` — lalu Flutter
  // yang menggambar.
  //
  // Konsekuensinya bukan cuma ukuran APK: petak bantunya jadi bisa
  // dihitung satu per satu oleh anak yang lupa rumusnya, dan diagram
  // batangnya ikut warna tema. Gambar tetap tidak bisa melakukan
  // keduanya.
  'ALTER TABLE static_questions ADD COLUMN figure_json TEXT',

  // Soal statis pun perlu tahu kesalahan apa yang ditiru tiap
  // pengecohnya — kalau tidak, seluruh soal cerita dan geometri jatuh
  // ke `MistakeKind.lainnya` dan dashboard orang tua kehilangan justru
  // bagian yang paling bisa ditindaklanjuti. Disimpan di dalam
  // `options_json`, jadi tidak ada kolom baru; yang bertambah cuma
  // urutan soal supaya isinya tampil dalam urutan yang ditulis
  // penulisnya, bukan urutan abjad id.
  'ALTER TABLE static_questions ADD COLUMN order_index INTEGER NOT NULL '
      'DEFAULT 0',
  'CREATE INDEX idx_static_questions_urutan ON static_questions'
      '(level_id, order_index)',

  // -------------------------------------------------------- berbayar
  // Dipisah dari `is_unlocked`, dan itu bukan kerapian. `is_unlocked`
  // menjawab "planet ini sudah ada isinya?" — pertanyaan tentang
  // konten. Kolom di bawah menjawab "planet ini perlu dibayar?" —
  // pertanyaan tentang hak. Menggabungkannya berarti planet yang belum
  // selesai ditulis dan planet yang belum dibeli jadi tidak bisa
  // dibedakan, dan anak yang belum bayar melihat pesan "segera hadir".
  'ALTER TABLE grades ADD COLUMN requires_purchase INTEGER NOT NULL '
      'DEFAULT 0',

  // Hak yang sudah dimiliki. Satu baris per pembelian, bukan satu
  // kolom `sudah_bayar` di `user_profile`.
  //
  // Alasannya pemulihan: waktu orang tua menekan "Pulihkan pembelian"
  // di HP baru, yang datang dari Play Store adalah daftar pembelian
  // beserta id pesanannya. Tabel yang berbentuk sama dengan daftar itu
  // bisa ditulis ulang apa adanya; satu kolom boolean tidak bisa
  // menyimpan dari mana asalnya, dan itu yang dibutuhkan waktu ada
  // yang menagih bukti.
  //
  // `verified` sengaja ada dan sengaja boleh `0`: pembelian yang belum
  // sempat diverifikasi tetap **membuka planetnya**. Anak yang sudah
  // dibayari tidak boleh menunggu jaringan untuk bisa belajar.
  '''
  CREATE TABLE entitlements (
    code         TEXT PRIMARY KEY,
    purchased_at TEXT NOT NULL,
    source       TEXT NOT NULL,
    order_id     TEXT,
    verified     INTEGER NOT NULL DEFAULT 0
  )
  ''',
];
