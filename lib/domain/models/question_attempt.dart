import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'question_attempt.freezed.dart';
part 'question_attempt.g.dart';

/// Satu baris `question_attempts`.
///
/// Dicatat sejak soal pertama di Tahap 1 walaupun yang membacanya —
/// mode Perbaiki Kesalahan dan dashboard orang tua — baru datang di
/// Tahap 2 dan 4. Tabel ini tidak pernah disinkronkan ke Firestore.
@freezed
abstract class QuestionAttempt with _$QuestionAttempt {
  const factory QuestionAttempt({
    int? id,
    required String levelId,
    required String questionSignature,
    required bool isCorrect,
    @Default(0) int timeMs,
    required DateTime answeredAt,
    MistakeKind? mistake,
  }) = _QuestionAttempt;

  factory QuestionAttempt.fromJson(Map<String, dynamic> json) =>
      _$QuestionAttemptFromJson(json);
}
