import 'dart:math';

import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/question_generator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final gen = QuestionGenerator(random: Random(42));

  test('membangkitkan sebanyak yang dijanjikan konfigurasi', () {
    final soal = gen.generate(const DifficultyConfig(questionCount: 10));
    expect(soal.length, 10);
  });

  test('satu sesi tidak mengulang soal selama variasinya cukup', () {
    final soal = gen.generate(
      const DifficultyConfig(minOperand: 1, maxOperand: 20, questionCount: 10),
    );
    expect(soal.map((s) => s.signature).toSet().length, 10);
  });

  test('S1 — operan tidak pernah keluar dari rentangnya', () {
    final soal = gen.generate(
      const DifficultyConfig(minOperand: 3, maxOperand: 9, questionCount: 30),
    );
    for (final s in soal) {
      expect(s.left, inInclusiveRange(3, 9), reason: s.prompt);
      expect(s.right, inInclusiveRange(3, 9), reason: s.prompt);
    }
  });

  test('S1 — hasil tidak melewati maxResult', () {
    final soal = gen.generate(
      const DifficultyConfig(
        minOperand: 1,
        maxOperand: 10,
        maxResult: 20,
        questionCount: 30,
      ),
    );
    expect(soal.every((s) => s.result <= 20), isTrue);
  });

  test('S4 — tanpa izin menyimpan, tidak ada satuan yang melewati sepuluh '
      'saat ada puluhan', () {
    final soal = gen.generate(
      const DifficultyConfig(
        minOperand: 10,
        maxOperand: 60,
        maxResult: 100,
        questionCount: 40,
      ),
    );
    for (final s in soal) {
      expect((s.left % 10) + (s.right % 10) < 10, isTrue, reason: s.prompt);
    }
  });

  test('S4 — dengan izin menyimpan, sebagian besar soal memang menyimpan', () {
    final soal = gen.generate(
      const DifficultyConfig(
        minOperand: 10,
        maxOperand: 89,
        maxResult: 100,
        allowCarry: true,
        questionCount: 40,
      ),
    );
    final menyimpan = soal
        .where((s) => (s.left % 10) + (s.right % 10) >= 10)
        .length;
    expect(menyimpan, greaterThan(soal.length ~/ 2));
  });

  test('pengurangan tidak pernah menghasilkan angka negatif', () {
    final soal = gen.generate(
      const DifficultyConfig(
        operations: [Operation.kurang],
        minOperand: 1,
        maxOperand: 20,
        questionCount: 30,
      ),
    );
    expect(soal.every((s) => s.result >= 0), isTrue);
  });

  test('pembagian selalu habis dibagi', () {
    final soal = gen.generate(
      const DifficultyConfig(
        operations: [Operation.bagi],
        minOperand: 2,
        maxOperand: 10,
        questionCount: 30,
      ),
    );
    for (final s in soal) {
      expect(s.left % s.right, 0, reason: s.prompt);
      expect(s.right * s.result, s.left, reason: s.prompt);
    }
  });

  group('S5 — posisi yang dicari', () {
    test('hasil', () {
      final s = gen.single(const DifficultyConfig());
      expect(s.prompt, endsWith('= ?'));
      expect(s.answer, '${s.result}');
    });

    test('operan kanan', () {
      final s = gen.single(
        const DifficultyConfig(unknown: UnknownPosition.operanKanan),
      );
      expect(s.prompt, contains('? ='));
      expect(s.answer, '${s.right}');
    });

    test('operan kiri', () {
      final s = gen.single(
        const DifficultyConfig(unknown: UnknownPosition.operanKiri),
      );
      expect(s.prompt, startsWith('?'));
      expect(s.answer, '${s.left}');
    });

    test('tanda operasinya, dan bentuknya dipaksa pilihan ganda', () {
      final s = gen.single(
        const DifficultyConfig(
          unknown: UnknownPosition.operator,
          formats: [QuestionFormat.isian],
        ),
      );
      expect(s.answer, s.operation.lambang);
      expect(s.format, QuestionFormat.pilihanGanda);
    });
  });

  test('S3 — bantuan benda turun jadi garis bilangan kalau angkanya besar', () {
    final s = gen.single(
      const DifficultyConfig(minOperand: 15, maxOperand: 40, maxResult: 100),
    );
    expect(s.visualAid, VisualAid.garisBilangan);
  });

  test('S2 — soal pilihan ganda punya opsi, soal isian tidak', () {
    final pg = gen.single(const DifficultyConfig());
    expect(pg.options, isNotEmpty);
    final isian = gen.single(
      const DifficultyConfig(formats: [QuestionFormat.isian]),
    );
    expect(isian.options, isEmpty);
  });

  test('S6 — batas waktu ikut menempel di soalnya', () {
    final s = gen.single(const DifficultyConfig(timeLimitSeconds: 20));
    expect(s.timeLimitSeconds, 20);
  });

  test('tiap soal punya pembahasan', () {
    for (final op in Operation.values) {
      final soal = gen.generate(
        DifficultyConfig(
          operations: [op],
          minOperand: 2,
          maxOperand: 12,
          allowCarry: true,
          questionCount: 12,
        ),
      );
      for (final s in soal) {
        expect(s.explanation, isNotNull, reason: s.prompt);
        expect(s.explanation, isNotEmpty, reason: s.prompt);
      }
    }
  });

  test('jawaban benar dikenali, jawaban lain tidak', () {
    final s = gen.single(const DifficultyConfig());
    expect(s.isCorrect(s.answer), isTrue);
    expect(s.isCorrect('${s.result + 1}'), isFalse);
    expect(s.mistakeOf(s.answer), isNull);
    expect(s.mistakeOf('999'), isNotNull);
  });

  test('Gerbang Planet mencampur pos sebelumnya tapi memakai bentuknya '
      'sendiri', () {
    final sumber = [
      const DifficultyConfig(minOperand: 1, maxOperand: 5, maxResult: 10),
      const DifficultyConfig(
        operations: [Operation.kurang],
        minOperand: 1,
        maxOperand: 20,
        maxResult: 20,
      ),
    ];
    final soal = gen.generateBoss(
      const DifficultyConfig(
        questionCount: 15,
        visualAid: VisualAid.tidakAda,
        timeLimitSeconds: 20,
        formats: [QuestionFormat.pilihanGanda],
        optionCount: 4,
      ),
      sumber,
    );

    expect(soal.length, 15);
    expect(soal.every((s) => s.visualAid == VisualAid.tidakAda), isTrue);
    expect(soal.every((s) => s.timeLimitSeconds == 20), isTrue);
    expect(soal.map((s) => s.operation).toSet().length, 2);
  });
}
