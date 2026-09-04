import 'package:angkasa/data/providers.dart';
import 'package:angkasa/data/repositories/leaderboard_repository.dart';
import 'package:angkasa/domain/models/liga.dart';
import 'package:angkasa/features/leaderboard/screens/peringkat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Layar Liga Mingguan, diuji tanpa jaringan dan tanpa basis data.
///
/// Semuanya lewat `papanLigaProvider`: seluruh keputusan tampilan layar
/// ini turunan dari satu nilai itu, dan itu memang yang membuatnya bisa
/// diuji sama sekali — tidak ada satu pun panggilan Firestore di dalam
/// pohon widgetnya.
void main() {
  final rabu = DateTime(2026, 9, 2, 10);

  EntriLiga entri(String uid, String nama, int xp) => EntriLiga(
    uid: uid,
    nickname: nama,
    avatarId: 'roket',
    xp: xp,
    diperbarui: rabu,
  );

  Future<void> pasang(WidgetTester tester, HasilPapan hasil) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const PeringkatScreen()),
        GoRoute(
          path: '/jelajah',
          builder: (_, _) => const Scaffold(body: Text('PETA')),
        ),
        GoRoute(
          path: '/nama-panggilan',
          builder: (_, _) => const Scaffold(body: Text('NAMA')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [papanLigaProvider.overrideWith((ref) async => hasil)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  HasilPapan papanBerisi({String? uidSaya = 'saya'}) => HasilPapan.terbuka(
    PapanLiga(
      weekId: '2026-W36',
      liga: 1,
      entri: [
        entri('a', 'RoketBiru', 340),
        entri('b', 'BintangKecil', 280),
        entri('c', 'AstroTujuh', 265),
        entri('d', 'PesawatKu', 248),
        entri('saya', 'RoketRafa', 210),
      ],
      uidSaya: uidSaya,
    ),
    sisaHari: 3,
  );

  group('papan yang berisi', () {
    testWidgets('podium menampilkan tiga teratas beserta XP-nya', (
      tester,
    ) async {
      await pasang(tester, papanBerisi());

      expect(find.text('Liga Mingguan'), findsOneWidget);
      expect(find.text('RoketBiru'), findsOneWidget);
      expect(find.text('340 XP'), findsOneWidget);
      expect(find.text('BintangKecil'), findsOneWidget);
      expect(find.text('AstroTujuh'), findsOneWidget);
    });

    testWidgets('jumlah pemain nyata yang disebut, bukan angka tiga puluh', (
      tester,
    ) async {
      await pasang(tester, papanBerisi());
      expect(find.text('5 pemain sekelasmu'), findsOneWidget);
      expect(find.text('30 pemain sekelasmu'), findsNothing);
    });

    testWidgets('sisa hari sebelum liga berganti muncul di pojok', (
      tester,
    ) async {
      await pasang(tester, papanBerisi());
      expect(find.text('3 hari lagi'), findsOneWidget);
    });

    testWidgets('yang di bawah podium bernomor mulai dari empat', (
      tester,
    ) async {
      await pasang(tester, papanBerisi());
      expect(find.text('PesawatKu'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('nama sendiri tidak muncul dua kali di layar', (tester) async {
      await pasang(tester, papanBerisi());

      // Barisnya sudah ditempel di bawah, jadi ia dilewati di daftar —
      // tapi nomornya tetap yang asli.
      expect(find.text('RoketRafa'), findsNothing);
      expect(find.text('Kamu'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('baris sendiri selalu ada di bawah, dan tertulis "Kamu"', (
      tester,
    ) async {
      await pasang(tester, papanBerisi());

      // Namanya diganti "Kamu" — anak mencari dirinya sendiri lebih
      // dulu, dan nama panggilannya sendiri justru bukan penanda
      // tercepat untuk itu.
      expect(find.text('Kamu'), findsOneWidget);
      expect(find.text('210'), findsOneWidget);
      expect(find.textContaining('Ligamu berganti tiap Senin'), findsOneWidget);
    });

    testWidgets('anak yang belum main minggu ini diberi tahu caranya masuk', (
      tester,
    ) async {
      await pasang(tester, papanBerisi(uidSaya: 'belum-ada'));

      expect(find.text('Kamu'), findsNothing);
      expect(
        find.textContaining('Selesaikan satu pos minggu ini'),
        findsOneWidget,
      );
    });
  });

  group('keadaan tertutup', () {
    testWidgets('luring: kalimatnya menegaskan pelajarannya tidak berhenti', (
      tester,
    ) async {
      await pasang(tester, const HasilPapan.tertutup(PapanTertutup.luring));

      expect(find.text('Belum tersambung'), findsOneWidget);
      expect(find.textContaining('tetap jalan'), findsOneWidget);
      expect(find.text('Kembali ke lintasan'), findsOneWidget);
    });

    testWidgets('dimatikan orang tua: disebut tidak mengunci materi', (
      tester,
    ) async {
      await pasang(
        tester,
        const HasilPapan.tertutup(PapanTertutup.dimatikanOrangTua),
      );

      expect(find.text('Papan peringkat dimatikan'), findsOneWidget);
      expect(find.textContaining('tetap terbuka'), findsOneWidget);
    });

    testWidgets('tanpa sinyal: XP disebut tidak hilang', (tester) async {
      await pasang(
        tester,
        const HasilPapan.tertutup(PapanTertutup.tidakAdaSinyal),
      );

      expect(find.text('Tidak ada sinyal'), findsOneWidget);
      expect(find.textContaining('Tidak ada yang hilang'), findsOneWidget);
    });

    testWidgets('belum punya nama: tombolnya membawa ke layar namanya', (
      tester,
    ) async {
      await pasang(
        tester,
        const HasilPapan.tertutup(PapanTertutup.belumPunyaNama),
      );

      expect(find.text('Pilih nama panggilan'), findsOneWidget);
      await tester.tap(find.text('Pilih nama panggilan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('NAMA'), findsOneWidget);
    });

    testWidgets('tidak satu pun keadaan tertutup berbunyi seperti kerusakan', (
      tester,
    ) async {
      for (final alasan in PapanTertutup.values) {
        await pasang(tester, HasilPapan.tertutup(alasan));
        expect(find.textContaining('Error'), findsNothing, reason: '$alasan');
        expect(find.textContaining('Gagal'), findsNothing, reason: '$alasan');
        expect(
          find.textContaining('Exception'),
          findsNothing,
          reason: '$alasan',
        );
      }
    });
  });
}
