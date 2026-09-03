import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../domain/engine/star_calculator.dart';
import '../../../domain/models/quiz_result.dart';
import 'quiz_state.dart';

/// Mesin satu sesi kuis: soal ke berapa, sisa hati, timer, dan hasilnya.
///
/// Semua keputusan ada di sini; layar kuis hanya menggambar dan
/// meneruskan ketukan. Itu sebabnya aturan bintang dan pencatatan
/// jawaban bisa diuji tanpa membangun satu widget pun.
class QuizController extends AsyncNotifier<QuizState> {
  QuizController(this.levelId);

  final String levelId;

  Timer? _timer;
  DateTime _mulaiSoal = DateTime.now();

  @override
  Future<QuizState> build() async {
    ref.onDispose(() => _timer?.cancel());

    final konten = ref.read(contentRepositoryProvider);
    final level = await konten.level(levelId);
    if (level == null) {
      throw StateError('Pos $levelId tidak ada di basis data');
    }
    final soal = await konten.soal(level);
    final zona = await ref.read(levelDaoProvider).chapter(level.chapterId);

    final awal = QuizState(
      level: level,
      chapter: zona,
      questions: soal,
      mulaiSesi: DateTime.now(),
      hearts: StarCalculator.heartsPerSession,
      sisaDetik: soal.isEmpty ? null : soal.first.timeLimitSeconds,
    );
    _mulaiSoal = DateTime.now();
    _mulaiTimer(awal.sisaDetik);
    return awal;
  }

  QuizState get _s => state.requireValue;

  // ------------------------------------------------------------ jawab
  void pilihOpsi(String label) {
    if (_s.terkunci) return;
    _nilai(label);
  }

  void ketik(String angka) {
    if (_s.terkunci) return;
    if (_s.input.length >= 4) return;
    state = AsyncData(_s.copyWith(input: _s.input + angka));
  }

  void hapusAngka() {
    if (_s.terkunci || _s.input.isEmpty) return;
    state = AsyncData(
      _s.copyWith(input: _s.input.substring(0, _s.input.length - 1)),
    );
  }

  void kirimIsian() {
    if (!_s.bisaKirim) return;
    _nilai(_s.input);
  }

  void _nilai(String jawaban) {
    _timer?.cancel();
    final s = _s;
    final soal = s.soal;
    final benar = soal.isCorrect(jawaban);
    final waktuMs = DateTime.now().difference(_mulaiSoal).inMilliseconds;

    final audio = ref.read(audioServiceProvider);
    if (benar) {
      audio.benar();
    } else {
      audio.salah();
    }

    state = AsyncData(
      s.copyWith(
        answers: [
          ...s.answers,
          AnsweredQuestion(
            question: soal,
            given: jawaban,
            isCorrect: benar,
            timeMs: waktuMs,
          ),
        ],
        hearts: benar ? s.hearts : s.hearts - 1,
        dipilih: jawaban,
        terkunci: true,
        benarTerakhir: benar,
      ),
    );

    // Yang benar lewat sendiri; yang salah menunggu, karena
    // pembahasannya harus sempat dibaca.
    if (benar) {
      Timer(const Duration(milliseconds: 650), () {
        if (ref.mounted) lanjut();
      });
    }
  }

  /// Waktu habis dihitung sebagai satu jawaban salah — tanpa itu, timer
  /// cuma jadi hiasan.
  void _waktuHabis() {
    if (_s.terkunci) return;
    _nilai('');
  }

  // ----------------------------------------------------------- lanjut
  Future<void> lanjut() async {
    final s = _s;
    if (!s.terkunci) return;

    if (s.habisNyawa || s.index + 1 >= s.total) {
      await _selesaikan();
      return;
    }

    final berikutnya = s.index + 1;
    _mulaiSoal = DateTime.now();
    final detik = s.questions[berikutnya].timeLimitSeconds;
    state = AsyncData(
      s.copyWith(
        index: berikutnya,
        input: '',
        hapusDipilih: true,
        terkunci: false,
        benarTerakhir: false,
        sisaDetik: detik,
        hapusTimer: detik == null,
      ),
    );
    _mulaiTimer(detik);
  }

  Future<void> _selesaikan() async {
    _timer?.cancel();
    final s = _s;
    final bintang = s.habisNyawa
        ? 0
        : StarCalculator.stars(correct: s.benar, total: s.total);

    final mentah = QuizResult(
      levelId: s.level.id,
      correct: s.benar,
      total: s.total,
      stars: bintang,
      xpEarned: 0,
      durationSeconds: DateTime.now().difference(s.mulaiSesi).inSeconds,
      outOfHearts: s.habisNyawa,
      answers: s.answers,
    );

    final tersimpan = await ref
        .read(progressRepositoryProvider)
        .simpanSesi(level: s.level, hasil: mentah);

    ref.invalidate(petaProvider);
    ref.invalidate(profileProvider);

    state = AsyncData(_s.copyWith(hasil: tersimpan, terkunci: true));
  }

  // ------------------------------------------------------------ timer
  void _mulaiTimer(int? detik) {
    _timer?.cancel();
    if (detik == null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!ref.mounted) {
        t.cancel();
        return;
      }
      final sisa = (_s.sisaDetik ?? 0) - 1;
      if (sisa <= 0) {
        t.cancel();
        state = AsyncData(_s.copyWith(sisaDetik: 0));
        _waktuHabis();
      } else {
        state = AsyncData(_s.copyWith(sisaDetik: sisa));
      }
    });
  }
}

final quizControllerProvider = AsyncNotifierProvider.autoDispose
    .family<QuizController, QuizState, String>(QuizController.new);
