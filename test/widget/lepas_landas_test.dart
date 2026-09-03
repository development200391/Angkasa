import 'dart:io';

import 'package:angkasa/core/services/audio_service.dart';
import 'package:angkasa/data/local/dao/attempt_dao.dart';
import 'package:angkasa/data/local/dao/badge_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/dao/profile_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/providers.dart';
import 'package:angkasa/data/repositories/badge_repository.dart';
import 'package:angkasa/data/repositories/progress_repository.dart';
import 'package:angkasa/domain/models/grade.dart';
import 'package:angkasa/domain/models/level_view.dart';
import 'package:angkasa/features/home/screens/lepas_landas_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Layar Lepas Landas cuma muncul enam kali seumur pemakaian, dan selalu
/// di ujung Gerbang Planet yang bertimer — jadi diuji di sini, bukan
/// dengan menembus gerbangnya dulu tiap kali.
///
/// Datanya dibaca lebih dulu di luar uji: `sqflite` memakai I/O sungguhan
/// yang tidak pernah selesai di dalam zona waktu palsu milik
/// `testWidgets`.
void main() {
  late Database db;
  late List<Grade> planets;
  late PetaPlanet peta;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    final profil = ProfileDao(db);
    await profil.simpan(
      (await profil.ambil()).copyWith(
        nickname: 'Uji',
        activeGradeId: 'grade-1',
      ),
    );

    final levelDao = LevelDao(db);
    final progressDao = ProgressDao(db);
    final attemptDao = AttemptDao(db);
    planets = await levelDao.semuaGrade();
    peta = await ProgressRepository(
      levelDao: levelDao,
      progressDao: progressDao,
      profileDao: profil,
      attemptDao: attemptDao,
      badgeRepository: BadgeRepository(
        badgeDao: BadgeDao(db),
        levelDao: levelDao,
        progressDao: progressDao,
        profileDao: profil,
        attemptDao: attemptDao,
      ),
    ).peta('grade-1');
  });

  tearDown(() => db.close());

  Future<void> pasang(WidgetTester tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const LepasLandasScreen(gradeId: 'grade-2'),
        ),
        GoRoute(
          path: '/jelajah',
          builder: (_, _) => const Scaffold(body: Text('PETA')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          planetsProvider.overrideWith((ref) async => planets),
          petaProvider.overrideWith((ref) async => peta),
          // Tanpa ini `just_audio` dipanggil di dalam uji; suara mati
          // membuat pemutarnya tidak pernah dibuat sama sekali.
          audioServiceProvider.overrideWithValue(AudioService(nyala: false)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    // Sekali pompa untuk membangun, sekali lagi supaya Future yang sudah
    // selesai sempat terbaca provider-nya.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('menyebut planet tujuan dan bekal yang dibawa', (tester) async {
    await pasang(tester);

    expect(find.textContaining('PLANET MULA TUNTAS'), findsOneWidget);
    expect(find.textContaining('Planet Puluh'), findsOneWidget);
    expect(find.text('Lepas landas'), findsOneWidget);
    expect(find.text('Nanti saja'), findsOneWidget);

    // 36 pos di Planet Mula, dan bintangnya masih nol di basis data baru.
    expect(find.textContaining('36 pos'), findsOneWidget);
  });

  testWidgets('"Nanti saja" mengembalikan ke peta tanpa berangkat', (
    tester,
  ) async {
    await pasang(tester);

    await tester.tap(find.text('Nanti saja'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('PETA'), findsOneWidget);
  });

  testWidgets('tombol lepas landas menjalankan animasinya dulu, bukan '
      'langsung pindah', (tester) async {
    await pasang(tester);

    await tester.tap(find.text('Lepas landas'));
    await tester.pump();

    // Setengah detik setelah ditekan, roketnya masih di layar: animasinya
    // memang panjang, dan itu disengaja.
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('PETA'), findsNothing);
    expect(find.byType(LepasLandasScreen), findsOneWidget);
  });
}
