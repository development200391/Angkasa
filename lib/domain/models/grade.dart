import 'package:freezed_annotation/freezed_annotation.dart';

part 'grade.freezed.dart';
part 'grade.g.dart';

/// Satu kelas SD — yang dilihat anak sebagai **planet**.
///
/// Temanya cuma label. Di kode dan basis data namanya tetap `grade`.
@freezed
abstract class Grade with _$Grade {
  const factory Grade({
    required String id,
    required String name,
    required int orderIndex,
    required String icon,

    /// Planet ini sudah ada isinya. Sejak Tahap 4 seluruhnya `true`.
    @Default(false) bool isUnlocked,

    /// Planet ini perlu dibeli sebelum bisa dimainkan.
    ///
    /// Sengaja terpisah dari [isUnlocked], dan bedanya bukan kerapian:
    /// yang satu menjawab "sudah ada isinya?", yang ini menjawab
    /// "sudah jadi hakmu?". Digabung jadi satu, planet yang belum
    /// selesai ditulis dan planet yang belum dibayar tampil serupa —
    /// dan orang tua yang melihat "segera hadir" di planet yang
    /// sebenarnya tinggal dibeli tidak akan pernah membelinya.
    @Default(false) bool requiresPurchase,
  }) = _Grade;

  const Grade._();

  factory Grade.fromJson(Map<String, dynamic> json) => _$GradeFromJson(json);

  /// `Kelas 1` — dipakai berpasangan dengan [name] di chip planet.
  String get label => 'Kelas $orderIndex';
}
