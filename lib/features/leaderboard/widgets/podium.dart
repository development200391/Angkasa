import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../domain/models/liga.dart';
import '../../onboarding/widgets/avatar_grid.dart';

/// Tiga teratas, dengan podium yang tingginya berbeda.
///
/// Urutan tampilnya 2 – 1 – 3, bukan 1 – 2 – 3. Itu bentuk podium yang
/// sudah dikenal semua anak tanpa perlu dijelaskan, dan yang membuat
/// juara pertama berada di tengah tanpa satu pun label tambahan.
class Podium extends StatelessWidget {
  const Podium({required this.tiga, this.uidSaya, super.key});

  final List<EntriLiga> tiga;
  final String? uidSaya;

  @override
  Widget build(BuildContext context) {
    if (tiga.isEmpty) return const SizedBox.shrink();

    // 2 – 1 – 3. Kalau pemainnya belum tiga, yang kosong tidak digambar
    // sama sekali; kotak abu tanpa isi terlihat seperti kerusakan.
    final urutan = <(int, EntriLiga)>[
      if (tiga.length > 1) (2, tiga[1]),
      (1, tiga[0]),
      if (tiga.length > 2) (3, tiga[2]),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (posisi, entri) in urutan)
          Expanded(
            child: _Tiang(
              posisi: posisi,
              entri: entri,
              saya: entri.uid == uidSaya,
            ),
          ),
      ],
    );
  }
}

class _Tiang extends StatelessWidget {
  const _Tiang({required this.posisi, required this.entri, required this.saya});

  final int posisi;
  final EntriLiga entri;
  final bool saya;

  static const _emas = [
    Color(0xFFF3CB7C),
    Color(0xFFE0A63F),
    Color(0xFF8E5709),
  ];
  static const _perak = [
    Color(0xFFEDF0F5),
    Color(0xFFCDD5E0),
    Color(0xFF9AA5B8),
  ];
  static const _perunggu = [
    Color(0xFFF0CBA6),
    Color(0xFFCE9358),
    Color(0xFF7A4E22),
  ];

  @override
  Widget build(BuildContext context) {
    final juara = posisi == 1;
    final warna = switch (posisi) {
      1 => _emas,
      2 => _perak,
      _ => _perunggu,
    };
    final ukuran = juara ? 66.0 : 52.0;
    final tinggiTiang = switch (posisi) {
      1 => 82.0,
      2 => 58.0,
      _ => 44.0,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: ukuran,
          height: ukuran,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.32, -0.44),
              radius: 0.9,
              colors: warna,
              stops: const [0, 0.46, 1],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF060B18).withValues(alpha: 0.55),
                offset: const Offset(0, 6),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Icon(
            Avatar.cari(entri.avatarId).ikon,
            size: ukuran * 0.44,
            color: warna.last,
          ),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 34,
          child: Text(
            entri.nickname,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: juara ? AppColors.brandLight : AppColors.inkOnSpace,
            ),
          ),
        ),
        Text(
          '${entri.xp} XP',
          style: AppTextStyles.caption.copyWith(
            fontSize: 11.5,
            color: AppColors.ink3OnSpace,
            fontFeatures: const [AppTextStyles.tabular],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: tinggiTiang,
          margin: const EdgeInsets.symmetric(horizontal: 7),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 9),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(
              color: saya
                  ? AppColors.brandLight.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.10),
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.03),
              ],
            ),
          ),
          child: Text(
            '$posisi',
            style: AppTextStyles.numeral.copyWith(
              fontSize: 19,
              color: juara ? AppColors.brandLight : AppColors.ink2OnSpace,
            ),
          ),
        ),
      ],
    );
  }
}

/// Satu baris di bawah podium.
class BarisPeringkat extends StatelessWidget {
  const BarisPeringkat({
    required this.posisi,
    required this.entri,
    this.saya = false,
    super.key,
  });

  final int posisi;
  final EntriLiga entri;
  final bool saya;

  @override
  Widget build(BuildContext context) {
    final avatar = Avatar.cari(entri.avatarId);

    return Semantics(
      label: saya
          ? 'Kamu, peringkat $posisi, ${entri.xp} XP'
          : '${entri.nickname}, peringkat $posisi, ${entri.xp} XP',
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: saya
              ? AppColors.brandLight.withValues(alpha: 0.14)
              : Colors.transparent,
          border: saya
              ? Border.all(color: AppColors.brandLight.withValues(alpha: 0.42))
              : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$posisi',
                textAlign: TextAlign.center,
                style: AppTextStyles.numeral.copyWith(
                  fontSize: 14.5,
                  color: saya ? AppColors.brandLight : AppColors.ink3OnSpace,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    avatar.warna,
                    Color.lerp(avatar.warna, Colors.black, 0.34)!,
                  ],
                ),
              ),
              child: Icon(avatar.ikon, size: 17, color: Colors.white),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                saya ? 'Kamu' : entri.nickname,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14.5,
                  fontWeight: saya ? FontWeight.w600 : FontWeight.w400,
                  color: saya ? AppColors.brandLight : AppColors.inkOnSpace,
                ),
              ),
            ),
            Text(
              '${entri.xp}',
              style: AppTextStyles.numeral.copyWith(
                fontSize: 15,
                color: saya ? AppColors.brandLight : AppColors.ink2OnSpace,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
