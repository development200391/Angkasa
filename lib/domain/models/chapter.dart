import 'package:freezed_annotation/freezed_annotation.dart';

part 'chapter.freezed.dart';
part 'chapter.g.dart';

/// Satu bab — yang dilihat anak sebagai **zona** di permukaan planet.
@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String gradeId,
    required String title,
    required String icon,
    required String color,
    required int orderIndex,
  }) = _Chapter;

  const Chapter._();

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  /// `Zona 2 · Penjumlahan sampai 20`
  String get label => 'Zona $orderIndex · $title';
}
