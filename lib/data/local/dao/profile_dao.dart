import 'package:sqflite/sqflite.dart';

import '../../../domain/models/user_profile.dart';

/// Satu baris, id 1. Tidak ada layar masuk dan tidak ada data pribadi —
/// yang disimpan cuma nama panggilan dan avatar.
class ProfileDao {
  ProfileDao(this._db);

  static const _id = 1;

  final Database _db;

  Future<UserProfile> ambil() async {
    final rows = await _db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [_id],
      limit: 1,
    );
    if (rows.isEmpty) {
      await _db.insert('user_profile', {'id': _id});
      return const UserProfile();
    }
    return _dari(rows.first);
  }

  Future<UserProfile> simpan(UserProfile p) async {
    await _db.insert('user_profile', {
      'id': _id,
      'nickname': p.nickname,
      'avatar_id': p.avatarId,
      'active_grade_id': p.activeGradeId,
      'total_xp': p.totalXp,
      'streak_count': p.streakCount,
      'streak_last_date': p.streakLastDate?.toIso8601String(),
      'streak_best': p.streakBest,
      'streak_shield_last_used': p.streakShieldLastUsed?.toIso8601String(),
      'blitz_best': p.blitzBest,
      'sound_on': p.soundOn ? 1 : 0,
      'notif_on': p.notifOn ? 1 : 0,
      'notif_hour': p.notifHour,
      'leaderboard_on': p.leaderboardOn ? 1 : 0,
      'sync_cellular': p.syncCellular ? 1 : 0,
      'last_sync_at': p.lastSyncAt?.toIso8601String(),
      'account_email': p.accountEmail,
      'firebase_uid': p.firebaseUid,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    return p;
  }

  Future<UserProfile> tambahXp(int xp) async {
    final p = await ambil();
    return simpan(p.copyWith(totalXp: p.totalXp + xp));
  }

  Future<UserProfile> gantiPlanet(String gradeId) async {
    final p = await ambil();
    return simpan(p.copyWith(activeGradeId: gradeId));
  }

  static DateTime? _waktu(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  static UserProfile _dari(Map<String, Object?> r) => UserProfile(
    id: r['id']! as int,
    nickname: r['nickname'] as String? ?? '',
    avatarId: r['avatar_id'] as String? ?? 'roket',
    activeGradeId: r['active_grade_id'] as String?,
    totalXp: r['total_xp'] as int? ?? 0,
    streakCount: r['streak_count'] as int? ?? 0,
    streakLastDate: _waktu(r['streak_last_date']),
    streakBest: r['streak_best'] as int? ?? 0,
    streakShieldLastUsed: _waktu(r['streak_shield_last_used']),
    blitzBest: r['blitz_best'] as int? ?? 0,
    soundOn: (r['sound_on'] as int? ?? 1) == 1,
    notifOn: (r['notif_on'] as int? ?? 1) == 1,
    notifHour: r['notif_hour'] as int?,
    leaderboardOn: (r['leaderboard_on'] as int? ?? 1) == 1,
    syncCellular: (r['sync_cellular'] as int? ?? 0) == 1,
    lastSyncAt: _waktu(r['last_sync_at']),
    accountEmail: r['account_email'] as String?,
    firebaseUid: r['firebase_uid'] as String?,
  );
}
