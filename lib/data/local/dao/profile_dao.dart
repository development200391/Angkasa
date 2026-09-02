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
      'sound_on': p.soundOn ? 1 : 0,
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

  static UserProfile _dari(Map<String, Object?> r) => UserProfile(
    id: r['id']! as int,
    nickname: r['nickname'] as String? ?? '',
    avatarId: r['avatar_id'] as String? ?? 'roket',
    activeGradeId: r['active_grade_id'] as String?,
    totalXp: r['total_xp'] as int? ?? 0,
    streakCount: r['streak_count'] as int? ?? 0,
    streakLastDate: r['streak_last_date'] is String
        ? DateTime.tryParse(r['streak_last_date']! as String)
        : null,
    soundOn: (r['sound_on'] as int? ?? 1) == 1,
    firebaseUid: r['firebase_uid'] as String?,
  );
}
