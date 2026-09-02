import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'pressable_3d.dart';

/// Tombol utama — emas, tebal, dan satu-satunya yang boleh berwarna
/// penuh di sebuah layar. Kalau ada dua tombol emas dalam satu layar,
/// salah satunya salah.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.height = 56,
    this.warna,
    this.warnaBadan,
    super.key,
  });

  /// Varian merah untuk sheet jawaban salah.
  const PrimaryButton.salah({
    required this.label,
    this.onPressed,
    this.height = 56,
    super.key,
  }) : warna = AppColors.wrong,
       warnaBadan = AppColors.wrongButtonBody;

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final Color? warna;
  final Color? warnaBadan;

  @override
  Widget build(BuildContext context) {
    final mati = onPressed == null;
    return Opacity(
      opacity: mati ? 0.55 : 1,
      child: Pressable3D(
        onPressed: onPressed,
        height: height,
        borderRadius: BorderRadius.circular(20),
        gradient: warna == null ? AppColors.primaryButtonGradient : null,
        color: warna,
        bodyColor: warnaBadan ?? AppColors.primaryButtonBody,
        dropShadow: BoxShadow(
          color: const Color(0xFF342002).withValues(alpha: 0.55),
          offset: const Offset(0, 13),
          blurRadius: 18,
          spreadRadius: -7,
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.button.copyWith(
              color: Colors.white,
              shadows: const [
                Shadow(color: Color(0x734A2C03), offset: Offset(0, 1.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tombol kedua: bergaris, tanpa tebal. Selalu berpasangan dengan
/// [PrimaryButton] dan tidak pernah berdiri sendiri sebagai aksi utama.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    this.onPressed,
    this.diAtasGelap = false,
    this.height = 52,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool diAtasGelap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final garis = diAtasGelap
        ? Colors.white.withValues(alpha: 0.18)
        : AppColors.line;
    final teks = diAtasGelap ? const Color(0xFFB8C5DE) : AppColors.ink2;
    return SizedBox(
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: garis, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          foregroundColor: teks,
        ),
        child: Text(
          label,
          style: AppTextStyles.button.copyWith(fontSize: 16, color: teks),
        ),
      ),
    );
  }
}

/// Tautan teks polos, untuk aksi yang boleh dilewati.
class GhostButton extends StatelessWidget {
  const GhostButton({
    required this.label,
    this.onPressed,
    this.diAtasGelap = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool diAtasGelap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: diAtasGelap ? AppColors.ink2OnSpace : AppColors.ink2,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.body.copyWith(
          fontSize: 15.5,
          color: diAtasGelap ? AppColors.ink2OnSpace : AppColors.ink2,
        ),
      ),
    );
  }
}
