import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Sisa hati satu sesi.
///
/// Lima hati per sesi, habis berarti mengulang pos dari awal. Bukan
/// nyawa global yang mengisi ulang sendiri: model itu memblokir anak
/// dari belajar dan mendorong pembelian.
class HeartBar extends StatelessWidget {
  const HeartBar({
    required this.sisa,
    this.total = 5,
    this.size = 19,
    super.key,
  });

  final int sisa;
  final int total;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sisa $sisa dari $total hati',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < total; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                scale: i < sisa ? 1 : 0.88,
                child: Icon(
                  i < sisa
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: size,
                  color: i < sisa ? AppColors.wrong : const Color(0xFFC6CEDC),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
