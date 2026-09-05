import 'dart:math';

import '../models/enums.dart';
import '../models/gambar.dart';
import '../models/question.dart';
import 'difficulty_config.dart';

/// Membangkitkan soal statistik beserta diagram batangnya.
///
/// Bagian yang sulit di sini bukan menghitung modus — itu satu baris.
/// Yang sulit **memilih datanya**: sekumpulan angka acak sering punya
/// dua modus, atau median yang jatuh di antara dua nilai, atau
/// rata-rata yang bukan bilangan bulat. Soal yang jawabannya ambigu
/// jauh lebih merusak daripada soal yang terlalu mudah — anak yang
/// menjawab dengan benar lalu disalahkan berhenti percaya pada
/// aplikasinya, dan tidak ada bintang yang bisa memperbaiki itu.
///
/// Jadi datanya dibangkitkan lalu **diperiksa**, dan yang tidak lolos
/// dibuang. Itu sebabnya `single` boleh memulangkan `null`.
class StatistikGenerator {
  StatistikGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Nama yang muncul di sumbu diagram. Pendek supaya labelnya tidak
  /// terpotong di layar sempit, dan lazim di Indonesia.
  static const nama = ['Ani', 'Budi', 'Citra', 'Dedi', 'Eka', 'Fani', 'Gilang'];

  static const judul = [
    'Banyak buku yang dibaca minggu ini',
    'Banyak gelas air yang diminum',
    'Banyak bintang yang dikumpulkan',
    'Banyak soal yang dikerjakan',
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

  /// Ukuran mana yang ditanya dibaca dari [DifficultyConfig.operations]:
  /// `tambah` → modus, `kurang` → median, `kali` → rata-rata. Urutannya
  /// mengikuti urutan diajarkannya, dan sebuah zona memakai satu saja.
  Question? single(DifficultyConfig config) {
    final banyak = 5;
    final maks = config.maxOperand < 3 ? 3 : config.maxOperand;
    final data = [for (var i = 0; i < banyak; i++) 1 + _random.nextInt(maks)];

    final operasi = config.operations.first;
    return switch (operasi) {
      Operation.kurang => _median(config, data),
      Operation.kali || Operation.bagi => _rataRata(config, data),
      Operation.tambah => _modus(config, data),
    };
  }

  GambarBatang _gambar(List<int> data) => GambarBatang(
    judul: judul[_random.nextInt(judul.length)],
    data: [
      for (var i = 0; i < data.length; i++)
        (label: nama[i % nama.length], nilai: data[i]),
    ],
  );

  // --------------------------------------------------------- modus
  Question? _modus(DifficultyConfig config, List<int> data) {
    final hitung = <int, int>{};
    for (final d in data) {
      hitung[d] = (hitung[d] ?? 0) + 1;
    }
    final terbanyak = hitung.values.reduce(max);

    // Modus harus tunggal, dan harus benar-benar berulang. Data yang
    // seluruh nilainya berbeda tidak punya modus, dan menyebut salah
    // satunya sebagai jawaban itu mengajarkan hal yang keliru.
    final kandidat = hitung.entries.where((e) => e.value == terbanyak);
    if (terbanyak < 2 || kandidat.length != 1) return null;

    final modus = kandidat.first.key;
    final tertinggi = data.reduce(max);
    final terendah = data.reduce(min);
    if (modus == tertinggi) return null; // pengecoh "terbesar" jadi benar

    return _rakit(
      config: config,
      data: data,
      kode: 'mo',
      pertanyaan: 'Berapa modusnya?',
      jawaban: '$modus',
      salah: {
        // Mengambil nilai terbesar — kekeliruan modus yang paling
        // sering, dan bentuknya "ukuran pemusatan tertukar".
        '$tertinggi': MistakeKind.ukuranPemusatanTertukar,
        '$terendah': MistakeKind.ukuranPemusatanTertukar,
        // Menjawab dengan **berapa kali** muncul, bukan nilainya.
        '$terbanyak': MistakeKind.angkaDariSoal,
      },
      pembahasan:
          'Modus itu nilai yang paling sering muncul. '
          '$modus muncul $terbanyak kali, lebih sering daripada yang lain.',
    );
  }

  // -------------------------------------------------------- median
  Question? _median(DifficultyConfig config, List<int> data) {
    final urut = [...data]..sort();
    final median = urut[urut.length ~/ 2];
    final tertinggi = urut.last;
    if (median == tertinggi) return null;

    // Nilai tengah **setelah diurutkan**, bukan yang di tengah diagram.
    // Kalau keduanya kebetulan sama, pengecoh yang paling penting
    // berubah jadi jawaban benar dan soalnya kehilangan gunanya.
    final tengahTakUrut = data[data.length ~/ 2];
    if (tengahTakUrut == median) return null;

    return _rakit(
      config: config,
      data: data,
      kode: 'me',
      pertanyaan: 'Berapa mediannya?',
      jawaban: '$median',
      salah: {
        '$tengahTakUrut': MistakeKind.langkahTerlewat,
        '$tertinggi': MistakeKind.ukuranPemusatanTertukar,
        '${urut.first}': MistakeKind.ukuranPemusatanTertukar,
      },
      pembahasan:
          'Median itu nilai tengah **setelah diurutkan**: '
          '${urut.join(", ")}. Yang di tengah $median. '
          'Mengambil batang yang di tengah gambar tanpa mengurutkan '
          'dulu adalah langkah yang terlewat.',
    );
  }

  // ------------------------------------------------------ rata-rata
  Question? _rataRata(DifficultyConfig config, List<int> data) {
    final jumlah = data.reduce((a, b) => a + b);
    if (jumlah % data.length != 0) return null; // harus bulat

    final rata = jumlah ~/ data.length;
    final tertinggi = data.reduce(max);
    if (rata == tertinggi) return null;

    return _rakit(
      config: config,
      data: data,
      kode: 'ra',
      pertanyaan: 'Berapa rata-ratanya?',
      jawaban: '$rata',
      salah: {
        // Dijumlah tapi lupa dibagi banyaknya data.
        '$jumlah': MistakeKind.langkahTerlewat,
        '$tertinggi': MistakeKind.ukuranPemusatanTertukar,
        '${rata + 1}': MistakeKind.melesetSatu,
      },
      pembahasan:
          'Rata-rata = jumlah semua nilai dibagi banyaknya. '
          '${data.join(" + ")} = $jumlah, lalu $jumlah ÷ ${data.length} = '
          '$rata.',
    );
  }

  Question? _rakit({
    required DifficultyConfig config,
    required List<int> data,
    required String kode,
    required String pertanyaan,
    required String jawaban,
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
      signature: '$kode:${data.join(",")}',
      format: QuestionFormat.statistik,
      // Angkanya ikut disebut di prompt, bukan cuma ada di diagram.
      // Diagram yang jadi satu-satunya sumber angka membuat soal ini
      // hilang sama sekali bagi anak yang memakai pembaca layar.
      prompt: '${data.join(", ")} — $pertanyaan',
      answer: jawaban,
      options: opsi..shuffle(_random),
      operation: Operation.tambah,
      left: 0,
      right: 0,
      result: int.tryParse(jawaban) ?? 0,
      visualAid: VisualAid.tidakAda,
      explanation: pembahasan,
      gambar: _gambar(data),
      timeLimitSeconds: config.timeLimitSeconds,
    );
  }

  /// Membangun ulang dari tanda tangan, mis. `mo:3,5,3,4,3`.
  Question? dariSignature(String signature, {int optionCount = 4}) {
    final m = RegExp(r'^(mo|me|ra):([\d,]+)$').firstMatch(signature);
    if (m == null) return null;
    final data = m.group(2)!.split(',').map(int.parse).toList();
    if (data.isEmpty) return null;

    final cfg = DifficultyConfig(optionCount: optionCount);
    return switch (m.group(1)!) {
      'me' => _median(cfg, data),
      'ra' => _rataRata(cfg, data),
      _ => _modus(cfg, data),
    };
  }
}
