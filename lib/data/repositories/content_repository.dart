import '../../domain/engine/question_generator.dart';
import '../../domain/models/chapter.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/grade.dart';
import '../../domain/models/level.dart';
import '../../domain/models/question.dart';
import '../local/dao/level_dao.dart';

/// Semua yang berhubungan dengan **isi**: planet, zona, pos, dan soal.
///
/// Widget tidak pernah menyentuh DAO — selalu lewat sini. Aturan itu yang
/// menjaga arah ketergantungan tetap satu arah.
class ContentRepository {
  ContentRepository(this._dao, {QuestionGenerator? generator})
    : _generator = generator ?? QuestionGenerator();

  final LevelDao _dao;
  final QuestionGenerator _generator;

  Future<List<Grade>> planets() => _dao.semuaGrade();

  Future<Grade?> planet(String id) => _dao.grade(id);

  Future<List<Chapter>> zona(String gradeId) => _dao.chapters(gradeId);

  Future<List<Level>> pos(String chapterId) => _dao.levels(chapterId);

  Future<Level?> level(String id) => _dao.level(id);

  Future<int> jumlahPos(String gradeId) => _dao.jumlahPos(gradeId);

  /// Soal untuk satu pos, dibangkitkan saat itu juga dari
  /// `difficulty_config`. Untuk Gerbang Planet, soalnya diambil campuran
  /// dari pos-pos sebelumnya di zona yang sama.
  Future<List<Question>> soal(Level level) async {
    if (!level.isBoss) {
      return _generator.generate(level.difficultyConfig);
    }
    final sezona = await _dao.levels(level.chapterId);
    final sumber = sezona
        .where((l) => !l.isBoss && l.orderIndex < level.orderIndex)
        .map((l) => l.difficultyConfig)
        .toList();
    return _generator.generateBoss(level.difficultyConfig, sumber);
  }

  /// Delapan soal lintas kelas untuk tes penempatan di akhir onboarding.
  ///
  /// Boleh dilewati. Hasilnya menentukan planet mana yang dibuka dan
  /// berapa zona pertama yang langsung ditandai selesai — menghemat anak
  /// yang sudah bisa dari dua puluh pos yang membosankan.
  ///
  /// Soalnya urut dari yang termudah ke yang tersulit, satu wakil per
  /// zona, lalu disaring jadi [jumlah] yang jaraknya rata.
  Future<List<SoalPenempatan>> soalPenempatan({int jumlah = 8}) async {
    final semua = <SoalPenempatan>[];
    for (final g in (await _dao.semuaGrade()).where((g) => g.isUnlocked)) {
      for (final z in await _dao.chapters(g.id)) {
        final posList = await _dao.levels(z.id);
        final wakil = posList.where((l) => !l.isBoss).toList();
        if (wakil.isEmpty) continue;
        // Pos tengah sebuah zona: sudah lewat pemanasan, belum sesulit
        // pos terakhir. Itu yang paling jelas memisahkan bisa dan belum.
        final l = wakil[wakil.length ~/ 2];
        semua.add(
          SoalPenempatan(
            // Selalu pilihan ganda tanpa bantuan: tes ini mengukur apa
            // yang sudah bisa, bukan melatih cara menjawabnya.
            soal: _generator.single(
              l.difficultyConfig.copyWith(
                formats: const [QuestionFormat.pilihanGanda],
                optionCount: 4,
                visualAid: VisualAid.tidakAda,
                timeLimitSeconds: null,
              ),
            ),
            gradeId: g.id,
            chapterId: z.id,
          ),
        );
      }
    }
    if (semua.length <= jumlah) return semua;

    final langkah = semua.length / jumlah;
    return [for (var i = 0; i < jumlah; i++) semua[(i * langkah).floor()]];
  }
}

/// Satu soal tes penempatan, lengkap dengan asal zonanya — itulah yang
/// dipakai menentukan anak ditaruh di mana.
class SoalPenempatan {
  const SoalPenempatan({
    required this.soal,
    required this.gradeId,
    required this.chapterId,
  });

  final Question soal;
  final String gradeId;
  final String chapterId;
}
