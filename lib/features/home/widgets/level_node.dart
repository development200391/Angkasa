import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/enums.dart';
import '../../../domain/models/level_view.dart';
import '../../../shared/widgets/star_rating.dart';

/// Satu pos di lintasan.
///
/// Empat keadaan, dan ketiganya yang bukan aktif tetap terlihat: pos
/// yang belum terbuka digembok, bukan disembunyikan. Anak harus bisa
/// melihat jalan yang menunggunya — itu yang membuat pos berikutnya
/// terasa layak dikejar.
class LevelNode extends StatelessWidget {
  const LevelNode({
    required this.view,
    this.onTap,
    this.diameter = 62,
    super.key,
  });

  final LevelView view;
  final VoidCallback? onTap;
  final double diameter;

  static const _selesai = [
    Color(0xFF63CCA3),
    Color(0xFF2E8563),
    Color(0xFF134A37),
  ];
  static const _aktif = [
    Color(0xFFFFD98A),
    Color(0xFFE9B24C),
    Color(0xFF9C5E0B),
  ];
  static const _terkunci = [
    Color(0xFF3A4767),
    Color(0xFF232E4A),
    Color(0xFF141C31),
  ];

  bool get _isAktif =>
      view.status == LevelStatus.unlocked ||
      (view.status == LevelStatus.boss && !view.progress.isCompleted);

  List<Color> get _warna => switch (view.status) {
    LevelStatus.completed => _selesai,
    LevelStatus.locked => _terkunci,
    LevelStatus.boss => view.progress.isCompleted ? _selesai : _aktif,
    LevelStatus.unlocked => _aktif,
  };

  @override
  Widget build(BuildContext context) {
    final d = view.level.isBoss ? diameter + 4 : diameter;

    return Semantics(
      button: onTap != null,
      label: _labelSemantik,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: d + 40,
              height: d + 12,
              child: Stack(
                alignment: Alignment.topCenter,
                // Cahaya pos aktif dan cincin gerbang sengaja meluber
                // keluar kotaknya; tanpa ini Flutter memotongnya jadi
                // persegi dan halonya terlihat seperti kartu.
                clipBehavior: Clip.none,
                children: [
                  if (_isAktif)
                    Positioned(
                      top: -20,
                      child: Container(
                        width: d + 54,
                        height: d + 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.brandLight.withValues(alpha: 0.24),
                              AppColors.brandLight.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (view.level.isBoss)
                    Positioned(
                      top: -14,
                      child: CustomPaint(
                        size: Size(d + 28, d + 28),
                        painter: const _CincinGerbang(),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: d * 0.82,
                      height: d * 0.19,
                      decoration: BoxDecoration(
                        color: const Color(0xFF060B18).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.all(
                          Radius.elliptical(d * 0.41, d * 0.1),
                        ),
                      ),
                    ),
                  ),
                  _Bola(diameter: d, warna: _warna, isi: _isi(d)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            _bawah(),
          ],
        ),
      ),
    );
  }

  Widget _isi(double d) {
    if (view.status == LevelStatus.locked) {
      return Icon(
        Icons.lock_rounded,
        size: d * 0.36,
        color: const Color(0xFFAEBBD9),
      );
    }
    if (view.level.isBoss) {
      // Gerbang yang sudah tembus berbintang emas; yang menunggu
      // digambar pucat di atas bola emasnya. Bintang gembok hanya untuk
      // gerbang yang memang masih terkunci.
      return StarIcon(
        terisi: view.progress.isCompleted,
        gembok: view.isLocked,
        diAtasGelap: false,
        size: d * 0.5,
      );
    }
    return Text(
      '${view.level.orderIndex}',
      style: AppTextStyles.numeral.copyWith(
        fontSize: d * 0.34,
        color: view.status == LevelStatus.completed
            ? const Color(0xFFEAF6F1)
            : const Color(0xFF3A2405),
      ),
    );
  }

  Widget _bawah() {
    if (view.status == LevelStatus.unlocked ||
        (view.status == LevelStatus.boss && !view.progress.isCompleted)) {
      return const _LabelMulai();
    }
    if (view.stars > 0) {
      return StarRating(stars: view.stars, size: 15, gap: 0);
    }
    return const SizedBox(height: 16);
  }

  String get _labelSemantik {
    final nama = view.level.displayTitle;
    return switch (view.status) {
      LevelStatus.locked => '$nama, terkunci',
      LevelStatus.completed => '$nama, ${view.stars} bintang',
      _ => '$nama, siap dimulai',
    };
  }
}

class _Bola extends StatelessWidget {
  const _Bola({required this.diameter, required this.warna, required this.isi});

  final double diameter;
  final List<Color> warna;
  final Widget isi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.34, -0.46),
          radius: 0.82,
          colors: warna,
          stops: const [0, 0.48, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF060B18).withValues(alpha: 0.35),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(diameter), painter: const _KilauBola()),
          isi,
        ],
      ),
    );
  }
}

/// Kilau kiri-atas dan pantulan tipis di tepi bawah — dua sapuan yang
/// membuat bolanya terbaca timbul.
class _KilauBola extends CustomPainter {
  const _KilauBola();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final pusat = Offset(r, r);

    canvas.drawArc(
      Rect.fromCircle(center: pusat, radius: r - 2),
      0.36,
      2.42,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    final kilau = Rect.fromCenter(
      center: Offset(size.width * 0.34, size.height * 0.28),
      width: size.width * 0.34,
      height: size.height * 0.24,
    );
    canvas.save();
    canvas.translate(kilau.center.dx, kilau.center.dy);
    canvas.rotate(-0.49);
    canvas.translate(-kilau.center.dx, -kilau.center.dy);
    canvas.drawOval(
      kilau,
      Paint()..color = Colors.white.withValues(alpha: 0.34),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _KilauBola oldDelegate) => false;
}

/// Cincin putus-putus di sekeliling Gerbang Planet — portal, bukan pos.
class _CincinGerbang extends CustomPainter {
  const _CincinGerbang();

  @override
  void paint(Canvas canvas, Size size) {
    final cat = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF3A4767);
    final r = size.width / 2;
    const potong = 0.28;
    for (var a = 0.0; a < 6.28; a += potong * 2) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(r, r), radius: r - 2),
        a,
        potong,
        false,
        cat,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CincinGerbang oldDelegate) => false;
}

/// Pil "MULAI" di bawah pos aktif. Satu-satunya ajakan di seluruh peta —
/// kalau ada dua, anak harus memilih dulu sebelum mulai.
class _LabelMulai extends StatelessWidget {
  const _LabelMulai();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.brandLight,
        borderRadius: BorderRadius.circular(13),
        boxShadow: const [
          BoxShadow(color: Color(0xFF8A5209), offset: Offset(0, 2)),
        ],
      ),
      child: const Text(
        'MULAI',
        style: TextStyle(
          fontFamily: AppTextStyles.family,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: Color(0xFF3A2405),
        ),
      ),
    );
  }
}
