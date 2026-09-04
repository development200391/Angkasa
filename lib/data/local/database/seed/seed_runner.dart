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

  /// Enam planet, seluruhnya berisi sejak Tahap 4.
  ///
  /// `berbayar` bukan sekadar penanda tampilan: ia yang menentukan
  /// planet mana yang butuh hak beli, dan sengaja ditulis **di sini**
  /// alih-alih di dalam berkas kontennya. Alasannya satu — daftar apa
  /// yang dijual adalah keputusan produk, dan meletakkannya di dalam
  /// JSON konten membuat siapa pun yang menambah planet baru diam-diam
  /// ikut menentukan harganya.
  static const planets =
      <({String id, String nama, int urutan, String ikon, bool berbayar})>[
        (
          id: 'grade-1',
          nama: 'Planet Mula',
          urutan: 1,
          ikon: 'mula',
          berbayar: false,
        ),
        (
          id: 'grade-2',
          nama: 'Planet Puluh',
          urutan: 2,
          ikon: 'puluh',
          berbayar: false,
        ),
        (
          id: 'grade-3',
          nama: 'Planet Kali',
          urutan: 3,
          ikon: 'kali',
          berbayar: true,
        ),
        (
          id: 'grade-4',
          nama: 'Planet Pecah',
          urutan: 4,
          ikon: 'pecah',
          berbayar: true,
        ),
        (
          id: 'grade-5',
          nama: 'Planet Ukur',
          urutan: 5,
          ikon: 'ukur',
          berbayar: true,
        ),
        (
          id: 'grade-6',
          nama: 'Planet Ruang',
          urutan: 6,
          ikon: 'ruang',
          berbayar: true,
        ),
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
        'requires_purchase': planet.berbayar ? 1 : 0,
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

        _isiSoalTertulis(batch, posId, pos['questions'] as List<dynamic>?);
      }
    }
  }

  /// Soal yang ditulis tangan untuk satu pos.
  ///
  /// Sebuah pos boleh punya keduanya: soal tertulis **dan**
  /// `difficultyConfig`. Yang tertulis dipakai lebih dulu, sisanya
  /// dibangkitkan sampai jumlah soalnya penuh. Itu yang membuat pos
  /// geometri tetap punya sepuluh soal walau yang digambar tangan baru
  /// enam, tanpa mengulang soal yang sama dua kali dalam satu sesi.
  void _isiSoalTertulis(Batch batch, String posId, List<dynamic>? soal) {
    if (soal == null) return;

    for (var i = 0; i < soal.length; i++) {
      final q = soal[i] as Map<String, dynamic>;
      final gambar = q['figure'];

      batch.insert('static_questions', {
        'id': q['id'],
        'level_id': posId,
        'order_index': i,
        'format': q['format'],
        'prompt': q['prompt'],
        'image_asset': q['imageAsset'],
        'options_json': jsonEncode(q['options']),
        'answer': q['answer'],
        'explanation': q['explanation'],
        'figure_json': gambar == null ? null : jsonEncode(gambar),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
