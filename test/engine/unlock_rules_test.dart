import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/unlock_rules.dart';
import 'package:angkasa/domain/models/chapter.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/level.dart';
import 'package:angkasa/domain/models/level_progress.dart';
import 'package:flutter_test/flutter_test.dart';

Level _pos(int i, {bool boss = false}) => Level(
  id: 'l-$i',
  chapterId: 'c-1',
  orderIndex: i,
  title: boss ? 'Gerbang Planet' : 'Pos $i',
  type: boss ? LevelType.boss : LevelType.practice,
  difficultyConfig: const DifficultyConfig(),
  xpReward: boss ? 30 : 10,
);

Chapter _zona(int i, {String grade = 'grade-1'}) => Chapter(
  id: 'c-$i',
  gradeId: grade,
  title: 'Zona $i',
  icon: 'zona',
  color: '#4FA3D9',
  orderIndex: i,
);

/// Lima pos biasa dan satu Gerbang Planet — bentuk baku semua zona.
final _zonaPenuh = [
  _pos(1),
  _pos(2),
  _pos(3),
  _pos(4),
  _pos(5),
  _pos(6, boss: true),
];

Map<String, LevelProgress> _progres(
  Map<String, ({int stars, bool buka})> isi,
) => {
  for (final e in isi.entries)
    e.key: LevelProgress(
      levelId: e.key,
      stars: e.value.stars,
      isUnlocked: e.value.buka,
    ),
};

void main() {
  group('aturan 1 — pos berikutnya', () {
    test('terbuka kalau pos sekarang dapat minimal satu bintang', () {
      final hasil = UnlockRules.setelahPos(
        selesai: _pos(1),
        stars: 1,
        levelsZona: _zonaPenuh,
        progres: _progres({'l-1': (stars: 0, buka: true)}),
      );
      expect(hasil.levelIds, contains('l-2'));
    });

    test('tidak terbuka kalau belum lulus', () {
      final hasil = UnlockRules.setelahPos(
        selesai: _pos(1),
        stars: 0,
        levelsZona: _zonaPenuh,
        progres: _progres({'l-1': (stars: 0, buka: true)}),
      );
      expect(hasil.isEmpty, isTrue);
    });

    test('pos yang sudah terbuka tidak dibuka dua kali', () {
      final hasil = UnlockRules.setelahPos(
        selesai: _pos(1),
        stars: 3,
        levelsZona: _zonaPenuh,
        progres: _progres({
          'l-1': (stars: 3, buka: true),
          'l-2': (stars: 0, buka: true),
        }),
      );
      expect(hasil.levelIds, isNot(contains('l-2')));
    });
  });

  group('aturan 2 — Gerbang Planet', () {
    test('terbuka hanya setelah semua pos biasa lulus', () {
      final belum = UnlockRules.setelahPos(
        selesai: _pos(4),
        stars: 2,
        levelsZona: _zonaPenuh,
        progres: _progres({
          'l-1': (stars: 3, buka: true),
          'l-2': (stars: 2, buka: true),
          'l-3': (stars: 1, buka: true),
          'l-4': (stars: 0, buka: true),
        }),
      );
      expect(belum.levelIds, isNot(contains('l-6')));

      final sudah = UnlockRules.setelahPos(
        selesai: _pos(5),
        stars: 2,
        levelsZona: _zonaPenuh,
        progres: _progres({
          'l-1': (stars: 3, buka: true),
          'l-2': (stars: 2, buka: true),
          'l-3': (stars: 1, buka: true),
          'l-4': (stars: 2, buka: true),
          'l-5': (stars: 0, buka: true),
        }),
      );
      expect(sudah.levelIds, contains('l-6'));
    });
  });

  group('aturan 3 — zona berikutnya', () {
    final zonaPlanet = [_zona(1), _zona(2), _zona(3)];
    final pertama = {'c-1': 'l-1-1', 'c-2': 'l-2-1', 'c-3': 'l-3-1'};

    test('terbuka kalau gerbang dijawab benar 12 dari 15', () {
      final hasil = UnlockRules.setelahGerbang(
        zona: _zona(1),
        benar: 12,
        total: 15,
        chaptersPlanet: zonaPlanet,
        levelPertamaZona: pertama,
        zonaSelesai: const {},
        gradeBerikutnyaId: 'grade-2',
      );
      expect(hasil.chapterIds, ['c-2']);
      expect(hasil.levelIds, ['l-2-1']);
    });

    test('tidak terbuka kalau 11 dari 15', () {
      final hasil = UnlockRules.setelahGerbang(
        zona: _zona(1),
        benar: 11,
        total: 15,
        chaptersPlanet: zonaPlanet,
        levelPertamaZona: pertama,
        zonaSelesai: const {},
        gradeBerikutnyaId: 'grade-2',
      );
      expect(hasil.isEmpty, isTrue);
    });
  });

  group('aturan 4 — planet berikutnya', () {
    final zonaPlanet = [_zona(1), _zona(2), _zona(3)];
    final pertama = {'c-1': 'l-1-1', 'c-2': 'l-2-1', 'c-3': 'l-3-1'};

    test('terbuka setelah 70% zona selesai', () {
      final hasil = UnlockRules.setelahGerbang(
        zona: _zona(3),
        benar: 15,
        total: 15,
        chaptersPlanet: zonaPlanet,
        levelPertamaZona: pertama,
        zonaSelesai: const {'c-1', 'c-2'},
        gradeBerikutnyaId: 'grade-2',
      );
      expect(hasil.gradeIds, ['grade-2']);
    });

    test('belum terbuka kalau baru satu dari tiga zona', () {
      final hasil = UnlockRules.setelahGerbang(
        zona: _zona(1),
        benar: 15,
        total: 15,
        chaptersPlanet: zonaPlanet,
        levelPertamaZona: pertama,
        zonaSelesai: const {},
        gradeBerikutnyaId: 'grade-2',
      );
      expect(hasil.gradeIds, isEmpty);
    });

    test('planet terakhir tidak punya planet berikutnya', () {
      final hasil = UnlockRules.setelahGerbang(
        zona: _zona(3),
        benar: 15,
        total: 15,
        chaptersPlanet: zonaPlanet,
        levelPertamaZona: pertama,
        zonaSelesai: const {'c-1', 'c-2'},
        gradeBerikutnyaId: null,
      );
      expect(hasil.gradeIds, isEmpty);
    });

    test('jalur manual selalu terbuka — itu inti aturan keempat', () {
      expect(UnlockRules.pilihManual(), isTrue);
    });
  });
}
