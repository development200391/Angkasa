import '../../core/constants/app_config.dart';
import '../../domain/engine/aturan_nilai.dart';
import '../../domain/engine/liga_rules.dart';
import '../../domain/engine/streak_rules.dart';
import '../../domain/models/liga.dart';
import '../local/dao/league_dao.dart';
import '../local/dao/profile_dao.dart';
import '../local/dao/progress_dao.dart';
import '../remote/remote_gateway.dart';

/// Kenapa papan peringkat tidak bisa ditampilkan.
enum PapanTertutup {
  /// Build luring, atau Firebase belum dikonfigurasi.
  luring,

  /// Orang tua mematikannya di layar Akun & data.
  dimatikanOrangTua,

  /// Dimatikan dari jauh lewat Remote Config.
  dimatikanPengembang,

  /// Tidak ada sinyal, atau papannya gagal dibaca.
  tidakAdaSinyal,

  /// Tersambung, tapi anak belum main sama sekali minggu ini — jadi
  /// belum punya baris di liga mana pun. Sengaja dibedakan dari
  /// [tidakAdaSinyal]: menyalahkan jaringan untuk sesuatu yang jaringannya
  /// baik-baik saja adalah cara tercepat membuat orang berhenti percaya
  /// pada pesan di layar.
  belumMainMingguIni,

  /// Anak belum menyelesaikan onboarding, jadi belum punya nama.
  belumPunyaNama,
}

/// Hasil membaca papan peringkat.
class HasilPapan {
  const HasilPapan.terbuka(this.papan, {this.sisaHari = 7}) : tertutup = null;
  const HasilPapan.tertutup(this.tertutup) : papan = null, sisaHari = 7;

  final PapanLiga? papan;
  final PapanTertutup? tertutup;
  final int sisaHari;

  bool get bisaTampil => papan != null;
}

/// Liga mingguan.
///
/// Yang paling penting di kelas ini justru bukan pengambilan datanya,
/// tapi [ringkasanBelumDilihat] — dan alasannya soal waktu. Papan
/// peringkat minggu lalu **berhenti ada** begitu Senin lewat: server
/// sudah pindah ke `weekId` baru dan liga lama tidak ditanya lagi oleh
/// siapa pun. Kalau peringkat akhir tidak disalin ke HP saat masih bisa
/// dibaca, layar Akhir minggu tidak punya angka sama sekali.
class LeaderboardRepository {
  LeaderboardRepository({
    required LeagueDao leagueDao,
    required ProfileDao profileDao,
    required ProgressDao progressDao,
    required this.gateway,
    this.aturan = _bawaan,
  }) : _liga = leagueDao,
       _profile = profileDao,
       _progress = progressDao;

  final LeagueDao _liga;
  final ProfileDao _profile;
  final ProgressDao _progress;
  final RemoteGateway gateway;
  final AturanNilai Function() aturan;

  static AturanNilai _bawaan() => AturanNilai.bawaan;

  /// Papan peringkat liga yang sedang berjalan.
  ///
  /// Selain memulangkan isinya, panggilan ini juga **menyimpan
  /// peringkat minggu ini ke HP**. Itu efek samping yang disengaja:
  /// inilah satu-satunya saat angka itu bisa diambil.
  Future<HasilPapan> papanSekarang({DateTime? waktu}) async {
    final sekarang = waktu ?? DateTime.now();
    final setelan = aturan();

    if (!AppConfig.enableLeaderboard || !setelan.papanPeringkatAktif) {
      return const HasilPapan.tertutup(PapanTertutup.dimatikanPengembang);
    }
    if (!gateway.tersedia) {
      return const HasilPapan.tertutup(PapanTertutup.luring);
    }

    final profil = await _profile.ambil();
    if (!profil.leaderboardOn) {
      return const HasilPapan.tertutup(PapanTertutup.dimatikanOrangTua);
    }
    if (profil.nickname.isEmpty) {
      return const HasilPapan.tertutup(PapanTertutup.belumPunyaNama);
    }

    final weekId = LigaRules.idMinggu(sekarang);
    final catatan = await _liga.minggu(weekId);
    final nomor = catatan?.liga ?? 0;
    if (nomor <= 0) {
      // Belum terdaftar minggu ini. Pendaftarannya menempel pada
      // pengiriman skor, bukan pada pembacaan papan — anak yang belum
      // main sekali pun minggu ini memang belum punya baris di sana.
      return const HasilPapan.tertutup(PapanTertutup.belumMainMingguIni);
    }

    try {
      final entri = await gateway.bacaPapan(
        weekId: weekId,
        liga: nomor,
        batas: setelan.ukuranLiga,
      );
      final urut = LigaRules.urutkan(
        entri,
        xp: (e) => e.xp,
        diperbarui: (e) => e.diperbarui,
        nama: (e) => e.nickname,
      );
      final papan = PapanLiga(
        weekId: weekId,
        liga: nomor,
        entri: urut,
        uidSaya: gateway.uid,
      );

      await _simpanPeringkat(weekId, papan, sekarang);
      return HasilPapan.terbuka(papan, sisaHari: LigaRules.sisaHari(sekarang));
    } catch (_) {
      return const HasilPapan.tertutup(PapanTertutup.tidakAdaSinyal);
    }
  }

  Future<void> _simpanPeringkat(
    String weekId,
    PapanLiga papan,
    DateTime sekarang,
  ) async {
    final peringkat = papan.peringkatSaya;
    if (peringkat == null) return;

    final minggu = StreakRules.mingguIni(sekarang);
    final hari = await _progress.harian(
      dari: minggu.first,
      sampai: minggu.last,
    );

    await _liga.simpan(
      weekId: weekId,
      peringkat: peringkat,
      pemain: papan.jumlahPemain,
      xp: hari.fold<int>(0, (a, h) => a + h.xpEarned),
      posSelesai: hari.fold<int>(0, (a, h) => a + h.levelsCompleted),
    );
  }

  /// Hasil minggu lalu yang belum pernah ditampilkan.
  ///
  /// `null` berarti tidak ada yang perlu ditampilkan — anak baru, atau
  /// layarnya sudah dilihat. Layar Akhir minggu tidak boleh muncul dua
  /// kali untuk minggu yang sama; sekali itu perayaan, dua kali itu
  /// gangguan.
  Future<RingkasanMinggu?> ringkasanBelumDilihat({DateTime? waktu}) async {
    final sekarang = waktu ?? DateTime.now();
    final weekId = LigaRules.idMinggu(sekarang);
    final lalu = await _liga.belumDilihatSebelum(weekId);
    if (lalu == null) return null;

    final sebelumnya = await _liga.sebelum(lalu.weekId);
    return RingkasanMinggu(
      weekId: lalu.weekId,
      peringkat: lalu.peringkat,
      pemain: lalu.pemain,
      xp: lalu.xp,
      posSelesai: lalu.posSelesai,
      peringkatSebelumnya: sebelumnya?.peringkat,
    );
  }

  Future<void> tandaiSudahDilihat(String weekId) =>
      _liga.simpan(weekId: weekId, sudahDilihat: true);

  Future<void> hapusSemua() => _liga.hapusSemua();
}
