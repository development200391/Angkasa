import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/pressable_3d.dart';

/// Kotak jawaban isian.
///
/// Angkanya besar dan tabular, dengan kursor yang tidak berkedip —
/// kedipan menarik mata terus-menerus ke tempat yang sudah jelas.
class JawabanBox extends StatelessWidget {
  const JawabanBox({required this.isi, this.benar, super.key});

  final String isi;

  /// `null` selama belum dinilai.
  final bool? benar;

  @override
  Widget build(BuildContext context) {
    final warna = switch (benar) {
      true => AppColors.ok,
      false => AppColors.wrong,
      _ => AppColors.brand,
    };
    return Container(
      height: 70,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna, width: 2.5),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F6FB), Color(0xFFFFFFFF)],
          stops: [0, 0.62],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(isi, style: AppTextStyles.question.copyWith(fontSize: 32)),
          const SizedBox(width: 3),
          Container(width: 2, height: 32, color: warna),
        ],
      ),
    );
  }
}

/// Papan angka.
///
/// Dibuat sendiri, bukan memakai papan ketik sistem: tombolnya jadi
/// cukup besar untuk jempol anak, tidak ada tombol emoji atau salin, dan
/// layarnya tidak pernah melompat waktu papan ketik muncul.
class Keypad extends StatelessWidget {
  const Keypad({
    required this.onAngka,
    required this.onHapus,
    required this.onKirim,
    this.aktif = true,
    super.key,
  });

  final ValueChanged<String> onAngka;
  final VoidCallback onHapus;
  final VoidCallback onKirim;
  final bool aktif;

  @override
  Widget build(BuildContext context) {
    Widget baris(List<Widget> anak) => Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          for (var i = 0; i < anak.length; i++) ...[
            if (i > 0) const SizedBox(width: 9),
            Expanded(child: anak[i]),
          ],
        ],
      ),
    );

    return Column(
      children: [
        baris([_angka('1'), _angka('2'), _angka('3')]),
        baris([_angka('4'), _angka('5'), _angka('6')]),
        baris([_angka('7'), _angka('8'), _angka('9')]),
        baris([
          _Tombol(
            onTap: aktif ? onHapus : null,
            warna: const Color(0xFFE3E8F0),
            badan: const Color(0xFFC8D0DD),
            child: const Icon(
              Icons.backspace_outlined,
              size: 22,
              color: AppColors.ink2,
            ),
          ),
          _angka('0'),
          _Tombol(
            onTap: aktif ? onKirim : null,
            warna: AppColors.brand,
            badan: const Color(0xFF97600C),
            child: const Icon(
              Icons.check_rounded,
              size: 26,
              color: Colors.white,
            ),
          ),
        ]),
      ],
    );
  }

  Widget _angka(String n) => _Tombol(
    onTap: aktif ? () => onAngka(n) : null,
    child: Text(n, style: AppTextStyles.option.copyWith(fontSize: 24)),
  );
}

class _Tombol extends StatelessWidget {
  const _Tombol({required this.child, this.onTap, this.warna, this.badan});

  final Widget child;
  final VoidCallback? onTap;
  final Color? warna;
  final Color? badan;

  @override
  Widget build(BuildContext context) {
    return Pressable3D(
      onPressed: onTap,
      height: 58,
      depth: 4,
      depthPressed: 1,
      borderRadius: BorderRadius.circular(17),
      gradient: warna == null
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFFFF), Color(0xFFF1F4FA)],
            )
          : null,
      color: warna,
      bodyColor: badan ?? const Color(0xFFD5DCE7),
      border: Border.all(color: warna ?? const Color(0xFFD6DDE8), width: 1.5),
      highlight: false,
      child: Center(child: child),
    );
  }
}
