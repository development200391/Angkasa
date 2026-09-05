import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/practice_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/liga.dart';
import '../../domain/models/quiz_result.dart';
import '../../features/account/screens/akun_data_screen.dart';
import '../../features/account/screens/data_dikirim_screen.dart';
import '../../features/account/screens/nama_panggilan_screen.dart';
import '../../features/account/screens/pulihkan_progres_screen.dart';
import '../../features/parent/screens/dashboard_screen.dart';
import '../../features/parent/screens/jenis_kesalahan_screen.dart';
import '../../features/store/screens/buka_planet_screen.dart';
import '../../features/store/screens/galaksi_screen.dart';
import '../../features/store/screens/pembelian_berhasil_screen.dart';
import '../../features/account/screens/simpan_progres_screen.dart';
import '../../features/home/screens/jelajah_screen.dart';
import '../../features/home/screens/lepas_landas_screen.dart';
import '../../features/leaderboard/screens/akhir_minggu_screen.dart';
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

  // ---- Tahap 3
  static const namaPanggilan = '/nama-panggilan';
  static const akhirMinggu = '/akhir-minggu';
  static const akunData = '/akun-data';
  static const simpanProgres = '/simpan-progres';
  static const pulihkanProgres = '/pulihkan-progres';
  static const dataDikirim = '/data-yang-dikirim';

  // ---------------------------------------------------------- Tahap 4
  static const galaksi = '/galaksi';
  static const bukaPlanet = '/buka-planet';
  static const pembelianBerhasil = '/pembelian-berhasil';
  static const dashboardOrtu = '/dashboard';
  static const jenisKesalahan = '/jenis-kesalahan';

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

      // ---- Tahap 3
      //
      // Empat dari lima layar di bawah cuma bisa dibuka lewat Gerbang
      // Orang Tua, dan itu bukan sekadar kebiasaan: begitu sebuah layar
      // bisa mengubah apa yang dikirim keluar dari HP anak, ia berhenti
      // jadi layar anak.
      GoRoute(
        path: Rute.namaPanggilan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const NamaPanggilanScreen(),
      ),
      GoRoute(
        path: Rute.akhirMinggu,
        parentNavigatorKey: _navigatorKey,
        builder: (_, state) =>
            AkhirMingguScreen(ringkasan: state.extra! as RingkasanMinggu),
      ),
      GoRoute(
        path: Rute.akunData,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const AkunDataScreen(),
      ),
      GoRoute(
        path: Rute.simpanProgres,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const SimpanProgresScreen(),
      ),
      GoRoute(
        path: Rute.pulihkanProgres,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const PulihkanProgresScreen(),
      ),

      // ------------------------------------------------------ Tahap 4
      GoRoute(
        path: Rute.galaksi,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const GalaksiScreen(),
      ),
      // Layar penjualan dan layar berhasilnya sengaja **tidak** di
      // balik Gerbang Orang Tua. Gerbangnya ada di jalan menuju
      // Galaksi, dan memasang gerbang kedua di tengah alur pembayaran
      // membuat orang tua yang sudah menekan "Beli" harus mengerjakan
      // soal perkalian sebelum boleh membayar.
      GoRoute(
        path: Rute.bukaPlanet,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const BukaPlanetScreen(),
      ),
      GoRoute(
        path: Rute.pembelianBerhasil,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const PembelianBerhasilScreen(),
      ),
      GoRoute(
        path: Rute.dashboardOrtu,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: Rute.jenisKesalahan,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const JenisKesalahanScreen(),
      ),
      GoRoute(
        path: Rute.dataDikirim,
        parentNavigatorKey: _navigatorKey,
        builder: (_, _) => const DataDikirimScreen(),
      ),
    ],
  );
});
