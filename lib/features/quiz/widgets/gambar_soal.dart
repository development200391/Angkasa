import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/gambar.dart';

/// Menggambar [Gambar] yang menyertai sebuah soal.
///
/// Empat bentuk, satu aturan yang sama untuk semuanya: **gambar ini
/// tidak boleh jadi satu-satunya sumber angkanya.** Seluruh ukuran yang
/// dibutuhkan sudah disebut di kalimat soalnya, dan yang ditambahkan di
/// sini cuma cara lain melihatnya. Anak yang memakai pembaca layar
/// tetap dapat soal yang utuh.
///
/// Yang membuat semua ini pantas ada: petak di persegi panjang bisa
/// **benar-benar dihitung**. Anak kelas 4 yang lupa rumus luas tidak
/// mentok — ia menghitung 40 kotak satu per satu dan tetap sampai ke
/// jawaban yang benar. Itu jalan keluar yang tidak bisa diberikan
/// sebuah gambar tetap.
class GambarSoal extends StatelessWidget {
  const GambarSoal({required this.gambar, this.diAtasGelap = false, super.key});

  final Gambar gambar;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) => switch (gambar) {
    final GambarPersegiPanjang g => _PersegiPanjang(
      gambar: g,
      diAtasGelap: diAtasGelap,
    ),
    final GambarSegitiga g => _Segitiga(gambar: g, diAtasGelap: diAtasGelap),
    final GambarBatang g => _Batang(gambar: g, diAtasGelap: diAtasGelap),
    final GambarBenda g => _Benda(gambar: g, diAtasGelap: diAtasGelap),
  };
}

Color _tinta(bool gelap) => gelap ? AppColors.inkOnSpace : AppColors.ink;
Color _tinta2(bool gelap) => gelap ? AppColors.ink2OnSpace : AppColors.ink2;
Color _tinta3(bool gelap) => gelap ? AppColors.ink3OnSpace : AppColors.ink3;

// =====================================================================
// Persegi panjang berpetak
// =====================================================================
class _PersegiPanjang extends StatelessWidget {
  const _PersegiPanjang({required this.gambar, required this.diAtasGelap});

  final GambarPersegiPanjang gambar;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    // Sisinya digambar sebanding, tapi dibatasi supaya persegi panjang
    // 15 × 2 tidak jadi garis setipis benang yang petaknya mustahil
    // dihitung.
    final rasio = (gambar.lebar / gambar.panjang).clamp(0.35, 1.0);

    return LayoutBuilder(
      builder: (context, batas) {
        final lebarGambar = batas.maxWidth.clamp(0.0, 300.0);
        final tinggiGambar = lebarGambar * rasio * 0.62;
        return SizedBox(
          width: lebarGambar,
          height: tinggiGambar + 46,
          child: CustomPaint(
            painter: _PelukisPersegiPanjang(
              gambar: gambar,
              tinta: _tinta(diAtasGelap),
              tinta3: _tinta3(diAtasGelap),
              gelap: diAtasGelap,
            ),
          ),
        );
      },
    );
  }
}

class _PelukisPersegiPanjang extends CustomPainter {
  _PelukisPersegiPanjang({
    required this.gambar,
    required this.tinta,
    required this.tinta3,
    required this.gelap,
  });

  final GambarPersegiPanjang gambar;
  final Color tinta;
  final Color tinta3;
  final bool gelap;

  static const _garis = AppColors.pecah;

  @override
  void paint(Canvas canvas, Size size) {
    const atas = 24.0;
    const kanan = 46.0;
    final kotak = Rect.fromLTWH(
      6,
      atas,
      size.width - kanan - 6,
      size.height - atas - 22,
    );

    final isi = Paint()..color = _garis.withValues(alpha: gelap ? 0.20 : 0.10);
    final tepi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = _garis;
    canvas.drawRRect(
      RRect.fromRectAndRadius(kotak, const Radius.circular(4)),
      isi,
    );

    // Petak bantunya — inti seluruh soal ini. Digambar sebelum tepinya
    // supaya garis tepi tetap yang paling tegas.
    if (gambar.petakTerbaca) {
      final petak = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _garis.withValues(alpha: 0.40);
      for (var i = 1; i < gambar.panjang; i++) {
        final x = kotak.left + kotak.width * i / gambar.panjang;
        canvas.drawLine(Offset(x, kotak.top), Offset(x, kotak.bottom), petak);
      }
      for (var i = 1; i < gambar.lebar; i++) {
        final y = kotak.top + kotak.height * i / gambar.lebar;
        canvas.drawLine(Offset(kotak.left, y), Offset(kotak.right, y), petak);
      }
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(kotak, const Radius.circular(4)),
      tepi,
    );

    final ukur = Paint()
      ..strokeWidth = 1.6
      ..color = tinta3;

    // Garis ukuran di atas, dengan siku di kedua ujungnya.
    const yAtas = 12.0;
    canvas.drawLine(
      Offset(kotak.left, yAtas),
      Offset(kotak.right, yAtas),
      ukur,
    );
    canvas.drawLine(
      Offset(kotak.left, yAtas - 4),
      Offset(kotak.left, yAtas + 4),
      ukur,
    );
    canvas.drawLine(
      Offset(kotak.right, yAtas - 4),
      Offset(kotak.right, yAtas + 4),
      ukur,
    );
    _teks(
      canvas,
      '${gambar.panjang} ${gambar.satuan}',
      Offset(kotak.center.dx, 0),
      tinta,
      tengah: true,
    );

    // Dan di kanan.
    final xKanan = kotak.right + 14;
    canvas.drawLine(
      Offset(xKanan, kotak.top),
      Offset(xKanan, kotak.bottom),
      ukur,
    );
    canvas.drawLine(
      Offset(xKanan - 4, kotak.top),
      Offset(xKanan + 4, kotak.top),
      ukur,
    );
    canvas.drawLine(
      Offset(xKanan - 4, kotak.bottom),
      Offset(xKanan + 4, kotak.bottom),
      ukur,
    );
    _teks(
      canvas,
      '${gambar.lebar} ${gambar.satuan}',
      Offset(xKanan + 6, kotak.center.dy - 8),
      tinta,
    );
  }

  @override
  bool shouldRepaint(_PelukisPersegiPanjang old) =>
      old.gambar.panjang != gambar.panjang ||
      old.gambar.lebar != gambar.lebar ||
      old.tinta != tinta;
}

// =====================================================================
// Segitiga dengan alas dan tinggi
// =====================================================================
class _Segitiga extends StatelessWidget {
  const _Segitiga({required this.gambar, required this.diAtasGelap});

  final GambarSegitiga gambar;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, batas) {
      final lebar = batas.maxWidth.clamp(0.0, 280.0);
      return SizedBox(
        width: lebar,
        height: 150,
        child: CustomPaint(
          painter: _PelukisSegitiga(
            gambar: gambar,
            tinta: _tinta(diAtasGelap),
            tinta3: _tinta3(diAtasGelap),
            gelap: diAtasGelap,
          ),
        ),
      );
    },
  );
}

class _PelukisSegitiga extends CustomPainter {
  _PelukisSegitiga({
    required this.gambar,
    required this.tinta,
    required this.tinta3,
    required this.gelap,
  });

  final GambarSegitiga gambar;
  final Color tinta;
  final Color tinta3;
  final bool gelap;

  static const _garis = AppColors.pecah;

  @override
  void paint(Canvas canvas, Size size) {
    final kiri = 22.0;
    final kanan = size.width - 58;
    final bawah = size.height - 26;
    final atas = 18.0;

    // Puncaknya sengaja tidak di tengah: segitiga sama kaki membuat
    // anak mengira tinggi selalu jatuh di tengah alas.
    final puncakX = kiri + (kanan - kiri) * 0.34;

    final jalur = Path()
      ..moveTo(kiri, bawah)
      ..lineTo(kanan, bawah)
      ..lineTo(puncakX, atas)
      ..close();

    canvas.drawPath(
      jalur,
      Paint()..color = _garis.withValues(alpha: gelap ? 0.20 : 0.10),
    );
    canvas.drawPath(
      jalur,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..color = _garis,
    );

    // Tingginya putus-putus, dengan siku di kakinya. Tanpa siku itu,
    // anak yang mengira sisi miring adalah tinggi tidak punya apa pun
    // yang membantahnya.
    final putus = Paint()
      ..strokeWidth = 1.8
      ..color = tinta3;
    for (var y = atas; y < bawah; y += 8) {
      canvas.drawLine(
        Offset(puncakX, y),
        Offset(puncakX, (y + 4).clamp(atas, bawah)),
        putus,
      );
    }
    canvas.drawRect(
      Rect.fromLTWH(puncakX, bawah - 9, 9, 9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = tinta3,
    );

    _teks(
      canvas,
      '${gambar.tinggi} ${gambar.satuan}',
      Offset(puncakX + 8, (atas + bawah) / 2 - 8),
      tinta,
    );
    _teks(
      canvas,
      '${gambar.alas} ${gambar.satuan}',
      Offset((kiri + kanan) / 2, bawah + 6),
      tinta,
      tengah: true,
    );
  }

  @override
  bool shouldRepaint(_PelukisSegitiga old) =>
      old.gambar.alas != gambar.alas ||
      old.gambar.tinggi != gambar.tinggi ||
      old.tinta != tinta;
}

void _teks(
  Canvas canvas,
  String isi,
  Offset di,
  Color warna, {
  bool tengah = false,
}) {
  final tp = TextPainter(
    text: TextSpan(
      text: isi,
      style: TextStyle(
        fontFamily: AppTextStyles.family,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: warna,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, tengah ? Offset(di.dx - tp.width / 2, di.dy) : di);
}

// =====================================================================
// Diagram batang
// =====================================================================
class _Batang extends StatelessWidget {
  const _Batang({required this.gambar, required this.diAtasGelap});

  final GambarBatang gambar;
  final bool diAtasGelap;

  /// Satu warna untuk semua batang. **Panjangnya yang membawa angka,
  /// bukan warnanya** — mewarnai tiap batang berbeda menyiratkan
  /// kategorinya berbeda, padahal yang dibandingkan justru besarnya.
  static const _warna = AppColors.ruang;

  @override
  Widget build(BuildContext context) {
    final tertinggi = gambar.tertinggi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (gambar.judul.isNotEmpty) ...[
          Text(
            gambar.judul,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _tinta2(diAtasGelap),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          height: 118,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in gambar.data)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Nilainya tetap ditulis. Membaca diagram memang
                        // bagian dari soalnya, tapi menyembunyikan
                        // angkanya mengubah soal statistik jadi soal
                        // mengukur dengan mata.
                        Text(
                          '${d.nilai}',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _tinta2(diAtasGelap),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          height: (96 * d.nilai / tertinggi).clamp(4.0, 96.0),
                          constraints: const BoxConstraints(maxWidth: 34),
                          decoration: const BoxDecoration(
                            color: _warna,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Container(
          height: 1.5,
          color: diAtasGelap ? AppColors.lineOnSpace : AppColors.line,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final d in gambar.data)
              Expanded(
                child: Text(
                  d.label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11,
                    color: _tinta3(diAtasGelap),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// =====================================================================
// Sekumpulan benda untuk soal cerita
// =====================================================================
class _Benda extends StatelessWidget {
  const _Benda({required this.gambar, required this.diAtasGelap});

  final GambarBenda gambar;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    // Di atas sepuluh, barisnya berhenti membantu dan mulai jadi
    // teka-teki menghitung emoji. Yang tampil angkanya saja.
    final barisan = gambar.terlaluBanyak
        ? Text(
            '${gambar.jumlah} × ${gambar.emoji}',
            style: AppTextStyles.h2.copyWith(color: _tinta(diAtasGelap)),
          )
        : Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < gambar.jumlah; i++)
                Text(gambar.emoji, style: const TextStyle(fontSize: 26)),
            ],
          );

    return Column(
      children: [
        if (gambar.catatan != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: diAtasGelap
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.okSoft,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              gambar.catatan!,
              style: AppTextStyles.title.copyWith(
                fontSize: 15,
                color: diAtasGelap ? AppColors.inkOnSpace : AppColors.ok,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        barisan,
        if (gambar.keterangan != null) ...[
          const SizedBox(height: 7),
          Text(
            gambar.keterangan!,
            style: AppTextStyles.caption.copyWith(color: _tinta3(diAtasGelap)),
          ),
        ],
      ],
    );
  }
}
