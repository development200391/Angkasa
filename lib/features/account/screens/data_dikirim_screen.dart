import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../widgets/daftar_data.dart';

/// Layar 24 · Data yang dikirim.
///
/// **Ini bukan halaman hukum.** Kebijakan Privasi tetap ada di tempatnya
/// sendiri; yang ini dua daftar yang bisa dibaca orang tua dalam sepuluh
/// detik, sambil berdiri di dapur.
///
/// Isinya wajib sama persis dengan deklarasi *Data safety* di Play
/// Console. Karena keduanya dibaca dari satu daftar di
/// `AccountRepository`, satu field baru yang disinkronkan akan langsung
/// terlihat di sini — dan itu pengingat termurah supaya deklarasinya
/// tidak pernah basi.
class DataDikirimScreen extends StatelessWidget {
  const DataDikirimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Data yang dikirim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 6, 22, 24),
        children: [
          const DaftarData(),
          const SizedBox(height: 24),
          Text(
            'Daftar ini sama persis dengan yang dideklarasikan di Play '
            'Console dan tertulis di Kebijakan Privasi.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
