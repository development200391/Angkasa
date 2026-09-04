import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;

import '../../core/services/connectivity_service.dart';
import '../../domain/engine/aturan_nilai.dart';
import '../../domain/engine/liga_rules.dart';
import '../../domain/engine/streak_rules.dart';
import '../../domain/models/liga.dart';
import '../local/dao/badge_dao.dart';
import '../local/dao/league_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';
import '../local/dao/sync_queue_dao.dart';
import '../remote/remote_gateway.dart';
import '../remote/remote_models.dart';

/// Kenapa sebuah antrean berhenti mengirim.
enum AlasanTertahan {
  /// Build ini memang luring, atau Firebase belum dikonfigurasi.
  luring,

  /// Tidak ada sinyal.
  tidakAdaSinyal,

  /// Ada sinyal, tapi cuma seluler dan orang tua mematikannya.
  menungguWifi,

  /// Belum ada akun — masuk anonim belum berhasil.
  belumMasuk,
}

/// Hasil satu kali pengiriman.
class HasilSinkron {
  const HasilSinkron({
    this.terkirim = 0,
    this.gagal = 0,
    this.menunggu = 0,
    this.tertahan,
    this.waktu,
  });

  final int terkirim;
  final int gagal;
  final int menunggu;

  /// Terisi kalau antrean tidak dijalankan sama sekali.
  final AlasanTertahan? tertahan;
  final DateTime? waktu;

  bool get bersih => menunggu == 0 && tertahan == null;
}

/// Antrean kiriman ke server, dan satu-satunya yang boleh mengosongkannya.
///
/// Tiga aturan sinkron di README dijalankan di sini, dan ketiganya
/// dipilih untuk membela hal yang sama — bahwa **belajar tidak boleh
/// menunggu jaringan**:
///
/// 1. **Ditulis ke antrean dulu, selalu.** Menyimpan pos ke SQLite tidak
///    pernah menunggu Firestore. Yang gagal terkirim tidak pernah
///    membatalkan bintang yang sudah didapat.
/// 2. **Ditahan tiga puluh detik.** Anak yang menyelesaikan tiga pos
///    berturut-turut menghasilkan satu penulisan, bukan tiga. Antreannya
///    menggabungkan dirinya sendiri lewat indeks unik di [SyncQueueDao].
/// 3. **Wi-Fi dulu.** Bawaannya tidak menyentuh kuota orang tua sama
///    sekali; yang tertahan menunggu Wi-Fi berikutnya, dan tidak ada
///    satu pun fitur yang rusak karenanya.
class SyncRepository {
  SyncRepository({
    required SyncQueueDao antreanDao,
    required ProfileDao profileDao,
    required ProgressDao progressDao,
    required BadgeDao badgeDao,
    required LeagueDao leagueDao,
    required this.gateway,
    required this.koneksi,
    this.aturan = _bawaan,
  }) : _antrean = antreanDao,
       _profile = profileDao,
       _progress = progressDao,
       _badge = badgeDao,
       _liga = leagueDao;

  final SyncQueueDao _antrean;
  final ProfileDao _profile;
  final ProgressDao _progress;
  final BadgeDao _badge;
  final LeagueDao _liga;
  final RemoteGateway gateway;
  final ConnectivityService koneksi;

  /// Dibaca sebagai fungsi, bukan nilai: Remote Config bisa mengubah
  /// ukuran liga di tengah pemakaian, dan yang berlaku adalah nilai
  /// saat kiriman berangkat.
  final AturanNilai Function() aturan;

  static AturanNilai _bawaan() => AturanNilai.bawaan;

  /// Ditahan tiga puluh detik, persis seperti yang tertulis di README.
  static const tundaan = Duration(seconds: 30);

  static const entitasProfil = 'profil';
  static const entitasCadangan = 'cadangan';
  static const entitasSkor = 'skor';

  Timer? _penunda;

  /// Diberitahukan tiap kali antrean berubah, supaya lencana "3 antre"
  /// di layar Jelajah tidak perlu memeriksa sendiri tiap detik.
  final _perubahan = StreamController<int>.broadcast();
  Stream<int> get perubahan => _perubahan.stream;

  void dispose() {
    _penunda?.cancel();
    _perubahan.close();
  }

  Future<int> jumlahMenunggu() => _antrean.jumlah();

  // ------------------------------------------------------------ antre
  /// Mencatat keadaan terkini anak ke antrean.
  ///
  /// Dipanggil tiap pos selesai dan tiap sesi latihan selesai. Karena
  /// kuncinya sama tiap kali, sepuluh panggilan berturut-turut tetap
  /// menyisakan satu baris.
  Future<void> antreProfil({DateTime? waktu}) async {
    final sekarang = waktu ?? DateTime.now();
    final profil = await _profile.ambil();
    if (profil.nickname.isEmpty) return;

    final minggu = StreakRules.mingguIni(sekarang);
    final hari = await _progress.harian(
      dari: minggu.first,
      sampai: minggu.last,
    );
    final xpMingguan = hari.fold(0, (a, h) => a + h.xpEarned);

    final daring = ProfilDaring(
      nickname: profil.nickname,
      avatarId: profil.avatarId,
      gradeLevel: profil.activeGradeId,
      totalXp: profil.totalXp,
      streakCount: profil.streakCount,
      weeklyXp: xpMingguan,
      lastSyncAt: sekarang,
      platform: _platform,
    );

    await _antrean.antre(
      entitas: entitasProfil,
      muatan: daring.sebagaiPeta,
      waktu: sekarang,
    );

    // Papan peringkat cuma diisi kalau orang tua mengizinkan. Ini
    // pemeriksaan pertama dari dua: yang kedua ada di pengiriman, supaya
    // baris yang sudah terlanjur mengantre pun tidak jadi terkirim.
    if (profil.leaderboardOn) {
      final weekId = LigaRules.idMinggu(sekarang);
      await _antrean.antre(
        entitas: entitasSkor,
        kunci: weekId,
        muatan: EntriLiga(
          uid: gateway.uid ?? '',
          nickname: profil.nickname,
          avatarId: profil.avatarId,
          xp: xpMingguan,
          // Nomor liga sengaja dibiarkan 0 di sini. Mendaftarkan diri ke
          // sebuah liga butuh jaringan, jadi itu diselesaikan saat
          // kiriman benar-benar berangkat — bukan saat mengantre, yang
          // sering justru terjadi waktu tidak ada sinyal.
          liga: (await _liga.minggu(weekId))?.liga ?? 0,
          diperbarui: sekarang,
        ).sebagaiPeta,
        waktu: sekarang,
      );
    }

    jadwalkan();
    _perubahan.add(await _antrean.jumlah());
  }

  /// Menyalin seluruh progres ke antrean cadangan.
  ///
  /// Jauh lebih berat daripada [antreProfil], jadi tidak dipanggil tiap
  /// pos — cuma waktu orang tua menyalakannya dan waktu aplikasi masuk
  /// latar belakang.
  Future<void> antreCadangan({DateTime? waktu}) async {
    final sekarang = waktu ?? DateTime.now();
    final progres = await _progress.semua();
    final lencana = await _badge.kode();

    final cadangan = CadanganProgres(
      pos: {
        for (final p in progres.values)
          if (p.stars > 0 || p.isUnlocked)
            p.levelId: '${p.stars},${p.bestScore}',
      },
      lencana: lencana.toList()..sort(),
      diperbarui: sekarang,
    );

    await _antrean.antre(
      entitas: entitasCadangan,
      muatan: cadangan.sebagaiPeta,
      waktu: sekarang,
    );
    jadwalkan();
    _perubahan.add(await _antrean.jumlah());
  }

  // --------------------------------------------------------- kirim
  /// Menyalakan penundaan tiga puluh detik. Panggilan berikutnya di
  /// dalam rentang itu cuma mengulang hitungannya dari awal.
  void jadwalkan() {
    _penunda?.cancel();
    _penunda = Timer(tundaan, () => unawaited(kirimSekarang()));
  }

  /// Mengosongkan antrean kalau boleh.
  ///
  /// [paksa] dipakai waktu orang tua menekan "Sinkronkan sekarang" di
  /// layar Akun & data: syarat Wi-Fi diabaikan karena itu keputusan yang
  /// baru saja mereka ambil sendiri.
  Future<HasilSinkron> kirimSekarang({bool paksa = false}) async {
    _penunda?.cancel();

    if (!gateway.tersedia) {
      return HasilSinkron(
        menunggu: await _antrean.jumlah(),
        tertahan: AlasanTertahan.luring,
      );
    }

    final jenis = await koneksi.sekarang();
    if (!jenis.tersambung) {
      return HasilSinkron(
        menunggu: await _antrean.jumlah(),
        tertahan: AlasanTertahan.tidakAdaSinyal,
      );
    }

    final profil = await _profile.ambil();
    if (jenis.berkuota && !profil.syncCellular && !paksa) {
      return HasilSinkron(
        menunggu: await _antrean.jumlah(),
        tertahan: AlasanTertahan.menungguWifi,
      );
    }

    // Masuk anonim bisa melempar — batas waktu, atau server menolak.
    // Kegagalannya diperlakukan sama seperti tidak ada sinyal: antreannya
    // utuh, dan dicoba lagi nanti.
    AkunDaring? akun;
    try {
      akun = await gateway.masukAnonim();
    } catch (e, s) {
      // Ditelan supaya antreannya utuh, tapi **tidak** didiamkan:
      // gagal masuk yang tidak pernah dilaporkan adalah jenis kerusakan
      // yang paling lama tidak ketahuan — semuanya terlihat normal dari
      // luar, cuma tidak ada satu pun data yang sampai.
      await gateway.catatGalat(e, s);
      akun = null;
    }
    if (akun == null) {
      return HasilSinkron(
        menunggu: await _antrean.jumlah(),
        tertahan: AlasanTertahan.belumMasuk,
      );
    }
    if (profil.firebaseUid != akun.uid) {
      await _profile.simpan(profil.copyWith(firebaseUid: akun.uid));
    }

    var terkirim = 0;
    var gagal = 0;
    for (final item in await _antrean.menunggu()) {
      try {
        await _kirimSatu(item, akun.uid, profil.leaderboardOn);
        await _antrean.selesai(item.id);
        terkirim++;
      } catch (e, s) {
        gagal++;
        final menyerah = await _antrean.gagal(item.id, e);
        if (menyerah) await gateway.catatGalat(e, s);
      }
    }

    final sisa = await _antrean.jumlah();
    final sekarang = DateTime.now();
    if (terkirim > 0) {
      await _profile.simpan(
        (await _profile.ambil()).copyWith(lastSyncAt: sekarang),
      );
    }
    _perubahan.add(sisa);

    return HasilSinkron(
      terkirim: terkirim,
      gagal: gagal,
      menunggu: sisa,
      waktu: sekarang,
    );
  }

  Future<void> _kirimSatu(
    ItemAntrean item,
    String uid,
    bool bolehPapanPeringkat,
  ) async {
    switch (item.entitas) {
      case entitasProfil:
        await gateway.tulisProfil(ProfilDaring.dariPeta(item.muatan));
      case entitasCadangan:
        await gateway.tulisCadangan(CadanganProgres.dariPeta(item.muatan));
      case entitasSkor:
        // Pemeriksaan kedua. Orang tua bisa mematikan papan peringkat
        // setelah barisnya mengantre, dan yang berlaku adalah setelan
        // saat kiriman benar-benar berangkat.
        if (!bolehPapanPeringkat) return;
        final entri = EntriLiga.dariPeta(uid, item.muatan);
        await gateway.tulisSkor(
          weekId: item.kunci,
          entri: entri.liga > 0
              ? entri
              : EntriLiga(
                  uid: entri.uid,
                  nickname: entri.nickname,
                  avatarId: entri.avatarId,
                  xp: entri.xp,
                  liga: await ligaUntukMinggu(item.kunci),
                  diperbarui: entri.diperbarui,
                ),
        );
      default:
        // Entitas yang tidak dikenal berasal dari versi aplikasi yang
        // lebih baru; membuangnya lebih baik daripada mencobanya
        // selamanya.
        return;
    }
  }

  /// Nomor liga anak ini minggu itu.
  ///
  /// Ditanyakan ke server sekali seminggu lalu disimpan lokal. Kalau
  /// pendaftarannya gagal, yang dikembalikan 1 — anak masuk liga
  /// pertama alih-alih hilang dari papan sama sekali, dan minggu depan
  /// pendaftarannya dicoba lagi.
  Future<int> ligaUntukMinggu(String weekId) async {
    final tersimpan = (await _liga.minggu(weekId))?.liga ?? 0;
    if (tersimpan > 0) return tersimpan;

    // Kalau pendaftarannya gagal, galatnya sengaja dibiarkan naik:
    // pemanggilnya sudah membungkus tiap baris antrean dengan `try`,
    // jadi barisnya tetap mengantre dan dicoba lagi nanti.
    final nomor = await gateway.daftarkanLiga(
      weekId: weekId,
      ukuran: aturan().ukuranLiga,
    );
    final dipakai = nomor > 0 ? nomor : 1;
    await _liga.simpan(weekId: weekId, liga: dipakai);
    return dipakai;
  }

  static String get _platform => defaultTargetPlatform.name.toLowerCase();
}
