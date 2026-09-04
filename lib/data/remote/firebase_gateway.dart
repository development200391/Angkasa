import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_config.dart';
import '../../domain/engine/aturan_nilai.dart';
import '../../domain/models/liga.dart';
import 'remote_gateway.dart';
import 'remote_models.dart';

/// Satu-satunya berkas di proyek ini yang mengimpor `firebase_*`.
///
/// Kalau berkas ini dihapus, sisa aplikasinya tetap dikompilasi dan
/// tetap jalan — [GatewayLuring] menggantikannya tanpa satu pun layar
/// yang perlu tahu. Itu bukan kebetulan; itulah syarat yang membuat
/// janji "kalau Firebase mati, aplikasinya jalan seperti Tahap 2" bisa
/// diperiksa, bukan cuma diucapkan.
class FirebaseGateway implements RemoteGateway {
  FirebaseGateway();

  bool _siap = false;
  FirebaseAuth? _auth;
  FirebaseFirestore? _db;
  FirebaseRemoteConfig? _config;
  FirebaseCrashlytics? _crash;
  bool _googleSiap = false;

  @override
  bool get tersedia => _siap;

  /// Butuh dua-duanya: Firebase menyala, dan `GOOGLE_SERVER_CLIENT_ID`
  /// terisi. Yang kedua itu **Web client ID**, bukan yang bertuliskan
  /// "android" — Android meminta client id milik server justru untuk
  /// mendapatkan `idToken` yang bisa diverifikasi Firebase.
  ///
  /// Selama `false`, layar Simpan progres menyebutkan itu apa adanya,
  /// dan cadangan otomatis lewat akun anonim tetap jalan tanpa ini.
  @override
  bool get bisaMasukGoogle =>
      _siap && AppConfig.googleServerClientId.isNotEmpty;

  @override
  String? get uid => _auth?.currentUser?.uid;

  /// Batas waktu tiap panggilan ke server.
  ///
  /// Ada karena kegagalan yang paling merepotkan bukan galat, melainkan
  /// **diam**: sambungan yang menggantung membuat antrean berhenti tanpa
  /// satu pun pesan, dan orang tua yang menekan "Kirim" tidak pernah
  /// mendapat jawaban apa pun. Lewat batas ini, kirimannya dihitung
  /// gagal, tetap mengantre, dan dicoba lagi nanti — persis seperti
  /// kalau sinyalnya hilang.
  static const _batasWaktu = Duration(seconds: 12);

  static const _koleksiPengguna = 'users';
  static const _koleksiLiga = 'leaderboard_weekly';
  static const _koleksiCadangan = 'cadangan';
  static const _dokCadangan = 'progres';

  @override
  Future<void> siapkan() async {
    if (_siap) return;
    if (!AppConfig.daringAktif) return;

    try {
      await Firebase.initializeApp(options: _opsi);
      _auth = FirebaseAuth.instance;
      _db = FirebaseFirestore.instance;

      // Firestore menyimpan cache-nya sendiri di HP. Kita tetap memakai
      // SQLite sebagai sumber kebenaran — cache ini cuma membuat papan
      // peringkat masih ada isinya waktu sinyal hilang di tengah jalan.
      //
      // **Urutannya penting.** `useFirestoreEmulator` bekerja dengan
      // menulis `host` ke `settings`; menetapkan `settings` sesudahnya
      // menimpanya kembali ke server sungguhan tanpa satu pun peringatan.
      _db!.settings = const Settings(persistenceEnabled: true);

      final emulator = AppConfig.firebaseEmulatorHost;
      if (emulator.isNotEmpty) {
        // Dipakai saat mengembangkan. Sengaja dipasang sebelum
        // panggilan apa pun: begitu alamat ini terisi, tidak ada satu
        // baris data pun yang bisa nyasar ke proyek sungguhan.
        await _auth!.useAuthEmulator(emulator, 9099);
        _db!.useFirestoreEmulator(emulator, 8080);
      }

      await _siapkanConfig();
      await _siapkanCrashlytics();

      _siap = true;
    } catch (e, s) {
      // Gagal menyalakan Firebase bukan alasan aplikasinya berhenti.
      // Anak tetap bisa belajar; yang hilang cuma papan peringkat.
      debugPrint('Firebase tidak menyala: $e');
      debugPrintStack(stackTrace: s);
      _siap = false;
    }
  }

  FirebaseOptions get _opsi => FirebaseOptions(
    apiKey: AppConfig.firebaseApiKey,
    appId: AppConfig.firebaseAppId,
    messagingSenderId: AppConfig.firebaseSenderId,
    projectId: AppConfig.firebaseProjectId,
    storageBucket: AppConfig.firebaseStorageBucket.isEmpty
        ? null
        : AppConfig.firebaseStorageBucket,
  );

  Future<void> _siapkanConfig() async {
    final config = FirebaseRemoteConfig.instance;
    await config.setDefaults(AturanNilai.bawaan.sebagaiPeta);
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 8),
        // Sekali sehari sudah cukup. Ambang bintang bukan sesuatu yang
        // pantas diubah di tengah sesi yang sedang dikerjakan anak.
        minimumFetchInterval: const Duration(hours: 12),
      ),
    );
    _config = config;
    unawaited(config.fetchAndActivate().catchError((_) => false));
  }

  Future<void> _siapkanCrashlytics() async {
    final crash = FirebaseCrashlytics.instance;
    await crash.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Tidak ada satu pun penanda yang bisa menunjuk ke anak tertentu.
    // Yang dikirim cuma versi skema dan platform — cukup untuk tahu
    // kerusakan ini menimpa pemasangan yang mana.
    FlutterError.onError = (galat) {
      FlutterError.presentError(galat);
      crash.recordFlutterFatalError(galat);
    };
    PlatformDispatcher.instance.onError = (galat, jejak) {
      // Dicetak dulu, baru dilaporkan. Menelan galat langsung ke
      // Crashlytics tanpa jejak lokal membuat kerusakan waktu
      // mengembangkan jadi tidak terlihat sama sekali — layarnya cuma
      // diam, dan tidak ada satu baris pun di log.
      debugPrint('Angkasa/galat: $galat');
      crash.recordError(galat, jejak, fatal: true);
      return true;
    };
    _crash = crash;
  }

  // ------------------------------------------------------------ akun
  @override
  Future<AkunDaring?> masukAnonim() async {
    final auth = _auth;
    if (!_siap || auth == null) return null;
    final sekarang = auth.currentUser;
    if (sekarang != null) {
      return AkunDaring(uid: sekarang.uid, email: sekarang.email);
    }
    final hasil = await auth.signInAnonymously().timeout(_batasWaktu);
    final pengguna = hasil.user;
    return pengguna == null
        ? null
        : AkunDaring(uid: pengguna.uid, email: pengguna.email);
  }

  /// Menautkan akun anonim yang sedang berjalan ke sebuah akun Google.
  ///
  /// Dipakai `linkWithCredential`, **bukan** `signInWithCredential`, dan
  /// bedanya bukan gaya: menautkan mempertahankan uid, jadi cadangan dan
  /// peringkat yang sudah ada langsung jadi milik akun Google itu tanpa
  /// satu byte pun dipindahkan. Masuk biasa akan membuat uid baru dan
  /// meninggalkan seluruh progres anak di akun anonim yang tidak akan
  /// pernah bisa dijangkau lagi dari HP mana pun.
  @override
  Future<TautanAkun> tautkanGoogle() async {
    final auth = _auth;
    if (!bisaMasukGoogle || auth == null) {
      return const TautanAkun(HasilTaut.gagal);
    }

    // Harus ada akun yang berjalan lebih dulu — itulah uid yang
    // dipertahankan. Orang tua yang menekan "Tautkan" tanpa pernah
    // menyalakan cadangan tetap dilayani, bukan ditolak.
    var pengguna = auth.currentUser;
    if (pengguna == null) {
      await masukAnonim();
      pengguna = auth.currentUser;
    }
    if (pengguna == null) return const TautanAkun(HasilTaut.gagal);

    final AuthCredential kredensial;
    try {
      kredensial = await _kredensialGoogle();
    } on GoogleSignInException catch (e) {
      // Menutup lembar pilihan akun bukan kerusakan, dan tidak dicatat
      // ke Crashlytics.
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return const TautanAkun(HasilTaut.dibatalkan);
      }

      // HP tanpa satu pun akun Google. Sayangnya `google_sign_in` tidak
      // memberi kode tersendiri untuk ini — Credential Manager
      // melaporkannya sebagai `unknownError`, dan yang membedakannya cuma
      // awalan keterangan yang ditempelkan paketnya sendiri. Cocok-teks
      // memang rapuh, tapi gagalnya aman: kalau awalan itu berubah di
      // versi berikutnya, yang muncul cuma pesan umum lagi, bukan
      // kerusakan. Yang tidak aman adalah menyuruh orang tua "coba lagi
      // nanti" untuk keadaan yang tidak akan berubah sampai mereka
      // menambahkan akun.
      if (e.code == GoogleSignInExceptionCode.unknownError &&
          (e.description ?? '').startsWith('No credential available')) {
        return const TautanAkun(HasilTaut.tidakAdaAkunDiHp);
      }

      debugPrint('Angkasa/google: ${e.code} ${e.description}');
      await catatGalat(e, StackTrace.current);
      return const TautanAkun(HasilTaut.gagal);
    } catch (e, s) {
      debugPrint('Angkasa/google: $e');
      await catatGalat(e, s);
      return const TautanAkun(HasilTaut.gagal);
    }

    try {
      final hasil = await pengguna
          .linkWithCredential(kredensial)
          .timeout(_batasWaktu);
      return _tautan(HasilTaut.berhasil, hasil.user);
    } on FirebaseAuthException catch (e, s) {
      // Sudah tertaut ke akun Google yang sama. Tidak ada yang perlu
      // dikerjakan, dan menyebutnya gagal cuma membingungkan.
      if (e.code == 'provider-already-linked') {
        return _tautan(HasilTaut.berhasil, pengguna);
      }

      // Akun Google itu sudah punya progresnya sendiri di HP lain.
      // Firebase menolak menautkan, dan itu benar — dua progres tidak
      // bisa digabung tanpa seseorang memilih. Yang dikerjakan di sini
      // cuma masuk ke akun tersebut; pilihannya diambil orang tua di
      // layar Pulihkan progres, dan progres di HP ini belum disentuh
      // sama sekali karena SQLite-lah sumber kebenarannya.
      if (e.code == 'credential-already-in-use' ||
          e.code == 'email-already-in-use') {
        try {
          final masuk = await auth
              .signInWithCredential(e.credential ?? kredensial)
              .timeout(_batasWaktu);
          return _tautan(HasilTaut.sudahDipakaiAkunLain, masuk.user);
        } catch (e2, s2) {
          debugPrint('Angkasa/google: gagal masuk ke akun lama — $e2');
          await catatGalat(e2, s2);
          return const TautanAkun(HasilTaut.gagal);
        }
      }

      debugPrint('Angkasa/google: ${e.code} ${e.message}');
      await catatGalat(e, s);
      return const TautanAkun(HasilTaut.gagal);
    } catch (e, s) {
      debugPrint('Angkasa/google: $e');
      await catatGalat(e, s);
      return const TautanAkun(HasilTaut.gagal);
    }
  }

  TautanAkun _tautan(HasilTaut hasil, User? pengguna) => pengguna == null
      ? const TautanAkun(HasilTaut.gagal)
      : TautanAkun(
          hasil,
          akun: AkunDaring(uid: pengguna.uid, email: pengguna.email),
        );

  /// Membuka lembar pilihan akun Google, lalu menukar `idToken`-nya jadi
  /// kredensial Firebase.
  Future<AuthCredential> _kredensialGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleSiap) {
      await google.initialize(serverClientId: AppConfig.googleServerClientId);
      _googleSiap = true;
    }
    if (!google.supportsAuthenticate()) {
      throw UnsupportedError('Masuk Google tidak tersedia di platform ini');
    }

    final akun = await google.authenticate();
    final idToken = akun.authentication.idToken;
    if (idToken == null) {
      // Nyaris selalu berarti SHA-1 pemasangan ini belum terdaftar di
      // proyek Firebase-nya. Ditulis lugas supaya tidak dikira galat
      // jaringan waktu mengembangkan.
      throw StateError('Google tidak memberi idToken — SHA-1 sudah didaftar?');
    }
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  @override
  Future<void> keluar() async {
    await _auth?.signOut();
    if (_googleSiap) {
      // Tanpa ini, lembar pilihan akun berikutnya langsung memakai akun
      // yang sama tanpa bertanya — dan orang tua yang barusan menghapus
      // datanya tidak punya jalan memilih akun lain.
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  // ----------------------------------------------------------- tulis
  DocumentReference<Map<String, dynamic>>? get _dokSaya {
    final id = uid;
    if (!_siap || id == null) return null;
    return _db!.collection(_koleksiPengguna).doc(id);
  }

  @override
  Future<void> tulisProfil(ProfilDaring profil) async {
    await _dokSaya
        ?.set(profil.sebagaiPeta, SetOptions(merge: true))
        .timeout(_batasWaktu);
  }

  @override
  Future<void> tulisCadangan(CadanganProgres cadangan) async {
    final dok = _dokSaya;
    if (dok == null) return;
    await dok
        .collection(_koleksiCadangan)
        .doc(_dokCadangan)
        .set(cadangan.sebagaiPeta, SetOptions(merge: false))
        .timeout(_batasWaktu);
  }

  @override
  Future<void> tulisSkor({
    required String weekId,
    required EntriLiga entri,
  }) async {
    final id = uid;
    if (!_siap || id == null) return;
    await _db!
        .collection(_koleksiLiga)
        .doc(weekId)
        .collection('entries')
        .doc(id)
        .set(entri.sebagaiPeta, SetOptions(merge: true))
        .timeout(_batasWaktu);
  }

  /// Pembagian liga dilakukan di sini, di dalam satu transaksi, dan
  /// bukan di Cloud Function.
  ///
  /// Tahap 3 sengaja tidak punya kode server: satu transaksi per anak
  /// per minggu jauh lebih murah daripada satu fungsi yang perlu
  /// di-deploy, dipantau, dan dibayar. Dokumen `{weekId}` cuma memegang
  /// dua angka — liga terakhir yang dibuka dan berapa isinya.
  @override
  Future<int> daftarkanLiga({
    required String weekId,
    required int ukuran,
  }) async {
    if (!_siap) return 0;
    final ref = _db!.collection(_koleksiLiga).doc(weekId);
    return _db!
        .runTransaction<int>((tx) async {
          final cuplikan = await tx.get(ref);
          final data = cuplikan.data() ?? const <String, dynamic>{};
          var liga = (data['ligaTerakhir'] as num?)?.toInt() ?? 1;
          var isi = (data['jumlah'] as num?)?.toInt() ?? 0;
          if (liga < 1) liga = 1;
          if (isi >= ukuran) {
            liga += 1;
            isi = 0;
          }
          tx.set(ref, {
            'ligaTerakhir': liga,
            'jumlah': isi + 1,
            'ukuran': ukuran,
          }, SetOptions(merge: true));
          return liga;
        })
        .timeout(_batasWaktu);
  }

  // ------------------------------------------------------------ baca
  @override
  Future<List<EntriLiga>> bacaPapan({
    required String weekId,
    required int liga,
    required int batas,
  }) async {
    if (!_siap) return const [];
    final hasil = await _db!
        .collection(_koleksiLiga)
        .doc(weekId)
        .collection('entries')
        .where('league', isEqualTo: liga)
        .orderBy('xp', descending: true)
        .limit(batas)
        .get()
        .timeout(_batasWaktu);
    return [for (final d in hasil.docs) EntriLiga.dariPeta(d.id, d.data())];
  }

  @override
  Future<ProfilDaring?> bacaProfil() async {
    final cuplikan = await _dokSaya?.get().timeout(_batasWaktu);
    final data = cuplikan?.data();
    return data == null ? null : ProfilDaring.dariPeta(data);
  }

  @override
  Future<CadanganProgres?> bacaCadangan() async {
    final dok = _dokSaya;
    if (dok == null) return null;
    final cuplikan = await dok
        .collection(_koleksiCadangan)
        .doc(_dokCadangan)
        .get()
        .timeout(_batasWaktu);
    final data = cuplikan.data();
    return data == null ? null : CadanganProgres.dariPeta(data);
  }

  @override
  Future<void> hapusSemuaData() async {
    final dok = _dokSaya;
    if (dok == null) return;
    // Baris papan peringkat minggu-minggu lalu ikut dihapus lewat aturan
    // masa simpan di server; yang bisa dihapus dari HP adalah dokumen
    // milik anak ini sendiri, dan itu yang dikerjakan di sini.
    await dok.collection(_koleksiCadangan).doc(_dokCadangan).delete();
    await dok.delete();
  }

  // --------------------------------------------------------- setelan
  @override
  Future<AturanNilai> aturanNilai() async {
    final config = _config;
    if (config == null) return AturanNilai.bawaan;
    try {
      final semua = config.getAll();
      return AturanNilai.dariPeta({
        for (final e in semua.entries) e.key: e.value.asString(),
      });
    } catch (_) {
      return AturanNilai.bawaan;
    }
  }

  // -------------------------------------------------------- laporan
  @override
  Future<void> catatGalat(
    Object galat,
    StackTrace jejak, {
    bool fatal = false,
  }) async {
    debugPrint('Angkasa/daring: $galat');
    await _crash?.recordError(galat, jejak, fatal: fatal);
  }

  @override
  Future<void> setPenanda(String kunci, Object nilai) async {
    await _crash?.setCustomKey(kunci, nilai);
  }

  /// Dibaca `defaultTargetPlatform`, bukan `dart:io` — supaya berkas
  /// ini tetap bisa dikompilasi untuk web, yang dipakai mengetes tata
  /// letak dengan `flutter run -d chrome`.
  static String get platform =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
}
