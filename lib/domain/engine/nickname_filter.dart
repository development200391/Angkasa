import 'dart:math';

/// Hasil pemeriksaan satu nama panggilan.
class HasilNama {
  const HasilNama._(this.boleh, this.alasan);

  const HasilNama.boleh() : this._(true, null);
  const HasilNama.tolak(String alasan) : this._(false, alasan);

  final bool boleh;

  /// Kalimat yang ditampilkan tepat di bawah kotak isian. Selalu
  /// menyebutkan apa yang harus diubah, bukan cuma "nama tidak valid".
  final String? alasan;
}

/// Penyaring nama panggilan.
///
/// Nama panggilan adalah **satu-satunya teks bebas di seluruh aplikasi**
/// — jadi satu-satunya yang perlu disaring. Sebelum Tahap 3 ia cuma
/// tulisan di layar Profil milik sendiri; begitu ia ikut terkirim ke
/// papan peringkat, ia jadi tulisan yang dibaca anak lain, dan itu
/// aturan mainnya berubah total.
///
/// Yang dijaga ada tiga, berurutan menurut seberapa mahal akibatnya:
///
/// 1. **Data pribadi.** Nomor telepon dan tahun lahir tidak boleh muat.
///    Karena itu angka dibatasi tiga digit: nomor telepon butuh delapan,
///    tahun lahir butuh empat.
/// 2. **Kata kasar.** Diperiksa pada bentuk yang sudah dinormalkan, jadi
///    `k4mpr3t` ketahuan sama seperti `kampret`.
/// 3. **Nama yang tidak bisa dibaca.** Huruf berulang dan tanda baca
///    dibuang supaya papan peringkat tetap terbaca.
///
/// Penyaring ini sengaja lugas dan seluruhnya di HP: mengirim nama anak
/// ke layanan moderasi pihak ketiga berarti mengirim data anak keluar
/// untuk memeriksa sesuatu yang bisa diperiksa di tempat.
abstract final class NicknameFilter {
  static const panjangMinimal = 3;
  static const panjangMaksimal = 16;
  static const digitMaksimal = 3;

  /// Kata yang tidak boleh muncul di dalam nama, dalam bentuk normal.
  ///
  /// Daftarnya pendek dan sengaja begitu: yang panjang menghasilkan
  /// korban salah tangkap ("Bagus" tersaring karena memuat "agus"),
  /// dan anak yang namanya ditolak tanpa alasan yang masuk akal tidak
  /// akan mencoba lagi. Cocoknya memakai pencarian bagian kata, jadi
  /// imbuhan dan sisipan ikut kena.
  static const terlarang = <String>[
    'anjing',
    'anjg',
    'anjay',
    'asu',
    'babi',
    'bajingan',
    'bangsat',
    'bego',
    'bodoh',
    'goblok',
    'idiot',
    'jancok',
    'kampret',
    'kontol',
    'memek',
    'ngentot',
    'pepek',
    'pukimak',
    'setan',
    'sialan',
    'tolol',
    'fuck',
    'shit',
    'bitch',
    'dick',
    'porn',
    'sex',
    'nazi',
    'hitler',
  ];

  /// Kata yang menandakan anak sedang menuliskan identitas atau kontak,
  /// bukan nama panggilan. Dicari sebagai bagian kata.
  static const bukanNamaPanggilan = <String>[
    'whatsapp',
    'telegram',
    'gmail',
    'email',
    'admin',
    'nomorku',
    'kelas',
    'sdit',
    'sekolah',
    'alamat',
    'rumahku',
  ];

  /// Singkatan pendek yang **tidak** boleh dicari sebagai bagian kata:
  /// `wa` ada di dalam "BintangWarna" dan `mi` di dalam "KomiKu", dan
  /// menolak keduanya jauh lebih merugikan daripada meloloskannya.
  ///
  /// Yang ditangkap justru pola khasnya — singkatan sekolah yang
  /// langsung diikuti angka kelas, seperti `SDN12`. Itu gabungan nama
  /// sekolah dan kelas dalam satu kata, dan persis itu yang tidak boleh
  /// terbaca anak lain di papan peringkat.
  static const singkatanPendek = <String>['wa', 'sdn', 'sd', 'mi', 'smp'];

  /// Angka dan simbol yang sering dipakai menggantikan huruf, supaya
  /// `4nj1n9` diperiksa sebagai `anjing`.
  static const _pengganti = <String, String>{
    '4': 'a',
    '@': 'a',
    '3': 'e',
    '1': 'i',
    '!': 'i',
    '0': 'o',
    '5': 's',
    '\$': 's',
    '7': 't',
    '9': 'g',
    '6': 'g',
    '8': 'b',
    '2': 'z',
  };

  /// Bentuk normal sebuah nama: huruf kecil, angka-pengganti
  /// dikembalikan jadi huruf, sisanya dibuang.
  static String normalkan(String nama) {
    final buf = StringBuffer();
    for (final huruf in nama.toLowerCase().split('')) {
      final ganti = _pengganti[huruf];
      if (ganti != null) {
        buf.write(ganti);
      } else if (RegExp(r'[a-z]').hasMatch(huruf)) {
        buf.write(huruf);
      }
    }
    return buf.toString();
  }

  static HasilNama periksa(String masukan) {
    final nama = masukan.trim();

    if (nama.length < panjangMinimal) {
      return const HasilNama.tolak('Minimal $panjangMinimal huruf.');
    }
    if (nama.length > panjangMaksimal) {
      return const HasilNama.tolak('Maksimal $panjangMaksimal huruf.');
    }
    if (!RegExp(r'^[A-Za-z]').hasMatch(nama)) {
      return const HasilNama.tolak('Harus dimulai dengan huruf.');
    }
    if (!RegExp(r'^[A-Za-z0-9]+$').hasMatch(nama)) {
      return const HasilNama.tolak('Hanya huruf dan angka, tanpa spasi.');
    }

    final digit = RegExp(r'[0-9]').allMatches(nama).length;
    if (digit > digitMaksimal) {
      return const HasilNama.tolak(
        'Angkanya terlalu banyak. Nomor telepon dan tahun lahir '
        'jangan dipakai, ya.',
      );
    }

    if (RegExp(r'(.)\1{3,}').hasMatch(nama.toLowerCase())) {
      return const HasilNama.tolak('Ada huruf yang berulang terlalu banyak.');
    }

    final normal = normalkan(nama);
    if (normal.length < panjangMinimal) {
      return const HasilNama.tolak('Pakai lebih banyak huruf, ya.');
    }
    for (final kata in terlarang) {
      if (normal.contains(kata)) {
        return const HasilNama.tolak('Nama ini tidak boleh dipakai.');
      }
    }
    for (final kata in bukanNamaPanggilan) {
      if (normal.contains(kata)) {
        return const HasilNama.tolak(
          'Sekolah, kelas, dan kontak jangan dipakai jadi nama.',
        );
      }
    }

    final kecil = nama.toLowerCase();
    for (final kata in singkatanPendek) {
      final utuh = kecil == kata;
      final diikutiAngka = RegExp('$kata[0-9]').hasMatch(kecil);
      if (utuh || diikutiAngka) {
        return const HasilNama.tolak(
          'Sekolah, kelas, dan kontak jangan dipakai jadi nama.',
        );
      }
    }

    return const HasilNama.boleh();
  }

  static const _depan = <String>[
    'Bintang',
    'Astro',
    'Meteor',
    'Roket',
    'Pesawat',
    'Bulan',
    'Komet',
    'Nebula',
    'Galaksi',
    'Orbit',
    'Satelit',
    'Planet',
  ];

  static const _belakang = <String>[
    'Kecil',
    'Tujuh',
    'Lucu',
    'Ku',
    'Sabit',
    'Cepat',
    'Berani',
    'Ceria',
    'Hebat',
    'Baru',
    'Emas',
    'Biru',
  ];

  /// Empat saran nama, seperti di layar Nama panggilan.
  ///
  /// Sarannya ada bukan sebagai hiasan: anak yang namanya baru ditolak
  /// butuh jalan keluar yang bisa ditekan sekali, bukan disuruh memikirkan
  /// nama lain dari nol.
  static List<String> saran({int jumlah = 4, Random? acak}) {
    final r = acak ?? Random();
    final hasil = <String>{};
    var jaga = 0;
    while (hasil.length < jumlah && jaga++ < 200) {
      final nama =
          _depan[r.nextInt(_depan.length)] +
          _belakang[r.nextInt(_belakang.length)];
      if (nama.length <= panjangMaksimal && periksa(nama).boleh) {
        hasil.add(nama);
      }
    }
    return hasil.toList();
  }
}
