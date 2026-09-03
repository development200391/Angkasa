import 'package:angkasa/domain/engine/badge_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('katalognya persis dua puluh empat, dan kodenya tidak kembar', () {
    expect(BadgeRules.katalog.length, BadgeRules.total);
    final kode = BadgeRules.katalog.map((b) => b.code).toSet();
    expect(kode.length, BadgeRules.total);
  });

  test('tiap lencana punya nama dan kalimat syarat', () {
    for (final b in BadgeRules.katalog) {
      expect(b.nama, isNotEmpty, reason: b.code);
      expect(b.keterangan, isNotEmpty, reason: b.code);
      expect(b.ikon, isNotEmpty, reason: b.code);
    }
  });

  test('anak baru belum dapat satu pun', () {
    expect(BadgeRules.baru(const BadgeContext(), const {}), isEmpty);
  });

  test('pos pertama membuka lencana pertama', () {
    final baru = BadgeRules.baru(const BadgeContext(posSelesai: 1), const {});
    expect(baru.map((b) => b.code), contains('pos_pertama'));
  });

  test('lencana yang sudah punya tidak dipulangkan lagi', () {
    final baru = BadgeRules.baru(const BadgeContext(posSelesai: 1), const {
      'pos_pertama',
    });
    expect(baru, isEmpty);
  });

  test('ambang bertingkat ikut terbuka sekaligus kalau lompat jauh', () {
    final baru = BadgeRules.baru(
      const BadgeContext(posSelesai: 30),
      const {},
    ).map((b) => b.code);
    expect(baru, containsAll(['pos_pertama', 'pos_10', 'pos_25']));
    expect(baru, isNot(contains('pos_50')));
  });

  test('streak memakai rekor terbaik, bukan yang sedang berjalan', () {
    // Rentetannya baru putus, tapi lencananya tidak ikut hilang.
    final baru = BadgeRules.baru(
      const BadgeContext(streakSekarang: 1, streakTerbaik: 7),
      const {},
    ).map((b) => b.code);
    expect(baru, containsAll(['streak_3', 'streak_7']));
    expect(baru, isNot(contains('streak_14')));
  });

  test('lencana latihan dinilai dari catatan latihan', () {
    final baru = BadgeRules.baru(
      const BadgeContext(
        soalDiperbaiki: 12,
        kilatTerbaik: 31,
        tantanganSelesai: 7,
      ),
      const {},
    ).map((b) => b.code);
    expect(baru, containsAll(['perbaiki_10', 'kilat_30', 'harian_7']));
    expect(baru, isNot(contains('kilat_50')));
  });

  test('cari mengembalikan definisi, dan null untuk kode asing', () {
    expect(BadgeRules.cari('pos_pertama')?.nama, 'Pos Pertama');
    expect(BadgeRules.cari('tidak_ada'), isNull);
  });
}
