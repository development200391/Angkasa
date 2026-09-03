import 'dart:math';

import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/question_generator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// Membangun ulang soal dari tanda tangannya adalah seluruh dasar mode
/// Perbaiki Kesalahan. Kalau ini meleset, soal yang muncul di layar
/// bukan soal yang dulu dijawab salah — dan modenya jadi berbohong.
void main() {
  final gen = QuestionGenerator(random: Random(3));

  test('hasil yang dicari', () {
    final q = gen.dariSignature('17+5=?')!;
    expect(q.prompt, '17 + 5 = ?');
    expect(q.answer, '22');
    expect(q.left, 17);
    expect(q.right, 5);
    expect(q.result, 22);
    expect(q.unknown, UnknownPosition.hasil);
  });

  test('operan kanan yang dicari', () {
    final q = gen.dariSignature('8+?=15')!;
    expect(q.answer, '7');
    expect(q.unknown, UnknownPosition.operanKanan);
    expect(q.prompt, '8 + ? = 15');
  });

  test('operan kiri yang dicari', () {
    final q = gen.dariSignature('?+4=12')!;
    expect(q.answer, '8');
    expect(q.unknown, UnknownPosition.operanKiri);
  });

  test('tanda yang dicari, dan bentuknya dipaksa pilihan ganda', () {
    final q = gen.dariSignature('3?4=12')!;
    expect(q.operation, Operation.kali);
    expect(q.answer, '×');
    expect(q.format, QuestionFormat.pilihanGanda);
  });

  test('keempat operasi terbaca', () {
    expect(gen.dariSignature('9−4=?')!.result, 5);
    expect(gen.dariSignature('6×7=?')!.result, 42);
    expect(gen.dariSignature('12÷3=?')!.result, 4);
  });

  test('soal hasil rakitan punya pengecoh bernama dan pembahasan', () {
    final q = gen.dariSignature('17+5=?')!;
    expect(q.options.where((o) => o.isCorrect).length, 1);
    expect(q.options.length, 4);
    expect(
      q.options.where((o) => o.mistake == MistakeKind.lupaMenyimpan),
      isNotEmpty,
    );
    expect(q.explanation, contains('simpan'));
  });

  test('tanda tangan asing dipulangkan sebagai null, bukan melempar', () {
    expect(gen.dariSignature(''), isNull);
    expect(gen.dariSignature('halo'), isNull);
    expect(gen.dariSignature('1+2'), isNull);
    expect(gen.dariSignature('9?4=99'), isNull);
  });

  test('bolak-balik: tanda tangan hasil rakitan sama dengan aslinya', () {
    final asli = gen.generate(
      const DifficultyConfig(
        operations: [Operation.tambah, Operation.kurang],
        minOperand: 1,
        maxOperand: 30,
        allowCarry: true,
        questionCount: 20,
      ),
    );
    for (final q in asli) {
      final ulang = gen.dariSignature(q.signature);
      expect(ulang, isNotNull, reason: q.signature);
      expect(ulang!.signature, q.signature);
      expect(ulang.answer, q.answer, reason: q.signature);
      expect(ulang.prompt, q.prompt, reason: q.signature);
    }
  });

  test('bolak-balik juga untuk soal yang dicari operannya', () {
    for (final unknown in [
      UnknownPosition.operanKiri,
      UnknownPosition.operanKanan,
      UnknownPosition.operator,
    ]) {
      final asli = gen.generate(
        DifficultyConfig(
          operations: const [Operation.tambah, Operation.kali],
          minOperand: 2,
          maxOperand: 12,
          unknown: unknown,
          questionCount: 12,
        ),
      );
      for (final q in asli) {
        final ulang = gen.dariSignature(q.signature);
        expect(ulang, isNotNull, reason: q.signature);
        expect(ulang!.answer, q.answer, reason: q.signature);
        expect(ulang.unknown, q.unknown, reason: q.signature);
      }
    }
  });
}
