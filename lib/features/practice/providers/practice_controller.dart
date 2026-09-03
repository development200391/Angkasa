import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/practice_repository.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/question.dart';
import '../../../domain/models/quiz_result.dart';

/// Keadaan satu sesi latihan bebas.
class PracticeState {
  const PracticeState({
    required this.mode,
    required this.soal,
    required this.mulai,
    this.index = 0,
    this.jawaban = const [],
    this.dipilih,
    this.terkunci = false,
    this.benarTerakhir = false,
    this.sisaDetik,
    this.beruntun = 0,
    this.hasil,
  });

  final PracticeMode mode;
  final List<Question> soal;
  final DateTime mulai;
  final int index;
  final List<AnsweredQuestion> jawaban;
  final String? dipilih;
  final bool terkunci;
  final bool benarTerakhir;

  /// Hitungan mundur Kilat 60 Detik. `null` untuk mode lain.
  final int? sisaDetik;

  /// Benar berturut-turut — cuma ditampilkan di Kilat.
  final int beruntun;

  final PracticeOutcome? hasil;

  bool get kosong => soal.isEmpty;

  Question get sekarang => soal[index % soal.length];

  int get benar => jawaban.where((a) => a.isCorrect).length;

  int get total => soal.length;

  int get nomor => index + 1;

  double get kemajuan => total == 0 ? 0 : (index / total).clamp(0, 1);

  PracticeState copyWith({
    int? index,
    List<AnsweredQuestion>? jawaban,
    String? dipilih,
    bool hapusDipilih = false,
    bool? terkunci,
    bool? benarTerakhir,
    int? sisaDetik,
    int? beruntun,
    PracticeOutcome? hasil,
  }) => PracticeState(
    mode: mode,
    soal: soal,
    mulai: mulai,
    index: index ?? this.index,
    jawaban: jawaban ?? this.jawaban,
    dipilih: hapusDipilih ? null : (dipilih ?? this.dipilih),
    terkunci: terkunci ?? this.terkunci,
    benarTerakhir: benarTerakhir ?? this.benarTerakhir,
    sisaDetik: sisaDetik ?? this.sisaDetik,
    beruntun: beruntun ?? this.beruntun,
    hasil: hasil ?? this.hasil,
  );
}

/// Mesin sesi latihan.
///
/// Beda tegas dari kuis lintasan: **tidak ada hati**. Latihan adalah
/// tempat yang aman untuk salah, dan sesi yang bisa berakhir sebelum
/// selesai membuat anak takut mencoba mode yang justru paling berguna
/// baginya.
class PracticeController extends AsyncNotifier<PracticeState> {
  PracticeController(this.mode);

  /// Lama satu ronde Kilat 60 Detik.
  static const detikKilat = 60;

  final PracticeMode mode;

  Timer? _timer;
  DateTime _mulaiSoal = DateTime.now();

  @override
  Future<PracticeState> build() async {
    ref.onDispose(() => _timer?.cancel());
    final repo = ref.read(practiceRepositoryProvider);

    final soal = switch (mode) {
      PracticeMode.latihanCepat => await repo.latihanCepat(),
      PracticeMode.perbaikiKesalahan => await repo.perbaikiKesalahan(),
      PracticeMode.tantanganHarian => await repo.tantanganHarian(),
      PracticeMode.kilat60 => await repo.soalKilat(),
    };

    _mulaiSoal = DateTime.now();
    final awal = PracticeState(
      mode: mode,
      soal: soal,
      mulai: DateTime.now(),
      sisaDetik: mode == PracticeMode.kilat60 ? detikKilat : null,
    );
    if (mode == PracticeMode.kilat60 && soal.isNotEmpty) _mulaiHitungMundur();
    return awal;
  }

  PracticeState get _s => state.requireValue;

  void jawab(String label) {
    if (_s.terkunci || _s.kosong) return;
    final soal = _s.sekarang;
    final benar = soal.isCorrect(label);

    final audio = ref.read(audioServiceProvider);
    if (benar) {
      audio.benar();
    } else {
      audio.salah();
    }

    final jawaban = [
      ..._s.jawaban,
      AnsweredQuestion(
        question: soal,
        given: label,
        isCorrect: benar,
        timeMs: DateTime.now().difference(_mulaiSoal).inMilliseconds,
      ),
    ];

    state = AsyncData(
      _s.copyWith(
        jawaban: jawaban,
        dipilih: label,
        terkunci: true,
        benarTerakhir: benar,
        beruntun: benar ? _s.beruntun + 1 : 0,
      ),
    );

    // Kilat tidak pernah berhenti untuk menjelaskan: yang diuji
    // kecepatan, dan pembahasannya sudah punya modenya sendiri.
    final jeda = mode == PracticeMode.kilat60
        ? const Duration(milliseconds: 260)
        : Duration(milliseconds: benar ? 650 : 1400);
    Timer(jeda, () {
      if (ref.mounted) lanjut();
    });
  }

  Future<void> lanjut() async {
    if (_s.hasil != null) return;
    final berikutnya = _s.index + 1;

    if (mode != PracticeMode.kilat60 && berikutnya >= _s.total) {
      await _selesaikan();
      return;
    }

    _mulaiSoal = DateTime.now();
    state = AsyncData(
      _s.copyWith(
        index: berikutnya,
        hapusDipilih: true,
        terkunci: false,
        benarTerakhir: false,
      ),
    );
  }

  void _mulaiHitungMundur() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!ref.mounted) {
        t.cancel();
        return;
      }
      final sisa = (_s.sisaDetik ?? 0) - 1;
      state = AsyncData(_s.copyWith(sisaDetik: sisa < 0 ? 0 : sisa));
      if (sisa <= 5 && sisa > 0) ref.read(audioServiceProvider).tik();
      if (sisa <= 0) {
        t.cancel();
        unawaited(_selesaikan());
      }
    });
  }

  /// Berhenti lebih awal tetap menyimpan apa yang sudah dikerjakan —
  /// jawaban benar yang hilang gara-gara menutup layar terasa curang.
  Future<void> hentikan() => _selesaikan();

  Future<void> _selesaikan() async {
    if (_s.hasil != null) return;
    _timer?.cancel();
    final s = _s;

    final hasil = await ref
        .read(practiceRepositoryProvider)
        .simpanSesi(
          mode: mode,
          jawaban: s.jawaban,
          detik: DateTime.now().difference(s.mulai).inSeconds,
        );

    ref.read(audioServiceProvider).naikLevel();
    ref.invalidate(profileProvider);
    ref.invalidate(practiceSummaryProvider);
    ref.invalidate(daftarSalahProvider);
    ref.invalidate(badgesProvider);
    ref.invalidate(mingguIniProvider);

    state = AsyncData(_s.copyWith(hasil: hasil, terkunci: true));
  }
}

final practiceControllerProvider = AsyncNotifierProvider.autoDispose
    .family<PracticeController, PracticeState, PracticeMode>(
      PracticeController.new,
    );
