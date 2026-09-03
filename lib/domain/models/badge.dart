import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

/// Satu baris `badges`: kode lencana dan tanggal dapatnya.
///
/// Isinya sengaja sesedikit itu. Nama, keterangan, dan syaratnya hidup
/// di katalog kode (`BadgeRules`), jadi memperbaiki kalimat sebuah
/// lencana tidak pernah butuh migrasi basis data.
@freezed
abstract class EarnedBadge with _$EarnedBadge {
  const factory EarnedBadge({
    required String code,
    required DateTime unlockedAt,
  }) = _EarnedBadge;

  factory EarnedBadge.fromJson(Map<String, dynamic> json) =>
      _$EarnedBadgeFromJson(json);
}
