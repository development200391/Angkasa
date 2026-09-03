import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/engine/badge_rules.dart';

/// Medali lencana.
///
/// Emas kalau sudah didapat, perak pucat kalau belum — dan yang belum
/// **tetap ditampilkan namanya**. Nama yang terbaca jauh lebih memancing
/// daripada kotak abu tanpa keterangan; itu yang memberi tahu anak ada
/// tujuan berikutnya.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    required this.ikon,
    required this.didapat,
    this.size = 74,
    super.key,
  });

  final String ikon;
  final bool didapat;
  final double size;

  /// Kunci ikon dari katalog domain dipetakan jadi ikon Material di
  /// sini — domain tidak perlu tahu apa pun tentang Flutter.
  static IconData ikonUntuk(String kunci) => switch (kunci) {
    'bintang' => Icons.star_rounded,
    'api' => Icons.local_fire_department_rounded,
    'centang' => Icons.check_rounded,
    'kilat' => Icons.bolt_rounded,
    'planet' => Icons.public_rounded,
    'roket' => Icons.rocket_launch_rounded,
    'perbaiki' => Icons.refresh_rounded,
    'kalender' => Icons.calendar_month_rounded,
    'jalur' => Icons.timeline_rounded,
    'perisai' => Icons.shield_rounded,
    'xp' => Icons.auto_awesome_rounded,
    _ => Icons.emoji_events_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.32, -0.44),
          radius: 0.9,
          colors: didapat
              ? const [Color(0xFFF3CB7C), Color(0xFFE0A63F), Color(0xFF8E5709)]
              : const [Color(0xFFEDF0F5), Color(0xFFCDD5E0), Color(0xFF9AA5B8)],
          stops: const [0, 0.46, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF141E34)
                .withValues(alpha: didapat ? 0.5 : 0.35),
            offset: const Offset(0, 6),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Icon(
        ikonUntuk(ikon),
        size: size * 0.42,
        color: didapat ? const Color(0xFF7A4707) : const Color(0xFF8C97A8),
      ),
    );
  }
}

/// Medali beserta namanya, satu sel di kisi Lencana.
class BadgeCell extends StatelessWidget {
  const BadgeCell({
    required this.code,
    required this.didapat,
    this.size = 74,
    this.tampilkanNama = true,
    super.key,
  });

  final String code;
  final bool didapat;
  final double size;
  final bool tampilkanNama;

  @override
  Widget build(BuildContext context) {
    final def = BadgeRules.cari(code);
    if (def == null) return const SizedBox.shrink();

    return Semantics(
      label: didapat
          ? '${def.nama}, sudah didapat'
          : '${def.nama}, terkunci. ${def.keterangan}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeMedal(ikon: def.ikon, didapat: didapat, size: size),
          if (tampilkanNama) ...[
            const SizedBox(height: 9),
            Text(
              def.nama,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 11.5,
                height: 1.3,
                fontWeight: didapat ? FontWeight.w600 : FontWeight.w400,
                color: didapat ? AppColors.ink2 : AppColors.ink3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
