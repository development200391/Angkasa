import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

/// Satu-satunya baris di tabel `user_profile`.
///
/// [firebaseUid] sudah disediakan sekarang tapi baru diisi di Tahap 3;
/// menambah kolom belakangan berarti menulis migrasi untuk sesuatu yang
/// sudah pasti datang.
@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    @Default(1) int id,
    @Default('') String nickname,
    @Default('roket') String avatarId,
    String? activeGradeId,
    @Default(0) int totalXp,
    @Default(0) int streakCount,
    DateTime? streakLastDate,

    /// Streak terpanjang yang pernah dicapai. Disimpan terpisah supaya
    /// lencana streak tidak hilang waktu rentetannya putus.
    @Default(0) int streakBest,

    /// Kapan pelindung streak mingguan terakhir terpakai.
    DateTime? streakShieldLastUsed,

    /// Rekor Kilat 60 Detik.
    @Default(0) int blitzBest,
    @Default(true) bool soundOn,

    /// Pemberitahuan harian. Bisa dimatikan di Pengaturan, di balik
    /// Gerbang Orang Tua.
    @Default(true) bool notifOn,

    /// Jam pemberitahuan, dipelajari dari `daily_activity`. `null`
    /// berarti belum cukup data dan dipakai jam bawaan.
    int? notifHour,
    String? firebaseUid,
  }) = _UserProfile;

  const UserProfile._();

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  bool get sudahOnboarding => nickname.isNotEmpty && activeGradeId != null;

  String get namaTampil => nickname.isEmpty ? 'Penjelajah' : nickname;
}
