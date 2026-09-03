import 'dart:math';

import '../models/enums.dart';
import '../models/question.dart';
import 'difficulty_config.dart';
import 'distractor_builder.dart';

/// Membangkitkan soal hitung dari sebuah [DifficultyConfig].
///
/// Yang disimpan di basis data adalah konfigurasinya, bukan soalnya.
/// Tanpa keputusan ini, mengisi 250 pos berarti menulis 2.500 soal
/// dengan tangan — dan proyeknya berhenti di situ.
class QuestionGenerator {
  QuestionGenerator({Random? random, DistractorBuilder? distractors})
    : _random = random ?? Random(),
      _distractors = distractors ?? DistractorBuilder(random: random);

  final Random _random;
  final DistractorBuilder _distractors;

  /// Satu set soal untuk satu sesi. Tidak ada dua soal yang sama dalam
  /// satu set selama variasinya masih cukup.
  List<Question> generate(DifficultyConfig config, {int? count}) {
    final target = count ?? config.questionCount;
    final hasil = <Question>[];
    final dipakai = <String>{};
    var putaran = 0;
    while (hasil.length < target && putaran < target * 60) {
      putaran++;
      final q = single(config);
      if (!dipakai.add(q.signature)) continue;
      hasil.add(q);
    }
    // Variasi habis (mis. rentang 1–5 tanpa menyimpan): ulangi yang ada
    // daripada memulangkan set yang kurang dari yang dijanjikan.
    var i = 0;
    while (hasil.length < target && hasil.isNotEmpty) {
      hasil.add(hasil[i++ % hasil.length]);
    }
    return hasil;
  }

  /// Soal Gerbang Planet: campuran dari pos-pos sebelumnya di zona itu,
  /// tapi selalu memakai bentuk, bantuan, dan timer milik [config] —
  /// gerbangnya menguji materinya, bukan mengulang bantuannya.
  List<Question> generateBoss(
    DifficultyConfig config,
    List<DifficultyConfig> sumber,
  ) {
    if (sumber.isEmpty) return generate(config);
    final target = config.questionCount;
    final hasil = <Question>[];
    final dipakai = <String>{};
    var putaran = 0;
    while (hasil.length < target && putaran < target * 60) {
      putaran++;
      final asal = sumber[hasil.length % sumber.length];
      final q = single(
        asal.copyWith(
          formats: config.formats,
          optionCount: config.optionCount,
          visualAid: config.visualAid,
          timeLimitSeconds: config.timeLimitSeconds,
        ),
      );
      if (!dipakai.add(q.signature)) continue;
      hasil.add(q);
    }
    return hasil;
  }

  /// Membangun ulang satu soal dari tanda tangannya, mis. `17+5=?`.
  ///
  /// Inilah yang membuat mode Perbaiki Kesalahan nyaris gratis: yang
  /// dicatat `question_attempts` cuma tanda tangannya, dan soalnya —
  /// lengkap dengan pengecoh bernama dan pembahasannya — dirakit lagi di
  /// sini. Tidak ada satu pun soal yang perlu disimpan.
  ///
  /// Mengembalikan `null` kalau tanda tangannya tidak dikenali; catatan
  /// lama dari versi yang berbeda tidak boleh membuat layar gagal muat.
  Question? dariSignature(
    String signature, {
    QuestionFormat format = QuestionFormat.pilihanGanda,
    int optionCount = 4,
    VisualAid visualAid = VisualAid.tidakAda,
    int? timeLimitSeconds,
  }) {
    final m = RegExp(r'^(\?|\d+)([+−×÷?])(\?|\d+)=(\?|\d+)$')
        .firstMatch(signature.replaceAll(' ', ''));
    if (m == null) return null;

    final kiri = m.group(1)!;
    final tanda = m.group(2)!;
    final kanan = m.group(3)!;
    final hasil = m.group(4)!;

    final unknown = tanda == '?'
        ? UnknownPosition.operator
        : kiri == '?'
        ? UnknownPosition.operanKiri
        : kanan == '?'
        ? UnknownPosition.operanKanan
        : UnknownPosition.hasil;

    Operation? operation;
    for (final o in Operation.values) {
      if (o.lambang == tanda) operation = o;
    }

    int? l = int.tryParse(kiri);
    int? r = int.tryParse(kanan);
    int? res = int.tryParse(hasil);

    if (unknown == UnknownPosition.operator) {
      if (l == null || r == null || res == null) return null;
      for (final o in Operation.values) {
        if (_hitung(o, l, r) == res) operation = o;
      }
      if (operation == null) return null;
    } else {
      if (operation == null) return null;
      switch (unknown) {
        case UnknownPosition.hasil:
          if (l == null || r == null) return null;
          res = _hitung(operation, l, r);
        case UnknownPosition.operanKiri:
          if (r == null || res == null) return null;
          l = switch (operation) {
            Operation.tambah => res - r,
            Operation.kurang => res + r,
            Operation.kali => r == 0 ? null : res ~/ r,
            Operation.bagi => res * r,
          };
        case UnknownPosition.operanKanan:
          if (l == null || res == null) return null;
          r = switch (operation) {
            Operation.tambah => res - l,
            Operation.kurang => l - res,
            Operation.kali => l == 0 ? null : res ~/ l,
            Operation.bagi => res == 0 ? null : l ~/ res,
          };
        case UnknownPosition.operator:
          break;
      }
    }
    if (l == null || r == null || res == null) return null;

    final bentuk = unknown == UnknownPosition.operator
        ? QuestionFormat.pilihanGanda
        : format;
    final answerValue = switch (unknown) {
      UnknownPosition.hasil => res,
      UnknownPosition.operanKiri => l,
      UnknownPosition.operanKanan => r,
      UnknownPosition.operator => 0,
    };

    return Question(
      signature: _signature(operation, l, r, res, unknown),
      format: bentuk,
      prompt: _prompt(operation, l, r, res, unknown),
      answer: unknown == UnknownPosition.operator
          ? operation.lambang
          : answerValue.toString(),
      options: bentuk == QuestionFormat.pilihanGanda
          ? _distractors.build(
              operation: operation,
              left: l,
              right: r,
              result: res,
              unknown: unknown,
              answerValue: answerValue,
              optionCount: optionCount,
            )
          : const <AnswerOption>[],
      operation: operation,
      left: l,
      right: r,
      result: res,
      unknown: unknown,
      visualAid: visualAid,
      explanation: _pembahasan(operation, l, r, res, unknown),
      timeLimitSeconds: timeLimitSeconds,
    );
  }

  static int _hitung(Operation op, int l, int r) => switch (op) {
    Operation.tambah => l + r,
    Operation.kurang => l - r,
    Operation.kali => l * r,
    Operation.bagi => r == 0 ? -1 : l ~/ r,
  };

  Question single(DifficultyConfig config) {
    final operation =
        config.operations[_random.nextInt(config.operations.length)];
    final (left, right, result) = _operan(config, operation);
    final unknown = config.unknown;

    // Yang dicari tandanya, bukan angkanya: papan angka tidak bisa
    // mengetik `×`, jadi soal seperti ini selalu pilihan ganda.
    final format = unknown == UnknownPosition.operator
        ? QuestionFormat.pilihanGanda
        : config.formats[_random.nextInt(config.formats.length)];

    final answerValue = switch (unknown) {
      UnknownPosition.hasil => result,
      UnknownPosition.operanKiri => left,
      UnknownPosition.operanKanan => right,
      UnknownPosition.operator => 0,
    };
    final answer = unknown == UnknownPosition.operator
        ? operation.lambang
        : answerValue.toString();

    final options = format == QuestionFormat.pilihanGanda
        ? _distractors.build(
            operation: operation,
            left: left,
            right: right,
            result: result,
            unknown: unknown,
            answerValue: answerValue,
            optionCount: config.optionCount,
            allowNegative: config.allowNegativeResult,
          )
        : const <AnswerOption>[];

    // Menggambar 17 apel tidak menolong siapa pun; di atas sepuluh,
    // bantuan bendanya turun jadi garis bilangan.
    var visual = config.visualAid;
    if (visual == VisualAid.benda &&
        (left > 10 ||
            right > 10 ||
            operation == Operation.kali ||
            operation == Operation.bagi ||
            unknown != UnknownPosition.hasil)) {
      visual = VisualAid.garisBilangan;
    }

    return Question(
      signature: _signature(operation, left, right, result, unknown),
      format: format,
      prompt: _prompt(operation, left, right, result, unknown),
      answer: answer,
      options: options,
      operation: operation,
      left: left,
      right: right,
      result: result,
      unknown: unknown,
      visualAid: visual,
      explanation: _pembahasan(operation, left, right, result, unknown),
      timeLimitSeconds: config.timeLimitSeconds,
    );
  }

  // ------------------------------------------------------------ operan
  (int, int, int) _operan(DifficultyConfig c, Operation op) {
    final min = c.minOperand < 0 ? 0 : c.minOperand;
    final max = c.maxOperand < min ? min : c.maxOperand;
    int acak() => min + _random.nextInt(max - min + 1);

    // Kalau posnya memang tentang menyimpan atau meminjam, sebagian
    // besar soalnya harus benar-benar menyimpan atau meminjam.
    final wajibTeknik = c.allowCarry && _random.nextInt(10) < 7;

    for (var coba = 0; coba < 200; coba++) {
      switch (op) {
        case Operation.tambah:
          final l = acak(), r = acak();
          final res = l + r;
          if (c.maxResult != null && res > c.maxResult!) continue;
          final simpan = _menyimpan(l, r);
          if (!c.allowCarry && simpan) continue;
          if (wajibTeknik && !simpan) continue;
          return (l, r, res);
        case Operation.kurang:
          var l = acak(), r = acak();
          if (l < r && !c.allowNegativeResult) {
            final t = l;
            l = r;
            r = t;
          }
          final res = l - r;
          if (res == 0 && _random.nextBool()) continue;
          if (c.maxResult != null && l > c.maxResult!) continue;
          final pinjam = _meminjam(l, r);
          if (!c.allowCarry && pinjam) continue;
          if (wajibTeknik && !pinjam) continue;
          return (l, r, res);
        case Operation.kali:
          final l = acak(), r = acak();
          final res = l * r;
          if (c.maxResult != null && res > c.maxResult!) continue;
          return (l, r, res);
        case Operation.bagi:
          final r = acak();
          if (r == 0) continue;
          final q = acak();
          final l = r * q;
          if (c.maxResult != null && l > c.maxResult!) continue;
          return (l, r, q);
      }
    }
    // Jalan buntu (rentang terlalu sempit): pulangkan yang paling aman.
    return switch (op) {
      Operation.tambah => (min, min, min + min),
      Operation.kurang => (max, min, max - min),
      Operation.kali => (min, min, min * min),
      Operation.bagi => (min * min, min == 0 ? 1 : min, min),
    };
  }

  static bool _menyimpan(int l, int r) =>
      (l >= 10 || r >= 10) && (l % 10) + (r % 10) >= 10;

  static bool _meminjam(int l, int r) => l >= 10 && (l % 10) < (r % 10);

  // ------------------------------------------------------------- teks
  String _signature(
    Operation op,
    int l,
    int r,
    int res,
    UnknownPosition unknown,
  ) {
    final o = op.lambang;
    return switch (unknown) {
      UnknownPosition.hasil => '$l$o$r=?',
      UnknownPosition.operanKiri => '?$o$r=$res',
      UnknownPosition.operanKanan => '$l$o?=$res',
      UnknownPosition.operator => '$l?$r=$res',
    };
  }

  String _prompt(Operation op, int l, int r, int res, UnknownPosition unknown) {
    final o = op.lambang;
    return switch (unknown) {
      UnknownPosition.hasil => '$l $o $r = ?',
      UnknownPosition.operanKiri => '? $o $r = $res',
      UnknownPosition.operanKanan => '$l $o ? = $res',
      UnknownPosition.operator => '$l ? $r = $res',
    };
  }

  /// Pembahasan singkat yang muncul saat itu juga waktu jawabannya salah.
  /// Bukan sekadar "salah", tapi caranya — dan kalau kesalahannya punya
  /// nama, namanya ikut disebut.
  String _pembahasan(
    Operation op,
    int l,
    int r,
    int res,
    UnknownPosition unknown,
  ) {
    final kalimat = '$l ${op.lambang} $r = $res.';
    switch (unknown) {
      case UnknownPosition.operanKiri:
      case UnknownPosition.operanKanan:
        final dicari = unknown == UnknownPosition.operanKiri ? l : r;
        final lain = unknown == UnknownPosition.operanKiri ? r : l;
        return switch (op) {
          Operation.tambah =>
            '$kalimat Cari selisihnya: $res − $lain = $dicari.',
          Operation.kali => '$kalimat Bagi hasilnya: $res ÷ $lain = $dicari.',
          Operation.kurang || Operation.bagi => '$kalimat Yang dicari $dicari.',
        };
      case UnknownPosition.operator:
        return '$kalimat Jadi tandanya ${op.lambang}.';
      case UnknownPosition.hasil:
        break;
    }

    switch (op) {
      case Operation.tambah:
        if (_menyimpan(l, r)) {
          final satuan = (l % 10) + (r % 10);
          return 'Satuan ${l % 10} + ${r % 10} = $satuan. Tulis ${satuan % 10} '
              'di satuan, lalu simpan 1 ke puluhan: '
              '${l ~/ 10} + ${r ~/ 10} + 1 = ${res ~/ 10}. Jadi $res.';
        }
        if (l <= 10 && r <= 10) {
          return '$kalimat Mulai dari $l, maju $r langkah.';
        }
        return '$kalimat Jumlahkan satuannya dulu, baru puluhannya.';
      case Operation.kurang:
        if (_meminjam(l, r)) {
          final satuan = (l % 10 + 10) - (r % 10);
          return 'Satuan ${l % 10} kurang dari ${r % 10}, jadi pinjam satu '
              'puluhan: ${l % 10 + 10} − ${r % 10} = $satuan. Puluhan tinggal '
              '${l ~/ 10 - 1} − ${r ~/ 10} = ${res ~/ 10}. Jadi $res.';
        }
        return '$kalimat Mulai dari $l, mundur $r langkah.';
      case Operation.kali:
        return '$kalimat Artinya $r ditambah sebanyak $l kali.';
      case Operation.bagi:
        return '$kalimat Karena $r × $res = $l.';
    }
  }
}
