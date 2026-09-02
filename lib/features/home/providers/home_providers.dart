import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Zona yang sedang dilihat di peta.
///
/// `null` berarti "ikuti zona aktif" — yang dihitung dari progres. Baru
/// terisi kalau anak memilih zona lain sendiri lewat chip zona, dan
/// kembali kosong tiap kali planetnya berganti.
class ZonaTerpilih extends Notifier<String?> {
  @override
  String? build() => null;

  void pilih(String chapterId) => state = chapterId;

  void ikutiProgres() => state = null;
}

final zonaTerpilihProvider = NotifierProvider<ZonaTerpilih, String?>(
  ZonaTerpilih.new,
);
