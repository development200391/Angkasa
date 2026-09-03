import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/services/audio_service.dart';
import '../core/services/notification_service.dart';
import '../domain/engine/streak_rules.dart';
import '../domain/models/daily_activity.dart';
import '../domain/models/level_view.dart';
import '../domain/models/user_profile.dart';
import 'local/dao/attempt_dao.dart';
import 'local/dao/badge_dao.dart';
import 'local/dao/level_dao.dart';
import 'local/dao/profile_dao.dart';
import 'local/dao/progress_dao.dart';
import 'repositories/badge_repository.dart';
import 'repositories/content_repository.dart';
import 'repositories/practice_repository.dart';
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
final badgeDaoProvider = Provider(
  (ref) => BadgeDao(ref.watch(databaseProvider)),
);

final contentRepositoryProvider = Provider(
  (ref) => ContentRepository(ref.watch(levelDaoProvider)),
);

final badgeRepositoryProvider = Provider(
  (ref) => BadgeRepository(
    badgeDao: ref.watch(badgeDaoProvider),
    levelDao: ref.watch(levelDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    attemptDao: ref.watch(attemptDaoProvider),
  ),
);

final progressRepositoryProvider = Provider(
  (ref) => ProgressRepository(
    levelDao: ref.watch(levelDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    attemptDao: ref.watch(attemptDaoProvider),
    badgeRepository: ref.watch(badgeRepositoryProvider),
  ),
);

final practiceRepositoryProvider = Provider(
  (ref) => PracticeRepository(
    levelDao: ref.watch(levelDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    attemptDao: ref.watch(attemptDaoProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    badgeRepository: ref.watch(badgeRepositoryProvider),
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
/// Ikut profil lewat `watch`, jadi berganti planet cukup mengubah profil
/// — peta menyusun ulang dirinya sendiri. Meng-`invalidate` peta dari
/// dalam notifier profil justru melingkar: peta memang bergantung pada
/// profil.
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

// ---------------------------------------------------------- layanan
/// Efek suara. Mengikuti setelan Suara di Pengaturan tanpa perlu satu
/// pun layar mengurusnya sendiri.
final audioServiceProvider = Provider<AudioService>((ref) {
  final audio = AudioService();
  ref.listen(profileProvider, (_, next) {
    final p = next.value;
    if (p != null) audio.setNyala(p.soundOn);
  }, fireImmediately: true);
  ref.onDispose(audio.dispose);
  return audio;
});

final notificationServiceProvider = Provider((ref) => NotificationService());

// ------------------------------------------------------- Tahap 2
/// Isi tab Latihan: berapa soal menunggu diperbaiki, tantangan hari ini
/// sudah dikerjakan atau belum, dan rekor Kilat.
final practiceSummaryProvider = FutureProvider((ref) async {
  ref.watch(profileProvider);
  return ref.watch(practiceRepositoryProvider).ringkasan();
});

/// Soal yang menunggu diperbaiki, sudah dikelompokkan pemanggilnya
/// menurut jenis kesalahan.
final daftarSalahProvider = FutureProvider((ref) async {
  ref.watch(profileProvider);
  return ref.watch(practiceRepositoryProvider).daftarSalah();
});

/// Lencana yang sudah didapat.
final badgesProvider = FutureProvider((ref) async {
  ref.watch(profileProvider);
  return ref.watch(badgeRepositoryProvider).semua();
});

/// Tujuh hari minggu ini, untuk deretan titik streak.
final mingguIniProvider = FutureProvider<List<DailyActivity>>((ref) async {
  ref.watch(profileProvider);
  final hari = StreakRules.mingguIni(DateTime.now());
  return ref
      .watch(progressDaoProvider)
      .harian(dari: hari.first, sampai: hari.last);
});

/// Menjadwalkan ulang pengingat harian dari keadaan terkini.
///
/// Dibaca sekali saat aplikasi dibuka dan tiap kali setelannya berubah.
/// Isinya menyebut angka yang nyata — streak yang sedang berjalan dan
/// pos yang menunggu — karena ajakan umum diabaikan setelah hari kedua.
final pengingatHarianProvider = FutureProvider<void>((ref) async {
  final profil = await ref.watch(profileProvider.future);
  final layanan = ref.watch(notificationServiceProvider);

  if (!profil.notifOn) {
    await layanan.batalkan();
    return;
  }

  // Jam dipelajari dari kebiasaan menjawab soal, lalu disimpan supaya
  // tidak berpindah-pindah tiap kali dihitung ulang.
  var jam = profil.notifHour;
  if (jam == null) {
    final dipelajari = await ref.read(attemptDaoProvider).jamPalingSering();
    if (dipelajari != null) {
      jam = dipelajari;
      await ref.read(profileRepositoryProvider).setJamPengingat(dipelajari);
    }
  }

  final peta = await ref.watch(petaProvider.future);
  final posBerikutnya = peta?.zonaAktif?.posAktif;
  final menunggu = (await ref.read(attemptDaoProvider).menunggu()).length;

  final kalimat = NotificationService.kalimat(
    streak: profil.streakCount,
    posBerikutnya: posBerikutnya == null
        ? null
        : '${posBerikutnya.level.displayTitle} di '
              '${peta!.zonaAktif!.chapter.title}',
    menungguDiperbaiki: menunggu,
  );

  await layanan.jadwalkanHarian(
    jam: jam ?? NotificationService.jamBawaan,
    judul: kalimat.judul,
    isi: kalimat.isi,
  );
});
