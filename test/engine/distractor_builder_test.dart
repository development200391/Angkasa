import 'dart:math';

import 'package:angkasa/domain/engine/distractor_builder.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final builder = DistractorBuilder(random: Random(1));

  List<String> label(
    Operation op,
    int l,
    int r,
    int res, {
    int jumlah = 3,
    UnknownPosition unknown = UnknownPosition.hasil,
    int? jawab,
  }) => builder
      .build(
        operation: op,
        left: l,
        right: r,
        result: res,
        unknown: unknown,
        answerValue: jawab ?? res,
        optionCount: jumlah,
      )
      .map((o) => o.label)
      .toList();

  test('jawaban benar selalu ada, tepat satu', () {
    final opsi = builder.build(
      operation: Operation.tambah,
      left: 7,
      right: 5,
      result: 12,
      unknown: UnknownPosition.hasil,
      answerValue: 12,
      optionCount: 4,
    );
    expect(opsi.where((o) => o.isCorrect).length, 1);
    expect(opsi.firstWhere((o) => o.isCorrect).label, '12');
  });

  test('jumlah opsi persis sebanyak yang diminta dan tidak ada kembar', () {
    for (final n in [3, 4]) {
      final l = label(Operation.tambah, 7, 5, 12, jumlah: n);
      expect(l.length, n);
      expect(l.toSet().length, n);
    }
  });

  test('posisi jawaban benar tidak bisa ditebak dari kebiasaan', () {
    // Bug yang baru ketahuan waktu aplikasinya benar-benar dijalankan:
    // waktu opsinya diurutkan menaik, pengecoh "meleset satu" ke dua
    // arah menaruh jawaban benar **selalu di tengah** — dan sepuluh soal
    // berturut-turut bisa dijawab 10/10 tanpa berhitung sama sekali.
    final builder = DistractorBuilder(random: Random(11));
    final posisi = <int>{};
    for (var n = 2; n < 40; n++) {
      final opsi = builder.build(
        operation: Operation.tambah,
        left: n,
        right: 1,
        result: n + 1,
        unknown: UnknownPosition.hasil,
        answerValue: n + 1,
        optionCount: 3,
      );
      posisi.add(opsi.indexWhere((o) => o.isCorrect));
    }
    expect(
      posisi.length,
      greaterThan(1),
      reason: 'tidak selalu di posisi yang sama',
    );
    expect(posisi, containsAll([0, 1, 2]));
  });

  test('jawaban benar tersebar merata, bukan cuma sesekali bergeser', () {
    final builder = DistractorBuilder(random: Random(5));
    final hitung = <int, int>{0: 0, 1: 0, 2: 0};
    for (var n = 0; n < 300; n++) {
      final opsi = builder.build(
        operation: Operation.tambah,
        left: 3 + (n % 15),
        right: 4,
        result: 7 + (n % 15),
        unknown: UnknownPosition.hasil,
        answerValue: 7 + (n % 15),
        optionCount: 3,
      );
      hitung[opsi.indexWhere((o) => o.isCorrect)] =
          hitung[opsi.indexWhere((o) => o.isCorrect)]! + 1;
    }
    // Menekan satu tombol terus-menerus tidak boleh lebih baik daripada
    // menebak — jadi tidak satu pun posisi boleh mendekati mayoritas.
    for (final e in hitung.entries) {
      expect(e.value, greaterThan(60), reason: 'posisi ${e.key}');
      expect(e.value, lessThan(160), reason: 'posisi ${e.key}');
    }
  });

  test('7 + 5 memancing meleset satu: 11 dan 13 ikut jadi pilihan', () {
    expect(label(Operation.tambah, 7, 5, 12, jumlah: 4), contains('11'));
    expect(label(Operation.tambah, 7, 5, 12, jumlah: 4), contains('13'));
  });

  test('17 + 5 memancing lupa menyimpan: 12', () {
    final opsi = builder.build(
      operation: Operation.tambah,
      left: 17,
      right: 5,
      result: 22,
      unknown: UnknownPosition.hasil,
      answerValue: 22,
      optionCount: 4,
    );
    final lupa = opsi.where((o) => o.mistake == MistakeKind.lupaMenyimpan);
    expect(lupa, isNotEmpty);
    expect(lupa.first.label, '12');
  });

  test('30 + 4 memancing salah nilai tempat: 70', () {
    final opsi = builder.build(
      operation: Operation.tambah,
      left: 30,
      right: 4,
      result: 34,
      unknown: UnknownPosition.hasil,
      answerValue: 34,
      optionCount: 4,
    );
    final tempat = opsi.where((o) => o.mistake == MistakeKind.salahNilaiTempat);
    expect(tempat, isNotEmpty);
    expect(tempat.first.label, '70');
  });

  test('operasi terbalik: 7 + 5 dibaca 7 − 5 jadi 2', () {
    final opsi = builder.build(
      operation: Operation.tambah,
      left: 7,
      right: 5,
      result: 12,
      unknown: UnknownPosition.hasil,
      answerValue: 12,
      optionCount: 4,
    );
    expect(
      opsi.where((o) => o.label == '2').single.mistake,
      MistakeKind.operasiTerbalik,
    );
  });

  test('tiap pengecoh punya nama — tidak ada yang tanpa jenis', () {
    final opsi = builder.build(
      operation: Operation.kurang,
      left: 22,
      right: 5,
      result: 17,
      unknown: UnknownPosition.hasil,
      answerValue: 17,
      optionCount: 4,
    );
    for (final o in opsi.where((o) => !o.isCorrect)) {
      expect(o.mistake, isNotNull, reason: 'opsi ${o.label}');
    }
  });

  test('tanpa izin negatif, tidak ada opsi di bawah nol', () {
    final l = label(Operation.kurang, 3, 2, 1, jumlah: 4).map(int.parse);
    expect(l.every((n) => n >= 0), isTrue);
  });

  test('yang dicari operan: hasil dan operan lain jadi pengecoh', () {
    final opsi = builder.build(
      operation: Operation.tambah,
      left: 8,
      right: 7,
      result: 15,
      unknown: UnknownPosition.operanKanan,
      answerValue: 7,
      optionCount: 4,
    );
    final label = opsi.map((o) => o.label).toList();
    expect(label, contains('15'));
    expect(label, contains('8'));
    expect(opsi.firstWhere((o) => o.isCorrect).label, '7');
  });

  test('yang dicari tandanya: opsinya lambang, bukan angka', () {
    final opsi = builder.build(
      operation: Operation.kali,
      left: 3,
      right: 4,
      result: 12,
      unknown: UnknownPosition.operator,
      answerValue: 0,
      optionCount: 3,
    );
    expect(opsi.length, 3);
    expect(opsi.firstWhere((o) => o.isCorrect).label, '×');
    expect(opsi.every((o) => int.tryParse(o.label) == null), isTrue);
  });
}
