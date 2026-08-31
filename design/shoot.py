"""Render design/ui.html jadi PNG di docs/screenshots/.

    python design/shoot.py            # semua layar + gabungannya
    python design/shoot.py 02         # satu layar saja

Butuh Playwright sekali pasang:

    pip install playwright
    python -m playwright install chromium

Berkas ui.html sudah menyematkan fontnya sendiri, jadi render ini tidak
butuh jaringan dan hasilnya sama di mesin mana pun.
"""
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

AKAR = Path(__file__).resolve().parent.parent
SUMBER = AKAR / "design" / "ui.html"
TUJUAN = AKAR / "docs" / "screenshots"
SKALA = 2  # 2x supaya tajam di layar retina dan saat diperkecil di README

LAYAR = [
    ("s1", "01-pilih-planet"),
    ("s2", "02-peta-lintasan"),
    ("s3", "03-detail-pos"),
    ("s4", "04-pilihan-ganda"),
    ("s5", "05-isian-garis-bilangan"),
    ("s6", "06-jawaban-salah"),
    ("s7", "07-hasil-pos"),
    ("s8", "08-gerbang-orang-tua"),
    ("s9", "09-latihan"),
    ("s10", "10-perbaiki-kesalahan"),
    ("s11", "11-kilat-60-detik"),
    ("s12", "12-tantangan-harian"),
    ("s13", "13-profil"),
    ("s14", "14-lencana"),
    ("s15", "15-lepas-landas"),
    ("s16", "16-pemberitahuan"),
    ("s17", "17-papan-peringkat"),
    ("s18", "18-akhir-minggu"),
    ("s19", "19-nama-panggilan"),
    ("s20", "20-luring"),
    ("s21", "21-simpan-progres"),
    ("s22", "22-pulihkan-progres"),
    ("s23", "23-akun-dan-data"),
    ("s24", "24-data-yang-dikirim"),
]

# satu gambar gabungan per tahap
GABUNGAN = [("tahap1", "00-semua-layar"),
             ("tahap2", "00-semua-layar-tahap2"),
             ("tahap3", "00-semua-layar-tahap3")]


def main() -> None:
    saring = sys.argv[1] if len(sys.argv) > 1 else None
    TUJUAN.mkdir(parents=True, exist_ok=True)

    with sync_playwright() as p:
        browser = p.chromium.launch()
        page = browser.new_page(
            viewport={"width": 1840, "height": 1200},
            device_scale_factor=SKALA,
        )
        page.goto(SUMBER.as_uri())
        page.wait_for_timeout(600)  # tunggu font tersemat selesai dipasang

        for pilih, nama in LAYAR:
            if saring and not nama.startswith(saring):
                continue
            page.locator(f"#{pilih}").screenshot(path=str(TUJUAN / f"{nama}.png"))
            print(f"  {nama}.png")

        if not saring:
            # gabungan semua layar, tanpa keterangan di bawahnya
            page.eval_on_selector_all(".cap", "els => els.forEach(e => e.style.display='none')")
            page.eval_on_selector("body", "el => el.style.padding='34px'")
            page.wait_for_timeout(120)
            for pilih, nama in GABUNGAN:
                page.locator(f"#{pilih}").screenshot(path=str(TUJUAN / f"{nama}.png"))
                print(f"  {nama}.png")

        browser.close()

    print(f"selesai → {TUJUAN}")


if __name__ == "__main__":
    main()
