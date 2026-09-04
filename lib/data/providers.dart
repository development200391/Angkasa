import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../core/constants/app_config.dart';
import '../core/services/audio_service.dart';
import '../core/services/connectivity_service.dart';
import '../core/services/notification_service.dart';
import '../domain/engine/aturan_nilai.dart';
import '../domain/engine/streak_rules.dart';
import '../domain/models/daily_activity.dart';
import '../domain/models/level_view.dart';
import '../domain/models/user_profile.dart';
import 'local/dao/attempt_dao.dart';
import 'local/dao/badge_dao.dart';
import 'local/dao/league_dao.dart';
import 'local/dao/level_dao.dart';
import 'local/dao/profile_dao.dart';
import 'local/dao/progress_dao.dart';
import 'local/dao/sync_queue_dao.dart';
import 'remote/firebase_gateway.dart';
import 'remote/remote_gateway.dart';
import 'repositories/account_repository.dart';
import 'repositories/badge_repository.dart';
import 'repositories/content_repository.dart';
import 'repositories/leaderboard_repository.dart';
import 'repositories/practice_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/progress_repository.dart';
import 'repositories/sync_repository.dart';

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
final syncQueueDaoProvider = Provider(
  (ref) => SyncQueueDao(ref.watch(databaseProvider)),
);
final leagueDaoProvider = Provider(
  (ref) => LeagueDao(ref.watch(databaseProvider)),
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
    // Satu-satunya sambungan antara belajar dan jaringan, dan arahnya
    // cuma satu: aktivitas memberi tahu antrean. Antrean tidak pernah
    // bisa menahan, membatalkan, atau memperlambat penyimpanan pos.
    setelahAktivitas: () => ref.read(syncRepositoryProvider).antreProfil(),
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

// ---------------------------------------------------------- Tahap 3
/// Pintu ke dunia luar.
///
/// Yang dipilih di sini menentukan seluruh sisa aplikasi. Bawaannya
/// [GatewayLuring] — tanpa `--dart-define` apa pun, tidak ada satu baris
/// kode Firebase yang pernah dijalankan, dan aplikasinya berperilaku
/// persis seperti Tahap 2.
final remoteGatewayProvider = Provider<RemoteGateway>((ref) {
  if (!AppConfig.daringAktif) return const GatewayLuring();
  return FirebaseGateway();
});

/// Keadaan sambungan. Dipakai spanduk "Tidak ada sinyal" di layar
/// Jelajah dan syarat "hanya lewat Wi-Fi" di antrean.
final connectivityProvider = Provider<ConnectivityService>((ref) {
  final layanan = AppConfig.daringAktif
      ? ConnectivityPlusService()
      : KoneksiTetap(JenisKoneksi.tidakAda);
  ref.onDispose(layanan.dispose);
  return layanan;
});

final koneksiProvider = StreamProvider<JenisKoneksi>((ref) async* {
  final layanan = ref.watch(connectivityProvider);
  yield await layanan.sekarang();
  yield* layanan.aliran;
});

/// Nilai dari Remote Config.
///
/// Selalu punya isi sejak detik pertama: keadaan awalnya
/// [AturanNilai.bawaan], yang sama persis dengan konstanta Tahap 2.
/// Kalau pengambilannya gagal atau lambat, tidak ada satu pun layar yang
/// menunggu — yang berubah cuma angkanya, dan itu pun belakangan.
class AturanNilaiNotifier extends Notifier<AturanNilai> {
  @override
  AturanNilai build() {
    _muat();
    return AturanNilai.bawaan;
  }

  Future<void> _muat() async {
    final gateway = ref.read(remoteGatewayProvider);
    if (!gateway.tersedia) return;
    state = await gateway.aturanNilai();
  }

  Future<void> muatUlang() => _muat();
}

final aturanNilaiProvider = NotifierProvider<AturanNilaiNotifier, AturanNilai>(
  AturanNilaiNotifier.new,
);

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  final repo = SyncRepository(
    antreanDao: ref.watch(syncQueueDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    badgeDao: ref.watch(badgeDaoProvider),
    leagueDao: ref.watch(leagueDaoProvider),
    gateway: ref.watch(remoteGatewayProvider),
    koneksi: ref.watch(connectivityProvider),
    aturan: () => ref.read(aturanNilaiProvider),
  );
  ref.onDispose(repo.dispose);
  return repo;
});

final leaderboardRepositoryProvider = Provider(
  (ref) => LeaderboardRepository(
    leagueDao: ref.watch(leagueDaoProvider),
    profileDao: ref.watch(profileDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    gateway: ref.watch(remoteGatewayProvider),
    aturan: () => ref.read(aturanNilaiProvider),
  ),
);

final accountRepositoryProvider = Provider(
  (ref) => AccountRepository(
    profileDao: ref.watch(profileDaoProvider),
    progressDao: ref.watch(progressDaoProvider),
    levelDao: ref.watch(levelDaoProvider),
    badgeDao: ref.watch(badgeDaoProvider),
    antreanDao: ref.watch(syncQueueDaoProvider),
    gateway: ref.watch(remoteGatewayProvider),
    sinkron: ref.watch(syncRepositoryProvider),
  ),
);

/// Berapa yang menunggu di antrean — angka di lencana "3 antre".
final antreanProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(syncRepositoryProvider);
  yield await repo.jumlahMenunggu();
  yield* repo.perubahan;
});

/// Papan peringkat liga yang sedang berjalan.
final papanLigaProvider = FutureProvider((ref) async {
  // Ikut tiga hal yang benar-benar bisa mengubah isinya: profil (nama,
  // avatar, setelan), antrean (skor yang baru terkirim), dan sambungan.
  ref.watch(profileProvider);
  ref.watch(antreanProvider);
  ref.watch(koneksiProvider);
  return ref.watch(leaderboardRepositoryProvider).papanSekarang();
});

/// Hasil minggu lalu yang belum pernah ditampilkan, kalau ada.
final ringkasanMingguProvider = FutureProvider((ref) async {
  ref.watch(profileProvider);
  return ref.watch(leaderboardRepositoryProvider).ringkasanBelumDilihat();
});

/// Keadaan akun untuk layar Akun & data.
final keadaanAkunProvider = FutureProvider((ref) async {
  ref.watch(profileProvider);
  ref.watch(antreanProvider);
  return ref.watch(accountRepositoryProvider).keadaan();
});

/// Dua progres yang harus dipilih salah satu — `null` kalau memang tidak
/// ada yang perlu dipilih, yang merupakan keadaan hampir semua orang.
final pilihanPemulihanProvider = FutureProvider(
  (ref) => ref.watch(accountRepositoryProvider).pilihanPemulihan(),
);
