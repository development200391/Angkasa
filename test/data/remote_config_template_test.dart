import 'dart:convert';
import 'dart:io';

import 'package:angkasa/domain/engine/aturan_nilai.dart';
import 'package:flutter_test/flutter_test.dart';

/// `remoteconfig.template.json` diperiksa terhadap kode.
///
/// Berkas itulah yang diunggah ke konsol Remote Config, dan isinya
/// mengendalikan bintang serta XP tiap anak. Kalau ia boleh berbeda dari
/// [AturanNilai.bawaan], kegagalannya berbentuk paling buruk: aplikasi
/// tanpa jaringan berhitung dengan satu angka, aplikasi yang berhasil
/// mengambil config berhitung dengan angka lain, dan **tidak ada satu
/// pun galat** yang muncul. Anak yang sama mendapat bintang berbeda
/// tergantung ada Wi-Fi atau tidak.
///
/// Jadi kesamaannya tidak dijaga kedisiplinan, tapi dijaga uji ini.
void main() {
  late Map<String, dynamic> parameter;

  setUpAll(() {
    final isi = File('remoteconfig.template.json').readAsStringSync();
    parameter =
        (jsonDecode(isi) as Map<String, dynamic>)['parameters']
            as Map<String, dynamic>;
  });

  Object nilaiTemplate(String kunci) {
    final p = parameter[kunci] as Map<String, dynamic>;
    final teks = (p['defaultValue'] as Map<String, dynamic>)['value'] as String;
    return switch (p['valueType']) {
      'BOOLEAN' => teks == 'true',
      'NUMBER' => num.parse(teks),
      _ => teks,
    };
  }

  test('kuncinya sama persis — tidak kurang, tidak lebih', () {
    expect(parameter.keys.toSet(), AturanNilai.bawaan.sebagaiPeta.keys.toSet());
  });

  test('tiap nilai bawaannya sama dengan yang dipakai build luring', () {
    AturanNilai.bawaan.sebagaiPeta.forEach((kunci, dariKode) {
      expect(
        nilaiTemplate(kunci),
        dariKode is num ? closeTo(dariKode, 1e-9) : dariKode,
        reason: 'parameter "$kunci" di template berbeda dari kode',
      );
    });
  });

  test('template yang diunggah tetap dibaca ulang jadi bawaan yang sama', () {
    // Perjalanan bolak-balik: kode → template → parser aplikasi. Yang
    // diperiksa bukan cuma nilainya cocok, tapi bahwa `dariPeta` benar
    // membaca bentuk teks yang dikirim Remote Config sungguhan.
    final dariTemplate = AturanNilai.dariPeta({
      for (final kunci in parameter.keys) kunci: nilaiTemplate(kunci),
    });

    expect(dariTemplate.sebagaiPeta, AturanNilai.bawaan.sebagaiPeta);
  });

  test('tiap parameter punya keterangan untuk yang membukanya di konsol', () {
    // Konsol Remote Config adalah tempat angka-angka ini digeser, sering
    // berbulan-bulan setelah ditulis. Parameter tanpa keterangan di sana
    // cuma nama dan angka.
    for (final entri in parameter.entries) {
      final ket = (entri.value as Map<String, dynamic>)['description'];
      expect(
        ket,
        isA<String>().having((s) => s.length, 'panjang', greaterThan(20)),
        reason: 'parameter "${entri.key}" belum punya keterangan',
      );
    }
  });
}
