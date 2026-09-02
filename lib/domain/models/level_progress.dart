import 'package:freezed_annotation/freezed_annotation.dart';

part 'level_progress.freezed.dart';
part 'level_progress.g.dart';

/// Progres anak pada satu pos.
///
/// [stars] disimpan yang **terbaik** dan tidak pernah turun — mengulang
/// pos yang sudah bintang tiga tidak bisa merusak apa pun, dan itu yang
/// membuat anak berani mencoba lagi.
@freezed
abstract class LevelProgress with _$LevelProgress {
  const factory LevelProgress({
    required String levelId,
    @Default(0) int stars,
    @Default(0) int bestScore,
    @Default(0) int attempts,
    DateTime? firstCompletedAt,
    DateTime? lastPlayedAt,
    @Default(false) bool isUnlocked,
  }) = _LevelProgress;

  const LevelProgress._();

  factory LevelProgress.fromJson(Map<String, dynamic> json) =>
      _$LevelProgressFromJson(json);

  bool get isCompleted => stars > 0;
}
