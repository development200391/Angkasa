import 'package:angkasa/domain/models/liga.dart';
import 'package:angkasa/features/leaderboard/screens/akhir_minggu_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Layar Akhir minggu, diuji di sini dan bukan di emulator.
///
/// Alasannya soal waktu, bukan kemalasan: layar ini cuma bisa muncul
/// kalau ada minggu **yang sudah lewat** dan peringkatnya sempat
/// tersalin ke HP. Memicunya sungguhan berarti menunggu sampai Senin.
///
/// Yang diperiksa adalah satu keputusan tata letak yang menentukan rasa
/// seluruh layar: **pergerakan yang ditonjolkan, bukan posisi.** "Naik 4"
/// tetap enak dibaca oleh anak di peringkat 25; "Peringkat 25" saja
/// tidak.
void main() {
  Future<void> pasang(WidgetTester tester, RingkasanMinggu ringkasan) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => AkhirMingguScreen(ringkasan: ringkasan),
        ),
        GoRoute(
          path: '/peringkat',
          builder: (_, _) => const Scaffold(body: Text('PAPAN')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  RingkasanMinggu ringkasan({
    int peringkat = 7,
    int? sebelumnya = 11,
    int pemain = 30,
    int xp = 210,
    int pos = 19,
  }) => RingkasanMinggu(
    weekId: '2026-W35',
    peringkat: peringkat,
    pemain: pemain,
    xp: xp,
    posSelesai: pos,
    peringkatSebelumnya: sebelumnya,
  );

  testWidgets('menyebut peringkat, jumlah pemain, dan tiga angka minggu itu', (
    tester,
  ) async {
    await pasang(tester, ringkasan());

    expect(find.text('Peringkat 7'), findsOneWidget);
    expect(find.textContaining('dari 30 pemain'), findsOneWidget);
    expect(find.text('210'), findsOneWidget);
    expect(find.text('19'), findsOneWidget);
    expect(find.text('Liga baru dimulai Senin pagi.'), findsOneWidget);
  });

  testWidgets('naik ditulis sebagai pergerakan, dengan tanda tambah', (
    tester,
  ) async {
    await pasang(tester, ringkasan(peringkat: 7, sebelumnya: 11));

    expect(find.textContaining('Naik 4 posisi'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);
  });

  testWidgets('anak di peringkat 25 yang naik tetap membaca kabar baik', (
    tester,
  ) async {
    // Inti seluruh layar ini. Kalau yang ditonjolkan posisinya, anak di
    // peringkat 25 tidak punya satu pun alasan membaca sampai habis.
    await pasang(tester, ringkasan(peringkat: 25, sebelumnya: 29));

    expect(find.textContaining('Naik 4 posisi'), findsOneWidget);
    expect(find.text('+4'), findsOneWidget);
  });

  testWidgets('turun disebut apa adanya, tidak disamarkan', (tester) async {
    await pasang(tester, ringkasan(peringkat: 12, sebelumnya: 9));

    expect(find.textContaining('Turun 3 posisi'), findsOneWidget);
    expect(find.text('-3'), findsOneWidget);
  });

  testWidgets('minggu pertama tidak berpura-pura punya pembanding', (
    tester,
  ) async {
    await pasang(tester, ringkasan(sebelumnya: null));

    expect(find.textContaining('Liga pertamamu'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.textContaining('Naik'), findsNothing);
  });

  testWidgets('tombol Oke menutup layar dan kembali ke papan', (tester) async {
    await pasang(tester, ringkasan());

    expect(find.text('Oke'), findsOneWidget);
    await tester.tap(find.text('Oke'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('PAPAN'), findsOneWidget);
  });
}
