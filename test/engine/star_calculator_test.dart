import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/star_calculator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level _level({LevelType type = LevelType.practice, int xp = 10}) => Level(
  id: 'l-1',
  chapterId: 'c-1',
  orderIndex: 1,
  title: 'Pos 1',
  type: type,
  difficultyConfig: const DifficultyConfig(),
  xpReward: xp,
);

void main() {
  group('bintang dari akurasi', () {
    test('sepuluh dari sepuluh dapat tiga', () {
      expect(StarCalculator.stars(correct: 10, total: 10), 3);
    });

    test('delapan dan sembilan dapat dua', () {
      expect(StarCalculator.stars(correct: 8, total: 10), 2);
      expect(StarCalculator.stars(correct: 9, total: 10), 2);
    });

    test('enam dan tujuh dapat satu', () {
      expect(StarCalculator.stars(correct: 6, total: 10), 1);
      expect(StarCalculator.stars(correct: 7, total: 10), 1);
    });

    test('di bawah enam belum lulus', () {
      for (var b = 0; b < 6; b++) {
        expect(StarCalculator.stars(correct: b, total: 10), 0, reason: '$b/10');
      }
    });

    test('ambangnya persen, jadi ikut untuk Gerbang Planet 15 soal', () {
      expect(StarCalculator.stars(correct: 15, total: 15), 3);
      expect(StarCalculator.stars(correct: 12, total: 15), 2);
      expect(StarCalculator.stars(correct: 9, total: 15), 1);
      expect(StarCalculator.stars(correct: 8, total: 15), 0);
    });

    test('total nol tidak membuat pembagian nol', () {
      expect(StarCalculator.stars(correct: 0, total: 0), 0);
    });
  });

  group('XP', () {
    test('pos baru sepuluh, bintang tiga dapat bonus lima', () {
      expect(
        StarCalculator.xp(level: _level(), stars: 2, sudahPernahLulus: false),
        10,
      );
      expect(
        StarCalculator.xp(level: _level(), stars: 3, sudahPernahLulus: false),
        15,
      );
    });

    test('Gerbang Planet tiga puluh', () {
      final gerbang = _level(type: LevelType.boss, xp: 30);
      expect(
        StarCalculator.xp(level: gerbang, stars: 2, sudahPernahLulus: false),
        30,
      );
    });

    test('mengulang pos yang sudah lulus cuma dua', () {
      expect(
        StarCalculator.xp(level: _level(), stars: 3, sudahPernahLulus: true),
        2,
      );
    });

    test('belum lulus tidak dapat XP sama sekali', () {
      expect(
        StarCalculator.xp(level: _level(), stars: 0, sudahPernahLulus: false),
        0,
      );
    });
  });
}
