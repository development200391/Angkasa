import 'package:just_audio/just_audio.dart';

import '../constants/app_assets.dart';

/// Efek suara.
///
/// Untuk aplikasi anak, suara bukan pemolesan akhir — aplikasi anak yang
/// diam terasa rusak, sekalipun semua logikanya benar.
///
/// Semua bunyi dibundel sebagai WAV pendek dan diputar dari berkas
/// lokal; tidak ada satu pun yang diunduh. Kalau pemutarnya gagal
/// (perangkat tanpa keluaran audio, mode senyap, emulator tanpa codec),
/// kegagalannya ditelan: sesi belajar tidak boleh berhenti gara-gara
/// suara.
class AudioService {
  AudioService({this.nyala = true});

  /// Ikut setelan Suara di Pengaturan.
  bool nyala;

  /// Satu pemutar per bunyi. Kuisnya cepat — kalau semua berbagi satu
  /// pemutar, bunyi "benar" berikutnya memotong bunyi sebelumnya.
  final _pemutar = <String, AudioPlayer>{};

  void setNyala(bool v) {
    nyala = v;
    if (!v) {
      for (final p in _pemutar.values) {
        p.stop();
      }
    }
  }

  Future<void> benar() => _mainkan(AppAssets.suaraBenar);
  Future<void> salah() => _mainkan(AppAssets.suaraSalah);
  Future<void> naikLevel() => _mainkan(AppAssets.suaraNaikLevel);
  Future<void> bintang() => _mainkan(AppAssets.suaraBintang);
  Future<void> lepasLandas() => _mainkan(AppAssets.suaraLepasLandas);
  Future<void> tik() => _mainkan(AppAssets.suaraTik);

  Future<void> _mainkan(String aset) async {
    if (!nyala) return;
    try {
      final p = _pemutar.putIfAbsent(aset, AudioPlayer.new);
      if (p.audioSource == null) await p.setAsset(aset);
      await p.seek(Duration.zero);
      await p.play();
    } catch (_) {
      // Bunyi yang gagal tidak pernah jadi kesalahan yang terlihat anak.
    }
  }

  Future<void> dispose() async {
    for (final p in _pemutar.values) {
      await p.dispose();
    }
    _pemutar.clear();
  }
}
