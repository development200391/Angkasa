import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_activity.freezed.dart';
part 'daily_activity.g.dart';

/// Satu hari di tabel `daily_activity`.
///
/// Tabel inilah yang ditanya streak, Tantangan Harian, dan jam
/// pemberitahuan — tiga fitur Tahap 2 yang tidak butuh satu pun tabel
/// baru karena Tahap 1 sudah mencatatnya sejak pos pertama.
@freezed
abstract class DailyActivity with _$DailyActivity {
  const factory DailyActivity({
    required DateTime date,
    @Default(0) int xpEarned,
    @Default(0) int levelsCompleted,
    @Default(0) int secondsPlayed,
    @Default(false) bool challengeDone,
  }) = _DailyActivity;

  const DailyActivity._();

  factory DailyActivity.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityFromJson(json);

  bool get aktif => xpEarned > 0 || levelsCompleted > 0 || secondsPlayed > 0;
}
