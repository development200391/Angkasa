import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'question.freezed.dart';
part 'question.g.dart';

/// Satu pilihan jawaban. Yang salah **tidak diacak** — tiap pengecoh
/// meniru satu kesalahan yang memang sering dilakukan anak, dan nama
/// kesalahan itulah yang nanti dibaca layar statistik.
@freezed
abstract class AnswerOption with _$AnswerOption {
  const factory AnswerOption({
    required String label,
    @Default(false) bool isCorrect,
    MistakeKind? mistake,
  }) = _AnswerOption;

  factory AnswerOption.fromJson(Map<String, dynamic> json) =>
      _$AnswerOptionFromJson(json);
}

/// Satu soal siap tampil. Dibangkitkan saat berjalan oleh
/// `QuestionGenerator`, atau dibaca dari tabel `static_questions`.
@freezed
abstract class Question with _$Question {
  const factory Question({
    /// Bentuk baku soal, mis. `7+5=?`. Inilah yang dicatat di
    /// `question_attempts` supaya mode Perbaiki Kesalahan bisa
    /// memanggilnya kembali tanpa menyimpan soalnya.
    required String signature,
    required QuestionFormat format,
    required String prompt,
    required String answer,
    @Default([]) List<AnswerOption> options,
    required Operation operation,
    required int left,
    required int right,
    required int result,
    @Default(UnknownPosition.hasil) UnknownPosition unknown,
    @Default(VisualAid.tidakAda) VisualAid visualAid,
    String? explanation,
    String? imageAsset,
    int? timeLimitSeconds,
  }) = _Question;

  const Question._();

  factory Question.fromJson(Map<String, dynamic> json) =>
      _$QuestionFromJson(json);

  bool isCorrect(String jawaban) => jawaban.trim() == answer;

  /// Kesalahan apa yang ditiru [jawaban]. `null` kalau jawabannya benar.
  MistakeKind? mistakeOf(String jawaban) {
    if (isCorrect(jawaban)) return null;
    for (final o in options) {
      if (o.label == jawaban) return o.mistake ?? MistakeKind.lainnya;
    }
    return MistakeKind.lainnya;
  }

  /// Batas atas garis bilangan — dibulatkan ke 10, 20, 50, atau 100.
  int get numberLineMax {
    final tertinggi = [left, right, result].reduce((a, b) => a > b ? a : b);
    for (final b in const [10, 20, 50, 100]) {
      if (tertinggi <= b) return b;
    }
    return ((tertinggi / 100).ceil()) * 100;
  }
}
