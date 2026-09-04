import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

/// Gambar yang menyertai sebuah soal, disimpan sebagai **data** dan
/// bukan sebagai berkas.
///
/// Keputusan ini menentukan apakah soal geometri bisa dikerjakan anak
/// yang lupa rumusnya. Sebuah PNG persegi panjang cuma bisa dilihat;
/// persegi panjang yang digambar dari `panjang: 8, lebar: 5` bisa
/// dibagi jadi 40 petak yang benar-benar bisa dihitung satu per satu.
/// Itu bukan hiasan — itu jalan keluar buat anak yang mentok, dan
/// satu-satunya alasan soal ini tidak berubah jadi tes hafalan rumus.
///
/// Tiga akibat lain yang ikut: APK tidak menggendong ratusan gambar,
/// diagram ikut warna tema tanpa dirender ulang, dan ukuran di soal
/// tidak akan pernah berbeda dari ukuran di gambarnya — karena memang
/// cuma ada satu angka.
///
/// Ditulis tangan, bukan `freezed`: bentuknya union yang dibaca dari
/// JSON konten, dan `dariJson` di bawah harus **tidak pernah melempar**.
/// Berkas konten yang salah satu barisnya keliru tidak boleh membuat
/// seluruh planet gagal dimuat.
sealed class Gambar {
  const Gambar();

  /// `null` kalau tidak ada gambar, atau kalau datanya tidak dikenali.
  ///
  /// Soal tanpa gambar tetap bisa dijawab — promptnya menyebutkan
  /// seluruh angka yang dibutuhkan. Itu syarat yang dipegang seluruh
  /// berkas konten, dan diperiksa uji `konten_test.dart`.
  static Gambar? dariJson(Object? sumber) {
    final Map<String, dynamic> j;
    switch (sumber) {
      case null:
        return null;
      case Map<String, dynamic> m:
        j = m;
      case String s when s.trim().isNotEmpty:
        try {
          final d = jsonDecode(s);
          if (d is! Map<String, dynamic>) return null;
          j = d;
        } catch (_) {
          return null;
        }
      default:
        return null;
    }

    try {
      return switch (j['jenis']) {
        'persegiPanjang' => GambarPersegiPanjang(
          panjang: _int(j['panjang']),
          lebar: _int(j['lebar']),
          satuan: (j['satuan'] as String?) ?? 'cm',
        ),
        'segitiga' => GambarSegitiga(
          alas: _int(j['alas']),
          tinggi: _int(j['tinggi']),
          satuan: (j['satuan'] as String?) ?? 'cm',
        ),
        'batang' => GambarBatang(
          judul: (j['judul'] as String?) ?? '',
          data: [
            for (final d in (j['data'] as List? ?? const []))
              if (d is List && d.length >= 2)
                (label: '${d[0]}', nilai: _int(d[1])),
          ],
        ),
        'benda' => GambarBenda(
          emoji: (j['emoji'] as String?) ?? '•',
          jumlah: _int(j['jumlah']),
          keterangan: j['keterangan'] as String?,
          catatan: j['catatan'] as String?,
        ),
        _ => null,
      };
    } catch (_) {
      return null;
    }
  }

  static int _int(Object? v) => switch (v) {
    final int i => i,
    final double d => d.round(),
    final String s => int.tryParse(s) ?? 0,
    _ => 0,
  };

  Map<String, Object?> get sebagaiPeta;

  String get sebagaiJson => jsonEncode(sebagaiPeta);
}

/// Persegi panjang berpetak. Dipakai luas dan keliling kelas 4.
class GambarPersegiPanjang extends Gambar {
  const GambarPersegiPanjang({
    required this.panjang,
    required this.lebar,
    this.satuan = 'cm',
  });

  final int panjang;
  final int lebar;
  final String satuan;

  int get luas => panjang * lebar;
  int get keliling => 2 * (panjang + lebar);

  /// Petaknya cuma digambar kalau jumlahnya masih bisa dihitung mata.
  /// Di atas itu garis-garisnya berubah jadi bising dan justru
  /// menyembunyikan bentuknya.
  bool get petakTerbaca => panjang <= 15 && lebar <= 15;

  @override
  Map<String, Object?> get sebagaiPeta => {
    'jenis': 'persegiPanjang',
    'panjang': panjang,
    'lebar': lebar,
    'satuan': satuan,
  };
}

/// Segitiga dengan alas dan tinggi ditandai. Tingginya digambar sebagai
/// garis putus-putus dengan siku — anak kelas 4 sering mengira sisi
/// miring yang jadi tinggi, dan gambar yang tidak menandainya membuat
/// soalnya menebak.
class GambarSegitiga extends Gambar {
  const GambarSegitiga({
    required this.alas,
    required this.tinggi,
    this.satuan = 'cm',
  });

  final int alas;
  final int tinggi;
  final String satuan;

  @override
  Map<String, Object?> get sebagaiPeta => {
    'jenis': 'segitiga',
    'alas': alas,
    'tinggi': tinggi,
    'satuan': satuan,
  };
}

/// Diagram batang untuk soal statistik.
///
/// Satu warna untuk semua batang — panjangnya yang membawa angka, bukan
/// warnanya. Nilainya tetap ditulis di atas tiap batang, karena
/// membacanya memang bagian dari soalnya.
class GambarBatang extends Gambar {
  const GambarBatang({required this.judul, required this.data});

  final String judul;
  final List<({String label, int nilai})> data;

  int get tertinggi => data.isEmpty
      ? 1
      : data.map((d) => d.nilai).reduce((a, b) => a > b ? a : b);

  @override
  Map<String, Object?> get sebagaiPeta => {
    'jenis': 'batang',
    'judul': judul,
    'data': [
      for (final d in data) [d.label, d.nilai],
    ],
  };
}

/// Sekumpulan benda sejenis untuk soal cerita — tiga pensil, lima
/// kelereng. Jumlahnya dibatasi supaya barisnya tetap muat satu baris;
/// di atas itu yang tampil angkanya saja.
class GambarBenda extends Gambar {
  const GambarBenda({
    required this.emoji,
    required this.jumlah,
    this.keterangan,
    this.catatan,
  });

  final String emoji;
  final int jumlah;

  /// Mis. `@ Rp 1.500` — harga satuan yang menempel di barisnya.
  final String? keterangan;

  /// Mis. `Rp 5.000` — angka lain di soal yang pantas terlihat.
  final String? catatan;

  static const maksTampil = 10;

  bool get terlaluBanyak => jumlah > maksTampil;

  @override
  Map<String, Object?> get sebagaiPeta => {
    'jenis': 'benda',
    'emoji': emoji,
    'jumlah': jumlah,
    if (keterangan != null) 'keterangan': keterangan,
    if (catatan != null) 'catatan': catatan,
  };
}

/// Menyambungkan [Gambar] ke `json_serializable`.
///
/// Ada supaya `Question` tetap punya `fromJson`/`toJson` yang utuh —
/// model yang setengah bisa diserialisasi adalah jebakan yang baru
/// terasa berbulan-bulan kemudian, waktu ada yang menyimpannya ke cache
/// dan gambarnya diam-diam hilang.
class GambarConverter implements JsonConverter<Gambar?, Map<String, dynamic>?> {
  const GambarConverter();

  @override
  Gambar? fromJson(Map<String, dynamic>? json) => Gambar.dariJson(json);

  @override
  Map<String, dynamic>? toJson(Gambar? gambar) =>
      gambar?.sebagaiPeta.map((k, v) => MapEntry(k, v as dynamic));
}
