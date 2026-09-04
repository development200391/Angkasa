import 'package:angkasa/data/remote/remote_gateway.dart';
import 'package:angkasa/data/remote/remote_models.dart';
import 'package:angkasa/domain/engine/aturan_nilai.dart';
import 'package:angkasa/domain/models/liga.dart';

/// Server tiruan yang seluruhnya di memori.
///
/// Bukan mock yang cuma mencatat panggilan: ia benar-benar menyimpan
/// dokumennya, membagi liga dengan aturan yang sama, dan bisa dipaksa
/// gagal. Yang diuji dengan ini bukan Firestore — melainkan apa yang
/// dilakukan aplikasi terhadap jawaban yang dikembalikannya.
class GatewayTiruan implements RemoteGateway {
  GatewayTiruan({this.tersedia = true, this.uid = 'uid-uji'});

  @override
  bool tersedia;

  @override
  String? uid;

  @override
  bool bisaMasukGoogle = false;

  /// Kalau terisi, tiap penulisan melemparnya. Dipakai menguji apa yang
  /// terjadi pada antrean waktu server menolak.
  Object? galatTulis;

  /// Kalau terisi, tiap pembacaan papan melemparnya.
  Object? galatBaca;

  final profil = <String, ProfilDaring>{};
  final cadangan = <String, CadanganProgres>{};
  final entri = <String, Map<String, EntriLiga>>{};
  final galatTercatat = <Object>[];

  AturanNilai setelan = AturanNilai.bawaan;

  int _ligaTerakhir = 1;
  int _isiLiga = 0;
  var siapkanDipanggil = 0;
  var tulisProfilDipanggil = 0;
  var tulisSkorDipanggil = 0;

  @override
  Future<void> siapkan() async => siapkanDipanggil++;

  @override
  Future<AkunDaring?> masukAnonim() async =>
      tersedia && uid != null ? AkunDaring(uid: uid!) : null;

  /// Hasil yang dipulangkan [tautkanGoogle]. Diatur tiap uji sesuai
  /// keadaan yang sedang diperiksa.
  TautanAkun tautan = const TautanAkun(HasilTaut.gagal);

  int tautDipanggil = 0;

  @override
  Future<TautanAkun> tautkanGoogle() async {
    tautDipanggil++;
    final akun = tautan.akun;
    if (akun != null) uid = akun.uid;
    return tautan;
  }

  @override
  Future<void> keluar() async {}

  void _periksaTulis() {
    if (galatTulis != null) throw galatTulis!;
  }

  @override
  Future<void> tulisProfil(ProfilDaring p) async {
    _periksaTulis();
    tulisProfilDipanggil++;
    profil[uid!] = p;
  }

  @override
  Future<void> tulisCadangan(CadanganProgres c) async {
    _periksaTulis();
    cadangan[uid!] = c;
  }

  @override
  Future<void> tulisSkor({
    required String weekId,
    required EntriLiga entri,
  }) async {
    _periksaTulis();
    tulisSkorDipanggil++;
    (this.entri[weekId] ??= {})[entri.uid] = entri;
  }

  @override
  Future<int> daftarkanLiga({
    required String weekId,
    required int ukuran,
  }) async {
    _periksaTulis();
    if (_isiLiga >= ukuran) {
      _ligaTerakhir++;
      _isiLiga = 0;
    }
    _isiLiga++;
    return _ligaTerakhir;
  }

  @override
  Future<List<EntriLiga>> bacaPapan({
    required String weekId,
    required int liga,
    required int batas,
  }) async {
    if (galatBaca != null) throw galatBaca!;
    final semua = entri[weekId]?.values ?? const <EntriLiga>[];
    return semua.where((e) => e.liga == liga).take(batas).toList();
  }

  @override
  Future<ProfilDaring?> bacaProfil() async => profil[uid];

  @override
  Future<CadanganProgres?> bacaCadangan() async => cadangan[uid];

  @override
  Future<void> hapusSemuaData() async {
    profil.remove(uid);
    cadangan.remove(uid);
    for (final minggu in entri.values) {
      minggu.remove(uid);
    }
  }

  @override
  Future<AturanNilai> aturanNilai() async => setelan;

  @override
  Future<void> catatGalat(
    Object galat,
    StackTrace jejak, {
    bool fatal = false,
  }) async => galatTercatat.add(galat);

  @override
  Future<void> setPenanda(String kunci, Object nilai) async {}

  /// Menaruh baris milik anak lain, supaya papan peringkatnya punya isi.
  void isiPapan(String weekId, List<EntriLiga> daftar) {
    for (final e in daftar) {
      (entri[weekId] ??= {})[e.uid] = e;
    }
  }
}
