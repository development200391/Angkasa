import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/enums.dart';

part 'difficulty_config.freezed.dart';
part 'difficulty_config.g.dart';

/// Enam sumbu kesulitan jadi satu kelas.
///
/// Ini yang disimpan di kolom `levels.difficulty_config` sebagai JSON —
/// bukan soalnya. Tanpa keputusan itu, mengisi 250 pos berarti menulis
/// 2.500 soal dengan tangan.
///
/// | Sumbu | Field |
/// |---|---|
/// | S1 rentang angka | [minOperand], [maxOperand], [maxResult] |
/// | S2 bentuk soal | [formats], [optionCount] |
/// | S3 bantuan visual | [visualAid] |
/// | S4 teknik | [allowCarry] |
/// | S5 posisi yang dicari | [unknown] |
/// | S6 tekanan waktu | [timeLimitSeconds] |
///
/// **Aturan emas:** satu pos hanya boleh menaikkan satu sumbu dari pos
/// sebelumnya. [naikSatuSumbuDari] memeriksa itu, dan uji di
/// `test/engine/seed_content_test.dart` menjalankannya atas seluruh konten.
@freezed
abstract class DifficultyConfig with _$DifficultyConfig {
  const factory DifficultyConfig({
    @Default([Operation.tambah]) List<Operation> operations,

    /// Bilangan macam apa yang dipakai pos ini.
    ///
    /// Bawaannya [NumberDomain.bulat], jadi seluruh konten Tahap 1–3
    /// tidak perlu diubah satu baris pun — dan itu memang syaratnya:
    /// menambah ranah tidak boleh menyentuh 78 pos yang sudah dimainkan
    /// anak.
    @Default(NumberDomain.bulat) NumberDomain domain,
    @Default(1) int minOperand,

    /// Batas atas operan. Artinya ikut [domain]: penyebut untuk
    /// pecahan, sepersepuluhnya untuk desimal, bilangan yang dipersenkan
    /// untuk persen.
    @Default(10) int maxOperand,

    /// Batas atas hasil. `null` berarti hanya operan yang dibatasi.
    /// Ikut sumbu S1, bukan sumbu baru.
    int? maxResult,
    @Default(false) bool allowCarry,
    @Default(false) bool allowNegativeResult,
    @Default(UnknownPosition.hasil) UnknownPosition unknown,
    @Default([QuestionFormat.pilihanGanda]) List<QuestionFormat> formats,
    @Default(3) int optionCount,
    @Default(VisualAid.benda) VisualAid visualAid,
    int? timeLimitSeconds,
    @Default(10) int questionCount,
  }) = _DifficultyConfig;

  const DifficultyConfig._();

  factory DifficultyConfig.fromJson(Map<String, dynamic> json) =>
      _$DifficultyConfigFromJson(json);

  /// Nilai tiap sumbu, dipakai untuk membandingkan dua pos berurutan.
  Map<String, Object?> get sumbu => {
    'ranah': domain.name,
    'S1': '$minOperand-$maxOperand/$maxResult',
    'S2': '${formats.map((f) => f.name).join(",")}/$optionCount',
    'S3': visualAid.name,
    'S4': allowCarry,
    'S5': unknown.name,
    'S6': timeLimitSeconds,
    'operasi': operations.map((o) => o.name).join(','),
  };

  /// Nama sumbu yang berbeda dari [sebelumnya]. Kosong berarti dua pos
  /// itu identik kesulitannya.
  List<String> bedaSumbuDari(DifficultyConfig sebelumnya) {
    final a = sebelumnya.sumbu, b = sumbu;
    return [
      for (final k in a.keys)
        if (a[k].toString() != b[k].toString()) k,
    ];
  }

  /// Aturan emas: tepat satu sumbu naik dari pos sebelumnya.
  bool naikSatuSumbuDari(DifficultyConfig sebelumnya) =>
      bedaSumbuDari(sebelumnya).length == 1;

  /// Perkiraan lama sesi dalam menit, untuk sheet detail pos.
  int get perkiraanMenit => (questionCount * 17 / 60).ceil();

  /// Batas atas desimal yang boleh dibangkitkan, mis. `9.9`.
  double get maksDesimal => maxOperand / 10;

  /// Batas bawahnya. Nol tidak pernah dipakai sebagai operan desimal —
  /// `0,0 + 0,4` terbaca seperti salah cetak.
  double get minDesimal => (minOperand < 1 ? 1 : minOperand) / 10;
}
