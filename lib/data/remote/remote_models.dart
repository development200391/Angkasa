/// Akun yang sedang masuk.
///
/// Bawaannya selalu anonim: `signInAnonymously()` dipanggil sekali saat
/// aplikasi pertama tersambung, tanpa layar masuk dan tanpa satu pun
/// data pribadi. [email] cuma terisi kalau orang tua menautkan akun
/// Google supaya progresnya bisa dipindah ke HP baru.
class AkunDaring {
  const AkunDaring({required this.uid, this.email});

  final String uid;
  final String? email;

  bool get anonim => email == null || email!.isEmpty;
}

/// Bagaimana usaha menautkan akun Google berakhir.
///
/// Empat, bukan dua, dan yang ketiga justru yang paling menentukan:
/// akun Google yang dipilih orang tua **sudah dipakai HP lain**. Itu
/// bukan galat — itu justru keadaan yang wajar waktu HP diganti, dan
/// satu-satunya jawaban yang benar adalah menanyakan progres mana yang
/// dipertahankan. Memperlakukannya sebagai kegagalan berarti menyuruh
/// orang tua mencoba lagi selamanya.
enum HasilTaut {
  /// Tertaut, dan uid-nya tetap sama — cadangan yang sudah ada langsung
  /// jadi milik akun Google itu tanpa satu byte pun dipindahkan.
  berhasil,

  /// Orang tua menutup lembar pilihan akun. Bukan kegagalan, dan tidak
  /// pantas dijawab pesan galat apa pun.
  dibatalkan,

  /// Akun Google itu sudah punya progres sendiri. Aplikasi sudah masuk
  /// ke akun tersebut; yang tersisa adalah memilih di layar Pulihkan
  /// progres.
  sudahDipakaiAkunLain,

  /// Tidak ada satu pun akun Google di HP ini.
  ///
  /// Dipisahkan dari [gagal] karena jawabannya berbeda: "coba lagi
  /// nanti" **tidak akan pernah berhasil** di HP yang memang belum punya
  /// akun Google. Yang perlu disebutkan adalah menambahkannya lewat
  /// Setelan.
  tidakAdaAkunDiHp,

  gagal,
}

/// [HasilTaut] beserta akun yang sedang berjalan sesudahnya.
class TautanAkun {
  const TautanAkun(this.hasil, {this.akun});

  final HasilTaut hasil;

  /// Akun yang aktif setelah usaha ini — bisa akun yang baru tertaut,
  /// bisa akun lama yang barusan dimasuki. `null` kalau tidak ada yang
  /// berubah.
  final AkunDaring? akun;
}

/// Isi dokumen `users/{uid}`.
///
/// Delapan field, dan tidak lebih. Daftar ini harus sama persis dengan
/// yang tertulis di layar **Data yang dikirim** dan dengan deklarasi
/// *Data safety* di Play Console — kalau suatu hari ada yang bertambah
/// di sini, dua tempat itu ikut berubah di komit yang sama.
class ProfilDaring {
  const ProfilDaring({
    required this.nickname,
    required this.avatarId,
    required this.gradeLevel,
    required this.totalXp,
    required this.streakCount,
    required this.weeklyXp,
    required this.lastSyncAt,
    required this.platform,
  });

  final String nickname;
  final String avatarId;

  /// Planet yang sedang aktif, misalnya `grade-1`.
  final String? gradeLevel;

  final int totalXp;
  final int streakCount;
  final int weeklyXp;
  final DateTime lastSyncAt;
  final String platform;

  /// Daftar field yang dikirim, ditulis sekali di sini.
  ///
  /// Ada uji yang membandingkan daftar ini dengan kunci [sebagaiPeta]
  /// **dan** dengan daftar di layar Data yang dikirim. Menambah satu
  /// field tanpa memperbarui dua tempat itu membuat ujinya merah — dan
  /// itu memang tujuannya, karena layar itu harus sama persis dengan
  /// deklarasi *Data safety* di Play Console.
  static const fieldnya = <String>[
    'nickname',
    'avatarId',
    'gradeLevel',
    'totalXp',
    'streakCount',
    'weeklyXp',
    'lastSyncAt',
    'platform',
  ];

  Map<String, Object?> get sebagaiPeta => {
    'nickname': nickname,
    'avatarId': avatarId,
    'gradeLevel': gradeLevel,
    'totalXp': totalXp,
    'streakCount': streakCount,
    'weeklyXp': weeklyXp,
    'lastSyncAt': lastSyncAt.toUtc().toIso8601String(),
    'platform': platform,
  };

  static ProfilDaring dariPeta(Map<String, Object?> p) => ProfilDaring(
    nickname: (p['nickname'] as String?) ?? '',
    avatarId: (p['avatarId'] as String?) ?? 'roket',
    gradeLevel: p['gradeLevel'] as String?,
    totalXp: (p['totalXp'] as num?)?.toInt() ?? 0,
    streakCount: (p['streakCount'] as num?)?.toInt() ?? 0,
    weeklyXp: (p['weeklyXp'] as num?)?.toInt() ?? 0,
    lastSyncAt:
        DateTime.tryParse((p['lastSyncAt'] as String?) ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
    platform: (p['platform'] as String?) ?? '-',
  );
}

/// Isi dokumen `users/{uid}/cadangan/progres`.
///
/// Ini satu-satunya hal yang dikirim di luar delapan field di atas, dan
/// ia ada untuk satu tujuan tunggal: **memulihkan progres di HP baru**.
/// Bentuknya sesempit mungkin — satu peta `id pos → "bintang,skor"` —
/// karena 78 pos hari ini akan jadi 250 pos di Tahap 4, dan dokumen
/// Firestore berhenti di 1 MiB.
///
/// Yang **tidak** ikut: `question_attempts`. Volumenya ribuan baris per
/// anak, tidak berguna sama sekali secara daring, dan langsung
/// membengkakkan tagihan. Jawaban tiap soal tinggal di HP, dan itulah
/// yang dijanjikan layar Data yang dikirim.
class CadanganProgres {
  const CadanganProgres({
    required this.pos,
    required this.lencana,
    required this.diperbarui,
  });

  /// `id pos` → `"bintang,skor terbaik"`.
  final Map<String, String> pos;
  final List<String> lencana;
  final DateTime diperbarui;

  int get jumlahPosSelesai => pos.values
      .where((v) => (int.tryParse(v.split(',').first) ?? 0) > 0)
      .length;

  Map<String, Object?> get sebagaiPeta => {
    'levels': pos,
    'badges': lencana,
    'updatedAt': diperbarui.toUtc().toIso8601String(),
  };

  static CadanganProgres dariPeta(Map<String, Object?> p) => CadanganProgres(
    pos: {
      for (final e in ((p['levels'] as Map?) ?? const {}).entries)
        '${e.key}': '${e.value}',
    },
    lencana: [for (final b in (p['badges'] as List?) ?? const []) '$b'],
    diperbarui:
        DateTime.tryParse((p['updatedAt'] as String?) ?? '')?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );
}
