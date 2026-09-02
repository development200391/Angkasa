import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Akar aplikasi.
///
/// Temanya mengikuti setelan sistem: layar berlatar angkasa memaksa
/// warnanya sendiri, jadi yang berubah cuma layar terang seperti kuis
/// dan pengaturan.
class AngkasaApp extends ConsumerWidget {
  const AngkasaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Angkasa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
