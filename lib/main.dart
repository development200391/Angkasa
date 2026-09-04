import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/local/database/app_database.dart';
import 'data/providers.dart';

/// Basis data dibuka **sebelum** `runApp`, bukan di dalam layar.
///
/// Semuanya lokal, jadi ini cepat — dan hasilnya seluruh pohon widget
/// boleh menganggap SQLite siap pakai. Tidak ada satu pun layar yang
/// perlu menangani keadaan "basis data belum ada".
///
/// Firebase disalakan sesudahnya, dan **tidak pernah menghalangi**:
/// panggilan `siapkan()` menelan galatnya sendiri, dan build luring —
/// yaitu `flutter run` tanpa argumen apa pun — melewatinya dalam satu
/// baris tanpa menyentuh jaringan. Kalau Firebase mati, yang hilang cuma
/// papan peringkat.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final db = await AppDatabase().database;

  final wadah = ProviderContainer(
    overrides: [databaseProvider.overrideWithValue(db)],
  );
  await wadah.read(remoteGatewayProvider).siapkan();

  runApp(
    UncontrolledProviderScope(container: wadah, child: const AngkasaApp()),
  );
}
