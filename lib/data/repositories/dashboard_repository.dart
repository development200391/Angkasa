import '../../domain/engine/streak_rules.dart';
import '../../domain/models/enums.dart';
import '../local/dao/attempt_dao.dart';
import '../local/dao/level_dao.dart';
import '../local/dao/progress_dao.dart';

/// Seberapa dikuasai sebuah zona.
///
/// Tiga tingkat, dan **selalu tampil sebagai ikon + tulisan + warna
/// sekaligus** — tidak pernah warna saja. Sekitar satu dari dua belas
/// laki-laki buta warna merah-hijau, dan bapak yang membuka layar ini
/// harus bisa membacanya.
enum Penguasaan {
  dikuasai,
  cukup,
  perluLatihan;

  String get label => switch (this) {
    Penguasaan.dikuasai => 'Dikuasai',
    Penguasaan.cukup => 'Cukup',
    Penguasaan.perluLatihan => 'Perlu latihan',
  };

  static Penguasaan dari(int benar, int total) {
    if (total == 0) return Penguasaan.perluLatihan;
    final p = benar / total;
    if (p >= 0.85) return Penguasaan.dikuasai;
    if (p >= 0.65) return Penguasaan.cukup;
    return Penguasaan.perluLatihan;
  }
}

class ZonaPenguasaan {
  const ZonaPenguasaan({
    required this.judul,
    required this.tingkat,
    required this.total,
  });

  final String judul;
  final Penguasaan tingkat;
  final int total;
}

class MenitHari {
  const MenitHari({required this.tanggal, required this.menit});

  final DateTime tanggal;
  final int menit;

  /// `S S R K J S M` — satu huruf, sesuai mockup layar 30.
  String get huruf =>
      const ['S', 'S', 'R', 'K', 'J', 'S', 'M'][tanggal.weekday - 1];
}

class KemajuanPlanet {
  const KemajuanPlanet({
    required this.nama,
    required this.urutan,
    required this.selesai,
    required this.total,
  });

  final String nama;
  final int urutan;
  final int selesai;
  final int total;

  double get pecahan => total == 0 ? 0 : selesai / total;
}

/// Isi layar Dashboard orang tua.
class RingkasanOrtu {
  const RingkasanOrtu({
    required this.nama,
    required this.posSelesai,
    required this.persenBenar,
    required this.menitMingguIni,
    required this.perHari,
    required this.planet,
  });

  final String nama;
  final int posSelesai;

  /// `null` kalau belum ada satu pun soal dikerjakan minggu ini.
  /// Menampilkan "0%" untuk anak yang sedang libur adalah tuduhan,
  /// bukan informasi.
  final int? persenBenar;

  final int menitMingguIni;
  final List<MenitHari> perHari;
  final List<KemajuanPlanet> planet;
}

/// Isi layar Jenis kesalahan.
class RingkasanKesalahan {
  const RingkasanKesalahan({
    required this.nama,
    required this.totalSoal,
    required this.kesalahan,
    required this.zona,
  });

  final String nama;
  final int totalSoal;

  /// Sudah terurut dari yang paling sering.
  final List<({MistakeKind jenis, int jumlah})> kesalahan;

  final List<ZonaPenguasaan> zona;

  int get terbanyak => kesalahan.isEmpty ? 1 : kesalahan.first.jumlah;
}

/// Menyusun dua layar dashboard orang tua dari data yang sudah dicatat
/// sejak Tahap 1.
///
/// **Tidak ada satu angka pun di sini yang dikirim ke server.** Seluruh
/// perhitungannya di HP, dari `question_attempts` dan `daily_activity`
/// — dan layar Jenis kesalahan menyebutkan itu apa adanya di kakinya.
/// Kalimat itu bukan basa-basi hukum: catatan jawaban tiap soal adalah
/// data paling pribadi yang dipunyai aplikasi ini, dan satu-satunya
/// janji yang bisa dipegang orang tua adalah janji yang bisa diperiksa
/// di layar Data yang dikirim.
class DashboardRepository {
  DashboardRepository({
    required AttemptDao attemptDao,
    required ProgressDao progressDao,
    required LevelDao levelDao,
  }) : _attempt = attemptDao,
       _progress = progressDao,
       _level = levelDao;

  final AttemptDao _attempt;
  final ProgressDao _progress;
  final LevelDao _level;

  /// Tujuh hari terakhir, bukan minggu kalender.
  ///
  /// Orang tua yang membukanya Selasa pagi ingin melihat sepekan
  /// terakhir, bukan dua hari sejak Senin.
  static const jendela = Duration(days: 7);

  Future<RingkasanOrtu> ringkasan({
    required String nama,
    DateTime? kini,
  }) async {
    final sekarang = kini ?? DateTime.now();
    final mulai = StreakRules.tanggalSaja(sekarang.subtract(jendela));

    final harian = await _progress.harian(dari: mulai, sampai: sekarang);
    final peta = {for (final h in harian) StreakRules.tanggalSaja(h.date): h};

    final perHari = <MenitHari>[];
    for (var i = 6; i >= 0; i--) {
      final t = StreakRules.tanggalSaja(sekarang.subtract(Duration(days: i)));
      perHari.add(
        MenitHari(tanggal: t, menit: (peta[t]?.secondsPlayed ?? 0) ~/ 60),
      );
    }

    final ketepatan = await _attempt.ketepatanSejak(mulai);
    final progres = await _progress.semua();

    final planet = <KemajuanPlanet>[];
    for (final g in await _level.semuaGrade()) {
      final idPos = (await _level.levelsGrade(g.id)).map((l) => l.id).toSet();
      if (idPos.isEmpty) continue;
      planet.add(
        KemajuanPlanet(
          nama: g.name,
          urutan: g.orderIndex,
          selesai: idPos.where((id) => (progres[id]?.stars ?? 0) > 0).length,
          total: idPos.length,
        ),
      );
    }

    return RingkasanOrtu(
      nama: nama,
      posSelesai: harian.fold(0, (a, h) => a + h.levelsCompleted),
      persenBenar: ketepatan.total == 0
          ? null
          : (ketepatan.benar * 100 / ketepatan.total).round(),
      menitMingguIni: perHari.fold(0, (a, h) => a + h.menit),
      perHari: perHari,
      // Planet yang belum disentuh sama sekali tidak ditampilkan —
      // deretan batang kosong membuat layar ini terbaca seperti daftar
      // kegagalan.
      planet: planet.where((p) => p.selesai > 0).toList(),
    );
  }

  /// Layar 31. Jendelanya sebulan, bukan sepekan: kesalahan yang
  /// berulang butuh cukup banyak soal sebelum polanya pantas disebut
  /// pola.
  Future<RingkasanKesalahan> kesalahan({
    required String nama,
    DateTime? kini,
  }) async {
    final sekarang = kini ?? DateTime.now();
    final mulai = StreakRules.tanggalSaja(
      sekarang.subtract(const Duration(days: 30)),
    );

    final ringkas = await _attempt.kesalahanSejak(mulai);
    final ketepatan = await _attempt.ketepatanSejak(mulai);

    final zona = <ZonaPenguasaan>[];
    for (final z in await _attempt.ketepatanPerZona()) {
      zona.add(
        ZonaPenguasaan(
          judul: z.judul,
          tingkat: Penguasaan.dari(z.benar, z.total),
          total: z.total,
        ),
      );
    }

    return RingkasanKesalahan(
      nama: nama,
      totalSoal: ketepatan.total,
      kesalahan: [
        for (final e in ringkas.entries)
          if (e.value > 0) (jenis: e.key, jumlah: e.value),
      ],
      zona: zona,
    );
  }
}
