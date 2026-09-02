import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/models/level_view.dart';
import '../domain/models/user_profile.dart';
import 'local/dao/attempt_dao.dart';
import 'local/dao/level_dao.dart';
import 'local/dao/profile_dao.dart';
import 'local/dao/progress_dao.dart';
import 'repositories/content_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/progress_repository.dart';

/// Basis data yang sudah dibuka. Diisi lewat `overrideWithValue` di
/// `main()`, jadi seluruh pohon widget boleh menganggapnya siap pakai
/// dan tidak ada satu pun layar yang perlu menunggu koneksi.
final databaseProvider = Provider<Database>(
  (ref) => throw UnimplementedError('databaseProvider harus di-override'),
);

final levelDaoProvider = Provider(
  (ref) => LevelDao(ref.watch(databaseProvider)),
);
final progressDaoProvider = Provider(
  (ref) => ProgressDao(ref.watch(databaseProvider)),
);
final profileDaoProvider = Provider(
  (ref) => ProfileDao(ref.watch(databaseProvider)),
);
final attemptDaoProvider = Provider(
  (ref) => AttemptDao(ref.watch(databaseProvider)),
);

final contentRepositoryProvider = Provider(
  (ref) => ContentRepository(ref.watch(levelDaoProvider)),
);

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(
    levelDao: ref.watch(levelDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    attemptDao: ref.watch(attemptDaoProvider),
  ),
);

final profileRepositoryProvider = Provider(
  (ref) => ProfileRepository(ref.watch(profileDaoProvider)),
);

/// Profil anak. Satu-satunya sumber untuk nama, avatar, XP, dan planet
/// yang sedang aktif.
class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() => ref.watch(profileRepositoryProvider).ambil();

  Future<void> gantiPlanet(String gradeId) async {
    final repo = ref.read(profileRepositoryProvider);
    state = AsyncData(await repo.gantiPlanet(gradeId));
    ref.invalidate(petaProvider);
  }

  Future<void> setSuara(bool nyala) async {
    final repo = ref.read(profileRepositoryProvider);
    state = AsyncData(await repo.setSuara(nyala));
  }

  Future<void> selesaikanOnboarding({
    required String nama,
    required String avatarId,
    required String gradeId,
  }) async {
    final repo = ref.read(profileRepositoryProvider);
    state = AsyncData(
      await repo.selesaikanOnboarding(
        nama: nama,
        avatarId: avatarId,
        gradeId: gradeId,
      ),
    );
    ref.invalidate(petaProvider);
  }

  Future<void> muatUlang() async {
    state = AsyncData(await ref.read(profileRepositoryProvider).ambil());
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile>(
  ProfileNotifier.new,
);

/// Peta planet yang sedang aktif — sumber layar Jelajah.
///
/// Sengaja satu provider untuk seluruh planet, bukan satu per zona:
/// bacanya sekali, dan layar hasil cukup memanggil `invalidate` sekali
/// juga setelah sesi selesai.
final petaProvider = FutureProvider<PetaPlanet?>((ref) async {
  final profil = await ref.watch(profileProvider.future);
  final gradeId = profil.activeGradeId;
  if (gradeId == null) return null;
  return ref.watch(progressRepositoryProvider).peta(gradeId);
});

/// Daftar enam planet untuk layar pilih planet.
final planetsProvider = FutureProvider(
  (ref) => ref.watch(contentRepositoryProvider).planets(),
);
