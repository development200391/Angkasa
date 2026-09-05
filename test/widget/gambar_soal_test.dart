import 'dart:math';

import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/question_generator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/gambar.dart';
import 'package:angkasa/domain/models/question.dart';
import 'package:angkasa/features/quiz/widgets/gambar_soal.dart';
import 'package:angkasa/features/quiz/widgets/quiz_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gambar soal untuk geometri, statistik, dan cerita.
///
/// Yang diperiksa di sini bukan "apakah gambarnya bagus" — itu tidak
/// bisa diuji. Yang dijaga dua janji yang gagalnya diam:
///
/// **Angkanya tetap terbaca.** Nilai tiap batang ditulis sebagai teks,
/// bukan cuma sebagai tinggi batang; diagram yang angkanya harus
/// diukur mata mengubah soal statistik jadi soal ketajaman penglihatan.
///
/// **Gambar tidak pernah menghalangi soalnya.** Kartu soal tetap
/// menampilkan kalimatnya lengkap, dan barisan benda yang terlalu
/// panjang berubah jadi angka alih-alih meluber keluar layar.
void main() {
  Future<void> pasang(WidgetTester tester, Widget anak) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 360, child: Center(child: anak)),
        ),
      ),
    );
    await tester.pump();
  }

  Question soal({required Gambar gambar, QuestionFormat? format}) => Question(
    signature: 'uji',
    format: format ?? QuestionFormat.geometri,
    prompt: 'Berapa luasnya?',
    answer: '40 cm²',
    options: const [
      AnswerOption(label: '40 cm²', isCorrect: true),
      AnswerOption(label: '13 cm²', mistake: MistakeKind.dijumlahBukanDikali),
      AnswerOption(label: '26 cm²', mistake: MistakeKind.kelilingBukanLuas),
    ],
    operation: Operation.kali,
    left: 0,
    right: 0,
    result: 40,
    gambar: gambar,
  );

  group('memilih bentuk yang benar', () {
    testWidgets('tiap jenis gambar punya penggambarnya sendiri', (
      tester,
    ) async {
      for (final g in <Gambar>[
        const GambarPersegiPanjang(panjang: 8, lebar: 5),
        const GambarSegitiga(alas: 6, tinggi: 4),
        const GambarBatang(judul: 'Buku', data: [(label: 'Ani', nilai: 3)]),
        const GambarBenda(emoji: '✏️', jumlah: 3),
      ]) {
        await pasang(tester, GambarSoal(gambar: g));
        expect(
          tester.takeException(),
          isNull,
          reason: g.runtimeType.toString(),
        );
      }
    });
  });

  group('diagram batang', () {
    const data = GambarBatang(
      judul: 'Banyak buku yang dibaca minggu ini',
      data: [
        (label: 'Ani', nilai: 3),
        (label: 'Budi', nilai: 5),
        (label: 'Citra', nilai: 3),
      ],
    );

    testWidgets('nilai tiap batang ditulis, bukan cuma digambar', (
      tester,
    ) async {
      await pasang(tester, const GambarSoal(gambar: data));

      expect(find.text('5'), findsOneWidget);
      // Dua batang bernilai 3 — dua-duanya menulis angkanya.
      expect(find.text('3'), findsNWidgets(2));
    });

    testWidgets('tiap batang punya namanya di sumbu', (tester) async {
      await pasang(tester, const GambarSoal(gambar: data));
      for (final n in ['Ani', 'Budi', 'Citra']) {
        expect(find.text(n), findsOneWidget);
      }
    });

    testWidgets('judulnya ikut tampil', (tester) async {
      await pasang(tester, const GambarSoal(gambar: data));
      expect(find.text('Banyak buku yang dibaca minggu ini'), findsOneWidget);
    });

    testWidgets('batang tertinggi tidak melebihi kotaknya', (tester) async {
      // Satu nilai yang jauh lebih besar dari sisanya dulu membuat
      // batangnya meluber keluar kartu.
      await pasang(
        tester,
        const GambarSoal(
          gambar: GambarBatang(
            judul: '',
            data: [(label: 'A', nilai: 1), (label: 'B', nilai: 99)],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('barisan benda', () {
    testWidgets('tiga pensil digambar tiga kali', (tester) async {
      await pasang(
        tester,
        const GambarSoal(
          gambar: GambarBenda(
            emoji: '✏️',
            jumlah: 3,
            keterangan: '@ Rp 1.500',
            catatan: 'Rp 5.000',
          ),
        ),
      );
      expect(find.text('✏️'), findsNWidgets(3));
      expect(find.text('@ Rp 1.500'), findsOneWidget);
      expect(find.text('Rp 5.000'), findsOneWidget);
    });

    testWidgets('lebih dari sepuluh berubah jadi angka, bukan barisan '
        'yang meluber', (tester) async {
      await pasang(
        tester,
        const GambarSoal(gambar: GambarBenda(emoji: '🍬', jumlah: 24)),
      );
      expect(find.text('24 × 🍬'), findsOneWidget);
      expect(find.text('🍬'), findsNothing);
    });
  });

  group('kartu soal', () {
    testWidgets('menggambar gambarnya dan tetap menulis kalimatnya', (
      tester,
    ) async {
      await pasang(
        tester,
        KartuSoal(
          soal: soal(gambar: const GambarPersegiPanjang(panjang: 8, lebar: 5)),
        ),
      );
      expect(find.byType(GambarSoal), findsOneWidget);
      expect(find.text('Berapa luasnya?'), findsOneWidget);
    });

    testWidgets('soal tanpa gambar tidak menyisakan ruang kosong', (
      tester,
    ) async {
      await pasang(
        tester,
        KartuSoal(
          soal: const Question(
            signature: '7+5=?',
            format: QuestionFormat.pilihanGanda,
            prompt: '7 + 5 = ?',
            answer: '12',
            operation: Operation.tambah,
            left: 7,
            right: 5,
            result: 12,
          ),
        ),
      );
      expect(find.byType(GambarSoal), findsNothing);
      expect(find.text('7 + 5 = ?'), findsOneWidget);
    });

    testWidgets('soal cerita dibaca rata kiri, bukan rata tengah', (
      tester,
    ) async {
      // Rata tengah membuat tiap baris mulai di tempat berbeda, dan
      // anak yang baru lancar membaca kehilangan barisnya.
      await pasang(
        tester,
        KartuSoal(
          soal: soal(
            gambar: const GambarBenda(emoji: '✏️', jumlah: 3),
            format: QuestionFormat.cerita,
          ),
        ),
      );
      final teks = tester.widget<Text>(find.text('Berapa luasnya?'));
      expect(teks.textAlign, TextAlign.start);
    });

    testWidgets('soal hitung tetap rata tengah', (tester) async {
      await pasang(
        tester,
        KartuSoal(soal: soal(gambar: const GambarSegitiga(alas: 6, tinggi: 4))),
      );
      final teks = tester.widget<Text>(find.text('Berapa luasnya?'));
      expect(teks.textAlign, TextAlign.center);
    });

    testWidgets('kartu di atas latar gelap tidak memakai tinta gelap', (
      tester,
    ) async {
      await pasang(
        tester,
        KartuSoal(
          soal: soal(
            gambar: const GambarBatang(judul: 'Uji', data: []),
          ),
          diAtasGelap: true,
        ),
      );
      expect(tester.takeException(), isNull);
      final gambar = tester.widget<GambarSoal>(find.byType(GambarSoal));
      expect(gambar.diAtasGelap, isTrue);
    });
  });

  group('pilihan jawaban tidak bergantung nama format', () {
    testWidgets('soal geometri tetap membawa pilihannya', (tester) async {
      // Regresi: layar kuis dulu cuma menampilkan opsi kalau
      // `format == pilihanGanda`. Soal geometri, cerita, dan statistik
      // punya pilihan tapi bukan format itu — dan anak terjebak di soal
      // yang tidak bisa dijawab maupun ditinggalkan.
      for (final f in [
        QuestionFormat.geometri,
        QuestionFormat.statistik,
        QuestionFormat.cerita,
      ]) {
        final q = soal(
          gambar: const GambarPersegiPanjang(panjang: 8, lebar: 5),
          format: f,
        );
        expect(q.options, isNotEmpty, reason: f.name);
        expect(q.format.pil, isNotNull, reason: f.name);
      }
    });
  });

  group('tidak meluber di layar sungguhan', () {
    // Uji widget melempar `RenderFlex overflowed` sebagai kegagalan,
    // jadi inilah cara termurah menangkap tata letak yang jebol —
    // tanpa harus membuka tiap pos satu per satu di HP.
    //
    // Ukurannya diambil dari dua ujung yang nyata: HP kecil 320 dp
    // (Android Go masih banyak dipakai) dan HP besar 430 dp.
    for (final lebar in [320.0, 360.0, 430.0]) {
      testWidgets('soal geometri muat di layar ${lebar.toInt()} dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(lebar * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final gen = QuestionGenerator(random: Random(17));
        final soal = gen.generate(
          const DifficultyConfig(
            formats: [QuestionFormat.geometri],
            operations: [Operation.kali],
            minOperand: 3,
            maxOperand: 14,
            optionCount: 4,
            questionCount: 8,
          ),
        );

        for (final q in soal) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: KartuSoal(soal: q),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: q.prompt);
        }
      });

      testWidgets('diagram statistik muat di layar ${lebar.toInt()} dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(lebar * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final gen = QuestionGenerator(random: Random(19));
        final soal = gen.generate(
          const DifficultyConfig(
            formats: [QuestionFormat.statistik],
            operations: [Operation.tambah],
            minOperand: 1,
            maxOperand: 9,
            optionCount: 4,
            questionCount: 8,
          ),
        );

        for (final q in soal) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: KartuSoal(soal: q),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: q.prompt);
        }
      });

      testWidgets('soal cerita muat di layar ${lebar.toInt()} dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(lebar * 3, 900 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        final gen = QuestionGenerator(random: Random(23));
        final soal = gen.generate(
          const DifficultyConfig(
            formats: [QuestionFormat.cerita],
            operations: [Operation.kurang, Operation.bagi, Operation.kali],
            minOperand: 2,
            maxOperand: 12,
            optionCount: 4,
            questionCount: 10,
          ),
        );

        for (final q in soal) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: KartuSoal(soal: q),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(tester.takeException(), isNull, reason: q.prompt);
        }
      });
    }
  });
}
