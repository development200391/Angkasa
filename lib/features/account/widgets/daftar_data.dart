import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/repositories/account_repository.dart';

/// Dua daftar: apa yang dikirim, apa yang tidak pernah dikirim.
///
/// Isinya dibaca dari [AccountRepository], bukan diketik di layar. Itu
/// bukan kerapian — layar Data yang dikirim harus **sama persis** dengan
/// deklarasi *Data safety* di Play Console, dan daftar yang ditulis
/// tangan di dua tempat akan berbeda pada perubahan pertama.
class DaftarData extends StatelessWidget {
  const DaftarData({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Kartu(
        judul: 'Dikirim ke server',
        warnaJudul: const Color(0xFF1C5B49),
        warnaTitik: AppColors.ok,
        garis: const Color(0xFFCFE5DB),
        latar: const [Color(0xFFFFFFFF), Color(0xFFF2FAF7)],
        bayangan: const Color(0xFFD5E8E0),
        ikon: Icons.check_rounded,
        isi: AccountRepository.yangDikirim,
      ),
      const SizedBox(height: 16),
      _Kartu(
        judul: 'Tidak pernah dikirim',
        warnaJudul: const Color(0xFF8E2C3A),
        warnaTitik: AppColors.wrong,
        garis: const Color(0xFFEBD6D9),
        latar: const [Color(0xFFFFFFFF), Color(0xFFFDF4F5)],
        bayangan: const Color(0xFFEFDCDF),
        ikon: Icons.close_rounded,
        isi: AccountRepository.tidakPernahDikirim,
      ),
    ],
  );
}

/// Bentuk pendeknya: dua kotak pil, dipakai di layar Simpan progres di
/// mana daftar penuhnya akan mendorong tombol keluar layar.
class DaftarDataRingkas extends StatelessWidget {
  const DaftarDataRingkas({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _Pilar(
        label: 'YANG DISIMPAN KE SERVER',
        latar: const Color(0xFFF5F7FB),
        garis: const Color(0xFFE1E7F0),
        warnaPil: const Color(0xFFE3EFEA),
        warnaTeks: const Color(0xFF1C5B49),
        isi: const [
          'Nama panggilan',
          'Avatar',
          'Total XP',
          'Kelas aktif',
          'Streak',
          'Bintang tiap pos',
        ],
      ),
      const SizedBox(height: 13),
      _Pilar(
        label: 'YANG TIDAK PERNAH DIKIRIM',
        latar: const Color(0xFFFDF6F7),
        garis: const Color(0xFFF0DFE2),
        warnaPil: const Color(0xFFFAE7EA),
        warnaTeks: const Color(0xFF8E2C3A),
        isi: const ['Nama asli', 'Umur', 'Lokasi', 'Jawaban soal', 'ID iklan'],
      ),
    ],
  );
}

class _Pilar extends StatelessWidget {
  const _Pilar({
    required this.label,
    required this.latar,
    required this.garis,
    required this.warnaPil,
    required this.warnaTeks,
    required this.isi,
  });

  final String label;
  final Color latar;
  final Color garis;
  final Color warnaPil;
  final Color warnaTeks;
  final List<String> isi;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(17, 15, 17, 16),
    decoration: BoxDecoration(
      color: latar,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: garis),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.62,
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in isi)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: warnaPil,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  t,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: warnaTeks,
                  ),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _Kartu extends StatelessWidget {
  const _Kartu({
    required this.judul,
    required this.warnaJudul,
    required this.warnaTitik,
    required this.garis,
    required this.latar,
    required this.bayangan,
    required this.ikon,
    required this.isi,
  });

  final String judul;
  final Color warnaJudul;
  final Color warnaTitik;
  final Color garis;
  final List<Color> latar;
  final Color bayangan;
  final IconData ikon;
  final List<String> isi;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(17, 15, 17, 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: garis),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: latar,
      ),
      boxShadow: [BoxShadow(color: bayangan, offset: const Offset(0, 5))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ikon, size: 19, color: warnaJudul),
            const SizedBox(width: 9),
            Text(
              judul,
              style: AppTextStyles.title.copyWith(
                fontSize: 14.5,
                color: warnaJudul,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (final baris in isi)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 7, right: 11),
                  decoration: BoxDecoration(
                    color: warnaTitik,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(child: _baris(baris)),
              ],
            ),
          ),
      ],
    ),
  );

  /// Bagian sesudah tanda pisah dibuat lebih redup — itu keterangan,
  /// bukan bagian dari daftarnya.
  Widget _baris(String teks) {
    final pisah = teks.indexOf(' — ');
    if (pisah < 0) {
      return Text(
        teks,
        style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45),
      );
    }
    return Text.rich(
      TextSpan(
        style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.45),
        children: [
          TextSpan(text: teks.substring(0, pisah)),
          TextSpan(
            text: teks.substring(pisah),
            style: const TextStyle(color: AppColors.ink3),
          ),
        ],
      ),
    );
  }
}
