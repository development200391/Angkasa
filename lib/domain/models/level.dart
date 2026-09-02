import 'package:freezed_annotation/freezed_annotation.dart';

import '../engine/difficulty_config.dart';
import 'enums.dart';

part 'level.freezed.dart';
part 'level.g.dart';

/// Satu level — yang dilihat anak sebagai **pos** di lintasan, atau
/// **Gerbang Planet** kalau [type] `boss`.
///
/// Jantung sistem: yang tersimpan bukan soalnya, tapi
/// [difficultyConfig] yang membangkitkannya.
@freezed
abstract class Level with _$Level {
  const factory Level({
    required String id,
    required String chapterId,
    required int orderIndex,
    required String title,
    @Default(LevelType.practice) LevelType type,
    required DifficultyConfig difficultyConfig,
    @Default(10) int xpReward,
  }) = _Level;

  const Level._();

  factory Level.fromJson(Map<String, dynamic> json) => _$LevelFromJson(json);

  bool get isBoss => type == LevelType.boss;

  /// Judul yang dipakai di sheet detail dan layar hasil.
  String get displayTitle => isBoss ? 'Gerbang Planet' : 'Pos $orderIndex';
}
