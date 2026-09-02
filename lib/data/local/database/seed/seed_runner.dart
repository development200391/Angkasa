import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/app_assets.dart';

/// Mengisi tabel konten sekali saat basis data pertama dibuat.
///
/// Seluruh materi ikut terpasang bersama aplikasi — tidak ada satu pun
/// unduhan sebelum anak bisa mulai. Itu janji "jalan penuh tanpa sinyal"
/// yang ditulis di halaman toko, dan janji itu dipenuhi di sini.
class SeedRunner {
  SeedRunner({Future<String> Function(String path)? bacaAset})
    : _baca = bacaAset ?? rootBundle.loadString;

  final Future<String> Function(String path) _baca;

  /// Enam planet selalu ada sejak awal, walau yang berisi baru dua.
  /// Anak kelas 4 harus bisa melihat planetnya di layar pilih planet,
  /// bukan menemukan daftar yang berhenti di kelas 2.
  static const planets = <({String id, String nama, int urutan, String ikon})>[
    (id: 'grade-1', nama: 'Planet Mula', urutan: 1, ikon: 'mula'),
    (id: 'grade-2', nama: 'Planet Puluh', urutan: 2, ikon: 'puluh'),
    (id: 'grade-3', nama: 'Planet Kali', urutan: 3, ikon: 'kali'),
    (id: 'grade-4', nama: 'Planet Pecah', urutan: 4, ikon: 'pecah'),
    (id: 'grade-5', nama: 'Planet Ukur', urutan: 5, ikon: 'ukur'),
    (id: 'grade-6', nama: 'Planet Ruang', urutan: 6, ikon: 'ruang'),
  ];

  Future<void> jalankan(Database db) async {
    final batch = db.batch();

    for (final planet in planets) {
      batch.insert('grades', {
        'id': planet.id,
        'name': planet.nama,
        'order_index': planet.urutan,
        'icon': planet.ikon,
        'is_unlocked': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    for (final berkas in AppAssets.seedFiles) {
      final isi = jsonDecode(await _baca(berkas)) as Map<String, dynamic>;
      _isiSatuPlanet(batch, isi);
    }

    batch.insert('user_profile', {
      'id': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    await batch.commit(noResult: true);
  }

  void _isiSatuPlanet(Batch batch, Map<String, dynamic> isi) {
    final grade = isi['grade'] as Map<String, dynamic>;
    final gradeId = grade['id'] as String;

    // Planet yang sudah punya konten dibuka apa adanya. Sisanya menunggu
    // Tahap 4, tapi tetap kelihatan di layar pilih planet.
    batch.update(
      'grades',
      {'is_unlocked': 1},
      where: 'id = ?',
      whereArgs: [gradeId],
    );

    for (final c in isi['chapters'] as List<dynamic>) {
      final zona = c as Map<String, dynamic>;
      final zonaId = zona['id'] as String;
      final urutanZona = zona['orderIndex'] as int;

      batch.insert('chapters', {
        'id': zonaId,
        'grade_id': gradeId,
        'title': zona['title'],
        'icon': zona['icon'] ?? 'zona',
        'color': zona['color'] ?? grade['color'],
        'order_index': urutanZona,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final l in zona['levels'] as List<dynamic>) {
        final pos = l as Map<String, dynamic>;
        final posId = pos['id'] as String;
        final urutanPos = pos['orderIndex'] as int;

        batch.insert('levels', {
          'id': posId,
          'chapter_id': zonaId,
          'order_index': urutanPos,
          'title': pos['title'],
          'type': pos['type'] ?? 'practice',
          'difficulty_config': jsonEncode(pos['difficultyConfig']),
          'xp_reward': pos['xpReward'] ?? 10,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        // Pos pertama zona pertama terbuka sejak awal — kalau tidak,
        // anak melihat lintasan yang seluruhnya digembok.
        batch.insert('level_progress', {
          'level_id': posId,
          'is_unlocked': (urutanZona == 1 && urutanPos == 1) ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }
  }
}
