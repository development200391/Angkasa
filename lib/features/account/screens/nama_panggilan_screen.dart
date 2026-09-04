import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/providers.dart';
import '../../../domain/engine/nickname_filter.dart';
import '../../../shared/widgets/primary_button.dart';

/// Layar 19 · Nama panggilan.
///
/// Ini **satu-satunya teks bebas di seluruh aplikasi**, jadi satu-satunya
/// yang perlu disaring. Sebelum papan peringkat ada, nama panggilan cuma
/// tulisan di layar Profil sendiri; begitu ia ikut terkirim dan dibaca
/// anak lain, aturan mainnya berubah total.
///
/// Pemeriksaannya berjalan **sambil mengetik**, bukan setelah menekan
/// tombol. Anak yang menulis nama lalu ditolak di detik terakhir akan
/// menebak-nebak apa yang salah; yang melihat centang hijau muncul di
/// huruf ketiga tahu persis kapan namanya sudah boleh.
class NamaPanggilanScreen extends ConsumerStatefulWidget {
  const NamaPanggilanScreen({super.key});

  @override
  ConsumerState<NamaPanggilanScreen> createState() => _State();
}

class _State extends ConsumerState<NamaPanggilanScreen> {
  final _kendali = TextEditingController();
  late List<String> _saran;
  HasilNama _hasil = const HasilNama.tolak('Minimal 3 huruf.');
  bool _menyimpan = false;

  /// Nama yang sudah ada baru bisa diisi setelah profilnya terbaca, dan
  /// itu belum tentu terjadi di `initState` — layar ini bisa dibuka dari
  /// pemberitahuan, sebelum satu pun layar lain sempat membaca profil.
  bool _terisi = false;

  @override
  void initState() {
    super.initState();
    _saran = NicknameFilter.saran(acak: Random());
    _kendali.addListener(() {
      setState(() => _hasil = NicknameFilter.periksa(_kendali.text));
    });
  }

  void _isiSekali(String nama) {
    if (_terisi) return;
    _terisi = true;
    if (nama.isEmpty) return;
    _kendali
      ..text = nama
      ..selection = TextSelection.collapsed(offset: nama.length);
  }

  @override
  void dispose() {
    _kendali.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    final hasil = await ref
        .read(accountRepositoryProvider)
        .gantiNama(_kendali.text);
    await ref.read(profileProvider.notifier).muatUlang();
    if (!mounted) return;
    setState(() => _menyimpan = false);

    if (hasil.boleh) {
      context.pop();
    } else {
      setState(() => _hasil = hasil);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profil = ref.watch(profileProvider).value;
    if (profil != null) _isiSekali(profil.nickname);

    final panjang = _kendali.text.characters.length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Nama panggilan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 12),
                children: [
                  Text(
                    'Ini nama yang dilihat pemain lain di papan peringkat.',
                    style: AppTextStyles.sub,
                  ),
                  const SizedBox(height: 20),
                  _Kotak(
                    kendali: _kendali,
                    panjang: panjang,
                    boleh: _hasil.boleh,
                  ),
                  const SizedBox(height: 12),
                  _Kabar(hasil: _hasil, kosong: _kendali.text.isEmpty),
                  const SizedBox(height: 26),
                  Text(
                    'SARAN',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.62,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Wrap(
                    spacing: 9,
                    runSpacing: 9,
                    children: [
                      for (final s in _saran)
                        _PilSaran(
                          teks: s,
                          onTap: () {
                            _kendali.text = s;
                            _kendali.selection = TextSelection.collapsed(
                              offset: s.length,
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  const _Peringatan(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 18),
              child: PrimaryButton(
                label: _menyimpan ? 'Menyimpan…' : 'Pakai nama ini',
                onPressed: _hasil.boleh && !_menyimpan ? _simpan : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kotak extends StatelessWidget {
  const _Kotak({
    required this.kendali,
    required this.panjang,
    required this.boleh,
  });

  final TextEditingController kendali;
  final int panjang;
  final bool boleh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: boleh ? AppColors.ok : AppColors.brand,
          width: 2.5,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F6FB), Color(0xFFFFFFFF)],
          stops: [0, 0.62],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: kendali,
              autofocus: true,
              maxLength: NicknameFilter.panjangMaksimal,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [
                // Karakter yang tidak akan pernah lolos pemeriksaan
                // dicegah sejak papan ketik, bukan ditolak belakangan.
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
              ],
              style: AppTextStyles.h2.copyWith(fontSize: 22),
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                isDense: true,
                hintText: 'RoketBiru',
              ),
            ),
          ),
          Text(
            '$panjang/${NicknameFilter.panjangMaksimal}',
            style: AppTextStyles.caption.copyWith(
              fontFeatures: const [AppTextStyles.tabular],
            ),
          ),
        ],
      ),
    );
  }
}

class _Kabar extends StatelessWidget {
  const _Kabar({required this.hasil, required this.kosong});

  final HasilNama hasil;
  final bool kosong;

  @override
  Widget build(BuildContext context) {
    if (kosong) {
      return Text('Antara 3 dan 16 huruf.', style: AppTextStyles.caption);
    }
    final warna = hasil.boleh ? AppColors.ok : AppColors.wrong;
    return Row(
      children: [
        Icon(
          hasil.boleh ? Icons.check_rounded : Icons.info_outline_rounded,
          size: 18,
          color: warna,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasil.boleh ? 'Nama ini boleh dipakai' : hasil.alasan!,
            style: AppTextStyles.body.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: warna,
            ),
          ),
        ),
      ],
    );
  }
}

class _PilSaran extends StatelessWidget {
  const _PilSaran({required this.teks, required this.onTap});

  final String teks;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF1F4FA),
    borderRadius: BorderRadius.circular(99),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          teks,
          style: AppTextStyles.body.copyWith(
            fontSize: 13.5,
            color: AppColors.ink2,
          ),
        ),
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
      color: const Color(0xFFF5F7FB),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE1E7F0)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.help_outline_rounded, size: 20, color: AppColors.ink3),
        const SizedBox(width: 11),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: AppTextStyles.body.copyWith(
                fontSize: 13,
                color: AppColors.ink2,
                height: 1.55,
              ),
              children: const [
                TextSpan(
                  text: 'Nama asli, nama sekolah, umur, dan nomor telepon ',
                ),
                TextSpan(
                  text: 'tidak boleh dipakai',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                TextSpan(text: '. Nama diperiksa otomatis sebelum disimpan.'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
