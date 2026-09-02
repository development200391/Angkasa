import 'package:freezed_annotation/freezed_annotation.dart';

import 'question.dart';

part 'quiz_result.freezed.dart';
part 'quiz_result.g.dart';

/// Satu soal yang sudah dijawab, lengkap dengan apa yang diisi anak.
/// Dipakai layar pembahasan dan dicatat ke `question_attempts`.
@freezed
abstract class AnsweredQuestion with _$AnsweredQuestion {
  const factory AnsweredQuestion({
    required Question question,
    required String given,
    required bool isCorrect,
    @Default(0) int timeMs,
  }) = _AnsweredQuestion;

  factory AnsweredQuestion.fromJson(Map<String, dynamic> json) =>
      _$AnsweredQuestionFromJson(json);
}

/// Hasil satu sesi pos.
@freezed
abstract class QuizResult with _$QuizResult {
  const factory QuizResult({
    required String levelId,
    required int correct,
    required int total,
    required int stars,
    required int xpEarned,
    required int durationSeconds,
    @Default(false) bool outOfHearts,
    @Default(false) bool isNewBest,
    @Default([]) List<AnsweredQuestion> answers,
    @Default([]) List<String> unlockedLevelIds,
    @Default(false) bool unlockedNextChapter,
  }) = _QuizResult;

  const QuizResult._();

  factory QuizResult.fromJson(Map<String, dynamic> json) =>
      _$QuizResultFromJson(json);

  bool get isPassed => stars > 0;

  List<AnsweredQuestion> get wrongAnswers =>
      answers.where((a) => !a.isCorrect).toList();

  /// `2:14`
  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
