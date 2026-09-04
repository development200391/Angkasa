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
///
/// Empat yang pertama dibangkitkan `QuestionGenerator` dari
/// `DifficultyConfig`. Tiga yang terakhir **tidak bisa** — soal cerita
/// butuh konteks, geometri butuh gambar berskala, statistik butuh
/// sekumpulan data yang dipilih supaya modusnya tunggal. Ketiganya
/// dibaca dari tabel `static_questions`, dan itulah yang membuat
/// perbandingan 80% dibangkitkan / 20% ditulis di README jadi nyata.
enum QuestionFormat {
  pilihanGanda,
  isian,
  dragDrop,
  cerita,
  geometri,
  statistik;

  /// Ditulis di pil kecil di atas soal, supaya anak tahu ia sedang
  /// mengerjakan jenis yang berbeda dan tidak mengira aplikasinya rusak
  /// waktu tiba-tiba ada gambar.
  String? get pil => switch (this) {
    QuestionFormat.cerita => 'Soal cerita',
    QuestionFormat.geometri => 'Geometri',
    QuestionFormat.statistik => 'Statistik',
    _ => null,
  };

  /// Ditulis sendiri di berkas konten, jadi namanya ikut jadi kontrak.
  static QuestionFormat dariNama(String nama) =>
      QuestionFormat.values.firstWhere(
        (f) => f.name == nama,
        orElse: () => QuestionFormat.pilihanGanda,
      );
}

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

  // --------------------------------------------- ditambahkan Tahap 4
  // Empat nama di atas lahir dari soal hitung. Soal cerita, geometri,
  // dan statistik punya kekeliruan yang khas dan berulang — dan kalau
  // semuanya jatuh ke `lainnya`, dashboard orang tua kehilangan justru
  // bagian yang paling bisa ditindaklanjuti.
  /// Berhenti sebelum langkah terakhir: mengurangi harga satu barang
  /// padahal yang dibeli tiga.
  langkahTerlewat,

  /// Menjawab dengan angka yang memang ada di soal, tapi bukan yang
  /// ditanyakan — harga satuan dipakai sebagai sisa uang.
  angkaDariSoal,

  /// Menjumlah sisi persegi panjang, bukan mengalikannya.
  dijumlahBukanDikali,

  /// Menghitung keliling padahal yang ditanya luas, atau sebaliknya.
  kelilingBukanLuas,

  /// Membaca diagram dengan benar tapi memilih ukuran yang salah —
  /// mengambil nilai terbesar waktu yang ditanya yang paling sering.
  ukuranPemusatanTertukar,

  /// Hasil yang masuk akal tapi tidak punya nama khusus.
  lainnya;

  String get label => switch (this) {
    MistakeKind.melesetSatu => 'Meleset satu',
    MistakeKind.operasiTerbalik => 'Operasi terbalik',
    MistakeKind.lupaMenyimpan => 'Lupa menyimpan',
    MistakeKind.salahNilaiTempat => 'Salah nilai tempat',
    MistakeKind.langkahTerlewat => 'Berhenti sebelum langkah terakhir',
    MistakeKind.angkaDariSoal => 'Mengambil angka yang ada di soal',
    MistakeKind.dijumlahBukanDikali => 'Dijumlah, bukan dikali',
    MistakeKind.kelilingBukanLuas => 'Keliling dan luas tertukar',
    MistakeKind.ukuranPemusatanTertukar =>
      'Modus, median, dan rata-rata tertukar',
    MistakeKind.lainnya => 'Salah hitung',
  };

  /// Kalimat yang dibaca orang tua di layar Jenis kesalahan.
  ///
  /// Sengaja dipisah dari [label]: yang di atas nama pendek untuk batang
  /// diagram, yang ini menjelaskan **apa yang sebenarnya terjadi di
  /// kepala anak**. Orang tua yang membaca "Lupa menyimpan, 12 kali"
  /// belum tahu harus berbuat apa; yang membaca kalimat di bawah tahu.
  String get penjelasan => switch (this) {
    MistakeKind.melesetSatu =>
      'Cara hitungnya sudah benar, hasilnya lebih atau kurang satu. '
          'Biasanya karena menghitung jari sambil terburu-buru.',
    MistakeKind.operasiTerbalik =>
      'Tandanya terbaca terbalik — dikurangi padahal ditambah.',
    MistakeKind.lupaMenyimpan =>
      'Satuannya benar, tapi simpanan ke puluhan tidak ikut ditambahkan.',
    MistakeKind.salahNilaiTempat =>
      'Angkanya dijumlah apa adanya tanpa melihat mana puluhan dan mana '
          'satuan.',
    MistakeKind.langkahTerlewat =>
      'Soalnya butuh dua langkah, dan berhenti di langkah pertama.',
    MistakeKind.angkaDariSoal =>
      'Menjawab dengan angka yang memang tertulis di soal, tapi bukan '
          'yang ditanyakan.',
    MistakeKind.dijumlahBukanDikali =>
      'Sisi-sisinya dijumlah. Luas didapat dengan mengalikan.',
    MistakeKind.kelilingBukanLuas =>
      'Yang dihitung kelilingnya, padahal yang ditanya luas.',
    MistakeKind.ukuranPemusatanTertukar =>
      'Diagramnya dibaca dengan benar, tapi modus, median, dan rata-rata '
          'masih tertukar.',
    MistakeKind.lainnya => 'Tidak mengikuti satu pola tertentu.',
  };

  static MistakeKind dariNama(String? nama) => MistakeKind.values.firstWhere(
    (m) => m.name == nama,
    orElse: () => MistakeKind.lainnya,
  );
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
