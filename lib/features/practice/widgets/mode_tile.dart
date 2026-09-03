import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/pressable_3d.dart';

/// Satu kartu mode latihan.
///
/// Ikonnya bergradien dan kartunya punya tebal — bentuk yang sama dengan
/// tombol utama, jadi anak langsung tahu benda ini bisa ditekan tanpa
/// perlu satu pun kata "ketuk di sini".
class ModeTile extends StatelessWidget {
  const ModeTile({
    required this.ikon,
    required this.gradien,
    required this.judul,
    required this.isi,
    this.onTap,
    this.pil,
    this.warnaPil,
    this.warnaTeksPil,
    this.garis,
    super.key,
  });

  final IconData ikon;
  final List<Color> gradien;
  final String judul;
  final String isi;
  final VoidCallback? onTap;

  /// Label kecil di kanan: angka merah, "XP ×2", atau "selesai".
  final String? pil;
  final Color? warnaPil;
  final Color? warnaTeksPil;
  final Color? garis;

  @override
  Widget build(BuildContext context) {
    final mati = onTap == null;
    return Opacity(
      opacity: mati ? 0.62 : 1,
      child: Pressable3D(
        onPressed: onTap,
        depth: 5,
        depthPressed: 1,
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F6FB)],
        ),
        border: Border.all(color: garis ?? const Color(0xFFDBE2ED), width: 1.5),
        bodyColor: const Color(0xFFD8DFEA),
        dropShadow: BoxShadow(
          color: const Color(0xFF1C2840).withValues(alpha: 0.3),
          offset: const Offset(0, 10),
          blurRadius: 14,
          spreadRadius: -8,
        ),
        highlight: false,
        padding: const EdgeInsets.fromLTRB(15, 15, 17, 15),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: gradien,
                ),
                boxShadow: [
                  BoxShadow(
                    color: gradien.last.withValues(alpha: 0.45),
                    offset: const Offset(0, 5),
                    blurRadius: 10,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Icon(ikon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: AppTextStyles.title),
                  const SizedBox(height: 2),
                  Text(isi, style: AppTextStyles.caption),
                ],
              ),
            ),
            if (pil != null) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: warnaPil ?? AppColors.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  pil!,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: warnaTeksPil ?? AppColors.ink2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
