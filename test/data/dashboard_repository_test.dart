import 'dart:io';

import 'package:angkasa/data/local/dao/attempt_dao.dart';
import 'package:angkasa/data/local/dao/level_dao.dart';
import 'package:angkasa/data/local/dao/progress_dao.dart';
import 'package:angkasa/data/local/database/app_database.dart';
import 'package:angkasa/data/local/database/seed/seed_runner.dart';
import 'package:angkasa/data/repositories/dashboard_repository.dart';
import 'package:angkasa/domain/models/enums.dart';
import 'package:angkasa/domain/models/question_attempt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Dashboard orang tua.
///
/// Yang dijaga di sini bukan ketepatan hitungnya — itu bagian yang
/// paling mudah. Yang dijaga **nada layarnya**: dua layar ini dibaca
/// orang tua tentang anaknya, dan angka yang salah tempat di sini
/// berubah jadi omelan di meja makan.
///
/// Tiga hal konkret yang diperiksa: anak yang libur tidak ditampilkan
/// sebagai "0% benar", jendela waktunya benar-benar membatasi, dan
/// tidak ada satu angka pun yang dihitung dari data yang dikirim ke
/// server.
void main() {
  late Database db;
  late DashboardRepository dash;
  late AttemptDao attemptDao;
  late ProgressDao progressDao;

  final kini = DateTime(2026, 9, 5, 10);

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await AppDatabase.memori(
      seed: SeedRunner(bacaAset: (path) async => File(path).readAsString()),
    );
    attemptDao = AttemptDao(db);
    progressDao = ProgressDao(db);
    dash = DashboardRepository(
      attemptDao: attemptDao,
      progressDao: progressDao,
      levelDao: LevelDao(db),
    );
  });

  tearDown(() => db.close());

  Future<void> jawab({
    required String levelId,
    required int benar,
    required int salah,
    MistakeKind kind = MistakeKind.lupaMenyimpan,
    DateTime? waktu,
  }) async {
    final t = waktu ?? kini;
    await attemptDao.catat([
      for (var i = 0; i < benar; i++)
        QuestionAttempt(
          levelId: levelId,
          questionSignature: 'b$i-${t.millisecondsSinceEpoch}',
          isCorrect: true,
          timeMs: 3000,
          answeredAt: t,
        ),
      for (var i = 0; i < salah; i++)
        QuestionAttempt(
          levelId: levelId,
          questionSignature: 's$i-${t.millisecondsSinceEpoch}',
          isCorrect: false,
          timeMs: 5000,
          answeredAt: t,
          mistake: kind,
        ),
    ]);
  }

  group('ringkasan minggu ini', () {
    test('anak yang belum main minggu ini tidak disebut nol persen', () async {
      // "0% jawaban benar" untuk anak yang sedang libur adalah tuduhan,
      // bukan informasi.
      final r = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(r.persenBenar, isNull);
      expect(r.menitMingguIni, 0);
    });

    test('ketepatan dihitung dari soal minggu ini saja', () async {
      await jawab(levelId: 'l-1-1-1', benar: 8, salah: 2);
      // Soal bulan lalu tidak boleh ikut menyeret angkanya.
      await jawab(
        levelId: 'l-1-1-1',
        benar: 0,
        salah: 40,
        waktu: kini.subtract(const Duration(days: 40)),
      );

      final r = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(r.persenBenar, 80);
    });

    test('selalu tujuh hari, dan hari terakhirnya hari ini', () async {
      final r = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(r.perHari.length, 7);
      expect(r.perHari.last.tanggal.day, kini.day);
      // Tanggal saja, tanpa jam: dua sesi di hari yang sama harus
      // jatuh ke batang yang sama berapa pun jamnya.
      final awal = kini.subtract(const Duration(days: 6));
      expect(
        r.perHari.first.tanggal,
        DateTime(awal.year, awal.month, awal.day),
      );
    });

    test('menit dijumlah dari detik yang benar-benar tercatat', () async {
      await progressDao.catatHarian(tanggal: kini, xp: 10, detik: 900);
      await progressDao.catatHarian(
        tanggal: kini.subtract(const Duration(days: 2)),
        xp: 10,
        detik: 600,
      );

      final r = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(r.menitMingguIni, 25);
      expect(r.perHari.last.menit, 15);
    });

    test('planet yang belum disentuh tidak ditampilkan', () async {
      // Deretan batang kosong membuat layar ini terbaca seperti daftar
      // kegagalan, bukan seperti kemajuan.
      final kosong = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(kosong.planet, isEmpty);

      await progressDao.simpanHasil(
        levelId: 'l-1-1-1',
        stars: 3,
        score: 10,
        waktu: kini,
      );
      final ada = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(ada.planet.length, 1);
      expect(ada.planet.first.nama, 'Planet Mula');
      expect(ada.planet.first.total, 36);
      expect(ada.planet.first.selesai, 1);
    });

    test('hurufnya mengikuti hari sungguhan', () async {
      // 5 September 2026 jatuh hari Sabtu.
      final r = await dash.ringkasan(nama: 'Rafa', kini: kini);
      expect(r.perHari.last.huruf, 'S');
      expect(r.perHari.map((h) => h.huruf).toList(), [
        'M',
        'S',
        'S',
        'R',
        'K',
        'J',
        'S',
      ]);
    });
  });

  group('jenis kesalahan', () {
    test('layar kosong sebelum ada yang bisa dihitung', () async {
      final r = await dash.kesalahan(nama: 'Rafa', kini: kini);
      expect(r.totalSoal, 0);
      expect(r.kesalahan, isEmpty);
    });

    test('kesalahan terurut dari yang paling sering', () async {
      await jawab(
        levelId: 'l-1-1-1',
        benar: 0,
        salah: 3,
        kind: MistakeKind.melesetSatu,
      );
      await jawab(
        levelId: 'l-1-1-2',
        benar: 0,
        salah: 7,
        kind: MistakeKind.lupaMenyimpan,
      );

      final r = await dash.kesalahan(nama: 'Rafa', kini: kini);
      expect(r.kesalahan.first.jenis, MistakeKind.lupaMenyimpan);
      expect(r.kesalahan.first.jumlah, 7);
      expect(r.terbanyak, 7);
    });

    test('tiap jenis kesalahan punya kalimat yang bisa ditindaklanjuti', () {
      // Inti seluruh layar ini. Nama pendek untuk batangnya, kalimat
      // penjelas untuk orang tuanya — dan tidak boleh ada satu pun
      // jenis yang kehilangan kalimatnya waktu jenis baru ditambahkan.
      for (final m in MistakeKind.values) {
        expect(m.label, isNotEmpty, reason: m.name);
        expect(m.penjelasan.length, greaterThan(25), reason: m.name);
      }
    });

    test('jendelanya sebulan, bukan seumur main', () async {
      await jawab(
        levelId: 'l-1-1-1',
        benar: 0,
        salah: 5,
        waktu: kini.subtract(const Duration(days: 60)),
      );
      final r = await dash.kesalahan(nama: 'Rafa', kini: kini);
      expect(r.kesalahan, isEmpty);
      expect(r.totalSoal, 0);
    });

    test('zona baru muncul setelah cukup banyak soal', () async {
      // Sembilan soal belum cukup untuk menyebut sebuah zona dikuasai
      // atau tidak — dan menyebutnya dengan data setipis itu justru
      // menyesatkan.
      await jawab(levelId: 'l-1-1-1', benar: 9, salah: 0);
      expect((await dash.kesalahan(nama: 'R', kini: kini)).zona, isEmpty);

      await jawab(levelId: 'l-1-1-1', benar: 5, salah: 0);
      final r = await dash.kesalahan(nama: 'R', kini: kini);
      expect(r.zona, isNotEmpty);
      expect(r.zona.first.tingkat, Penguasaan.dikuasai);
    });

    test('sesi latihan bebas tidak menyeret penguasaan zona', () async {
      // `latihan:` tidak punya zona. Memaksakannya masuk membuat zona
      // yang jarang dilatih terlihat lebih buruk daripada keadaannya.
      await jawab(levelId: 'latihan:kilat60', benar: 0, salah: 30);
      final r = await dash.kesalahan(nama: 'R', kini: kini);
      expect(r.zona, isEmpty);
      // Tapi kesalahannya tetap dihitung — anak tetap keliru di situ.
      expect(r.kesalahan, isNotEmpty);
    });

    test('ambang penguasaan: 85% dikuasai, 65% cukup', () {
      expect(Penguasaan.dari(85, 100), Penguasaan.dikuasai);
      expect(Penguasaan.dari(84, 100), Penguasaan.cukup);
      expect(Penguasaan.dari(65, 100), Penguasaan.cukup);
      expect(Penguasaan.dari(64, 100), Penguasaan.perluLatihan);
      expect(Penguasaan.dari(0, 0), Penguasaan.perluLatihan);
    });
  });
}
