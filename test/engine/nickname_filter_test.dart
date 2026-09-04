import 'dart:math';

import 'package:angkasa/domain/engine/nickname_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool boleh(String nama) => NicknameFilter.periksa(nama).boleh;

  group('bentuk nama', () {
    test('nama biasa lolos', () {
      expect(boleh('RoketBiru'), isTrue);
      expect(boleh('Rafa'), isTrue);
      expect(boleh('AstroTujuh'), isTrue);
    });

    test('terlalu pendek dan terlalu panjang ditolak', () {
      expect(boleh('Ab'), isFalse);
      expect(boleh('A' * 17), isFalse);
      expect(boleh('A' * 16), isFalse, reason: 'huruf berulang');
      expect(boleh('BintangKecilKu12'), isTrue, reason: 'pas 16');
    });

    test('spasi dan tanda baca ditolak', () {
      expect(boleh('Roket Biru'), isFalse);
      expect(boleh('Roket_Biru'), isFalse);
      expect(boleh('Roket-Biru'), isFalse);
      expect(boleh('Roket@Biru'), isFalse);
    });

    test('harus dimulai huruf', () {
      expect(boleh('7Roket'), isFalse);
      expect(boleh('123456'), isFalse);
    });

    test('huruf yang berulang empat kali ditolak', () {
      expect(boleh('Roketttt'), isFalse);
      expect(
        boleh('Roketttty'),
        isFalse,
        reason: 'empat, walau ada sesudahnya',
      );
      expect(boleh('Rokettt'), isTrue, reason: 'tiga masih boleh');
    });
  });

  group('data pribadi', () {
    test('nomor telepon tidak muat', () {
      expect(boleh('Rafa081234567'), isFalse);
      expect(
        NicknameFilter.periksa('Rafa081234567').alasan,
        contains('telepon'),
      );
    });

    test('tahun lahir tidak muat', () {
      expect(boleh('Rafa2016'), isFalse);
      expect(boleh('Rafa16'), isTrue, reason: 'dua digit masih wajar');
      expect(boleh('Rafa123'), isTrue, reason: 'tiga digit batasnya');
    });

    test('sekolah dan kontak ditolak', () {
      expect(boleh('RafaGmail'), isFalse);
      expect(boleh('KelasSatu'), isFalse);
      expect(boleh('RafaWhatsapp'), isFalse);
    });

    test('singkatan sekolah yang diikuti angka kelas ditolak', () {
      expect(boleh('RafaSDN12'), isFalse);
      expect(boleh('AstroSMP7'), isFalse);
    });

    test('singkatan pendek tidak menyaring nama yang tidak bersalah', () {
      // "wa" ada di dalam "BintangWarna" dan "mi" di dalam "KomiKu";
      // menolak keduanya jauh lebih merugikan daripada meloloskannya.
      expect(boleh('BintangWarna'), isTrue);
      expect(boleh('KomiKu'), isTrue);
      expect(boleh('Sadewa'), isTrue);
    });
  });

  group('kata kasar', () {
    test('ditolak apa adanya', () {
      expect(boleh('SiTolol'), isFalse);
      expect(boleh('AnjingKu'), isFalse);
    });

    test('angka pengganti huruf tidak menyelamatkannya', () {
      // Ditulis `4nj1n9` tetap terbaca `anjing` setelah dinormalkan.
      expect(NicknameFilter.normalkan('4nj1n9'), 'anjing');
      expect(boleh('4nj1n9'), isFalse);
      expect(boleh('T0l0l'), isFalse);
    });

    test('kata kasar di tengah nama juga tertangkap', () {
      expect(boleh('SuperAsuKu'), isFalse);
      expect(boleh('Bangsawan'), isTrue, reason: 'bukan "bangsat"');
    });
  });

  group('saran', () {
    test('memberi empat nama, semuanya lolos pemeriksaannya sendiri', () {
      final saran = NicknameFilter.saran(acak: Random(7));
      expect(saran.length, 4);
      expect(saran.toSet().length, 4, reason: 'tidak kembar');
      for (final s in saran) {
        expect(boleh(s), isTrue, reason: s);
      }
    });

    test('benih yang sama menghasilkan saran yang sama', () {
      expect(
        NicknameFilter.saran(acak: Random(3)),
        NicknameFilter.saran(acak: Random(3)),
      );
    });
  });

  group('alasan penolakan', () {
    test('selalu menyebutkan apa yang harus diubah', () {
      for (final nama in ['Ab', 'Roket Biru', '7Roket', 'Rafa081234567']) {
        final hasil = NicknameFilter.periksa(nama);
        expect(hasil.boleh, isFalse, reason: nama);
        expect(hasil.alasan, isNotNull, reason: nama);
        expect(hasil.alasan, isNotEmpty, reason: nama);
      }
    });

    test('yang lolos tidak membawa alasan', () {
      expect(NicknameFilter.periksa('RoketBiru').alasan, isNull);
    });
  });
}
