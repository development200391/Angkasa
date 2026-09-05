import 'dart:io';

import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Migrasi skema, dijalankan atas basis data yang sudah berisi.
///
/// Ada karena kegagalan migrasi berbentuk paling buruk yang bisa
/// dibayangkan aplikasi ini: **progres anak hilang**, di HP yang sudah
/// dipakai berbulan-bulan, dan baru ketahuan sesudah rilis masuk toko.
/// Tidak ada satu pun uji lain yang bisa menangkapnya — semuanya
/// membangun basis data baru dari nol, dan basis data baru selalu benar.
///
/// Jadi yang diperiksa di sini justru jalur yang tidak pernah dilewati
/// pemasangan baru: v1 → v2 → v3 → v4 di atas data yang sudah ada.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  /// Basis data pada versi [sampai], berisi data pengguna secukupnya
  /// untuk membuktikan tidak ada yang hilang.
  Future<Database> lama(int sampai) async {
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: sampai),
    );
    for (var v = 1; v <= sampai; v++) {
      for (final sql in AppDatabase.migrasiUntuk(v)) {
        await db.execute(sql);
      }
    }

    await db.insert('grades', {
      'id': 'grade-1',
      'name': 'Planet Mula',
      'order_index': 1,
      'icon': 'mula',
      'is_unlocked': 1,
    });
    await db.insert('chapters', {
      'id': 'c-1-1',
      'grade_id': 'grade-1',
      'title': 'Bilangan sampai 10',
      'icon': 'zona',
      'color': '#4FA3D9',
      'order_index': 1,
    });
    await db.insert('levels', {
      'id': 'l-1-1-1',
      'chapter_id': 'c-1-1',
      'order_index': 1,
      'title': 'Pos 1',
      'type': 'practice',
      'difficulty_config': '{}',
      'xp_reward': 10,
    });
    await db.insert('level_progress', {
      'level_id': 'l-1-1-1',
      'stars': 3,
      'best_score': 10,
      'attempts': 2,
      'is_unlocked': 1,
      'first_completed_at': '2026-03-01T08:00:00.000',
    });
    await db.insert('user_profile', {
      'id': 1,
      'nickname': 'Rani',
      'total_xp': 480,
      'streak_count': 12,
      'active_grade_id': 'grade-1',
    });
    await db.insert('badges', {
      'code': 'pos_pertama',
      'unlocked_at': '2026-03-01T08:00:00.000',
    });
    await db.insert('question_attempts', {
      'level_id': 'l-1-1-1',
      'question_signature': '7+5=?',
      'is_correct': 0,
      'time_ms': 4100,
      'answered_at': '2026-03-01T08:00:00.000',
      'mistake_kind': 'lupaMenyimpan',
    });
    return db;
  }

  Future<void> naikkan(Database db, int dari, int ke) async {
    for (var v = dari + 1; v <= ke; v++) {
      for (final sql in AppDatabase.migrasiUntuk(v)) {
        await db.execute(sql);
      }
    }
  }

  Future<Set<String>> kolom(Database db, String tabel) async {
    final rows = await db.rawQuery('PRAGMA table_info($tabel)');
    return {for (final r in rows) r['name'] as String};
  }

  test('v3 → v4 tidak menghilangkan satu pun data anak', () async {
    final db = await lama(3);
    await naikkan(db, 3, 4);

    final profil = (await db.query('user_profile')).single;
    expect(profil['nickname'], 'Rani');
    expect(profil['total_xp'], 480);
    expect(profil['streak_count'], 12);

    final progres = (await db.query('level_progress')).single;
    expect(progres['stars'], 3);
    expect(progres['first_completed_at'], '2026-03-01T08:00:00.000');

    expect((await db.query('badges')).length, 1);

    // Catatan kesalahan adalah satu-satunya data yang tidak bisa dibuat
    // ulang dari mana pun — cadangan di server pun tidak menyimpannya.
    final salah = (await db.query('question_attempts')).single;
    expect(salah['mistake_kind'], 'lupaMenyimpan');

    await db.close();
  });

  test('v4 menambah tempat untuk gambar dan hak beli', () async {
    final db = await lama(3);
    expect(await kolom(db, 'static_questions'), isNot(contains('figure_json')));

    await naikkan(db, 3, 4);

    expect(await kolom(db, 'static_questions'), contains('figure_json'));
    expect(await kolom(db, 'static_questions'), contains('order_index'));
    expect(await kolom(db, 'grades'), contains('requires_purchase'));

    // Tabelnya harus benar-benar bisa ditulis, bukan cuma ada.
    await db.insert('entitlements', {
      'code': 'semua_planet',
      'purchased_at': '2026-09-04T00:00:00.000',
      'source': 'play',
      'order_id': 'GPA.1234',
      'verified': 1,
    });
    expect((await db.query('entitlements')).single['code'], 'semua_planet');

    await db.close();
  });

  test('planet yang sudah ada tidak tiba-tiba jadi berbayar', () async {
    // Migrasi menambah kolom dengan bawaan 0. Kalau bawaannya keliru,
    // anak yang sudah main berbulan-bulan membuka aplikasi dan
    // menemukan Planet Mula terkunci di balik paywall.
    final db = await lama(3);
    await naikkan(db, 3, 4);

    final grade = (await db.query('grades')).single;
    expect(grade['requires_purchase'], 0);
    expect(grade['is_unlocked'], 1);

    await db.close();
  });

  test('pemasangan baru langsung sampai v4, lewat jalur yang sama', () async {
    final db = await lama(4);
    expect(await kolom(db, 'grades'), contains('requires_purchase'));
    expect((await db.query('entitlements')), isEmpty);
    await db.close();
  });

  test('memperbarui aplikasi ikut membawa materi barunya', () async {
    // Bug yang cuma ketahuan di HP: `onUpgrade` menaikkan skema tapi
    // tidak pernah menyemai konten. Anak yang memperbarui aplikasinya
    // mendapat tabel-tabel Tahap 4 dan **nol planet baru** — sementara
    // pemasangan baru mendapat semuanya. Persis kebalikan dari siapa
    // yang paling pantas dapat.
    final seed = SeedRunner(
      bacaAset: (path) async => File(path).readAsString(),
    );

    // Pemasangan lama: skema v3, konten dua planet, progres berjalan.
    final db = await lama(3);
    await db.delete('grades');
    await db.delete('levels');
    await db.delete('chapters');
    await db.delete('level_progress');

    await naikkan(db, 3, 4);
    await seed.jalankan(db);

    final pos =
        (await db.rawQuery('SELECT COUNT(*) c FROM levels')).first['c'] as int;
    expect(pos, 250, reason: 'materi Tahap 4 tidak ikut masuk');

    final berbayar = await db.query(
      'grades',
      where: 'requires_purchase = 1',
      orderBy: 'order_index',
    );
    expect(berbayar.map((g) => g['id']), [
      'grade-3',
      'grade-4',
      'grade-5',
      'grade-6',
    ]);

    await db.close();
  });

  test('menyemai ulang tidak menyentuh satu bintang pun', () async {
    // Syarat yang membuat menyemai ulang di `onUpgrade` boleh dilakukan
    // sama sekali. `levels` ditulis dengan `replace` karena isinya
    // memang harus mengikuti berkas konten; `level_progress` ditulis
    // dengan `ignore`, dan itulah yang menjaga progres anak.
    final seed = SeedRunner(
      bacaAset: (path) async => File(path).readAsString(),
    );
    final db = await lama(4);
    await seed.jalankan(db);

    await db.update(
      'level_progress',
      {'stars': 3, 'best_score': 10},
      where: 'level_id = ?',
      whereArgs: ['l-1-1-1'],
    );

    // Semai lagi, seolah aplikasinya diperbarui sekali lagi.
    await seed.jalankan(db);

    final progres = (await db.query(
      'level_progress',
      where: 'level_id = ?',
      whereArgs: ['l-1-1-1'],
    )).single;
    expect(progres['stars'], 3);
    expect(progres['best_score'], 10);

    final profil = (await db.query('user_profile')).single;
    expect(profil['nickname'], 'Rani');
    expect(profil['total_xp'], 480);

    await db.close();
  });

  test('tiap versi skema punya migrasinya, tidak ada yang bolong', () async {
    for (var v = 1; v <= AppDatabase.versiSkema; v++) {
      expect(
        AppDatabase.migrasiUntuk(v),
        isNotEmpty,
        reason:
            'migrasi v$v kosong — naik versiSkema tanpa menulis migrasinya '
            'membuat pemasangan lama berhenti di skema yang tidak lengkap',
      );
    }
  });
}
