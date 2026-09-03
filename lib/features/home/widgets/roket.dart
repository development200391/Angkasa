import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Roket Angkasa — bentuk yang sama persis dengan ikon peluncur.
///
/// Jalurnya diambil dari `design/ui.html`, dalam sistem koordinat
/// −30…30. Digambar, bukan diimpor: roket yang sama muncul di ikon
/// aplikasi, di splash, dan di layar Lepas Landas, dan ketiganya tidak
/// boleh berbeda satu piksel pun.
abstract final class RoketPainter {
  static final _badan = Path()
    ..moveTo(0, -30)
    ..cubicTo(12, -18, 15, -2, 13, 12)
    ..lineTo(-13, 12)
    ..cubicTo(-15, -2, -12, -18, 0, -30)
    ..close();

  static final _siripKiri = Path()
    ..moveTo(-13, 4)
    ..lineTo(-25, 18)
    ..lineTo(-13, 15)
    ..close();

  static final _siripKanan = Path()
    ..moveTo(13, 4)
    ..lineTo(25, 18)
    ..lineTo(13, 15)
    ..close();

  static final _ekor = Path()
    ..moveTo(-6, 14)
    ..quadraticBezierTo(0, 30, 6, 14)
    ..close();

  /// Menggambar roket berpusat di [pusat] dengan tinggi kira-kira
  /// dua kali [radius].
  static void gambarRoket(Canvas canvas, Offset pusat, double radius) {
    canvas.save();
    canvas.translate(pusat.dx, pusat.dy);
    canvas.scale(radius / 30);

    canvas.drawPath(_badan, Paint()..color = AppColors.brandLight);
    // Jendela dilubangi, bukan ditimpa — siluetnya tetap terbaca sebagai
    // roket waktu semua detail lain hilang.
    canvas.drawCircle(
      const Offset(0, -9),
      6.5,
      Paint()..color = AppColors.space,
    );

    final putih = Paint()..color = const Color(0xFFF5F7FF);
    canvas.drawPath(_siripKiri, putih);
    canvas.drawPath(_siripKanan, putih);
    canvas.drawPath(_ekor, putih);

    canvas.restore();
  }

  /// Semburan api. [dorongan] 1 = menyala tenang, 3 = melesat.
  static void gambarApi(
    Canvas canvas,
    Offset pusat,
    double radius,
    double dorongan,
  ) {
    final lebar = radius * 0.5;
    final panjang = radius * 1.1 * dorongan;
    final atas = pusat.dy + radius * 0.5;

    final jalur = Path()
      ..moveTo(pusat.dx, atas + panjang)
      ..cubicTo(
        pusat.dx - lebar,
        atas + panjang * 0.45,
        pusat.dx - lebar * 0.55,
        atas,
        pusat.dx,
        atas - radius * 0.1,
      )
      ..cubicTo(
        pusat.dx + lebar * 0.55,
        atas,
        pusat.dx + lebar,
        atas + panjang * 0.45,
        pusat.dx,
        atas + panjang,
      )
      ..close();

    canvas.drawPath(
      jalur,
      Paint()
        ..shader =
            const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFE7B0), Color(0xFFE9863A), Color(0x00A83B12)],
              stops: [0, 0.45, 1],
            ).createShader(
              Rect.fromLTRB(
                pusat.dx - lebar,
                atas - radius * 0.1,
                pusat.dx + lebar,
                atas + panjang,
              ),
            ),
    );
  }
}

/// Roket sebagai widget, untuk dipakai di luar adegan animasi.
class Roket extends StatelessWidget {
  const Roket({this.size = 64, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _RoketWidgetPainter()),
  );
}

class _RoketWidgetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => RoketPainter.gambarRoket(
    canvas,
    Offset(size.width / 2, size.height / 2),
    size.width / 2,
  );

  @override
  bool shouldRepaint(covariant _RoketWidgetPainter oldDelegate) => false;
}
