import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/quiz_result.dart';
import '../../features/home/screens/jelajah_screen.dart';
import '../../features/leaderboard/screens/peringkat_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/pilih_planet_screen.dart';
import '../../features/parent_gate/screens/parent_gate_screen.dart';
import '../../features/practice/screens/latihan_screen.dart';
import '../../features/profile/screens/pengaturan_screen.dart';
import '../../features/profile/screens/profil_screen.dart';
import '../../features/quiz/screens/quiz_screen.dart';
import '../../features/quiz/screens/result_screen.dart';
import '../../features/quiz/screens/review_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import 'shell_scaffold.dart';

/// Semua alamat layar dikumpulkan di satu tempat, jadi tidak ada satu
/// pun teks rute yang ditulis dua kali.
abstract final class Rute {
  static const splash = '/';
  static const onboarding = '/onboarding';

  static const jelajah = '/jelajah';
  static const latihan = '/latihan';
  static const peringkat = '/peringkat';
  static const profil = '/profil';

  static const kuis = '/kuis/:levelId';
  static const hasil = '/hasil';
  static const pembahasan = '/pembahasan';
  static const pilihPlanet = '/pilih-planet';
  static const gerbangOrtu = '/gerbang-orang-tua';
  static const pengaturan = '/pengaturan';

  static String kuisUntuk(String levelId) => '/kuis/$levelId';
}

final _navigatorKey = GlobalKey<NavigatorState>();

/// `ShellRoute` mengurus empat tab bersarang tanpa perlu menulis
/// navigator sendiri, dan tiap tab menyimpan tumpukannya masing-masing.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _navigatorKey,
    initialLocation: Rute.splash,
    routes: [
      GoRoute(path: Rute.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Rute.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.jelajah,
                builder: (_, _) => const JelajahScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.latihan,
                builder: (_, _) => const LatihanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.peringkat,
                builder: (_, _) => const PeringkatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Rute.profil,
                builder: (_, _) => const ProfilScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Rute.kuis,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) =>
            QuizScreen(levelId: state.pathParameters['levelId']!),
      ),
      GoRoute(
        path: Rute.hasil,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) => ResultScreen(hasil: state.extra! as QuizResult),
      ),
      GoRoute(
        path: Rute.pembahasan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) => ReviewScreen(hasil: state.extra! as QuizResult),
      ),
      GoRoute(
        path: Rute.pilihPlanet,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const PilihPlanetScreen(),
      ),
      GoRoute(
        path: Rute.gerbangOrtu,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) =>
            ParentGateScreen(tujuan: state.extra as String? ?? Rute.pengaturan),
      ),
      GoRoute(
        path: Rute.pengaturan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const PengaturanScreen(),
      ),
    ],
  );
});
