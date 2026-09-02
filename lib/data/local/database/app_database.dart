import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'migrations/migration_v1.dart';
import 'seed/seed_runner.dart';

/// Satu-satunya pintu ke SQLite.
///
/// **SQLite adalah sumber kebenaran.** Firestore baru datang di Tahap 3
/// dan cuma jadi cermin untuk papan peringkat dan pemulihan di HP baru;
/// kalau nanti keduanya berbeda, yang di sini yang menang.
class AppDatabase {
  AppDatabase({this.namaBerkas = 'angkasa.db', this.seedRunner});

  static const versiSkema = 1;

  final String namaBerkas;
  final SeedRunner? seedRunner;

  Database? _db;

  Future<Database> get database async => _db ??= await _buka();

  Future<Database> _buka() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, namaBerkas),
      version: versiSkema,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, versi) async {
        await _jalankan(db, migrationV1);
        await (seedRunner ?? SeedRunner()).jalankan(db);
      },
      onUpgrade: (db, dari, ke) async {
        // Migrasi versi 2 dan seterusnya masuk di sini, satu blok per
        // versi, tanpa pernah menghapus data pengguna.
        for (var v = dari + 1; v <= ke; v++) {
          await _jalankan(db, migrasiUntuk(v));
        }
      },
    );
  }

  /// Dipakai uji: basis data in-memory tanpa berkas.
  static Future<Database> memori({SeedRunner? seed}) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: versiSkema,
      onCreate: (db, versi) async {
        await _jalankan(db, migrationV1);
        if (seed != null) await seed.jalankan(db);
      },
    );
    return db;
  }

  static List<String> migrasiUntuk(int versi) => switch (versi) {
    1 => migrationV1,
    _ => const [],
  };

  static Future<void> _jalankan(Database db, List<String> perintah) async {
    final batch = db.batch();
    for (final sql in perintah) {
      batch.execute(sql);
    }
    await batch.commit(noResult: true);
  }

  Future<void> tutup() async {
    await _db?.close();
    _db = null;
  }
}
