import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/account_repository.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/primary_button.dart';

/// Layar 22 · Pulihkan progres.
///
/// **Satu-satunya tempat di seluruh aplikasi di mana data bisa hilang**
/// — jadi tidak ada satu pun pilihan yang dicentang duluan, peringatannya
/// ditulis lugas, dan menutup layar ini selalu aman.
///
/// Layarnya cuma muncul kalau dua-duanya berisi. Kalau salah satu
/// kosong, tidak ada yang perlu dipilih dan aplikasi tidak boleh
/// berpura-pura ada keputusan yang harus diambil.
class PulihkanProgresScreen extends ConsumerStatefulWidget {
  const PulihkanProgresScreen({super.key});

  @override
  ConsumerState<PulihkanProgresScreen> createState() => _State();
}

enum _Pilih { hpIni, akun }

class _State extends ConsumerState<PulihkanProgresScreen> {
  _Pilih? _pilihan;
  bool _bekerja = false;

  Future<void> _terapkan() async {
    if (_pilihan == null) return;
    setState(() => _bekerja = true);

    final repo = ref.read(accountRepositoryProvider);
    final berhasil = _pilihan == _Pilih.akun
        ? await repo.pulihkanDariAkun()
        : await repo.pertahankanYangDiHp();

    await ref.read(profileProvider.notifier).muatUlang();
    ref
      ..invalidate(petaProvider)
      ..invalidate(badgesProvider)
      ..invalidate(pilihanPemulihanProvider);

    if (!mounted) return;
    setState(() => _bekerja = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          berhasil
              ? (_pilihan == _Pilih.akun
                    ? 'Progres dari akun dipakai.'
                    : 'Progres di HP ini dipertahankan.')
              : 'Belum berhasil. Coba lagi setelah tersambung.',
        ),
      ),
    );
    if (berhasil) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pilihan = ref.watch(pilihanPemulihanProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Ada dua progres'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: pilihan.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              EmptyView(judul: 'Tidak bisa memeriksa', keterangan: '$e'),
          data: (p) => p == null
              ? const EmptyView(
                  judul: 'Tidak ada yang perlu dipilih',
                  keterangan:
                      'Cuma ada satu progres — entah di HP ini saja, atau di '
                      'akun saja. Tidak ada yang bisa saling menimpa.',
                  ikon: Icons.check_circle_outline_rounded,
                )
              : _Isi(
                  pilihan: p,
                  terpilih: _pilihan,
                  bekerja: _bekerja,
                  onPilih: (v) => setState(() => _pilihan = v),
                  onTerapkan: _terapkan,
                ),
        ),
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  const _Isi({
    required this.pilihan,
    required this.terpilih,
    required this.bekerja,
    required this.onPilih,
    required this.onTerapkan,
  });

  final PilihanPemulihan pilihan;
  final _Pilih? terpilih;
  final bool bekerja;
  final ValueChanged<_Pilih> onPilih;
  final VoidCallback onTerapkan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 2, 22, 12),
            children: [
              Text(
                'Akun ini sudah punya data tersimpan, sementara di HP ini '
                'juga ada progres. Pilih salah satu.',
                style: AppTextStyles.sub,
              ),
              const SizedBox(height: 20),
              _Kartu(
                judul: 'Di HP ini',
                ringkasan: pilihan.diHpIni,
                aktif: terpilih == _Pilih.hpIni,
                onTap: () => onPilih(_Pilih.hpIni),
              ),
              const SizedBox(height: 13),
              _Kartu(
                judul: 'Tersimpan di akun',
                ringkasan: pilihan.diAkun,
                aktif: terpilih == _Pilih.akun,
                onTap: () => onPilih(_Pilih.akun),
              ),
              const SizedBox(height: 20),
              const _Peringatan(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 18),
          child: PrimaryButton(
            label: bekerja ? 'Menerapkan…' : 'Pakai yang dipilih',
            onPressed: terpilih == null || bekerja ? null : onTerapkan,
          ),
        ),
      ],
    );
  }
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.judul,
    required this.ringkasan,
    required this.aktif,
    required this.onTap,
  });

  final String judul;
  final RingkasanProgres ringkasan;
  final bool aktif;
  final VoidCallback onTap;

  static const _bulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String get _kapan {
    final t = ringkasan.terakhir;
    if (t == null) return 'Belum pernah main';
    final kini = DateTime.now();
    final selisih = DateTime(
      kini.year,
      kini.month,
      kini.day,
    ).difference(DateTime(t.year, t.month, t.day)).inDays;
    if (selisih <= 0) return 'Terakhir main hari ini';
    if (selisih == 1) return 'Terakhir main kemarin';
    return 'Terakhir main ${t.day} ${_bulan[t.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: aktif,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: aktif ? AppColors.brand : AppColors.line,
              width: aktif ? 2 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Radio(aktif: aktif),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judul,
                          style: AppTextStyles.title.copyWith(fontSize: 15.5),
                        ),
                        const SizedBox(height: 1),
                        Text(_kapan, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 9,
                runSpacing: 8,
                children: [
                  _Pil('${ringkasan.posSelesai} pos', aktif: aktif),
                  _Pil('${ringkasan.totalXp} XP', aktif: aktif),
                  _Pil(ringkasan.nama, aktif: aktif),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.aktif});

  final bool aktif;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: aktif ? AppColors.brand : AppColors.line,
        width: 2,
      ),
    ),
    child: aktif
        ? Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.brand,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

class _Pil extends StatelessWidget {
  const _Pil(this.teks, {required this.aktif});

  final String teks;
  final bool aktif;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
    decoration: BoxDecoration(
      color: aktif ? const Color(0xFFFBEFD3) : const Color(0xFFF1F4FA),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      teks,
      style: AppTextStyles.caption.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: aktif ? const Color(0xFF8A5A0B) : AppColors.ink2,
      ),
    ),
  );
}

class _Peringatan extends StatelessWidget {
  const _Peringatan();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: const Color(0xFFFDF3F4),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF0D3D7)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.warning_amber_rounded,
          size: 20,
          color: AppColors.wrong,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                height: 1.55,
                color: const Color(0xFF8E2C3A),
              ),
              children: const [
                TextSpan(text: 'Yang tidak dipilih akan '),
                TextSpan(
                  text: 'hilang permanen',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(
                  text:
                      '. Kalau ragu, tutup dulu layar ini — datanya aman '
                      'sampai kamu memilih.',
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
