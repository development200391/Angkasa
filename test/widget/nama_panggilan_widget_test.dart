import 'package:angkasa/data/providers.dart';
import 'package:angkasa/domain/models/user_profile.dart';
import 'package:angkasa/features/account/screens/nama_panggilan_screen.dart';
import 'package:angkasa/shared/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Layar Nama panggilan, tanpa basis data dan tanpa jaringan.
///
/// Profilnya dipasang langsung lewat `overrideWith`: `sqflite` memakai
/// I/O sungguhan yang tidak pernah selesai di dalam zona waktu palsu
/// milik `testWidgets`, jadi menyentuhnya dari sini berarti ujinya
/// menggantung sampai batas waktu.
///
/// Penyimpanannya sendiri diuji di `test/data/account_repository_test.dart`,
/// di mana basis datanya sungguhan dan zonanya normal. Yang diperiksa di
/// berkas ini cuma satu hal, dan itu memang tugas layarnya: **kapan**
/// penyaringnya bekerja — sambil mengetik, bukan setelah menekan tombol.
class _ProfilTetap extends ProfileNotifier {
  _ProfilTetap(this._profil);

  final UserProfile _profil;

  @override
  Future<UserProfile> build() async => _profil;
}

void main() {
  Future<void> pasang(WidgetTester tester, {String nama = 'RoketLama'}) async {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const NamaPanggilanScreen()),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileProvider.overrideWith(
            () => _ProfilTetap(
              UserProfile(nickname: nama, activeGradeId: 'grade-1'),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> tulis(WidgetTester tester, String teks) async {
    await tester.enterText(find.byType(TextField), teks);
    await tester.pump();
  }

  bool tombolHidup(WidgetTester tester) =>
      tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed !=
      null;

  testWidgets('nama yang sudah ada muncul di kotaknya', (tester) async {
    await pasang(tester);

    expect(find.text('RoketLama'), findsOneWidget);
    expect(find.text('9/16'), findsOneWidget);
    expect(find.text('Nama ini boleh dipakai'), findsOneWidget);
  });

  testWidgets('anak baru mulai dari kotak kosong, bukan dari "Penjelajah"', (
    tester,
  ) async {
    await pasang(tester, nama: '');

    expect(find.text('Penjelajah'), findsNothing);
    expect(find.text('0/16'), findsOneWidget);
    expect(find.text('Antara 3 dan 16 huruf.'), findsOneWidget);
    expect(tombolHidup(tester), isFalse);
  });

  testWidgets('penghitung huruf ikut berubah sambil mengetik', (tester) async {
    await pasang(tester);
    await tulis(tester, 'Bulan');
    expect(find.text('5/16'), findsOneWidget);
  });

  testWidgets('centang hijau muncul begitu namanya boleh', (tester) async {
    await pasang(tester);

    await tulis(tester, 'Ab');
    expect(find.text('Nama ini boleh dipakai'), findsNothing);
    expect(find.textContaining('Minimal 3 huruf'), findsOneWidget);
    expect(tombolHidup(tester), isFalse);

    await tulis(tester, 'Abc');
    expect(find.text('Nama ini boleh dipakai'), findsOneWidget);
    expect(tombolHidup(tester), isTrue);
  });

  testWidgets('alasan penolakan tampil sebelum tombol ditekan', (tester) async {
    await pasang(tester);
    await tulis(tester, 'Rafa2016');

    expect(
      find.textContaining('Nomor telepon dan tahun lahir'),
      findsOneWidget,
    );
    expect(find.text('Nama ini boleh dipakai'), findsNothing);
    expect(tombolHidup(tester), isFalse);
  });

  testWidgets('kata kasar ditolak tanpa mengulanginya di layar', (
    tester,
  ) async {
    await pasang(tester);
    await tulis(tester, 'SiTolol');

    // Kalimatnya sengaja tidak menyebut kata yang ditolak. Menampilkan
    // "kata 'tolol' tidak boleh" berarti menuliskannya sekali lagi, di
    // layar anak.
    expect(find.text('Nama ini tidak boleh dipakai.'), findsOneWidget);
    expect(tombolHidup(tester), isFalse);
  });

  testWidgets('menekan saran langsung mengisi kotaknya', (tester) async {
    await pasang(tester);
    await tulis(tester, 'Ab');
    expect(tombolHidup(tester), isFalse);

    // Sarannya diacak tiap kali layar dibuka, jadi yang diambil pil
    // pertama apa pun isinya — dan justru itu yang diuji: sarannya
    // selalu sebuah nama yang lolos.
    final pil = find.descendant(
      of: find.byType(Wrap),
      matching: find.byType(Text),
    );
    final teks = tester.widget<Text>(pil.first).data!;

    await tester.tap(pil.first);
    await tester.pump();

    expect(find.text('Nama ini boleh dipakai'), findsOneWidget);
    expect(tombolHidup(tester), isTrue);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      teks,
    );
  });

  testWidgets('peringatan data pribadi selalu terlihat', (tester) async {
    await pasang(tester);
    expect(find.textContaining('Nama asli, nama sekolah'), findsOneWidget);
    expect(find.textContaining('diperiksa otomatis'), findsOneWidget);
  });
}
