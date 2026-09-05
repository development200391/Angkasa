import 'dart:math';

import 'package:angkasa/domain/engine/desimal_generator.dart';
import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/pecahan_generator.dart';
import 'package:angkasa/domain/engine/question_generator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/gambar.dart';
import 'package:angkasa/domain/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ranah pecahan, desimal, dan persen.
///
/// Yang diperiksa bukan "apakah hitungannya benar" — itu bagian yang
/// paling mudah. Yang dijaga di sini dua hal yang gagalnya diam:
/// **pengecohnya benar-benar bernama**, karena pengecoh tanpa nama
/// membuat dashboard orang tua cuma bisa bilang "salah hitung"; dan
/// **tanda tangannya bisa dibaca balik**, karena tanpa itu soal pecahan
/// yang dijawab salah tidak akan pernah muncul lagi di mode Perbaiki
/// Kesalahan — padahal justru itu soal yang paling perlu diulang.
void main() {
  group('pecahan', () {
    final gen = PecahanGenerator(random: Random(7));

    const sepenyebut = DifficultyConfig(
      domain: NumberDomain.pecahan,
      operations: [Operation.tambah],
      minOperand: 4,
      maxOperand: 12,
      optionCount: 4,
      questionCount: 20,
    );

    test('penyebutnya sama di kedua ruas dan di jawabannya', () {
      for (final q in gen.generate(sepenyebut)) {
        final angka = RegExp(r'(\d+)/(\d+)').allMatches(q.prompt).toList();
        expect(angka.length, 2, reason: q.prompt);
        expect(
          angka[0].group(2),
          angka[1].group(2),
          reason: 'penyebut berbeda: ${q.prompt}',
        );
        expect(q.answer, endsWith('/${angka[0].group(2)}'), reason: q.prompt);
      }
    });

    test('pembilang tidak pernah melebihi penyebut tanpa allowCarry', () {
      for (final q in gen.generate(sepenyebut)) {
        final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(q.answer)!;
        expect(
          int.parse(m.group(1)!),
          lessThan(int.parse(m.group(2)!)),
          reason: 'pecahan campuran bocor ke pos dasar: ${q.answer}',
        );
      }
    });

    test('allowCarry membuka hasil yang melewati satu utuh', () {
      final lewat = gen
          .generate(sepenyebut.copyWith(allowCarry: true, questionCount: 40))
          .where((q) {
            final m = RegExp(r'^(\d+)/(\d+)$').firstMatch(q.answer)!;
            return int.parse(m.group(1)!) >= int.parse(m.group(2)!);
          });
      expect(lewat, isNotEmpty);
    });

    test('penyebut yang ikut dijumlah selalu ada sebagai pengecoh bernama', () {
      // Kekeliruan pecahan yang paling sering. Kalau ia tidak pernah
      // tampil sebagai pilihan, anak yang melakukannya tidak akan
      // pernah tercatat melakukannya.
      final soal = gen.generate(sepenyebut.copyWith(questionCount: 30));
      final punya = soal.where(
        (q) =>
            q.options.any((o) => o.mistake == MistakeKind.penyebutIkutDihitung),
      );
      expect(punya.length, soal.length);
    });

    test('tiap pengecoh punya nama, tidak ada yang jatuh ke lainnya', () {
      for (final q in gen.generate(sepenyebut.copyWith(questionCount: 30))) {
        for (final o in q.options.where((o) => !o.isCorrect)) {
          expect(
            o.mistake,
            isNot(MistakeKind.lainnya),
            reason: '${q.prompt} → ${o.label}',
          );
        }
      }
    });

    test('jawaban benar selalu ada tepat satu', () {
      for (final q in gen.generate(sepenyebut.copyWith(questionCount: 30))) {
        expect(q.options.where((o) => o.isCorrect).length, 1);
        expect(q.options.firstWhere((o) => o.isCorrect).label, q.answer);
      }
    });

    test('tanda tangannya bisa dibaca balik jadi soal yang sama', () {
      for (final q in gen.generate(sepenyebut.copyWith(questionCount: 20))) {
        final lagi = gen.dariSignature(q.signature);
        expect(lagi, isNotNull, reason: q.signature);
        expect(lagi!.answer, q.answer, reason: q.signature);
      }
    });

    test('perkalian dengan bilangan bulat: penyebutnya tetap', () {
      final kali = PecahanGenerator(random: Random(3)).generate(
        sepenyebut.copyWith(
          operations: [Operation.kali],
          allowCarry: true,
          questionCount: 15,
        ),
      );
      for (final q in kali) {
        final penyebutSoal = RegExp(r'/(\d+)').firstMatch(q.prompt)!.group(1);
        expect(q.answer, endsWith('/$penyebutSoal'), reason: q.prompt);
      }
    });
  });

  group('desimal', () {
    final gen = DesimalGenerator(random: Random(11));

    const cfg = DifficultyConfig(
      domain: NumberDomain.desimal,
      operations: [Operation.tambah, Operation.kurang],
      minOperand: 1,
      maxOperand: 99,
      optionCount: 4,
      allowCarry: true,
      questionCount: 25,
    );

    test('memakai koma, bukan titik', () {
      for (final q in gen.generate(cfg)) {
        expect(q.answer, contains(','), reason: q.answer);
        expect(q.answer, isNot(contains('.')), reason: q.answer);
      }
    });

    test('tidak pernah menghasilkan galat pembulatan biner', () {
      // Seluruh hitungan dikerjakan dalam persepuluhan bulat. Kalau
      // suatu hari ada yang mengubahnya jadi `double`, jawaban seperti
      // `0,30000000000000004` akan lolos ke layar anak.
      for (final q in gen.generate(cfg.copyWith(questionCount: 60))) {
        expect(
          RegExp(r'^\d+,\d$').hasMatch(q.answer),
          isTrue,
          reason: 'bukan satu angka di belakang koma: ${q.answer}',
        );
      }
    });

    test('koma yang salah tempat selalu ditawarkan sebagai pengecoh', () {
      final soal = gen.generate(cfg.copyWith(questionCount: 25));
      for (final q in soal) {
        expect(
          q.options.any((o) => o.mistake == MistakeKind.komaSalahTempat),
          isTrue,
          reason: q.prompt,
        );
      }
    });

    test('tanpa allowCarry hasilnya tidak menyeberangi bilangan bulat', () {
      final aman = DesimalGenerator(random: Random(5)).generate(
        cfg.copyWith(
          allowCarry: false,
          operations: [Operation.tambah],
          maxOperand: 49,
          questionCount: 20,
        ),
      );
      for (final q in aman) {
        final m = RegExp(r'^(\d+),(\d) \+ (\d+),(\d) = \?$')
            .firstMatch(q.prompt)!;
        final a = int.parse(m.group(2)!);
        final b = int.parse(m.group(4)!);
        expect(a + b, lessThan(10), reason: q.prompt);
      }
    });

    test('tanda tangannya bisa dibaca balik', () {
      for (final q in gen.generate(cfg.copyWith(questionCount: 20))) {
        final lagi = gen.dariSignature(q.signature);
        expect(lagi, isNotNull, reason: q.signature);
        expect(lagi!.answer, q.answer, reason: q.signature);
      }
    });
  });

  group('persen', () {
    final gen = DesimalGenerator(random: Random(13));

    const cfg = DifficultyConfig(
      domain: NumberDomain.persen,
      minOperand: 20,
      maxOperand: 200,
      optionCount: 4,
      questionCount: 25,
    );

    test('jawabannya selalu bilangan bulat', () {
      for (final q in gen.generate(cfg)) {
        expect(int.tryParse(q.answer), isNotNull, reason: q.prompt);
      }
    });

    test('persentasenya selalu yang bisa dihitung di kepala', () {
      for (final q in gen.generate(cfg)) {
        final p = int.parse(RegExp(r'^(\d+)%').firstMatch(q.prompt)!.group(1)!);
        expect(DesimalGenerator.persenRamah, contains(p), reason: q.prompt);
      }
    });

    test('lupa membagi seratus punya namanya sendiri', () {
      for (final q in gen.generate(cfg)) {
        final p = int.parse(RegExp(r'^(\d+)%').firstMatch(q.prompt)!.group(1)!);
        final dasar = int.parse(
          RegExp(r'dari (\d+)').firstMatch(q.prompt)!.group(1)!,
        );
        final salah = q.options.firstWhere(
          (o) => o.label == '${dasar * p}',
          orElse: () => const AnswerOption(label: ''),
        );
        if (salah.label.isNotEmpty) {
          expect(salah.mistake, MistakeKind.komaSalahTempat, reason: q.prompt);
        }
      }
    });

    test('tanda tangannya bisa dibaca balik', () {
      for (final q in gen.generate(cfg.copyWith(questionCount: 15))) {
        final lagi = gen.dariSignature(q.signature);
        expect(lagi, isNotNull, reason: q.signature);
        expect(lagi!.answer, q.answer, reason: q.signature);
      }
    });
  });

  group('dialihkan lewat QuestionGenerator', () {
    test('satu pintu untuk seluruh ranah — layar tidak perlu tahu', () {
      final gen = QuestionGenerator(random: Random(2));
      for (final ranah in NumberDomain.values) {
        final soal = gen.generate(
          DifficultyConfig(
            domain: ranah,
            minOperand: ranah == NumberDomain.persen ? 20 : 2,
            maxOperand: ranah == NumberDomain.desimal ? 99 : 12,
            allowCarry: true,
            questionCount: 10,
          ),
        );
        expect(soal.length, 10, reason: ranah.name);
        for (final q in soal) {
          expect(q.answer, isNotEmpty, reason: '${ranah.name}: ${q.prompt}');
        }
      }
    });

    test('tanda tangan tiap ranah tidak pernah beririsan', () {
      // Kalau tata bahasanya beririsan, catatan lama bisa dibaca
      // generator yang salah dan memulangkan soal yang berbeda dari
      // yang dulu dikerjakan anak.
      final gen = QuestionGenerator(random: Random(4));
      final bulat = gen
          .generate(const DifficultyConfig(questionCount: 10))
          .map((q) => q.signature);
      for (final s in bulat) {
        expect(s, isNot(contains('/')));
        expect(s, isNot(contains(',')));
        expect(s, isNot(contains('%')));
      }
    });

    test('Perbaiki Kesalahan tetap bisa memanggil ulang soal pecahan', () {
      final gen = QuestionGenerator(random: Random(9));
      final q = gen.dariSignature('3/8+2/8=?');
      expect(q, isNotNull);
      expect(q!.answer, '5/8');
      expect(
        q.options.any((o) => o.label == '5/16'),
        isTrue,
        reason: 'pengecoh penyebut-ikut-dijumlah hilang saat dibaca balik',
      );
    });

    test('Perbaiki Kesalahan tetap bisa memanggil ulang soal persen', () {
      final gen = QuestionGenerator(random: Random(9));
      final q = gen.dariSignature('20%150=?');
      expect(q, isNotNull);
      expect(q!.answer, '30');
    });

    test('tanda tangan yang tidak dikenali memulangkan null, bukan galat', () {
      final gen = QuestionGenerator(random: Random(1));
      expect(gen.dariSignature('entah apa ini'), isNull);
      expect(gen.dariSignature('3/8+2/9=?'), isNull);
    });
  });

  group('bentuk soal baru: cerita, geometri, statistik', () {
    QuestionGenerator gen([int benih = 21]) =>
        QuestionGenerator(random: Random(benih));

    DifficultyConfig cfg(QuestionFormat f, List<Operation> op) =>
        DifficultyConfig(
          formats: [f],
          operations: op,
          minOperand: 3,
          maxOperand: 12,
          optionCount: 4,
          questionCount: 15,
        );

    test('geometri: luas dijawab dengan cm², bukan cm', () {
      for (final q in gen().generate(
        cfg(QuestionFormat.geometri, [Operation.kali]),
      )) {
        expect(q.answer, endsWith('cm²'), reason: q.prompt);
        expect(q.gambar, isA<GambarPersegiPanjang>(), reason: q.prompt);
      }
    });

    test('geometri: dua kekeliruan di mockup layar 28 selalu ditawarkan', () {
      // 13 = sisi dijumlah, 26 = keliling. Kalau keduanya tidak pernah
      // jadi pilihan, anak yang melakukannya tidak pernah tercatat.
      for (final q in gen().generate(
        cfg(QuestionFormat.geometri, [Operation.kali]),
      )) {
        final nama = q.options.map((o) => o.mistake).toSet();
        expect(
          nama,
          contains(MistakeKind.dijumlahBukanDikali),
          reason: q.prompt,
        );
        expect(nama, contains(MistakeKind.kelilingBukanLuas), reason: q.prompt);
      }
    });

    test('geometri: petaknya benar-benar sebanyak luasnya', () {
      // Inti seluruh keputusan menyimpan gambar sebagai data: petak di
      // layar harus bisa dihitung dan hasilnya jawaban yang benar.
      for (final q in gen().generate(
        cfg(QuestionFormat.geometri, [Operation.kali]),
      )) {
        final g = q.gambar as GambarPersegiPanjang;
        expect('${g.panjang * g.lebar} cm²', q.answer, reason: q.prompt);
      }
    });

    test('statistik: modus selalu tunggal dan benar-benar berulang', () {
      for (final q in gen(
        31,
      ).generate(cfg(QuestionFormat.statistik, [Operation.tambah]))) {
        final data = (q.gambar as GambarBatang).data.map((d) => d.nilai);
        final hitung = <int, int>{};
        for (final d in data) {
          hitung[d] = (hitung[d] ?? 0) + 1;
        }
        final terbanyak = hitung.values.reduce((a, b) => a > b ? a : b);
        expect(terbanyak, greaterThan(1), reason: q.prompt);
        expect(
          hitung.values.where((v) => v == terbanyak).length,
          1,
          reason: 'modus ganda — soalnya jadi ambigu: ${q.prompt}',
        );
        expect(hitung[int.parse(q.answer)], terbanyak, reason: q.prompt);
      }
    });

    test('statistik: rata-rata yang dibangkitkan selalu bulat', () {
      for (final q in gen(
        33,
      ).generate(cfg(QuestionFormat.statistik, [Operation.kali]))) {
        expect(int.tryParse(q.answer), isNotNull, reason: q.prompt);
        final data = (q.gambar as GambarBatang).data.map((d) => d.nilai);
        final jumlah = data.reduce((a, b) => a + b);
        expect(jumlah % data.length, 0, reason: q.prompt);
      }
    });

    test('statistik: angkanya ikut di prompt, bukan cuma di diagram', () {
      // Diagram yang jadi satu-satunya sumber angka membuat soal ini
      // hilang sama sekali bagi anak yang memakai pembaca layar.
      for (final q in gen(
        35,
      ).generate(cfg(QuestionFormat.statistik, [Operation.tambah]))) {
        for (final d in (q.gambar as GambarBatang).data) {
          expect(q.prompt, contains('${d.nilai}'), reason: q.prompt);
        }
      }
    });

    test('cerita: selalu dua langkah, dan berhenti di langkah pertama '
        'punya namanya sendiri', () {
      for (final q in gen(
        41,
      ).generate(cfg(QuestionFormat.cerita, [Operation.kurang]))) {
        expect(
          q.options.any((o) => o.mistake == MistakeKind.langkahTerlewat),
          isTrue,
          reason: q.prompt,
        );
        expect(q.explanation, contains('langkah'), reason: q.prompt);
      }
    });

    test('cerita: rupiahnya ditulis dengan titik ribuan', () {
      for (final q in gen(
        43,
      ).generate(cfg(QuestionFormat.cerita, [Operation.kurang]))) {
        expect(q.answer, startsWith('Rp '), reason: q.answer);
        expect(
          RegExp(r'^Rp \d{1,3}(\.\d{3})*$').hasMatch(q.answer),
          isTrue,
          reason: 'format rupiah tidak lazim: ${q.answer}',
        );
      }
    });

    test('cerita: sisanya tidak pernah nol atau negatif', () {
      for (final q in gen(
        45,
      ).generate(cfg(QuestionFormat.cerita, [Operation.kurang]))) {
        final n = int.parse(q.answer.replaceAll(RegExp(r'[^0-9]'), ''));
        expect(n, greaterThan(0), reason: q.prompt);
      }
    });

    test('ketiganya bisa dibaca balik dari tanda tangannya', () {
      for (final f in [
        QuestionFormat.cerita,
        QuestionFormat.geometri,
        QuestionFormat.statistik,
      ]) {
        final g = gen(51);
        for (final q in g.generate(cfg(f, [Operation.kurang]))) {
          final lagi = g.dariSignature(q.signature);
          expect(lagi, isNotNull, reason: '${f.name}: ${q.signature}');
          expect(lagi!.answer, q.answer, reason: '${f.name}: ${q.signature}');
          expect(lagi.prompt, q.prompt, reason: '${f.name}: ${q.signature}');
        }
      }
    });

    test('tiap soal bergambar tetap menyebut angkanya di prompt', () {
      for (final f in [
        QuestionFormat.cerita,
        QuestionFormat.geometri,
        QuestionFormat.statistik,
      ]) {
        for (final q in gen(53).generate(cfg(f, [Operation.kali]))) {
          expect(q.gambar, isNotNull, reason: '${f.name}: ${q.prompt}');
          expect(
            RegExp(r'\d').hasMatch(q.prompt),
            isTrue,
            reason: 'prompt tanpa angka: ${q.prompt}',
          );
        }
      }
    });
  });
}
