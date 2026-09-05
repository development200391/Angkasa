import 'dart:math';

import '../models/enums.dart';
import '../models/question.dart';
import 'difficulty_config.dart';

/// Membangkitkan soal desimal dan persen untuk Planet Ukur.
///
/// Dua ranah dalam satu berkas karena keduanya berbagi satu kekeliruan
/// yang mendominasi segalanya: **letak koma**. Anak yang menjawab
/// `0,7 + 0,4 = 11` dan anak yang menjawab `20% dari 150 = 3000`
/// melakukan hal yang sama — menghitung angkanya dengan benar lalu
/// kehilangan kelipatan sepuluh. Memberi keduanya nama yang sama
/// membuat dashboard orang tua bisa menyebutnya sekali, bukan dua kali
/// dengan istilah berbeda.
///
/// Seluruh hitungan dikerjakan dalam **persepuluhan bulat**, tidak
/// pernah `double`. `0.1 + 0.2` di komputer bukan `0.3`, dan soal
/// matematika anak bukan tempat yang tepat untuk menjelaskan IEEE 754.
class DesimalGenerator {
  DesimalGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Persentase yang dipakai. Semuanya bisa dihitung di kepala lewat
  /// separuh, seperempat, atau sepersepuluh — soal `37% dari 84`
  /// menguji kalkulator, bukan pemahaman.
  static const persenRamah = [10, 20, 25, 50, 75];

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

  Question? single(DifficultyConfig config) => switch (config.domain) {
    NumberDomain.persen => _persen(config),
    _ => _desimal(config),
  };

  /// `73` → `7,3`. Koma, bukan titik: ini aplikasi berbahasa Indonesia,
  /// dan anak kelas 5 menulis `7,3` di buku tulisnya.
  static String tulis(int persepuluhan) {
    final tanda = persepuluhan < 0 ? '-' : '';
    final n = persepuluhan.abs();
    return '$tanda${n ~/ 10},${n % 10}';
  }

  // ------------------------------------------------------- desimal
  Question? _desimal(DifficultyConfig config) {
    final min = (config.minOperand < 1 ? 1 : config.minOperand);
    final maks = config.maxOperand < min ? min : config.maxOperand;

    final operasi =
        config.operations.contains(Operation.kurang) && _random.nextBool()
        ? Operation.kurang
        : Operation.tambah;

    var a = min + _random.nextInt(maks - min + 1);
    var b = min + _random.nextInt(maks - min + 1);
    if (operasi == Operation.kurang && b > a) {
      final t = a;
      a = b;
      b = t;
    }

    final hasil = operasi == Operation.tambah ? a + b : a - b;
    if (hasil <= 0) return null;

    // `allowCarry` di ranah desimal berarti hasilnya boleh menyeberangi
    // bilangan bulat — persepuluhannya menyimpan ke satuan. Sumbu S4
    // yang sama, arti yang setara.
    final menyeberang = operasi == Operation.tambah
        ? (a % 10) + (b % 10) >= 10
        : (a % 10) < (b % 10);
    if (!config.allowCarry && menyeberang) return null;

    final teksA = tulis(a);
    final teksB = tulis(b);

    return _rakit(
      config: config,
      operasi: operasi,
      kiri: a,
      kanan: b,
      hasil: hasil,
      signature: '$teksA${operasi.lambang}$teksB=?',
      prompt: '$teksA ${operasi.lambang} $teksB = ?',
      jawaban: tulis(hasil),
      salah: {
        // Komanya hilang sama sekali: 0,7 + 0,4 dijawab 11.
        '$hasil': MistakeKind.komaSalahTempat,
        // Komanya kelewat satu tempat ke kiri.
        '0,$hasil': MistakeKind.komaSalahTempat,
        tulis(hasil + 1): MistakeKind.melesetSatu,
        tulis(hasil - 1): MistakeKind.melesetSatu,
        tulis(operasi == Operation.tambah ? (a - b).abs() : a + b):
            MistakeKind.operasiTerbalik,
      },
      pembahasan:
          'Samakan dulu tempat komanya, lalu hitung seperti bilangan '
          'biasa: ${a ~/ 10},${a % 10} ${operasi.lambang} '
          '${b ~/ 10},${b % 10} = ${tulis(hasil)}.',
    );
  }

  // -------------------------------------------------------- persen
  Question? _persen(DifficultyConfig config) {
    final p = persenRamah[_random.nextInt(persenRamah.length)];

    // Bilangan dasarnya kelipatan 20 supaya seluruh persentase di atas
    // memulangkan bilangan bulat. Jawaban `22,5` di pos persen dasar
    // bukan soal yang lebih sulit — soal yang salah tempat.
    final maks = config.maxOperand < 20 ? 20 : config.maxOperand;
    final kelipatan = 1 + _random.nextInt(maks ~/ 20);
    final dasar = kelipatan * 20;

    final hasil = dasar * p ~/ 100;
    if (hasil <= 0) return null;

    return _rakit(
      config: config,
      operasi: Operation.kali,
      kiri: p,
      kanan: dasar,
      hasil: hasil,
      signature: '$p%$dasar=?',
      prompt: '$p% dari $dasar = ?',
      jawaban: '$hasil',
      salah: {
        // Lupa membagi seratus: 20 × 150.
        '${dasar * p}': MistakeKind.komaSalahTempat,
        // Menjawab dengan angka yang memang tertulis di soal.
        '$p': MistakeKind.angkaDariSoal,
        // Yang dihitung sisanya, bukan bagiannya.
        '${dasar - hasil}': MistakeKind.langkahTerlewat,
        // Dibagi sepuluh, bukan seratus. Ada supaya soal 50% tetap
        // bisa dibangkitkan: di situ "sisanya" selalu sama dengan
        // jawabannya, dan tanpa pengecoh kelima ini seluruh soal 50%
        // akan ditolak penjaga — menghapus persentase yang justru
        // paling sering dipakai anak.
        '${dasar * p ~/ 10}': MistakeKind.komaSalahTempat,
        '${hasil + 1}': MistakeKind.melesetSatu,
      },
      pembahasan:
          '$p% berarti $p dari tiap 100. '
          '$dasar ÷ 100 = ${dasar ~/ 100 == 0 ? (dasar / 100) : dasar ~/ 100}, '
          'lalu dikali $p — atau langsung: $dasar × $p ÷ 100 = $hasil.',
    );
  }

  // ------------------------------------------------------------ rakit
  Question? _rakit({
    required DifficultyConfig config,
    required Operation operasi,
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

    for (final e in salah.entries) {
      if (opsi.length >= config.optionCount) break;
      if (e.key == jawaban) continue;
      if (opsi.any((o) => o.label == e.key)) continue;
      if (e.key.startsWith('-') || e.key == '0' || e.key == '0,0') continue;
      opsi.add(AnswerOption(label: e.key, mistake: e.value));
    }

    // Penjaga yang sama seperti di generator geometri, cerita, dan
    // statistik: pengecoh yang bertabrakan dengan jawaban benar hilang
    // diam-diam, dan soalnya turun jadi tiga pilihan tanpa satu pun
    // tanda. `50% dari 100` yang lolos ke sini punya jawaban 50 dan
    // pengecoh "sisanya" yang juga 50.
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

  /// Membangun ulang soal desimal atau persen dari tanda tangannya.
  Question? dariSignature(
    String signature, {
    QuestionFormat format = QuestionFormat.pilihanGanda,
    int optionCount = 4,
    int? timeLimitSeconds,
  }) {
    final bersih = signature.replaceAll(' ', '');

    final desimal = RegExp(r'^(\d+),(\d)([+−])(\d+),(\d)=\?$')
        .firstMatch(bersih);
    if (desimal != null) {
      final a =
          int.parse(desimal.group(1)!) * 10 + int.parse(desimal.group(2)!);
      final b =
          int.parse(desimal.group(4)!) * 10 + int.parse(desimal.group(5)!);
      final operasi = desimal.group(3)! == '+'
          ? Operation.tambah
          : Operation.kurang;
      final hasil = operasi == Operation.tambah ? a + b : a - b;
      if (hasil <= 0) return null;

      return _rakit(
        config: DifficultyConfig(
          domain: NumberDomain.desimal,
          formats: [format],
          optionCount: optionCount,
          timeLimitSeconds: timeLimitSeconds,
        ),
        operasi: operasi,
        kiri: a,
        kanan: b,
        hasil: hasil,
        signature: bersih,
        prompt: '${tulis(a)} ${operasi.lambang} ${tulis(b)} = ?',
        jawaban: tulis(hasil),
        salah: {
          '$hasil': MistakeKind.komaSalahTempat,
          '0,$hasil': MistakeKind.komaSalahTempat,
          tulis(hasil + 1): MistakeKind.melesetSatu,
          tulis(hasil - 1): MistakeKind.melesetSatu,
          tulis(operasi == Operation.tambah ? (a - b).abs() : a + b):
              MistakeKind.operasiTerbalik,
        },
        pembahasan:
            'Samakan dulu tempat komanya, lalu hitung seperti bilangan '
            'biasa: ${tulis(a)} ${operasi.lambang} ${tulis(b)} = '
            '${tulis(hasil)}.',
      );
    }

    final persen = RegExp(r'^(\d+)%(\d+)=\?$').firstMatch(bersih);
    if (persen != null) {
      final p = int.parse(persen.group(1)!);
      final dasar = int.parse(persen.group(2)!);
      final hasil = dasar * p ~/ 100;
      if (hasil <= 0) return null;

      return _rakit(
        config: DifficultyConfig(
          domain: NumberDomain.persen,
          formats: [format],
          optionCount: optionCount,
          timeLimitSeconds: timeLimitSeconds,
        ),
        operasi: Operation.kali,
        kiri: p,
        kanan: dasar,
        hasil: hasil,
        signature: bersih,
        prompt: '$p% dari $dasar = ?',
        jawaban: '$hasil',
        salah: {
          '${dasar * p}': MistakeKind.komaSalahTempat,
          '$p': MistakeKind.angkaDariSoal,
          '${dasar - hasil}': MistakeKind.langkahTerlewat,
          '${hasil + 1}': MistakeKind.melesetSatu,
        },
        penuh: false,
        pembahasan:
            '$p% berarti $p dari tiap 100. '
            '$dasar × $p ÷ 100 = $hasil.',
      );
    }

    return null;
  }
}
