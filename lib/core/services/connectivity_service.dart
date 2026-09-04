import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Jenis sambungan, disederhanakan jadi yang benar-benar mengubah
/// keputusan aplikasi ini.
///
/// Tidak ada `mungkin` atau `terbatas` di sini. Yang perlu dijawab cuma
/// dua pertanyaan: boleh mengirim sekarang, dan boleh mengirim lewat
/// kuota orang tua.
enum JenisKoneksi {
  tidakAda,
  wifi,
  seluler,

  /// Ethernet, VPN, dan sejenisnya. Diperlakukan sama seperti Wi-Fi:
  /// tidak ada kuota yang terpakai.
  lain;

  bool get tersambung => this != JenisKoneksi.tidakAda;
  bool get berkuota => this == JenisKoneksi.seluler;
}

/// Keadaan sambungan.
///
/// Dibungkus jadi antarmuka sendiri supaya dua hal jadi mungkin: uji
/// bisa memaksa keadaannya tanpa perangkat, dan build luring tidak
/// pernah memanggil paketnya sama sekali.
abstract interface class ConnectivityService {
  Future<JenisKoneksi> sekarang();
  Stream<JenisKoneksi> get aliran;
  void dispose();
}

class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? bawaan])
    : _c = bawaan ?? Connectivity();

  final Connectivity _c;

  @override
  Future<JenisKoneksi> sekarang() async {
    try {
      return _dari(await _c.checkConnectivity());
    } catch (_) {
      // Gagal menanyakan sambungan bukan alasan menghentikan apa pun.
      // Anggap tersambung dan biarkan pengirimannya sendiri yang gagal
      // — itu jawaban yang lebih benar daripada menebak tidak ada
      // sinyal lalu diam saja.
      return JenisKoneksi.lain;
    }
  }

  @override
  Stream<JenisKoneksi> get aliran =>
      _c.onConnectivityChanged.map(_dari).distinct();

  @override
  void dispose() {}

  static JenisKoneksi _dari(List<ConnectivityResult> hasil) {
    if (hasil.isEmpty || hasil.every((r) => r == ConnectivityResult.none)) {
      return JenisKoneksi.tidakAda;
    }
    if (hasil.contains(ConnectivityResult.wifi)) return JenisKoneksi.wifi;
    if (hasil.contains(ConnectivityResult.mobile)) return JenisKoneksi.seluler;
    return JenisKoneksi.lain;
  }
}

/// Keadaan yang dipaksa. Dipakai build luring dan seluruh uji.
class KoneksiTetap implements ConnectivityService {
  KoneksiTetap(this.jenis);

  JenisKoneksi jenis;
  final _pengendali = StreamController<JenisKoneksi>.broadcast();

  void ubah(JenisKoneksi baru) {
    jenis = baru;
    _pengendali.add(baru);
  }

  @override
  Future<JenisKoneksi> sekarang() async => jenis;

  @override
  Stream<JenisKoneksi> get aliran => _pengendali.stream;

  @override
  void dispose() => _pengendali.close();
}
