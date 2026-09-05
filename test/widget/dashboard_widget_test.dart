import 'package:angkasa/data/repositories/dashboard_repository.dart';
import 'package:angkasa/features/parent/widgets/batang_mendatar.dart';
import 'package:angkasa/features/parent/widgets/batang_menit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dua widget diagram dashboard orang tua.
///
/// Ada karena satu piksel. Versi pertama `BatangMenit` meluber tepat
/// **1 piksel** — cukup untuk memunculkan pita kuning "BOTTOM
/// OVERFLOWED" melintang di layar yang dibaca orang tua tentang
/// anaknya. Uji repositori tidak bisa menangkap itu; uji widget bisa,
/// karena overflow di sini dilaporkan sebagai kegagalan.
void main() {
  Future<void> pasang(
    WidgetTester tester,
    Widget anak, {
    double lebar = 360,
  }) async {
    tester.view.physicalSize = Size(lebar * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(22), child: anak),
        ),
      ),
    );
    await tester.pump();
  }

  List<MenitHari> hari(List<int> menit) => [
    for (var i = 0; i < menit.length; i++)
      MenitHari(tanggal: DateTime(2026, 8, 30 + i), menit: menit[i]),
  ];

  group('diagram menit', () {
    for (final lebar in [320.0, 360.0, 430.0]) {
      testWidgets('muat di layar ${lebar.toInt()} dp', (tester) async {
        await pasang(
          tester,
          BatangMenit(hari: hari([14, 20, 24, 0, 9, 26, 12])),
          lebar: lebar,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('angka cuma ditulis di hari tertinggi', (tester) async {
      // Menulisnya di tiap batang membuat deretnya penuh angka kecil
      // yang tidak satu pun dibaca.
      await pasang(tester, BatangMenit(hari: hari([14, 20, 24, 0, 9, 26, 12])));
      expect(find.text('26'), findsOneWidget);
      expect(find.text('14'), findsNothing);
    });

    testWidgets('minggu yang seluruhnya kosong tidak meledak', (tester) async {
      await pasang(tester, BatangMenit(hari: hari([0, 0, 0, 0, 0, 0, 0])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('satu hari yang jauh lebih tinggi tetap muat', (tester) async {
      await pasang(tester, BatangMenit(hari: hari([1, 1, 240, 1, 1, 1, 1])));
      expect(tester.takeException(), isNull);
    });

    testWidgets('huruf harinya lengkap tujuh', (tester) async {
      await pasang(tester, BatangMenit(hari: hari([1, 2, 3, 4, 5, 6, 7])));
      // 30 Agustus 2026 hari Minggu.
      for (final h in ['M', 'S', 'R', 'K', 'J']) {
        expect(find.text(h), findsWidgets, reason: h);
      }
    });
  });

  group('batang mendatar', () {
    testWidgets('angkanya ditulis, bukan cuma panjang batangnya', (
      tester,
    ) async {
      await pasang(
        tester,
        const BatangMendatar(label: 'Planet Mula', nilai: '36/36', pecahan: 1),
      );
      expect(find.text('Planet Mula'), findsOneWidget);
      expect(find.text('36/36'), findsOneWidget);
    });

    testWidgets('label panjang dipotong, tidak meluber', (tester) async {
      await pasang(
        tester,
        const BatangMendatar(
          label: 'Penjumlahan dan pengurangan dengan menyimpan sampai seratus',
          nilai: '12×',
          pecahan: 0.4,
        ),
        lebar: 320,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('pecahan di luar 0–1 tidak meledak', (tester) async {
      await pasang(
        tester,
        const BatangMendatar(label: 'X', nilai: '9', pecahan: 3.2),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('pil status', () {
    testWidgets('selalu ikon dan tulisan, tidak pernah warna saja', (
      tester,
    ) async {
      // Sekitar satu dari dua belas laki-laki buta warna merah-hijau,
      // dan bapak yang membuka layar ini harus bisa membedakan
      // "Dikuasai" dari "Perlu latihan" tanpa melihat warnanya.
      for (final p in Penguasaan.values) {
        await pasang(
          tester,
          PilStatus(
            teks: p.label,
            ikon: Icons.check_rounded,
            warna: const Color(0xFF0C6B45),
            latar: const Color(0xFFE2F4EC),
          ),
        );
        expect(find.text(p.label), findsOneWidget, reason: p.name);
        expect(find.byType(Icon), findsOneWidget, reason: p.name);
      }
    });
  });
}
