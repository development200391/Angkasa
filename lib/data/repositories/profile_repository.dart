import '../../domain/models/user_profile.dart';
import '../local/dao/profile_dao.dart';

/// Nama panggilan, avatar, planet aktif, dan XP. Tidak ada nama lengkap,
/// tidak ada tanggal lahir, tidak ada surel — makin sedikit yang
/// disimpan, makin sedikit yang perlu dijelaskan ke orang tua.
class ProfileRepository {
  ProfileRepository(this._dao);

  final ProfileDao _dao;

  Future<UserProfile> ambil() => _dao.ambil();

  Future<UserProfile> simpan(UserProfile p) => _dao.simpan(p);

  /// Aturan unlock nomor empat, jalur manual: planet boleh dipilih
  /// sendiri sejak onboarding dan diganti kapan saja lewat Profil.
  Future<UserProfile> gantiPlanet(String gradeId) => _dao.gantiPlanet(gradeId);

  Future<UserProfile> setSuara(bool nyala) async {
    final p = await _dao.ambil();
    return _dao.simpan(p.copyWith(soundOn: nyala));
  }

  Future<UserProfile> setPemberitahuan(bool nyala) async {
    final p = await _dao.ambil();
    return _dao.simpan(p.copyWith(notifOn: nyala));
  }

  /// Menyimpan jam yang dipelajari dari kebiasaan main, supaya
  /// pengingatnya tidak berpindah-pindah tiap kali dihitung ulang.
  Future<UserProfile> setJamPengingat(int jam) async {
    final p = await _dao.ambil();
    if (p.notifHour == jam) return p;
    return _dao.simpan(p.copyWith(notifHour: jam));
  }

  Future<UserProfile> selesaikanOnboarding({
    required String nama,
    required String avatarId,
    required String gradeId,
  }) async {
    final p = await _dao.ambil();
    return _dao.simpan(
      p.copyWith(
        nickname: nama.trim(),
        avatarId: avatarId,
        activeGradeId: gradeId,
      ),
    );
  }

  /// Dipakai tombol "Mulai dari awal" di Pengaturan, di balik Gerbang
  /// Orang Tua. XP ikut dinolkan supaya papan peringkat nanti tidak
  /// menyimpan angka yang tidak ada progresnya.
  Future<UserProfile> resetProfil() async {
    final p = await _dao.ambil();
    return _dao.simpan(
      p.copyWith(totalXp: 0, streakCount: 0, streakLastDate: null),
    );
  }
}
