/// Jenis pos di lintasan.
enum LevelType {
  /// Pos biasa: 10 soal.
  practice,

  /// Gerbang Planet: 15 soal campuran, tanpa bantuan visual.
  boss,
}

/// Keadaan sebuah pos di mata anak.
enum LevelStatus { locked, unlocked, completed, boss }

/// Operasi hitung yang bisa dibangkitkan generator.
enum Operation {
  tambah,
  kurang,
  kali,
  bagi;

  String get lambang => switch (this) {
    Operation.tambah => '+',
    Operation.kurang => '−',
    Operation.kali => '×',
    Operation.bagi => '÷',
  };
}

/// Sumbu S5 — bagian mana dari kalimat matematika yang ditanyakan.
enum UnknownPosition { hasil, operanKiri, operanKanan, operator }

/// Sumbu S2 — bentuk soal.
enum QuestionFormat { pilihanGanda, isian, dragDrop, cerita }

/// Sumbu S3 — bantuan visual, dari benda nyata sampai angka telanjang.
enum VisualAid { benda, garisBilangan, tidakAda }

/// Nama kesalahan yang ditiru sebuah pengecoh. Inilah yang mengubah
/// `question_attempts` dari catatan nilai jadi data diagnosa.
enum MistakeKind {
  /// Salah hitung jari: meleset satu.
  melesetSatu,

  /// Membaca `+` sebagai `−`, atau sebaliknya.
  operasiTerbalik,

  /// Menjumlah satuan, lupa menyimpan ke puluhan.
  lupaMenyimpan,

  /// Menjumlah angkanya, bukan nilai tempatnya.
  salahNilaiTempat,

  /// Hasil yang masuk akal tapi tidak punya nama khusus.
  lainnya;

  String get label => switch (this) {
    MistakeKind.melesetSatu => 'Meleset satu',
    MistakeKind.operasiTerbalik => 'Operasi terbalik',
    MistakeKind.lupaMenyimpan => 'Lupa menyimpan',
    MistakeKind.salahNilaiTempat => 'Salah nilai tempat',
    MistakeKind.lainnya => 'Salah hitung',
  };
}

/// Empat mode latihan bebas. Tidak satu pun mengubah bintang di
/// lintasan — itu janji yang membuat anak berani mencoba di sini.
enum PracticeMode {
  latihanCepat,
  perbaikiKesalahan,
  tantanganHarian,
  kilat60;

  String get judul => switch (this) {
    PracticeMode.latihanCepat => 'Latihan Cepat',
    PracticeMode.perbaikiKesalahan => 'Perbaiki Kesalahan',
    PracticeMode.tantanganHarian => 'Tantangan Harian',
    PracticeMode.kilat60 => 'Kilat 60 Detik',
  };

  /// Dipakai sebagai `level_id` di `question_attempts`. Berawalan
  /// `latihan:` supaya tidak pernah bentrok dengan id pos sungguhan.
  String get catatanId => 'latihan:$name';
}
