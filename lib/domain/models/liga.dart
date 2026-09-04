/// Satu baris di papan peringkat.
///
/// Isinya persis lima hal, dan tidak akan pernah bertambah tanpa alasan
/// yang bisa ditulis di layar Data yang dikirim: nama panggilan, nomor
/// avatar, XP minggu ini, nomor liga, dan kapan terakhir diperbarui.
class EntriLiga {
  const EntriLiga({
    required this.uid,
    required this.nickname,
    required this.avatarId,
    required this.xp,
    required this.diperbarui,
    this.liga = 1,
  });

  final String uid;
  final String nickname;
  final String avatarId;
  final int xp;
  final int liga;
  final DateTime diperbarui;

  Map<String, Object?> get sebagaiPeta => {
    'nickname': nickname,
    'avatarId': avatarId,
    'xp': xp,
    'league': liga,
    'updatedAt': diperbarui.toUtc().toIso8601String(),
  };

  static EntriLiga dariPeta(String uid, Map<String, Object?> p) => EntriLiga(
    uid: uid,
    nickname: (p['nickname'] as String?) ?? 'Penjelajah',
    avatarId: (p['avatarId'] as String?) ?? 'roket',
    xp: (p['xp'] as num?)?.toInt() ?? 0,
    liga: (p['league'] as num?)?.toInt() ?? 1,
    diperbarui:
        DateTime.tryParse((p['updatedAt'] as String?) ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}

/// Papan peringkat satu liga, sudah urut dan sudah tahu di mana anak ini
/// berdiri.
class PapanLiga {
  const PapanLiga({
    required this.weekId,
    required this.liga,
    required this.entri,
    required this.uidSaya,
  });

  const PapanLiga.kosong(this.weekId)
    : liga = 0,
      entri = const [],
      uidSaya = null;

  final String weekId;
  final int liga;

  /// Sudah terurut: XP terbesar di indeks 0.
  final List<EntriLiga> entri;
  final String? uidSaya;

  bool get kosong => entri.isEmpty;

  int get jumlahPemain => entri.length;

  /// Peringkat anak ini, dihitung dari 1. `null` kalau ia belum punya
  /// baris di liga ini — biasanya karena minggu ini belum main sama
  /// sekali.
  int? get peringkatSaya {
    if (uidSaya == null) return null;
    final i = entri.indexWhere((e) => e.uid == uidSaya);
    return i < 0 ? null : i + 1;
  }

  EntriLiga? get sayaEntri {
    final i = peringkatSaya;
    return i == null ? null : entri[i - 1];
  }

  /// Tiga teratas untuk podium, apa adanya kalau pemainnya belum tiga.
  List<EntriLiga> get podium => entri.take(3).toList();

  /// Sisanya, di bawah podium.
  List<EntriLiga> get sisa => entri.skip(3).toList();
}

/// Hasil satu minggu yang sudah lewat — isi layar Akhir minggu.
class RingkasanMinggu {
  const RingkasanMinggu({
    required this.weekId,
    required this.peringkat,
    required this.pemain,
    required this.xp,
    required this.posSelesai,
    this.peringkatSebelumnya,
  });

  final String weekId;
  final int peringkat;
  final int pemain;
  final int xp;
  final int posSelesai;

  /// Peringkat minggu sebelumnya, kalau ada. Inilah yang membuat layar
  /// akhir minggu bisa menonjolkan pergerakan, bukan posisi.
  final int? peringkatSebelumnya;

  int? get pergerakan =>
      peringkatSebelumnya == null ? null : peringkatSebelumnya! - peringkat;
}
