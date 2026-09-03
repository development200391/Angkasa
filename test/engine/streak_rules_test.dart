import 'package:angkasa/domain/engine/streak_rules.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rabu 2 September 2026 — dipakai sebagai "hari ini" di seluruh berkas
/// ini supaya perhitungan mingguannya bisa diperiksa dengan tangan.
final rabu = DateTime(2026, 9, 2);

void main() {
  group('streak harian', () {
    test('hari pertama selalu mulai dari satu', () {
      final h = StreakRules.perbarui(
        streakSekarang: 0,
        terakhirAktif: null,
        pelindungTerakhir: null,
        hariIni: rabu,
      );
      expect(h.streak, 1);
      expect(h.hariBaru, isTrue);
    });

    test('main lagi di hari yang sama tidak menambah apa pun', () {
      final h = StreakRules.perbarui(
        streakSekarang: 5,
        terakhirAktif: rabu,
        pelindungTerakhir: null,
        hariIni: rabu.add(const Duration(hours: 6)),
      );
      expect(h.streak, 5);
      expect(h.hariBaru, isFalse);
    });

    test('main kemarin lalu hari ini menambah satu', () {
      final h = StreakRules.perbarui(
        streakSekarang: 5,
        terakhirAktif: rabu.subtract(const Duration(days: 1)),
        pelindungTerakhir: null,
        hariIni: rabu,
      );
      expect(h.streak, 6);
      expect(h.pelindungTerpakai, isFalse);
    });
  });

  group('pelindung mingguan', () {
    test('satu hari bolong ditambal, rentetannya tetap jalan', () {
      final h = StreakRules.perbarui(
        streakSekarang: 30,
        terakhirAktif: rabu.subtract(const Duration(days: 2)),
        pelindungTerakhir: null,
        hariIni: rabu,
      );
      expect(h.streak, 31);
      expect(h.pelindungTerpakai, isTrue);
      expect(h.putus, isFalse);
    });

    test('dua hari bolong tidak bisa ditambal', () {
      final h = StreakRules.perbarui(
        streakSekarang: 30,
        terakhirAktif: rabu.subtract(const Duration(days: 3)),
        pelindungTerakhir: null,
        hariIni: rabu,
      );
      expect(h.streak, 1);
      expect(h.putus, isTrue);
    });

    test('pelindung yang sudah terpakai minggu ini tidak bisa dipakai '
        'dua kali', () {
      final h = StreakRules.perbarui(
        streakSekarang: 12,
        terakhirAktif: rabu.subtract(const Duration(days: 2)),
        // Senin minggu yang sama.
        pelindungTerakhir: rabu.subtract(const Duration(days: 2)),
        hariIni: rabu,
      );
      expect(h.streak, 1);
      expect(h.putus, isTrue);
    });

    test('pelindung menyala lagi begitu masuk minggu baru', () {
      // Dipakai Selasa minggu lalu, sekarang Rabu minggu ini.
      final mingguLalu = rabu.subtract(const Duration(days: 8));
      expect(
        StreakRules.pelindungTersedia(
          pelindungTerakhir: mingguLalu,
          hariIni: rabu,
        ),
        isTrue,
      );
    });

    test('pelindung dari hari Senin yang sama belum menyala lagi', () {
      final senin = StreakRules.awalMinggu(rabu);
      expect(
        StreakRules.pelindungTersedia(pelindungTerakhir: senin, hariIni: rabu),
        isFalse,
      );
    });
  });

  group('minggu', () {
    test('minggu selalu dimulai Senin', () {
      final senin = StreakRules.awalMinggu(rabu);
      expect(senin.weekday, DateTime.monday);
      expect(senin, DateTime(2026, 8, 31));
    });

    test('Minggu masih ikut minggu yang sama', () {
      final minggu = DateTime(2026, 9, 6);
      expect(StreakRules.samaMinggu(rabu, minggu), isTrue);
      // Senin berikutnya sudah minggu lain.
      expect(StreakRules.samaMinggu(rabu, DateTime(2026, 9, 7)), isFalse);
    });

    test('tujuh hari, Senin sampai Minggu', () {
      final hari = StreakRules.mingguIni(rabu);
      expect(hari.length, 7);
      expect(hari.first, DateTime(2026, 8, 31));
      expect(hari.last, DateTime(2026, 9, 6));
    });
  });
}
