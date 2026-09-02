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
    @Default(false) bool isUnlocked,
  }) = _Grade;

  const Grade._();

  factory Grade.fromJson(Map<String, dynamic> json) => _$GradeFromJson(json);

  /// `Kelas 1` — dipakai berpasangan dengan [name] di chip planet.
  String get label => 'Kelas $orderIndex';
}
