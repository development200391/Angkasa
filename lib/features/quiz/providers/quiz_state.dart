import '../../../domain/models/chapter.dart';
import '../../../domain/models/level.dart';
import '../../../domain/models/question.dart';
import '../../../domain/models/quiz_result.dart';

/// Keadaan satu sesi kuis.
///
/// Cukup banyak yang harus dijaga bersamaan — soal ke berapa, sisa hati,
/// timer, jawaban yang sudah masuk — dan itu alasan kuis ini punya
/// controller sendiri, bukan `setState` di dalam layar.
class QuizState {
  const QuizState({
    required this.level,
    required this.chapter,
    required this.questions,
    required this.mulaiSesi,
    this.index = 0,
    this.hearts = 5,
    this.answers = const [],
    this.input = '',
    this.dipilih,
    this.terkunci = false,
    this.benarTerakhir = false,
    this.sisaDetik,
    this.hasil,
  });

  final Level level;
  final Chapter? chapter;
  final List<Question> questions;
  final DateTime mulaiSesi;

  final int index;
  final int hearts;
  final List<AnsweredQuestion> answers;

  /// Isi papan angka untuk soal isian.
  final String input;

  /// Opsi yang barusan ditekan, dipakai mewarnai tombolnya.
  final String? dipilih;

  /// Sedang menampilkan umpan balik; ketukan berikutnya diabaikan
  /// sampai anak menekan Lanjut.
  final bool terkunci;
  final bool benarTerakhir;

  /// Sisa detik untuk soal ini. `null` berarti pos tanpa timer.
  final int? sisaDetik;

  /// Terisi begitu sesinya berakhir dan hasilnya sudah disimpan.
  final QuizResult? hasil;

  Question get soal => questions[index];

  int get total => questions.length;

  int get nomor => index + 1;

  int get benar => answers.where((a) => a.isCorrect).length;

  double get kemajuan => total == 0 ? 0 : nomor / total;

  bool get habisNyawa => hearts <= 0;

  bool get bisaKirim => input.isNotEmpty && !terkunci;

  QuizState copyWith({
    int? index,
    int? hearts,
    List<AnsweredQuestion>? answers,
    String? input,
    String? dipilih,
    bool hapusDipilih = false,
    bool? terkunci,
    bool? benarTerakhir,
    int? sisaDetik,
    bool hapusTimer = false,
    QuizResult? hasil,
  }) => QuizState(
    level: level,
    chapter: chapter,
    questions: questions,
    mulaiSesi: mulaiSesi,
    index: index ?? this.index,
    hearts: hearts ?? this.hearts,
    answers: answers ?? this.answers,
    input: input ?? this.input,
    dipilih: hapusDipilih ? null : (dipilih ?? this.dipilih),
    terkunci: terkunci ?? this.terkunci,
    benarTerakhir: benarTerakhir ?? this.benarTerakhir,
    sisaDetik: hapusTimer ? null : (sisaDetik ?? this.sisaDetik),
    hasil: hasil ?? this.hasil,
  );
}
