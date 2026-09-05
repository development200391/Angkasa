import 'dart:math';

import '../models/enums.dart';
import '../models/question.dart';
import 'difficulty_config.dart';

/// Membangkitkan soal pecahan.
///
/// Ada supaya Planet Pecah tidak perlu ditulis tangan. Empat puluh pos
/// dikali sepuluh soal berarti 400 soal pecahan yang dipilih satu per
/// satu — dan proyeknya berhenti di situ, persis seperti alasan
/// `QuestionGenerator` ada untuk bilangan bulat.
///
/// **[Operation] ditafsirkan sama persis seperti pada bilangan bulat.**
/// Yang berganti jenis bilangannya, bukan arti operasinya: `tambah`
/// tetap menjumlah, `kali` tetap mengali. Menggunakan `kali` untuk
/// berarti "pecahan senilai" akan menghemat satu field dan menghabiskan
/// setahun kebingungan orang berikutnya yang membaca berkas konten.
///
/// Penyebutnya selalu sama di kedua ruas. Menyamakan penyebut adalah
/// keterampilan tersendiri yang pantas punya zonanya sendiri; menyelipkannya
/// diam-diam ke soal penjumlahan membuat anak gagal karena hal yang belum
/// pernah diajarkan.
class PecahanGenerator {
  PecahanGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Penyebut yang dipakai. Semuanya membagi habis 12 atau 10 supaya
  /// hasilnya tetap ramah dibaca, dan tidak satu pun ganjil besar —
  /// `3/7 + 2/7` benar secara matematika dan tidak berarti apa-apa buat
  /// anak kelas 4.
  static const penyebutRamah = [2, 3, 4, 5, 6, 8, 10, 12];

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

  Question? single(DifficultyConfig config) {
    final penyebut = _penyebut(config);
    final operasi =
        config.operations[_random.nextInt(config.operations.length)];

    return switch (operasi) {
      Operation.tambah ||
      Operation.kurang => _tambahKurang(config, operasi, penyebut),
      Operation.kali => _kaliBulat(config, penyebut),
      // Pembagian pecahan baru masuk kelas 6 dan butuh konsep kebalikan.
      // Sampai zonanya ada, `bagi` jatuh ke penjumlahan alih-alih
      // memulangkan `null` dan membuat posnya kurang soal.
      Operation.bagi => _tambahKurang(config, Operation.tambah, penyebut),
    };
  }

  int _penyebut(DifficultyConfig config) {
    final boleh = penyebutRamah
        .where((n) => n >= config.minOperand && n <= config.maxOperand)
        .toList();
    if (boleh.isEmpty) return 4;
    return boleh[_random.nextInt(boleh.length)];
  }

  // ------------------------------------------------- tambah / kurang
  Question? _tambahKurang(
    DifficultyConfig config,
    Operation operasi,
    int penyebut,
  ) {
    if (penyebut < 2) return null;

    // Pembilang selalu di bawah penyebut: pecahan campuran punya
    // zonanya sendiri, dan `5/4` di pos penjumlahan dasar membuat anak
    // mengira ia salah.
    final a = 1 + _random.nextInt(penyebut - 1);
    final b = 1 + _random.nextInt(penyebut - 1);

    final (kiri, kanan) = operasi == Operation.kurang && b > a
        ? (b, a)
        : (a, b);
    final hasil = operasi == Operation.tambah ? kiri + kanan : kiri - kanan;

    // `allowCarry` di ranah pecahan berarti: hasilnya boleh melewati
    // satu utuh. Sumbu S4 yang sama, arti yang setara — menyimpan ke
    // puluhan dan melewati satu utuh sama-sama "hasilnya keluar dari
    // rentang yang ditunggu anak".
    if (!config.allowCarry && hasil >= penyebut) return null;
    if (hasil <= 0) return null;

    final teksKiri = '$kiri/$penyebut';
    final teksKanan = '$kanan/$penyebut';
    final teksHasil = '$hasil/$penyebut';

    return _rakit(
      config: config,
      operasi: operasi,
      penyebut: penyebut,
      kiri: kiri,
      kanan: kanan,
      hasil: hasil,
      signature: '$teksKiri${operasi.lambang}$teksKanan=?',
      prompt: '$teksKiri ${operasi.lambang} $teksKanan = ?',
      jawaban: teksHasil,
      salah: {
        // Kekeliruan pecahan yang paling sering, dan yang paling pantas
        // punya nama: aturannya diterapkan konsisten, cuma ke bagian
        // yang salah.
        '$hasil/${penyebut * 2}': MistakeKind.penyebutIkutDihitung,
        '${hasil + 1}/$penyebut': MistakeKind.melesetSatu,
        '${hasil - 1}/$penyebut': MistakeKind.melesetSatu,
        '${operasi == Operation.tambah ? (kiri - kanan) : (kiri + kanan)}'
                '/$penyebut':
            MistakeKind.operasiTerbalik,
      },
      pembahasan:
          'Penyebutnya sama, jadi yang dihitung cuma pembilangnya: '
          '$kiri ${operasi.lambang} $kanan = $hasil. '
          'Penyebutnya tetap $penyebut.',
    );
  }

  // --------------------------------------------- pecahan × bilangan
  Question? _kaliBulat(DifficultyConfig config, int penyebut) {
    if (penyebut < 2) return null;
    final a = 1 + _random.nextInt(penyebut - 1);
    final k = 2 + _random.nextInt(4); // 2–5
    final hasil = a * k;

    if (!config.allowCarry && hasil >= penyebut) return null;

    final teksKiri = '$a/$penyebut';
    return _rakit(
      config: config,
      operasi: Operation.kali,
      penyebut: penyebut,
      kiri: a,
      kanan: k,
      hasil: hasil,
      signature: '$teksKiri×$k=?',
      prompt: '$teksKiri × $k = ?',
      jawaban: '$hasil/$penyebut',
      salah: {
        '$hasil/${penyebut * k}': MistakeKind.penyebutIkutDihitung,
        '${a + k}/$penyebut': MistakeKind.operasiTerbalik,
        '${hasil + 1}/$penyebut': MistakeKind.melesetSatu,
        '${hasil - 1}/$penyebut': MistakeKind.melesetSatu,
      },
      pembahasan:
          'Mengali pecahan dengan bilangan bulat: pembilangnya saja yang '
          'dikali. $a × $k = $hasil, penyebutnya tetap $penyebut.',
    );
  }

  // ------------------------------------------------------------ rakit
  Question? _rakit({
    required DifficultyConfig config,
    required Operation operasi,
    required int penyebut,
    required int kiri,
    required int kanan,
    required int hasil,
    required String signature,
    required String prompt,
    required String jawaban,
    required Map<String, MistakeKind> salah,
    required String pembahasan,
    bool penuh = true,
  }) {
    final format = config.formats[_random.nextInt(config.formats.length)];
    final opsi = <AnswerOption>[AnswerOption(label: jawaban, isCorrect: true)];

    // Pengecoh diambil menurut urutan yang ditulis di atas, bukan
    // diacak: yang pertama selalu kekeliruan yang paling sering, jadi
    // anak yang keliru hampir selalu bertemu pengecoh yang benar-benar
    // menamai kekeliruannya. Yang diacak **posisinya** di layar.
    for (final e in salah.entries) {
      if (opsi.length >= config.optionCount) break;
      if (e.key == jawaban) continue;
      if (opsi.any((o) => o.label == e.key)) continue;
      if (e.key.startsWith('0/') || e.key.startsWith('-')) continue;
      opsi.add(AnswerOption(label: e.key, mistake: e.value));
    }

    // Penjaga yang sama seperti di generator geometri, cerita, dan
    // statistik: pengecoh yang bertabrakan dengan jawaban benar hilang
    // diam-diam, dan soalnya turun jadi tiga pilihan tanpa satu pun
    // tanda. Pecahan yang hasilnya kebetulan sama dengan salah
    // satu pengecohnya jatuh ke keadaan yang sama.
    if (penuh && opsi.length < config.optionCount) return null;

    return Question(
      signature: signature,
      format: format,
      prompt: prompt,
      answer: jawaban,
      options: format == QuestionFormat.isian
          ? const []
          : (opsi..shuffle(_random)),
      operation: operasi,
      left: kiri,
      right: kanan,
      result: hasil,
      visualAid: VisualAid.tidakAda,
      explanation: pembahasan,
      timeLimitSeconds: config.timeLimitSeconds,
    );
  }

  /// Membangun ulang soal pecahan dari tanda tangannya, mis. `3/8+2/8=?`.
  ///
  /// Dipakai mode Perbaiki Kesalahan, sama seperti pada bilangan bulat —
  /// tanpa ini, soal pecahan yang dijawab salah tidak akan pernah
  /// muncul lagi di sana, dan justru itu soal yang paling perlu diulang.
  Question? dariSignature(
    String signature, {
    QuestionFormat format = QuestionFormat.pilihanGanda,
    int optionCount = 4,
    int? timeLimitSeconds,
  }) {
    final bersih = signature.replaceAll(' ', '');

    final tambahKurang = RegExp(r'^(\d+)/(\d+)([+−])(\d+)/(\d+)=\?$')
        .firstMatch(bersih);
    if (tambahKurang != null) {
      final kiri = int.parse(tambahKurang.group(1)!);
      final penyebut = int.parse(tambahKurang.group(2)!);
      final kanan = int.parse(tambahKurang.group(4)!);
      if (int.parse(tambahKurang.group(5)!) != penyebut) return null;
      final operasi = tambahKurang.group(3)! == '+'
          ? Operation.tambah
          : Operation.kurang;
      final hasil = operasi == Operation.tambah ? kiri + kanan : kiri - kanan;
      if (hasil <= 0) return null;

      return _rakit(
        config: DifficultyConfig(
          domain: NumberDomain.pecahan,
          formats: [format],
          optionCount: optionCount,
          timeLimitSeconds: timeLimitSeconds,
        ),
        operasi: operasi,
        penyebut: penyebut,
        kiri: kiri,
        kanan: kanan,
        hasil: hasil,
        signature: bersih,
        prompt: '$kiri/$penyebut ${operasi.lambang} $kanan/$penyebut = ?',
        jawaban: '$hasil/$penyebut',
        salah: {
          '$hasil/${penyebut * 2}': MistakeKind.penyebutIkutDihitung,
          '${hasil + 1}/$penyebut': MistakeKind.melesetSatu,
          '${hasil - 1}/$penyebut': MistakeKind.melesetSatu,
          '${operasi == Operation.tambah ? (kiri - kanan) : (kiri + kanan)}'
                  '/$penyebut':
              MistakeKind.operasiTerbalik,
        },
        pembahasan:
            'Penyebutnya sama, jadi yang dihitung cuma pembilangnya: '
            '$kiri ${operasi.lambang} $kanan = $hasil. '
            'Penyebutnya tetap $penyebut.',
      );
    }

    final kali = RegExp(r'^(\d+)/(\d+)×(\d+)=\?$').firstMatch(bersih);
    if (kali != null) {
      final a = int.parse(kali.group(1)!);
      final penyebut = int.parse(kali.group(2)!);
      final k = int.parse(kali.group(3)!);
      final hasil = a * k;
      return _rakit(
        config: DifficultyConfig(
          domain: NumberDomain.pecahan,
          formats: [format],
          optionCount: optionCount,
          timeLimitSeconds: timeLimitSeconds,
        ),
        operasi: Operation.kali,
        penyebut: penyebut,
        kiri: a,
        kanan: k,
        hasil: hasil,
        signature: bersih,
        prompt: '$a/$penyebut × $k = ?',
        jawaban: '$hasil/$penyebut',
        salah: {
          '$hasil/${penyebut * k}': MistakeKind.penyebutIkutDihitung,
          '${a + k}/$penyebut': MistakeKind.operasiTerbalik,
          '${hasil + 1}/$penyebut': MistakeKind.melesetSatu,
          '${hasil - 1}/$penyebut': MistakeKind.melesetSatu,
        },
        penuh: false,
        pembahasan:
            'Mengali pecahan dengan bilangan bulat: pembilangnya saja yang '
            'dikali. $a × $k = $hasil, penyebutnya tetap $penyebut.',
      );
    }

    return null;
  }
}
