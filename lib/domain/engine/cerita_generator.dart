import 'dart:math';

import '../models/enums.dart';
import '../models/gambar.dart';
import '../models/question.dart';
import 'difficulty_config.dart';

/// Membangkitkan soal cerita dari pola yang ditulis tangan.
///
/// Inilah bagian "20% ditulis" yang dijanjikan README — dan yang
/// ditulis tangan bukan soalnya, melainkan **polanya**. Sebuah pola
/// membawa kalimatnya, dua langkah hitungnya, dan yang paling penting:
/// nama untuk tiap cara anak bisa keliru. Dari satu pola lahir ratusan
/// soal yang angkanya berbeda dan pengecohnya tetap bernama.
///
/// Kenapa ini tidak bisa dibangkitkan sepenuhnya seperti soal hitung:
/// konteksnya harus masuk akal. "Rani membeli 47 pensil seharga Rp 90
/// tiap batang" benar secara aritmetika dan tidak pernah terjadi di
/// dunia. Angka yang wajar untuk uang jajan, banyaknya barang, dan
/// harga satuan adalah pengetahuan tentang Indonesia, bukan tentang
/// matematika — dan itu yang dititipkan di `_barang` dan
/// `_hargaRamah` di bawah.
///
/// Semua pola di bawah **dua langkah**. Soal cerita satu langkah cuma
/// soal hitung yang dipanjangkan kalimatnya; yang benar-benar diuji di
/// sini kemampuan berhenti di langkah yang benar, dan itulah kenapa
/// [MistakeKind.langkahTerlewat] selalu jadi salah satu pengecohnya.
class CeritaGenerator {
  CeritaGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const _nama = [
    'Rani',
    'Bima',
    'Sinta',
    'Dimas',
    'Laras',
    'Yoga',
    'Nadia',
  ];

  List<Question> generate(DifficultyConfig config, {int? count}) {
    final target = count ?? config.questionCount;
    final hasil = <Question>[];
    final dipakai = <String>{};
    var putaran = 0;
    while (hasil.length < target && putaran < target * 80) {
      putaran++;
      final q = single(config);
      if (q == null || !dipakai.add(q.signature)) continue;
      hasil.add(q);
    }
    var i = 0;
    while (hasil.length < target && hasil.isNotEmpty) {
      hasil.add(hasil[i++ % hasil.length]);
    }
    return hasil;
  }

  /// Pola mana yang dipakai dibaca dari [DifficultyConfig.operations],
  /// sama seperti ranah lain: `kurang` → belanja dan kembalian,
  /// `bagi` → membagi rata, `kali` → menghitung total.
  Question? single(DifficultyConfig config) {
    final operasi =
        config.operations[_random.nextInt(config.operations.length)];
    final orang = _nama[_random.nextInt(_nama.length)];

    return switch (operasi) {
      Operation.bagi => _bagiRata(config, orang),
      Operation.kali || Operation.tambah => _hitungTotal(config, orang),
      Operation.kurang => _belanja(config, orang),
    };
  }

  int _acak(int min, int maks) => min + _random.nextInt(maks - min + 1);

  static String _rupiah(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return 'Rp $buf';
  }

  // ------------------------------------------------ belanja & sisa
  /// Pola yang persis ada di mockup layar 27: uang, beberapa barang,
  /// harga satuan, berapa sisanya.
  Question? _belanja(DifficultyConfig config, String orang) {
    final barang = _barang[_random.nextInt(_barang.length)];
    final banyak = _acak(2, 5);
    final harga = _hargaRamah[_random.nextInt(_hargaRamah.length)];
    final belanja = banyak * harga;

    // Uangnya harus cukup, dan sisanya tidak boleh nol — "berapa
    // sisanya" yang jawabannya nol terbaca seperti soal jebakan.
    final uang = ((belanja ~/ 1000) + _acak(1, 3)) * 1000;
    final sisa = uang - belanja;
    if (sisa <= 0 || sisa >= uang) return null;

    return _rakit(
      config: config,
      kode: 'bl',
      kunci: '$banyak,$harga,$uang,${barang.nama},$orang',
      prompt:
          '$orang punya uang ${_rupiah(uang)}. Dia membeli $banyak '
          '${barang.nama}, harganya ${_rupiah(harga)} tiap ${barang.satuan}. '
          'Berapa sisa uang $orang?',
      jawaban: _rupiah(sisa),
      gambar: GambarBenda(
        emoji: barang.emoji,
        jumlah: banyak,
        keterangan: '@ ${_rupiah(harga)}',
        catatan: _rupiah(uang),
      ),
      salah: {
        // Cuma satu barang yang dikurangi — berhenti sebelum mengalikan.
        _rupiah(uang - harga): MistakeKind.langkahTerlewat,
        // Menjawab dengan harga satuannya, angka yang memang ada di soal.
        _rupiah(harga): MistakeKind.angkaDariSoal,
        // Yang dihitung total belanjanya, bukan sisanya.
        _rupiah(belanja): MistakeKind.operasiTerbalik,
      },
      pembahasan:
          'Dua langkah. Pertama total belanjanya: $banyak × '
          '${_rupiah(harga)} = ${_rupiah(belanja)}. '
          'Baru sisanya: ${_rupiah(uang)} − ${_rupiah(belanja)} = '
          '${_rupiah(sisa)}.',
    );
  }

  // --------------------------------------------------- membagi rata
  Question? _bagiRata(DifficultyConfig config, String orang) {
    final barang = _barang[_random.nextInt(_barang.length)];
    final anak = _acak(3, 6);
    final tiap = _acak(2, 8);
    final total = anak * tiap;

    // Sisanya sengaja **sebanyak temannya**. Kalau sisanya lebih kecil
    // dari itu, anak yang lupa menyisihkan tetap mendapat hasil bagi
    // yang sama — pembagian bulatnya menelan kelebihannya — dan
    // pengecoh "berhenti sebelum langkah terakhir" tidak pernah berbeda
    // dari jawaban yang benar.
    final sisa = anak;
    // Tiga pengecohnya harus benar-benar berbeda satu sama lain dan
    // dari jawabannya: `tiap + 1`, `anak`, dan `tiap - 1`.
    if (tiap < 2) return null;
    if (anak == tiap || anak == tiap + 1 || anak == tiap - 1) return null;

    return _rakit(
      config: config,
      kode: 'br',
      kunci: '$total,$anak,$sisa,${barang.nama},$orang',
      prompt:
          '$orang punya ${total + sisa} ${barang.nama}. Dia membagikannya '
          'rata kepada $anak temannya, dan menyisakan $sisa untuk dirinya '
          'sendiri. Berapa ${barang.satuan} yang diterima tiap teman?',
      jawaban: '$tiap',
      gambar: GambarBenda(
        emoji: barang.emoji,
        jumlah: total + sisa,
        keterangan: 'dibagi $anak teman',
      ),
      salah: {
        // Membagi seluruhnya tanpa menyisihkan dulu. Karena sisanya
        // sebanyak temannya, hasilnya persis `tiap + 1`.
        '${(total + sisa) ~/ anak}': MistakeKind.langkahTerlewat,
        '$anak': MistakeKind.angkaDariSoal,
        // Sengaja `tiap - 1`, bukan `tiap + 1`: yang di atas sudah
        // memakai `tiap + 1`, dan dua pengecoh dengan angka yang sama
        // menyusut jadi satu — menyisakan tiga pilihan di pos yang
        // meminta empat, lalu soalnya dibuang penjaga di `_rakit`.
        '${tiap - 1}': MistakeKind.melesetSatu,
      },
      pembahasan:
          'Sisihkan dulu $sisa untuk $orang: ${total + sisa} − $sisa = '
          '$total. Baru dibagi rata: $total ÷ $anak = $tiap '
          '${barang.satuan} tiap teman.',
    );
  }

  // -------------------------------------------------- hitung total
  Question? _hitungTotal(DifficultyConfig config, String orang) {
    final barang = _barang[_random.nextInt(_barang.length)];
    final kotak = _acak(3, 7);
    final tiapKotak = _acak(4, 9);
    final tambahan = _acak(2, 9);
    final total = kotak * tiapKotak + tambahan;

    return _rakit(
      config: config,
      kode: 'ht',
      kunci: '$kotak,$tiapKotak,$tambahan,${barang.nama},$orang',
      prompt:
          '$orang punya $kotak kotak ${barang.nama}, tiap kotak berisi '
          '$tiapKotak. Lalu ibunya memberi $tambahan lagi. '
          'Berapa ${barang.satuan} ${barang.nama} $orang sekarang?',
      jawaban: '$total',
      gambar: GambarBenda(
        emoji: barang.emoji,
        jumlah: kotak,
        keterangan: 'tiap kotak $tiapKotak',
      ),
      salah: {
        // Lupa menambahkan pemberian ibunya.
        '${kotak * tiapKotak}': MistakeKind.langkahTerlewat,
        // Kotak dan isinya dijumlah, bukan dikali.
        '${kotak + tiapKotak + tambahan}': MistakeKind.dijumlahBukanDikali,
        '${total + 1}': MistakeKind.melesetSatu,
      },
      pembahasan:
          'Dua langkah. Isi seluruh kotaknya dulu: $kotak × $tiapKotak = '
          '${kotak * tiapKotak}. Baru tambahkan pemberian ibunya: '
          '${kotak * tiapKotak} + $tambahan = $total.',
    );
  }

  Question? _rakit({
    required DifficultyConfig config,
    required String kode,
    required String kunci,
    required String prompt,
    required String jawaban,
    required Gambar gambar,
    required Map<String, MistakeKind> salah,
    required String pembahasan,
    bool penuh = true,
  }) {
    final opsi = <AnswerOption>[AnswerOption(label: jawaban, isCorrect: true)];
    for (final e in salah.entries) {
      if (opsi.length >= config.optionCount) break;
      if (e.key == jawaban) continue;
      if (opsi.any((o) => o.label == e.key)) continue;
      opsi.add(AnswerOption(label: e.key, mistake: e.value));
    }

    // Pengecoh yang bertabrakan dengan jawaban benar — atau dengan
    // pengecoh lain — **hilang diam-diam**, dan yang hilang justru
    // yang paling penting. Persegi panjang 6 × 3 punya luas 18 dan
    // keliling 18; pengecoh "keliling dan luas tertukar" di situ
    // berubah jadi jawaban yang benar.
    //
    // Soal seperti itu tidak lebih mudah, ia **rusak**: pilihannya
    // tinggal dua, dan anak yang tertukar keliling-luas tidak pernah
    // tercatat tertukar. Jadi soalnya dibuang dan dibangkitkan ulang.
    if (penuh && opsi.length < config.optionCount) return null;

    return Question(
      signature: '$kode:$kunci',
      format: QuestionFormat.cerita,
      prompt: prompt,
      answer: jawaban,
      options: opsi..shuffle(_random),
      operation: Operation.kali,
      left: 0,
      right: 0,
      result: 0,
      visualAid: VisualAid.tidakAda,
      explanation: pembahasan,
      gambar: gambar,
      timeLimitSeconds: config.timeLimitSeconds,
    );
  }

  /// Barang yang benar-benar dibeli anak SD di Indonesia, beserta
  /// satuannya. Salah satuan — "3 buah pensil" — membuat soalnya
  /// terbaca seperti diterjemahkan mesin.
  static const _barang = <({String nama, String satuan, String emoji})>[
    (nama: 'pensil', satuan: 'batang', emoji: '✏️'),
    (nama: 'penghapus', satuan: 'buah', emoji: '🧽'),
    (nama: 'buku tulis', satuan: 'buah', emoji: '📓'),
    (nama: 'permen', satuan: 'butir', emoji: '🍬'),
    (nama: 'kelereng', satuan: 'butir', emoji: '🔵'),
    (nama: 'stiker', satuan: 'lembar', emoji: '⭐'),
  ];

  /// Harga yang benar-benar ada di kantin sekolah. Angka seperti
  /// Rp 1.237 aritmetikanya sama sahnya dan tidak pernah ada di dunia.
  static const _hargaRamah = [500, 1000, 1500, 2000, 2500, 3000];

  /// Membangun ulang soal cerita dari tanda tangannya.
  ///
  /// Tidak seperti soal hitung, yang dirakit ulang di sini **kalimatnya
  /// juga** — dan namanya diambil dari kunci, bukan diacak lagi. Anak
  /// yang membuka Perbaiki Kesalahan harus bertemu soal yang persis
  /// sama, bukan soal serupa dengan tokoh berbeda.
  Question? dariSignature(String signature, {int optionCount = 4}) {
    final m = RegExp(r'^(bl|br|ht):(.+)$').firstMatch(signature);
    if (m == null) return null;
    final bagian = m.group(2)!.split(',');
    if (bagian.length < 4) return null;

    final angka = [for (final b in bagian.take(3)) int.tryParse(b)];
    if (angka.any((a) => a == null)) return null;
    final barang = _barang.where((b) => b.nama == bagian[3]).firstOrNull;
    if (barang == null) return null;

    // Nama tokohnya **ikut** tanda tangan, dan itu bukan hiasan. Anak
    // yang membuka Perbaiki Kesalahan harus bertemu soal yang persis
    // sama — kalimat yang sama, tokoh yang sama. Soal serupa dengan
    // tokoh berbeda membuatnya mengira ia belum pernah salah di situ.
    final orang = bagian.length > 4 && _nama.contains(bagian[4])
        ? bagian[4]
        : _nama.first;
    final cfg = DifficultyConfig(optionCount: optionCount);

    switch (m.group(1)!) {
      case 'bl':
        final banyak = angka[0]!;
        final harga = angka[1]!;
        final uang = angka[2]!;
        final belanja = banyak * harga;
        final sisa = uang - belanja;
        if (sisa <= 0) return null;
        return _rakit(
          config: cfg,
          kode: 'bl',
          kunci: m.group(2)!,
          prompt:
              '$orang punya uang ${_rupiah(uang)}. Dia membeli $banyak '
              '${barang.nama}, harganya ${_rupiah(harga)} tiap '
              '${barang.satuan}. Berapa sisa uang $orang?',
          jawaban: _rupiah(sisa),
          gambar: GambarBenda(
            emoji: barang.emoji,
            jumlah: banyak,
            keterangan: '@ ${_rupiah(harga)}',
            catatan: _rupiah(uang),
          ),
          salah: {
            _rupiah(uang - harga): MistakeKind.langkahTerlewat,
            _rupiah(harga): MistakeKind.angkaDariSoal,
            _rupiah(belanja): MistakeKind.operasiTerbalik,
          },
          pembahasan:
              'Total belanjanya: $banyak × ${_rupiah(harga)} = '
              '${_rupiah(belanja)}. Sisanya: ${_rupiah(uang)} − '
              '${_rupiah(belanja)} = ${_rupiah(sisa)}.',
        );
      case 'br':
        final total = angka[0]!;
        final anak = angka[1]!;
        final sisa = angka[2]!;
        if (anak == 0) return null;
        final tiap = total ~/ anak;
        return _rakit(
          config: cfg,
          kode: 'br',
          kunci: m.group(2)!,
          prompt:
              '$orang punya ${total + sisa} ${barang.nama}. Dia '
              'membagikannya rata kepada $anak temannya, dan menyisakan '
              '$sisa untuk dirinya sendiri. Berapa ${barang.satuan} yang '
              'diterima tiap teman?',
          jawaban: '$tiap',
          gambar: GambarBenda(
            emoji: barang.emoji,
            jumlah: total + sisa,
            keterangan: 'dibagi $anak teman',
          ),
          salah: {
            '${(total + sisa) ~/ anak}': MistakeKind.langkahTerlewat,
            '$anak': MistakeKind.angkaDariSoal,
            '${tiap + 1}': MistakeKind.melesetSatu,
          },
          penuh: false,
          pembahasan:
              'Sisihkan dulu $sisa: ${total + sisa} − $sisa = $total. '
              'Lalu $total ÷ $anak = $tiap.',
        );
      default:
        final kotak = angka[0]!;
        final tiapKotak = angka[1]!;
        final tambahan = angka[2]!;
        final total = kotak * tiapKotak + tambahan;
        return _rakit(
          config: cfg,
          kode: 'ht',
          kunci: m.group(2)!,
          prompt:
              '$orang punya $kotak kotak ${barang.nama}, tiap kotak '
              'berisi $tiapKotak. Lalu ibunya memberi $tambahan lagi. '
              'Berapa ${barang.satuan} ${barang.nama} $orang sekarang?',
          jawaban: '$total',
          gambar: GambarBenda(
            emoji: barang.emoji,
            jumlah: kotak,
            keterangan: 'tiap kotak $tiapKotak',
          ),
          salah: {
            '${kotak * tiapKotak}': MistakeKind.langkahTerlewat,
            '${kotak + tiapKotak + tambahan}': MistakeKind.dijumlahBukanDikali,
            '${total + 1}': MistakeKind.melesetSatu,
          },
          penuh: false,
          pembahasan:
              '$kotak × $tiapKotak = ${kotak * tiapKotak}, lalu '
              '+ $tambahan = $total.',
        );
    }
  }
}
