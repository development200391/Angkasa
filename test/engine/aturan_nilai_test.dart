import 'package:angkasa/domain/engine/aturan_nilai.dart';
import 'package:angkasa/domain/engine/difficulty_config.dart';
import 'package:angkasa/domain/engine/star_calculator.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/level.dart';
import 'package:flutter_test/flutter_test.dart';

Level pos({LevelType type = LevelType.practice, int xp = 10}) => Level(
  id: 'l-1-1-1',
  chapterId: 'c-1-1',
  orderIndex: 1,
  title: 'Pos',
  type: type,
  difficultyConfig: const DifficultyConfig(),
  xpReward: xp,
);

void main() {
  group('nilai bawaan', () {
    test('sama persis dengan konstanta Tahap 2', () {
      const a = AturanNilai.bawaan;
      expect(a.ambangTigaBintang, StarCalculator.ambangTigaBintang);
      expect(a.ambangDuaBintang, StarCalculator.ambangDuaBintang);
      expect(a.ambangSatuBintang, StarCalculator.ambangSatuBintang);
      expect(a.xpPos, StarCalculator.xpPos);
      expect(a.xpGerbang, StarCalculator.xpGerbang);
      expect(a.bonusTigaBintang, StarCalculator.bonusTigaBintang);
      expect(a.xpMengulang, StarCalculator.xpMengulang);
      expect(a.xpTantangan, StarCalculator.xpTantangan);
      expect(a.heartsPerSession, StarCalculator.heartsPerSession);
    });

    test('tanpa Remote Config, bintangnya persis seperti sebelumnya', () {
      expect(StarCalculator.stars(correct: 10, total: 10), 3);
      expect(StarCalculator.stars(correct: 8, total: 10), 2);
      expect(StarCalculator.stars(correct: 6, total: 10), 1);
      expect(StarCalculator.stars(correct: 5, total: 10), 0);
    });

    test('tanpa Remote Config, XP-nya persis seperti sebelumnya', () {
      expect(
        StarCalculator.xp(level: pos(), stars: 3, sudahPernahLulus: false),
        15,
      );
      expect(
        StarCalculator.xp(level: pos(), stars: 1, sudahPernahLulus: false),
        10,
      );
      expect(
        StarCalculator.xp(level: pos(), stars: 3, sudahPernahLulus: true),
        2,
      );
      expect(
        StarCalculator.xp(
          level: pos(type: LevelType.boss, xp: 30),
          stars: 2,
          sudahPernahLulus: false,
        ),
        30,
      );
    });
  });

  group('nilai dari Remote Config', () {
    test('ambang yang lebih longgar benar-benar berlaku', () {
      final longgar = AturanNilai.dariPeta(const {
        'ambang_tiga_bintang': 0.9,
        'ambang_dua_bintang': 0.7,
        'ambang_satu_bintang': 0.5,
      });
      expect(
        StarCalculator.stars(correct: 9, total: 10, aturan: longgar),
        3,
        reason: '9/10 jadi tiga bintang',
      );
      expect(StarCalculator.stars(correct: 5, total: 10, aturan: longgar), 1);
    });

    test('nilai berupa teks ikut terbaca — Remote Config memulangkan teks', () {
      final a = AturanNilai.dariPeta(const {
        'xp_pos': '25',
        'ukuran_liga': '40',
        'papan_peringkat_aktif': 'false',
      });
      expect(a.xpPos, 25);
      expect(a.ukuranLiga, 40);
      expect(a.papanPeringkatAktif, isFalse);
    });

    test('sakelar mati papan peringkat bisa dibalik dari jauh', () {
      expect(
        AturanNilai.dariPeta(const {'papan_peringkat_aktif': false})
            .papanPeringkatAktif,
        isFalse,
      );
    });
  });

  group('penyaringan nilai yang tidak masuk akal', () {
    test('ambang di luar 0–1 dibuang, bukan dipakai', () {
      final a = AturanNilai.dariPeta(const {
        'ambang_tiga_bintang': 5.0,
        'ambang_dua_bintang': -1,
        'ambang_satu_bintang': 0,
      });
      expect(a.ambangTigaBintang, AturanNilai.bawaan.ambangTigaBintang);
      expect(a.ambangDuaBintang, AturanNilai.bawaan.ambangDuaBintang);
      expect(a.ambangSatuBintang, AturanNilai.bawaan.ambangSatuBintang);
    });

    test('ambang yang terbalik dipulihkan urutannya', () {
      // Satu salah ketik di konsol tidak boleh membuat semua anak
      // kehilangan bintangnya.
      final a = AturanNilai.dariPeta(const {
        'ambang_tiga_bintang': 0.6,
        'ambang_dua_bintang': 0.9,
      });
      expect(a.ambangDuaBintang, lessThanOrEqualTo(a.ambangTigaBintang));
      expect(a.ambangSatuBintang, lessThanOrEqualTo(a.ambangDuaBintang));
    });

    test('XP negatif dan raksasa dibuang', () {
      final a = AturanNilai.dariPeta(const {
        'xp_pos': -5,
        'xp_gerbang': 999999,
        'hati_per_sesi': 0,
      });
      expect(a.xpPos, AturanNilai.bawaan.xpPos);
      expect(a.xpGerbang, AturanNilai.bawaan.xpGerbang);
      expect(a.heartsPerSession, AturanNilai.bawaan.heartsPerSession);
    });

    test('peta kosong menghasilkan bawaan yang utuh', () {
      final a = AturanNilai.dariPeta(const {});
      expect(a.sebagaiPeta, AturanNilai.bawaan.sebagaiPeta);
    });

    test('sampah total tidak melempar', () {
      final a = AturanNilai.dariPeta(const {
        'xp_pos': 'sepuluh',
        'ambang_dua_bintang': {'aneh': true},
        'ukuran_liga': null,
      });
      expect(a.xpPos, AturanNilai.bawaan.xpPos);
      expect(a.ukuranLiga, AturanNilai.bawaan.ukuranLiga);
    });
  });

  test('peta bawaan memuat tiap kunci yang bisa dibaca kembali', () {
    // Yang dikirim ke `setDefaults` dan yang dibaca kembali harus
    // memakai nama kunci yang sama; kalau tidak, nilai di konsol
    // Remote Config diam-diam tidak pernah terpakai.
    final bolak = AturanNilai.dariPeta(AturanNilai.bawaan.sebagaiPeta);
    expect(bolak.sebagaiPeta, AturanNilai.bawaan.sebagaiPeta);
  });
}
