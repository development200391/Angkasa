import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/app_router.dart';
import '../../../data/providers.dart';
import '../../../domain/models/grade.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../home/widgets/starfield.dart';
import '../widgets/avatar_grid.dart';
import '../widgets/planet_grid.dart';
import 'penempatan_screen.dart';

/// Onboarding empat langkah: nama, avatar, pilih planet, tes penempatan.
///
/// Langkah keempat boleh dilewati — dan itu penting. Tes penempatan yang
/// wajib membuat anak yang baru memasang aplikasi harus lulus ujian
/// dulu sebelum boleh main.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _nama = TextEditingController();
  int _langkah = 0;
  String _avatar = 'roket';
  String? _gradeId;
  bool _menyimpan = false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  void _maju() => setState(() => _langkah++);

  void _mundur() {
    if (_langkah == 0) return;
    setState(() => _langkah--);
  }

  Future<void> _selesai({String? gradeIdPenempatan}) async {
    if (_menyimpan) return;
    setState(() => _menyimpan = true);
    final gradeId = gradeIdPenempatan ?? _gradeId;
    if (gradeId == null) {
      setState(() => _menyimpan = false);
      return;
    }
    await ref
        .read(profileProvider.notifier)
        .selesaikanOnboarding(
          nama: _nama.text.trim().isEmpty ? 'Penjelajah' : _nama.text,
          avatarId: _avatar,
          gradeId: gradeId,
        );
    if (mounted) context.go(Rute.jelajah);
  }

  @override
  Widget build(BuildContext context) {
    final planets = ref.watch(planetsProvider);

    return Scaffold(
      backgroundColor: AppColors.space,
      body: Stack(
        children: [
          const Positioned.fill(child: Starfield()),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            height: 5,
                            decoration: BoxDecoration(
                              color: i <= _langkah
                                  ? AppColors.brandLight
                                  : Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: planets.when(
                    loading: () => const LoadingView(diAtasGelap: true),
                    error: (e, _) => EmptyView(
                      judul: 'Data planet tidak terbaca',
                      keterangan: '$e',
                      diAtasGelap: true,
                    ),
                    data: (daftar) => _isi(daftar),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _isi(List<Grade> daftar) => switch (_langkah) {
    0 => _LangkahNama(controller: _nama, onLanjut: _maju),
    1 => _LangkahAvatar(
      terpilih: _avatar,
      onPilih: (id) => setState(() => _avatar = id),
      onLanjut: _maju,
      onKembali: _mundur,
    ),
    2 => _LangkahPlanet(
      planets: daftar,
      terpilih: _gradeId,
      menyimpan: _menyimpan,
      onPilih: (g) => setState(() => _gradeId = g.id),
      onLanjut: _gradeId == null ? null : () => _selesai(),
      onTes: _maju,
      onKembali: _mundur,
    ),
    _ => PenempatanScreen(
      onSelesai: (gradeId) => _selesai(gradeIdPenempatan: gradeId),
      onLewati: () => _selesai(),
    ),
  };
}

class _Judul extends StatelessWidget {
  const _Judul({required this.judul, this.keterangan});

  final String judul;
  final String? keterangan;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          judul,
          style: AppTextStyles.h1.copyWith(color: AppColors.inkOnSpace),
        ),
        if (keterangan != null) ...[
          const SizedBox(height: 9),
          Text(
            keterangan!,
            style: AppTextStyles.sub.copyWith(color: AppColors.ink2OnSpace),
          ),
        ],
      ],
    );
  }
}

class _LangkahNama extends StatefulWidget {
  const _LangkahNama({required this.controller, required this.onLanjut});

  final TextEditingController controller;
  final VoidCallback onLanjut;

  @override
  State<_LangkahNama> createState() => _LangkahNamaState();
}

class _LangkahNamaState extends State<_LangkahNama> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Judul(
            judul: 'Siapa yang mau\nberangkat?',
            keterangan: 'Nama panggilan saja. Tidak perlu nama lengkap.',
          ),
          const SizedBox(height: 26),
          TextField(
            controller: widget.controller,
            autofocus: true,
            maxLength: 12,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
            style: AppTextStyles.h2.copyWith(color: AppColors.inkOnSpace),
            cursorColor: AppColors.brandLight,
            decoration: InputDecoration(
              hintText: 'Nama panggilan',
              hintStyle: AppTextStyles.h2.copyWith(
                color: AppColors.ink3OnSpace,
              ),
              counterStyle: AppTextStyles.caption.copyWith(
                color: AppColors.ink3OnSpace,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(
                  color: AppColors.brandLight,
                  width: 2,
                ),
              ),
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Lanjut',
            onPressed: widget.controller.text.trim().isEmpty
                ? null
                : widget.onLanjut,
          ),
        ],
      ),
    );
  }
}

class _LangkahAvatar extends StatelessWidget {
  const _LangkahAvatar({
    required this.terpilih,
    required this.onPilih,
    required this.onLanjut,
    required this.onKembali,
  });

  final String terpilih;
  final ValueChanged<String> onPilih;
  final VoidCallback onLanjut;
  final VoidCallback onKembali;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Judul(
            judul: 'Pilih tanda\npengenalmu',
            keterangan: 'Muncul di profil dan papan peringkat nanti.',
          ),
          const SizedBox(height: 26),
          AvatarGrid(terpilih: terpilih, onPilih: onPilih),
          const Spacer(),
          PrimaryButton(label: 'Lanjut', onPressed: onLanjut),
          GhostButton(
            label: 'Kembali',
            diAtasGelap: true,
            onPressed: onKembali,
          ),
        ],
      ),
    );
  }
}

class _LangkahPlanet extends StatelessWidget {
  const _LangkahPlanet({
    required this.planets,
    required this.terpilih,
    required this.menyimpan,
    required this.onPilih,
    required this.onLanjut,
    required this.onTes,
    required this.onKembali,
  });

  final List<Grade> planets;
  final String? terpilih;
  final bool menyimpan;
  final ValueChanged<Grade> onPilih;
  final VoidCallback? onLanjut;
  final VoidCallback onTes;
  final VoidCallback onKembali;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Judul(
            judul: 'Kelas berapa\nsekarang?',
            keterangan: 'Bisa diganti kapan saja lewat Profil.',
          ),
          const SizedBox(height: 22),
          PlanetGrid(planets: planets, terpilih: terpilih, onPilih: onPilih),
          const SizedBox(height: 24),
          PrimaryButton(
            label: menyimpan ? 'Menyiapkan…' : 'Lanjut',
            onPressed: menyimpan ? null : onLanjut,
          ),
          GhostButton(
            label: 'Belum yakin? Coba tes penempatan',
            diAtasGelap: true,
            onPressed: onTes,
          ),
          GhostButton(
            label: 'Kembali',
            diAtasGelap: true,
            onPressed: onKembali,
          ),
        ],
      ),
    );
  }
}
