import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/practice_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/quiz_result.dart';
import '../../features/home/screens/jelajah_screen.dart';
import '../../features/home/screens/lepas_landas_screen.dart';
import '../../features/leaderboard/screens/peringkat_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/onboarding/screens/pilih_planet_screen.dart';
import '../../features/parent_gate/screens/parent_gate_screen.dart';
import '../../features/practice/screens/hasil_latihan_screen.dart';
import '../../features/practice/screens/kilat_screen.dart';
import '../../features/practice/screens/latihan_screen.dart';
import '../../features/practice/screens/perbaiki_screen.dart';
import '../../features/practice/screens/sesi_latihan_screen.dart';
import '../../features/practice/screens/tantangan_screen.dart';
import '../../features/profile/screens/lencana_screen.dart';
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

  // ---- Tahap 2
  static const sesiLatihan = '/latihan/sesi/:mode';
  static const hasilLatihan = '/latihan/hasil';
  static const perbaiki = '/latihan/perbaiki';
  static const tantangan = '/latihan/tantangan';
  static const kilat = '/latihan/kilat';
  static const lencana = '/lencana';
  static const lepasLandas = '/lepas-landas/:gradeId';

  static String kuisUntuk(String levelId) => '/kuis/$levelId';

  static String sesiLatihanUntuk(PracticeMode mode) =>
      '/latihan/sesi/${mode.name}';

  static String lepasLandasKe(String gradeId) => '/lepas-landas/$gradeId';
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

      // ---- Tahap 2
      GoRoute(
        path: Rute.sesiLatihan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) => SesiLatihanScreen(
          mode: PracticeMode.values.firstWhere(
            (m) => m.name == state.pathParameters['mode'],
            orElse: () => PracticeMode.latihanCepat,
          ),
        ),
      ),
      GoRoute(
        path: Rute.hasilLatihan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) =>
            HasilLatihanScreen(hasil: state.extra! as PracticeOutcome),
      ),
      GoRoute(
        path: Rute.perbaiki,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const PerbaikiScreen(),
      ),
      GoRoute(
        path: Rute.tantangan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const TantanganScreen(),
      ),
      GoRoute(
        path: Rute.kilat,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const KilatScreen(),
      ),
      GoRoute(
        path: Rute.lencana,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const LencanaScreen(),
      ),
      GoRoute(
        path: Rute.lepasLandas,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) =>
            LepasLandasScreen(gradeId: state.pathParameters['gradeId']!),
      ),
    ],
  );
});
