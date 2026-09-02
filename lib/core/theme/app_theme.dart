import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// Dua tema. Yang terang dipakai layar kuis dan sheet; yang gelap dipakai
/// peta lintasan, onboarding, dan layar hasil — semua yang berlatar angkasa.
abstract final class AppTheme {
  static ThemeData get light => _build(
    brightness: Brightness.light,
    scaffold: AppColors.bg,
    surface: AppColors.surface,
    primary: AppColors.brand,
    ink: AppColors.ink,
    ink2: AppColors.ink2,
    outline: AppColors.line,
  );

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    scaffold: AppColors.space,
    surface: AppColors.space2,
    primary: AppColors.brandLight,
    ink: AppColors.inkOnSpace,
    ink2: AppColors.ink2OnSpace,
    outline: const Color(0xFF2A3654),
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color primary,
    required Color ink,
    required Color ink2,
    required Color outline,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          brightness: brightness,
        ).copyWith(
          primary: primary,
          surface: surface,
          onSurface: ink,
          error: AppColors.wrong,
          outline: outline,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: AppTextStyles.family,
      textTheme: AppTextStyles.textTheme(ink, ink2),
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(color: ink),
        iconTheme: IconThemeData(color: ink2),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      // Tanpa ini Material 3 mewarnai dialog dari warna merek dan
      // hasilnya kartu peach yang tidak ada di palet mana pun.
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: AppTextStyles.h2.copyWith(color: AppColors.ink),
        contentTextStyle: AppTextStyles.sub,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: AppTextStyles.body.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
