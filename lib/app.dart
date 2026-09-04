import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/providers.dart';
import 'domain/models/liga.dart';

/// Akar aplikasi.
///
/// Temanya mengikuti setelan sistem: layar berlatar angkasa memaksa
/// warnanya sendiri, jadi yang berubah cuma layar terang seperti kuis
/// dan pengaturan.
class AngkasaApp extends ConsumerStatefulWidget {
  const AngkasaApp({super.key});

  @override
  ConsumerState<AngkasaApp> createState() => _AngkasaAppState();
}

class _AngkasaAppState extends ConsumerState<AngkasaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Antrean dikosongkan waktu aplikasi masuk latar belakang.
  ///
  /// Ini titik kirim kedua dari dua yang tertulis di README — yang
  /// pertama penundaan tiga puluh detik sesudah pos selesai. Anak yang
  /// main lima menit lalu menekan tombol home tidak pernah menunggu
  /// tiga puluh detik itu habis, dan tanpa titik ini kirimannya baru
  /// berangkat besok.
  @override
  void didChangeAppLifecycleState(AppLifecycleState keadaan) {
    if (keadaan == AppLifecycleState.paused ||
        keadaan == AppLifecycleState.detached) {
      final sinkron = ref.read(syncRepositoryProvider);
      sinkron
        ..antreCadangan()
        ..kirimSekarang();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menjadwalkan ulang pengingat harian tiap aplikasi dibuka: isinya
    // menyebut streak dan pos yang menunggu, jadi harus ikut berubah
    // waktu keduanya berubah.
    ref.watch(pengingatHarianProvider);

    // Hasil liga minggu lalu, kalau ada dan belum pernah dilihat.
    // Menunggu sampai ada yang ditampilkan, bukan dipanggil dari dalam
    // sebuah layar: liga bisa berganti sementara aplikasi terbuka.
    ref.listen(ringkasanMingguProvider, (_, next) {
      final ringkasan = next.value;
      if (ringkasan != null) _tampilkanAkhirMinggu(ringkasan);
    });

    return MaterialApp.router(
      title: 'Angkasa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }

  void _tampilkanAkhirMinggu(RingkasanMinggu ringkasan) {
    // Dijadwalkan setelah frame ini: `ref.listen` bisa terpicu di
    // tengah build, dan berpindah layar dari sana melempar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(routerProvider).push(Rute.akhirMinggu, extra: ringkasan);
    });
  }
}
