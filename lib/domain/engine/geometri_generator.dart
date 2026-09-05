import 'dart:math';

import '../models/enums.dart';
import '../models/gambar.dart';
import '../models/question.dart';
import 'difficulty_config.dart';

/// Membangkitkan soal geometri beserta gambarnya.
///
/// Rencana awal menaruh soal geometri di `static_questions` — ditulis
/// satu per satu. Yang mengubahnya keputusan lain: [Gambar] menyimpan
/// gambar **sebagai data**, bukan berkas. Begitu `8 × 5` cuma dua angka
/// dan bukan sebuah PNG, soalnya bisa dibangkitkan seperti soal hitung
/// mana pun — dan yang tersisa untuk ditulis tangan cuma polanya.
///
/// Yang tetap ditulis tangan: **nama kekeliruannya**. `13` bukan
/// sembarang angka salah, itu sisi-sisi yang dijumlah; `26` itu
/// keliling. Dua kekeliruan paling umum di kelas 4, dan keduanya
/// dinamai di sini supaya dashboard orang tua bisa menyebutnya.
class GeometriGenerator {
  GeometriGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  List<Question> generate(DifficultyConfig config, {int? count}) {
    final target = count ?? config.questionCount;
    final hasil = <Question>[];
    final dipakai = <String>{};
    var putaran = 0;
    while (hasil.length < target && putaran < target * 60) {
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

  /// Bentuk mana yang dibangkitkan dibaca dari [DifficultyConfig.operations]:
  /// `kali` berarti luas, `tambah` berarti keliling. Bukan pemaksaan —
  /// luas memang perkalian dan keliling memang penjumlahan, dan anak
  /// yang tertukar keduanya persis sedang tertukar operasinya.
  Question? single(DifficultyConfig config) {
    final segitiga = config.visualAid == VisualAid.garisBilangan;
    final keliling =
        config.operations.contains(Operation.tambah) &&
        !config.operations.contains(Operation.kali);

    return segitiga ? _segitiga(config) : _persegiPanjang(config, keliling);
  }

  int _sisi(DifficultyConfig config) {
    final min = config.minOperand < 2 ? 2 : config.minOperand;
    final maks = config.maxOperand < min + 1 ? min + 1 : config.maxOperand;
    return min + _random.nextInt(maks - min + 1);
  }

  Question? _persegiPanjang(DifficultyConfig config, bool keliling) {
    final panjang = _sisi(config);
    var lebar = _sisi(config);
    // Persegi panjang yang kebetulan persegi bukan salah, tapi soal
    // "berapa luasnya" dengan dua sisi sama membuat pengecoh keliling
    // dan pengecoh dijumlah bertabrakan.
    if (lebar == panjang) lebar = panjang > 2 ? panjang - 1 : panjang + 1;

    final gambar = GambarPersegiPanjang(panjang: panjang, lebar: lebar);
    final jawaban = keliling ? gambar.keliling : gambar.luas;
    final satuan = keliling ? 'cm' : 'cm²';

    return _rakit(
      config: config,
      gambar: gambar,
      signature: 'pp:$panjang×$lebar:${keliling ? "k" : "l"}',
      prompt: keliling
          ? 'Persegi panjang dengan panjang $panjang cm dan lebar '
                '$lebar cm. Berapa kelilingnya?'
          : 'Persegi panjang dengan panjang $panjang cm dan lebar '
                '$lebar cm. Berapa luasnya?',
      jawaban: '$jawaban $satuan',
      salah: keliling
          ? {
              '${gambar.luas} $satuan': MistakeKind.kelilingBukanLuas,
              '${panjang + lebar} $satuan': MistakeKind.langkahTerlewat,
              '${gambar.keliling + 2} $satuan': MistakeKind.melesetSatu,
            }
          : {
              // Dua kekeliruan yang persis ada di mockup layar 28.
              '${panjang + lebar} $satuan': MistakeKind.dijumlahBukanDikali,
              '${gambar.keliling} $satuan': MistakeKind.kelilingBukanLuas,
              '${gambar.luas + panjang} $satuan': MistakeKind.melesetSatu,
            },
      pembahasan: keliling
          ? 'Keliling itu jumlah seluruh sisinya: '
                '$panjang + $lebar + $panjang + $lebar = ${gambar.keliling} cm. '
                'Atau 2 × ($panjang + $lebar).'
          : 'Luas persegi panjang = panjang × lebar = '
                '$panjang × $lebar = ${gambar.luas} cm². '
                'Kalau lupa rumusnya, petak di gambarnya bisa dihitung '
                'satu per satu.',
    );
  }

  Question? _segitiga(DifficultyConfig config) {
    final alas = _sisi(config);
    var tinggi = _sisi(config);
    // Alas × tinggi harus genap supaya luasnya bilangan bulat. Jawaban
    // `17,5 cm²` di pos luas segitiga dasar bukan soal yang lebih
    // sulit — soal yang salah tempat.
    if ((alas * tinggi).isOdd) tinggi = tinggi > 2 ? tinggi - 1 : tinggi + 1;

    final gambar = GambarSegitiga(alas: alas, tinggi: tinggi);
    final luas = alas * tinggi ~/ 2;

    return _rakit(
      config: config,
      gambar: gambar,
      signature: 'sg:$alas×$tinggi',
      prompt:
          'Segitiga dengan alas $alas cm dan tinggi $tinggi cm. '
          'Berapa luasnya?',
      jawaban: '$luas cm²',
      salah: {
        // Lupa dibagi dua: kekeliruan luas segitiga yang paling sering,
        // dan bentuknya persis "berhenti sebelum langkah terakhir".
        '${alas * tinggi} cm²': MistakeKind.langkahTerlewat,
        '${alas + tinggi} cm²': MistakeKind.dijumlahBukanDikali,
        '${luas + 1} cm²': MistakeKind.melesetSatu,
      },
      pembahasan:
          'Luas segitiga = alas × tinggi ÷ 2 = '
          '$alas × $tinggi ÷ 2 = $luas cm². '
          'Bagian ÷ 2 itu yang paling sering terlewat.',
    );
  }

  Question? _rakit({
    required DifficultyConfig config,
    required Gambar gambar,
    required String signature,
    required String prompt,
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
      signature: signature,
      format: QuestionFormat.geometri,
      prompt: prompt,
      answer: jawaban,
      options: opsi..shuffle(_random),
      operation: Operation.kali,
      left: 0,
      right: 0,
      result: int.tryParse(jawaban.split(' ').first) ?? 0,
      visualAid: VisualAid.tidakAda,
      explanation: pembahasan,
      gambar: gambar,
      timeLimitSeconds: config.timeLimitSeconds,
    );
  }

  /// Membangun ulang dari tanda tangan, mis. `pp:8×5:l` atau `sg:6×4`.
  ///
  /// Awalannya sengaja bukan angka: tanda tangan geometri tidak boleh
  /// bisa terbaca sebagai soal hitung oleh generator mana pun.
  Question? dariSignature(String signature, {int optionCount = 4}) {
    final pp = RegExp(r'^pp:(\d+)×(\d+):([kl])$').firstMatch(signature);
    if (pp != null) {
      final panjang = int.parse(pp.group(1)!);
      final lebar = int.parse(pp.group(2)!);
      final keliling = pp.group(3)! == 'k';
      final gambar = GambarPersegiPanjang(panjang: panjang, lebar: lebar);
      final jawaban = keliling ? gambar.keliling : gambar.luas;
      final satuan = keliling ? 'cm' : 'cm²';

      return _rakit(
        config: DifficultyConfig(optionCount: optionCount),
        gambar: gambar,
        signature: signature,
        prompt:
            'Persegi panjang dengan panjang $panjang cm dan lebar '
            '$lebar cm. Berapa ${keliling ? "kelilingnya" : "luasnya"}?',
        jawaban: '$jawaban $satuan',
        salah: keliling
            ? {
                '${gambar.luas} $satuan': MistakeKind.kelilingBukanLuas,
                '${panjang + lebar} $satuan': MistakeKind.langkahTerlewat,
              }
            : {
                '${panjang + lebar} $satuan': MistakeKind.dijumlahBukanDikali,
                '${gambar.keliling} $satuan': MistakeKind.kelilingBukanLuas,
              },
        penuh: false,
        pembahasan: keliling
            ? 'Keliling = 2 × ($panjang + $lebar) = ${gambar.keliling} cm.'
            : 'Luas = $panjang × $lebar = ${gambar.luas} cm².',
      );
    }

    final sg = RegExp(r'^sg:(\d+)×(\d+)$').firstMatch(signature);
    if (sg != null) {
      final alas = int.parse(sg.group(1)!);
      final tinggi = int.parse(sg.group(2)!);
      final luas = alas * tinggi ~/ 2;
      return _rakit(
        config: DifficultyConfig(optionCount: optionCount),
        gambar: GambarSegitiga(alas: alas, tinggi: tinggi),
        signature: signature,
        prompt:
            'Segitiga dengan alas $alas cm dan tinggi $tinggi cm. '
            'Berapa luasnya?',
        jawaban: '$luas cm²',
        salah: {
          '${alas * tinggi} cm²': MistakeKind.langkahTerlewat,
          '${alas + tinggi} cm²': MistakeKind.dijumlahBukanDikali,
        },
        penuh: false,
        pembahasan:
            'Luas segitiga = alas × tinggi ÷ 2 = $alas × $tinggi ÷ 2 = '
            '$luas cm².',
      );
    }

    return null;
  }
}
