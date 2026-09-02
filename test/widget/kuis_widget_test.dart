import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/question.dart';
import 'package:angkasa/features/quiz/widgets/heart_bar.dart';
import 'package:angkasa/features/quiz/widgets/q_input.dart';
import 'package:angkasa/features/quiz/widgets/q_multiple_choice.dart';
import 'package:angkasa/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _soal = Question(
  signature: '7+5=?',
  format: QuestionFormat.pilihanGanda,
  prompt: '7 + 5 = ?',
  answer: '12',
  options: [
    AnswerOption(label: '2', mistake: MistakeKind.operasiTerbalik),
    AnswerOption(label: '11', mistake: MistakeKind.melesetSatu),
    AnswerOption(label: '12', isCorrect: true),
  ],
  operation: Operation.tambah,
  left: 7,
  right: 5,
  result: 12,
);

Widget _bungkus(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('pilihan ganda menampilkan semua opsi dan meneruskan '
      'ketukan', (tester) async {
    String? ditekan;
    await tester.pumpWidget(
      _bungkus(QMultipleChoice(soal: _soal, onPilih: (l) => ditekan = l)),
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    await tester.tap(find.text('12'));
    expect(ditekan, '12');
  });

  testWidgets('sesudah terkunci, opsi tidak bisa ditekan lagi', (tester) async {
    var jumlah = 0;
    await tester.pumpWidget(
      _bungkus(
        QMultipleChoice(
          soal: _soal,
          terkunci: true,
          dipilih: '11',
          onPilih: (_) => jumlah++,
        ),
      ),
    );

    await tester.tap(find.text('12'));
    await tester.pump();
    expect(jumlah, 0);
  });

  testWidgets('hati yang tersisa digambar terisi, sisanya kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_bungkus(const HeartBar(sisa: 3)));
    expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.favorite_border_rounded), findsNWidgets(2));
  });

  testWidgets('papan angka mengirim angka, hapus, dan kirim', (tester) async {
    final ditekan = <String>[];
    await tester.pumpWidget(
      _bungkus(
        Keypad(
          onAngka: ditekan.add,
          onHapus: () => ditekan.add('hapus'),
          onKirim: () => ditekan.add('kirim'),
        ),
      ),
    );

    await tester.tap(find.text('7'));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.byIcon(Icons.check_rounded));
    expect(ditekan, ['7', 'hapus', 'kirim']);
  });

  testWidgets('tombol utama tanpa aksi tidak memanggil apa pun', (
    tester,
  ) async {
    var jumlah = 0;
    await tester.pumpWidget(_bungkus(const PrimaryButton(label: 'Mulai')));
    await tester.tap(find.text('Mulai'));
    expect(jumlah, 0);

    await tester.pumpWidget(
      _bungkus(PrimaryButton(label: 'Mulai', onPressed: () => jumlah++)),
    );
    await tester.tap(find.text('Mulai'));
    expect(jumlah, 1);
  });
}
