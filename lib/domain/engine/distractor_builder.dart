import 'dart:math';

import '../models/enums.dart';
import '../models/question.dart';

/// Membangun pengecoh pilihan ganda.
///
/// **Nilai pengecohnya tidak diacak — posisinya diacak.** Dua hal yang
/// berbeda, dan keduanya penting.
///
/// Nilainya: tiap pengecoh meniru satu kesalahan yang benar-benar sering
/// dilakukan anak, dan tiap kesalahan itu punya nama ([MistakeKind]).
/// Efek sampingnya yang paling berharga: karena pengecohnya bernama,
/// `question_attempts` berubah dari catatan nilai jadi data diagnosa —
/// "sering lupa menyimpan", bukan "nilai 60".
///
/// Posisinya: sampai Tahap 2 opsinya diurutkan menaik supaya angkanya
/// enak dibaca. Itu keliru, dan baru ketahuan saat menjalankan aplikasi
/// di emulator: pengecoh yang paling sering terpakai adalah "meleset
/// satu" ke dua arah, jadi urutan menaik menaruh jawaban benar **selalu
/// di tengah**. Sepuluh soal berturut-turut bisa dijawab 10/10 tanpa
/// berhitung sama sekali, cuma dengan menekan tombol tengah — dan bintang
/// tiga yang didapat begitu tidak mengukur apa pun.
class DistractorBuilder {
  DistractorBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Daftar opsi lengkap (benar + pengecoh), posisinya diacak.
  List<AnswerOption> build({
    required Operation operation,
    required int left,
    required int right,
    required int result,
    required UnknownPosition unknown,
    required int answerValue,
    required int optionCount,
    bool allowNegative = false,
  }) {
    if (unknown == UnknownPosition.operator) {
      return _operatorOptions(operation, optionCount);
    }

    final kandidat = <int, MistakeKind>{};
    void tambah(int nilai, MistakeKind jenis) {
      if (nilai == answerValue) return;
      if (nilai < 0 && !allowNegative) return;
      kandidat.putIfAbsent(nilai, () => jenis);
    }

    for (final n in _bernama(
      operation: operation,
      left: left,
      right: right,
      result: result,
      unknown: unknown,
      answerValue: answerValue,
    ).entries) {
      tambah(n.key, n.value);
    }

    // Cadangan kalau kesalahan bernama tidak cukup mengisi slot.
    tambah(answerValue + 1, MistakeKind.melesetSatu);
    tambah(answerValue - 1, MistakeKind.melesetSatu);
    tambah(answerValue + 2, MistakeKind.lainnya);
    tambah(answerValue - 2, MistakeKind.lainnya);
    tambah(answerValue + 10, MistakeKind.salahNilaiTempat);
    tambah(answerValue - 10, MistakeKind.salahNilaiTempat);

    final dipilih = kandidat.entries.take(optionCount - 1).toList();
    return <AnswerOption>[
      AnswerOption(label: '$answerValue', isCorrect: true),
      for (final e in dipilih)
        AnswerOption(label: '${e.key}', mistake: e.value),
    ]..shuffle(_random);
  }

  /// Kesalahan yang punya nama, urut dari yang paling sering terjadi.
  Map<int, MistakeKind> _bernama({
    required Operation operation,
    required int left,
    required int right,
    required int result,
    required UnknownPosition unknown,
    required int answerValue,
  }) {
    final m = <int, MistakeKind>{};
    // Yang lebih dulu disebut menang: kalau dua kesalahan menghasilkan
    // angka yang sama (17 + 5 → 12 bisa datang dari lupa menyimpan
    // *dan* dari membaca + sebagai −), yang tercatat adalah yang paling
    // sering benar-benar terjadi.
    void set(int nilai, MistakeKind jenis) => m.putIfAbsent(nilai, () => jenis);

    // Yang ditanya operan, bukan hasil: anak sering menjawab hasilnya
    // atau operan yang satunya — dua angka yang memang ada di layar.
    if (unknown != UnknownPosition.hasil) {
      set(result, MistakeKind.operasiTerbalik);
      set(
        unknown == UnknownPosition.operanKiri ? right : left,
        MistakeKind.operasiTerbalik,
      );
      set(answerValue + 1, MistakeKind.melesetSatu);
      set(answerValue - 1, MistakeKind.melesetSatu);
      return m;
    }

    // Urutannya menentukan pengecoh mana yang terpakai waktu slotnya
    // cuma dua. Yang paling sering benar-benar terjadi didahulukan:
    // teknik yang sedang dilatih pos itu, lalu salah hitung jari, baru
    // salah baca tanda — kalau dibalik, `4 + 4` malah menawarkan `0`.
    switch (operation) {
      case Operation.tambah:
        // Lupa menyimpan: satuan dijumlah, puluhannya tidak dinaikkan.
        if (_menyimpan(left, right)) {
          set(
            ((left % 10 + right % 10) % 10) + (left ~/ 10 + right ~/ 10) * 10,
            MistakeKind.lupaMenyimpan,
          );
        }
        set(result + 1, MistakeKind.melesetSatu);
        set(result - 1, MistakeKind.melesetSatu);
        // Salah nilai tempat: angkanya dijumlah, bukan nilainya.
        if (left >= 10 || right >= 10) {
          final salah = _jumlahDigitBerbobot(left, right);
          if (salah != result) set(salah, MistakeKind.salahNilaiTempat);
        }
        set(left - right, MistakeKind.operasiTerbalik);
      case Operation.kurang:
        // Meminjam dilewat: tiap kolom dikurangkan dari yang lebih besar.
        if (_meminjam(left, right)) {
          set(
            ((left % 10) - (right % 10)).abs() +
                (left ~/ 10 - right ~/ 10) * 10,
            MistakeKind.lupaMenyimpan,
          );
        }
        set(result - 1, MistakeKind.melesetSatu);
        set(result + 1, MistakeKind.melesetSatu);
        set(left + right, MistakeKind.operasiTerbalik);
      case Operation.kali:
        set(result - left, MistakeKind.melesetSatu); // kurang satu putaran
        set(result + left, MistakeKind.melesetSatu); // lebih satu putaran
        set(left + right, MistakeKind.operasiTerbalik);
        set(result * 10, MistakeKind.salahNilaiTempat);
      case Operation.bagi:
        set(result + 1, MistakeKind.melesetSatu);
        set(result - 1, MistakeKind.melesetSatu);
        set(left - right, MistakeKind.operasiTerbalik);
        set(left * right, MistakeKind.operasiTerbalik);
    }
    return m;
  }

  List<AnswerOption> _operatorOptions(Operation benar, int optionCount) {
    final lain = Operation.values.where((o) => o != benar).toList()
      ..shuffle(_random);
    return <AnswerOption>[
      AnswerOption(label: benar.lambang, isCorrect: true),
      for (final o in lain.take(optionCount - 1))
        AnswerOption(label: o.lambang, mistake: MistakeKind.operasiTerbalik),
    ]..shuffle(_random);
  }

  /// Menyimpan hanya berlaku kalau ada kolom puluhan yang bisa dinaiki.
  /// `7 + 5` bukan menyimpan — itu melewati sepuluh, urusan sumbu S1.
  static bool _menyimpan(int l, int r) =>
      (l >= 10 || r >= 10) && (l % 10) + (r % 10) >= 10;

  static bool _meminjam(int l, int r) => l >= 10 && (l % 10) < (r % 10);

  /// `30 + 4` dibaca `3 + 4` lalu ditulis kembali sebagai puluhan → `70`.
  static int _jumlahDigitBerbobot(int l, int r) {
    final pl = l ~/ 10, sl = l % 10, pr = r ~/ 10, sr = r % 10;
    if (sl == 0 && pr == 0) return (pl + sr) * 10;
    if (sr == 0 && pl == 0) return (pr + sl) * 10;
    return (pl + pr + sl + sr) * 10;
  }
}
