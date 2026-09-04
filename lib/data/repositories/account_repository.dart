import '../../core/constants/app_config.dart';
import '../../domain/engine/nickname_filter.dart';
import '../../domain/models/user_profile.dart';
import '../local/dao/badge_dao.dart';
import '../local/dao/level_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../remote/remote_gateway.dart';
import '../remote/remote_models.dart';
import 'sync_repository.dart';

/// Ringkasan satu simpanan progres, untuk layar Pulihkan progres.
class RingkasanProgres {
  const RingkasanProgres({
    required this.nama,
    required this.gradeId,
    required this.posSelesai,
    required this.totalXp,
    required this.terakhir,
  });

  final String nama;
  final String? gradeId;
  final int posSelesai;
  final int totalXp;
  final DateTime? terakhir;
}

/// Dua progres yang harus dipilih salah satu.
class PilihanPemulihan {
  const PilihanPemulihan({required this.diHpIni, required this.diAkun});

  final RingkasanProgres diHpIni;
  final RingkasanProgres diAkun;
}

/// Keadaan akun, dibaca layar Akun & data.
class KeadaanAkun {
  const KeadaanAkun({
    required this.tersambung,
    required this.anonim,
    required this.email,
    required this.menunggu,
    required this.terakhirSinkron,
    required this.bisaMasukGoogle,
  });

  final bool tersambung;
  final bool anonim;
  final String? email;
  final int menunggu;
  final DateTime? terakhirSinkron;
  final bool bisaMasukGoogle;

  bool get bersih => tersambung && menunggu == 0;
}

/// Akun, cadangan, dan setelan data — semuanya di balik Gerbang Orang
/// Tua.
///
/// Satu aturan menjalar ke seluruh kelas ini: **tidak ada satu pun
/// tombol di sini yang boleh mengunci materi belajar**. Mematikan papan
/// peringkat, menolak menyalakan cadangan, bahkan menghapus seluruh data
/// di server — semuanya cuma mengubah apa yang dikirim keluar. Kalau
/// menolaknya terasa berisiko, orang tua akan memilih tidak memasang
/// aplikasinya sama sekali.
class AccountRepository {
  AccountRepository({
    required ProfileDao profileDao,
    required ProgressDao progressDao,
    required LevelDao levelDao,
    required BadgeDao badgeDao,
    required SyncQueueDao antreanDao,
    required this.gateway,
    required this.sinkron,
  }) : _profile = profileDao,
       _progress = progressDao,
       _level = levelDao,
       _badge = badgeDao,
       _antrean = antreanDao;

  final ProfileDao _profile;
  final ProgressDao _progress;
  final LevelDao _level;
  final BadgeDao _badge;
  final SyncQueueDao _antrean;
  final RemoteGateway gateway;
  final SyncRepository sinkron;

  // ---------------------------------------------------------- setelan
  Future<UserProfile> setPapanPeringkat(bool nyala) async {
    final p = await _profile.ambil();
    final baru = await _profile.simpan(p.copyWith(leaderboardOn: nyala));
    if (nyala) {
      await sinkron.antreProfil();
    }
    return baru;
  }

  Future<UserProfile> setSinkronSeluler(bool nyala) async {
    final p = await _profile.ambil();
    final baru = await _profile.simpan(p.copyWith(syncCellular: nyala));
    if (nyala) await sinkron.kirimSekarang();
    return baru;
  }

  /// Mengganti nama panggilan, setelah disaring.
  ///
  /// Mengembalikan hasil pemeriksaan apa adanya kalau ditolak, supaya
  /// layar bisa menampilkan alasannya — bukan sekadar "gagal".
  Future<HasilNama> gantiNama(String nama) async {
    final hasil = NicknameFilter.periksa(nama);
    if (!hasil.boleh) return hasil;

    final p = await _profile.ambil();
    await _profile.simpan(p.copyWith(nickname: nama.trim()));
    await sinkron.antreProfil();
    return hasil;
  }

  // ------------------------------------------------------------ akun
  Future<KeadaanAkun> keadaan() async {
    final profil = await _profile.ambil();
    return KeadaanAkun(
      tersambung: gateway.tersedia,
      anonim: profil.akunAnonim,
      email: profil.accountEmail,
      menunggu: await _antrean.jumlah(),
      terakhirSinkron: profil.lastSyncAt,
      bisaMasukGoogle: gateway.bisaMasukGoogle && AppConfig.daringAktif,
    );
  }

  /// Menyalakan cadangan otomatis: masuk anonim sekali, lalu menyalin
  /// seluruh progres yang ada sekarang.
  ///
  /// Tidak ada layar masuk dan tidak ada surel yang diminta. Akun anonim
  /// sudah cukup untuk mencadangkan; menautkannya ke Google baru perlu
  /// kalau HP-nya benar-benar diganti.
  /// Tidak pernah melempar.
  ///
  /// Tiap panggilan ke server di sini dibungkus, dan alasannya konkret:
  /// tombol yang menunggu `Future` yang melempar akan **tersangkut di
  /// "Menyimpan…" selamanya** — tidak berhasil, tidak gagal, dan tidak
  /// bisa ditekan lagi. Kegagalan yang terlihat jauh lebih baik daripada
  /// tombol yang diam.
  Future<bool> nyalakanCadangan() async {
    if (!gateway.tersedia) return false;
    try {
      final akun = await gateway.masukAnonim();
      if (akun == null) return false;

      final p = await _profile.ambil();
      await _profile.simpan(
        p.copyWith(firebaseUid: akun.uid, accountEmail: akun.email),
      );
      await sinkron.antreProfil();
      await sinkron.antreCadangan();
      final hasil = await sinkron.kirimSekarang(paksa: true);
      return hasil.terkirim > 0;
    } catch (e, s) {
      await gateway.catatGalat(e, s);
      return false;
    }
  }

  /// Menautkan akun Google, dan menyimpan akun yang berjalan sesudahnya.
  ///
  /// Tidak ada satu pun cabang di sini yang mengirim progres. Untuk
  /// [HasilTaut.berhasil] memang tidak perlu — uid-nya tidak berubah,
  /// jadi cadangan yang sudah ada di server sejak tadi sudah menjadi
  /// milik akun Google itu. Dan untuk [HasilTaut.sudahDipakaiAkunLain]
  /// mengirim justru berbahaya: itu akan menimpa progres HP lama
  /// **sebelum** orang tua sempat memilih di layar Pulihkan progres.
  Future<HasilTaut> tautkanGoogle() async {
    try {
      final tautan = await gateway.tautkanGoogle();
      final akun = tautan.akun;
      if (akun != null) {
        final p = await _profile.ambil();
        await _profile.simpan(
          p.copyWith(firebaseUid: akun.uid, accountEmail: akun.email),
        );
      }
      return tautan.hasil;
    } catch (e, s) {
      await gateway.catatGalat(e, s);
      return HasilTaut.gagal;
    }
  }

  // -------------------------------------------------------- pemulihan
  /// Membandingkan progres di HP ini dengan yang tersimpan di akun.
  ///
  /// `null` berarti tidak ada yang perlu dipilih: entah akunnya kosong,
  /// entah HP-nya kosong. Layar Pulihkan progres cuma muncul kalau
  /// dua-duanya berisi — dan itu memang satu-satunya keadaan yang
  /// benar-benar membingungkan.
  Future<PilihanPemulihan?> pilihanPemulihan() async {
    if (!gateway.tersedia) return null;

    final ProfilDaring? profilDaring;
    final CadanganProgres? cadangan;
    try {
      if (await gateway.masukAnonim() == null) return null;
      profilDaring = await gateway.bacaProfil();
      cadangan = await gateway.bacaCadangan();
    } catch (e, s) {
      // Gagal menanyakan server bukan berarti ada dua progres. Yang
      // benar adalah tidak menampilkan layar pemulihan sama sekali —
      // satu-satunya layar di aplikasi ini yang bisa menghapus data.
      await gateway.catatGalat(e, s);
      return null;
    }
    if (profilDaring == null || cadangan == null) return null;
    if (cadangan.jumlahPosSelesai == 0) return null;

    final lokal = await _profile.ambil();
    final progres = await _progress.semua();
    final posLokal = progres.values.where((p) => p.stars > 0).length;
    if (posLokal == 0) return null;

    return PilihanPemulihan(
      diHpIni: RingkasanProgres(
        nama: lokal.namaTampil,
        gradeId: lokal.activeGradeId,
        posSelesai: posLokal,
        totalXp: lokal.totalXp,
        terakhir: progres.values
            .map((p) => p.lastPlayedAt)
            .nonNulls
            .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a),
      ),
      diAkun: RingkasanProgres(
        nama: profilDaring.nickname,
        gradeId: profilDaring.gradeLevel,
        posSelesai: cadangan.jumlahPosSelesai,
        totalXp: profilDaring.totalXp,
        terakhir: cadangan.diperbarui,
      ),
    );
  }

  /// Menimpa progres di HP dengan yang tersimpan di akun.
  ///
  /// Yang tidak dipilih hilang permanen — itu ditulis lugas di layarnya,
  /// dan tidak ada satu pun pilihan yang dicentang lebih dulu.
  Future<bool> pulihkanDariAkun() async {
    final CadanganProgres? cadangan;
    final ProfilDaring? profilDaring;
    try {
      cadangan = await gateway.bacaCadangan();
      profilDaring = await gateway.bacaProfil();
    } catch (e, s) {
      await gateway.catatGalat(e, s);
      return false;
    }
    if (cadangan == null || profilDaring == null) return false;

    // Cadangan bisa dibuat versi aplikasi yang punya pos lebih banyak.
    // Yang belum ada di pemasangan ini dibuang, bukan dipaksa masuk.
    final dikenal = await _level.semuaIdPos();
    await _progress.pulihkan({
      for (final e in cadangan.pos.entries)
        if (dikenal.contains(e.key)) e.key: e.value,
    });

    await _badge.hapusSemua();
    await _badge.simpan(cadangan.lencana, cadangan.diperbarui);

    final lokal = await _profile.ambil();
    await _profile.simpan(
      lokal.copyWith(
        nickname: profilDaring.nickname,
        avatarId: profilDaring.avatarId,
        activeGradeId: profilDaring.gradeLevel ?? lokal.activeGradeId,
        totalXp: profilDaring.totalXp,
        streakCount: profilDaring.streakCount,
      ),
    );
    return true;
  }

  /// Menimpa yang tersimpan di akun dengan progres di HP ini.
  Future<bool> pertahankanYangDiHp() async {
    try {
      await sinkron.antreProfil();
      await sinkron.antreCadangan();
      final hasil = await sinkron.kirimSekarang(paksa: true);
      return hasil.terkirim > 0;
    } catch (e, s) {
      await gateway.catatGalat(e, s);
      return false;
    }
  }

  // ---------------------------------------------------------- hapus
  /// Menghapus seluruh data anak ini di server, dan berhenti mengirim.
  ///
  /// Tidak menyentuh apa pun di HP: bintang, XP, dan lencana tetap ada.
  /// Yang dihapus benar-benar cuma salinan di server, karena itulah yang
  /// dijanjikan tulisan tombolnya.
  Future<void> hapusDataServer() async {
    await _antrean.hapusSemua();
    if (gateway.tersedia) {
      try {
        await gateway.hapusSemuaData();
        await gateway.keluar();
      } catch (e, s) {
        // Setelan lokal tetap dimatikan di bawah, sekalipun servernya
        // tidak bisa dihubungi: yang dijanjikan tombol ini adalah
        // berhenti mengirim, dan itu bagian yang selalu bisa ditepati.
        await gateway.catatGalat(e, s);
      }
    }
    final p = await _profile.ambil();
    await _profile.simpan(
      p.copyWith(
        leaderboardOn: false,
        firebaseUid: null,
        accountEmail: null,
        lastSyncAt: null,
      ),
    );
  }

  /// Isi dua daftar di layar Data yang dikirim.
  ///
  /// Sengaja dibangkitkan dari kode, bukan diketik di layar: daftar yang
  /// ditulis tangan akan basi pada perubahan pertama, dan layar ini
  /// harus sama persis dengan deklarasi *Data safety* di Play Console.
  static List<String> get yangDikirim => const [
    'Nama panggilan — yang diketik sendiri',
    'Nomor avatar',
    'Total XP dan XP minggu ini',
    'Kelas yang sedang aktif',
    'Jumlah hari streak',
    'Bintang tiap pos, untuk memulihkan progres',
  ];

  static List<String> get tidakPernahDikirim => const [
    'Nama asli, umur, sekolah',
    'Lokasi',
    'Jawaban tiap soal — tinggal di HP',
    'ID iklan, IMEI, MAC address',
    'Kontak, foto, mikrofon',
  ];
}
