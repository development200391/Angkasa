import 'package:angkasa/domain/engine/liga_rules.dart';
import 'package:angkasa/domain/models/liga.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('penanda minggu', () {
    test('Rabu 2 September 2026 ada di minggu ke-36', () {
      expect(LigaRules.idMinggu(DateTime(2026, 9, 2)), '2026-W36');
    });

    test('seluruh minggu menghasilkan penanda yang sama', () {
      final senin = DateTime(2026, 8, 31);
      final penanda = {
        for (var i = 0; i < 7; i++)
          LigaRules.idMinggu(senin.add(Duration(days: i))),
      };
      expect(penanda, {'2026-W36'});
    });

    test('minggu di pergantian tahun tidak terbelah jadi dua liga', () {
      // Aturan ISO: 29 Desember 2025 (Senin) sampai 4 Januari 2026
      // adalah satu minggu, dan namanya minggu pertama tahun 2026.
      expect(LigaRules.idMinggu(DateTime(2025, 12, 29)), '2026-W01');
      expect(LigaRules.idMinggu(DateTime(2026, 1, 1)), '2026-W01');
      expect(LigaRules.idMinggu(DateTime(2026, 1, 4)), '2026-W01');
      expect(LigaRules.idMinggu(DateTime(2026, 1, 5)), '2026-W02');
    });

    test('penandanya urut sebagai teks — itu yang dipakai query lokal', () {
      final a = LigaRules.idMinggu(DateTime(2026, 1, 5));
      final b = LigaRules.idMinggu(DateTime(2026, 9, 2));
      expect(a.compareTo(b), lessThan(0));
    });
  });

  group('sisa hari', () {
    test('Senin pagi berarti tujuh hari lagi', () {
      expect(LigaRules.sisaHari(DateTime(2026, 8, 31, 6)), 7);
    });

    test('Minggu malam berarti satu hari lagi, bukan nol', () {
      expect(LigaRules.sisaHari(DateTime(2026, 9, 6, 23, 30)), 1);
      expect(
        LigaRules.kalimatSisa(DateTime(2026, 9, 6, 23, 30)),
        'Besok berganti',
      );
    });

    test('Rabu siang berarti lima hari lagi', () {
      expect(LigaRules.sisaHari(DateTime(2026, 9, 2, 12)), 5);
      expect(LigaRules.kalimatSisa(DateTime(2026, 9, 2, 12)), '5 hari lagi');
    });
  });

  group('pembagian liga', () {
    test('tiga puluh pertama masuk liga satu', () {
      expect(LigaRules.ligaUntuk(0), 1);
      expect(LigaRules.ligaUntuk(29), 1);
      expect(LigaRules.ligaUntuk(30), 2);
      expect(LigaRules.ligaUntuk(59), 2);
      expect(LigaRules.ligaUntuk(60), 3);
    });

    test('ukuran nol tidak membuatnya membagi dengan nol', () {
      expect(LigaRules.ligaUntuk(5, ukuran: 0), 6);
    });
  });

  group('urutan papan', () {
    EntriLiga e(String nama, int xp, DateTime waktu) => EntriLiga(
      uid: nama,
      nickname: nama,
      avatarId: 'roket',
      xp: xp,
      diperbarui: waktu,
    );

    final pagi = DateTime(2026, 9, 2, 8);
    final malam = DateTime(2026, 9, 5, 20);

    test('XP terbesar di atas', () {
      final urut = LigaRules.urutkan(
        [e('Kecil', 10, pagi), e('Besar', 300, pagi), e('Sedang', 120, pagi)],
        xp: (x) => x.xp,
        diperbarui: (x) => x.diperbarui,
        nama: (x) => x.nickname,
      );
      expect(urut.map((x) => x.nickname), ['Besar', 'Sedang', 'Kecil']);
    });

    test('kalau seri, yang lebih dulu mencapainya menang', () {
      final urut = LigaRules.urutkan(
        [e('Belakangan', 200, malam), e('Duluan', 200, pagi)],
        xp: (x) => x.xp,
        diperbarui: (x) => x.diperbarui,
        nama: (x) => x.nickname,
      );
      expect(urut.first.nickname, 'Duluan');
    });

    test('urutannya sama tiap kali dihitung ulang', () {
      final daftar = [e('Bulan', 50, pagi), e('Astro', 50, pagi)];
      final sekali = LigaRules.urutkan(
        daftar,
        xp: (x) => x.xp,
        diperbarui: (x) => x.diperbarui,
        nama: (x) => x.nickname,
      ).map((x) => x.nickname);
      final lagi = LigaRules.urutkan(
        daftar.reversed,
        xp: (x) => x.xp,
        diperbarui: (x) => x.diperbarui,
        nama: (x) => x.nickname,
      ).map((x) => x.nickname);
      expect(sekali, lagi);
    });
  });

  group('kalimat pergerakan', () {
    test('naik disebut naik, dan angkanya positif', () {
      expect(
        LigaRules.kalimatPergerakan(sekarang: 7, sebelumnya: 11),
        'Naik 4 posisi dari minggu lalu.',
      );
    });

    test('turun tetap disebut apa adanya', () {
      expect(
        LigaRules.kalimatPergerakan(sekarang: 12, sebelumnya: 9),
        'Turun 3 posisi dari minggu lalu.',
      );
    });

    test('minggu pertama tidak berpura-pura punya pembanding', () {
      expect(LigaRules.kalimatPergerakan(sekarang: 7), 'Liga pertamamu.');
    });

    test('pergerakan nol tidak ditulis sebagai "naik 0"', () {
      expect(
        LigaRules.kalimatPergerakan(sekarang: 5, sebelumnya: 5),
        'Posisi yang sama dengan minggu lalu.',
      );
    });
  });

  group('papan liga', () {
    EntriLiga e(String uid, int xp) => EntriLiga(
      uid: uid,
      nickname: uid,
      avatarId: 'roket',
      xp: xp,
      diperbarui: DateTime(2026, 9, 2),
    );

    test('peringkat sendiri dihitung dari satu', () {
      final papan = PapanLiga(
        weekId: '2026-W36',
        liga: 1,
        entri: [e('a', 300), e('b', 200), e('saya', 100)],
        uidSaya: 'saya',
      );
      expect(papan.peringkatSaya, 3);
      expect(papan.sayaEntri?.xp, 100);
    });

    test('anak yang belum main minggu ini tidak punya peringkat', () {
      final papan = PapanLiga(
        weekId: '2026-W36',
        liga: 1,
        entri: [e('a', 300)],
        uidSaya: 'saya',
      );
      expect(papan.peringkatSaya, isNull);
    });

    test('podium mengambil tiga teratas, sisanya di bawah', () {
      final papan = PapanLiga(
        weekId: '2026-W36',
        liga: 1,
        entri: [e('a', 5), e('b', 4), e('c', 3), e('d', 2), e('e', 1)],
        uidSaya: 'a',
      );
      expect(papan.podium.length, 3);
      expect(papan.sisa.map((x) => x.uid), ['d', 'e']);
    });

    test('podium tidak memaksa tiga kalau pemainnya baru dua', () {
      final papan = PapanLiga(
        weekId: '2026-W36',
        liga: 1,
        entri: [e('a', 5), e('b', 4)],
        uidSaya: 'a',
      );
      expect(papan.podium.length, 2);
      expect(papan.sisa, isEmpty);
    });
  });
}
