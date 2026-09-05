import 'package:angkasa/data/remote/purchase_gateway.dart';

/// Toko tiruan untuk uji.
///
/// Bedanya dengan [GatewayBeliLuring]: yang ini bisa **berhasil**.
/// Yang luring dipakai build sungguhan tanpa toko dan selalu menolak;
/// yang ini dipakai uji untuk memainkan tiap akhir yang mungkin —
/// termasuk yang paling sulit ditemui di HP, seperti pembayaran yang
/// tertunda berjam-jam lewat transfer bank.
class TokoTiruan implements PurchaseGateway {
  TokoTiruan({this.tersedia = true, this.harga = 'Rp 49.000'});

  @override
  bool tersedia;

  String harga;

  /// Kalau `false`, produknya dianggap belum aktif di Play Console.
  bool produkAda = true;

  /// Yang dipulangkan [beli].
  HasilBeli hasilBeli = HasilBeli.berhasil;

  /// Yang dipulangkan [pulihkan].
  List<PembelianDaring> riwayat = const [];

  /// Kalau terisi, tiap panggilan melemparnya.
  Object? galat;

  int beliDipanggil = 0;
  int pulihkanDipanggil = 0;

  @override
  Future<void> siapkan() async {}

  @override
  Future<ProdukBeli?> produk(String id) async {
    if (galat != null) throw galat!;
    if (!tersedia || !produkAda) return null;
    return ProdukBeli(id: id, harga: harga, judul: 'Semua planet');
  }

  @override
  Future<HasilBeli> beli(String id) async {
    beliDipanggil++;
    if (galat != null) throw galat!;
    if (!tersedia) return HasilBeli.tidakAdaToko;
    return hasilBeli;
  }

  @override
  Future<List<PembelianDaring>> pulihkan() async {
    pulihkanDipanggil++;
    if (galat != null) throw galat!;
    return riwayat;
  }

  @override
  Future<void> tutup() async {}
}
