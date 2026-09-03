"""Bangkitkan efek suara Angkasa jadi berkas WAV.

Nadanya dibangkitkan, bukan diunduh: aplikasi anak harus utuh di HP yang
tidak pernah tersambung internet, dan lisensi berkas suara pihak ketiga
adalah satu urusan yang tidak perlu ada di proyek sekecil ini.

Semua bunyi pendek, lembut, dan berakhir dengan peredaman — suara yang
memotong mendadak terdengar seperti aplikasi rusak.

    python tool/buat_suara.py
"""
import math
import pathlib
import struct
import wave

TUJUAN = pathlib.Path(__file__).resolve().parent.parent / "assets/audio"
LAJU = 22050


def nada(frekuensi, detik, volume=0.5, mulai=0.0, gelombang="sin"):
    """Satu nada dengan serangan cepat dan peredaman halus."""
    n = int(LAJU * detik)
    contoh = []
    for i in range(n):
        t = i / LAJU
        f = frekuensi + (0 if mulai == 0 else (frekuensi - mulai) * 0)
        if gelombang == "segitiga":
            fase = (t * f) % 1
            nilai = 4 * abs(fase - 0.5) - 1
        else:
            nilai = math.sin(2 * math.pi * f * t)
        # amplop: naik 8 ms, turun sisanya
        serang = min(1.0, t / 0.008)
        redam = min(1.0, (detik - t) / (detik * 0.6))
        contoh.append(nilai * volume * serang * redam)
    return contoh


def sapuan(dari, ke, detik, volume=0.45):
    """Nada yang meluncur dari satu frekuensi ke frekuensi lain."""
    n = int(LAJU * detik)
    contoh = []
    fase = 0.0
    for i in range(n):
        t = i / LAJU
        f = dari + (ke - dari) * (t / detik)
        fase += 2 * math.pi * f / LAJU
        serang = min(1.0, t / 0.02)
        redam = min(1.0, (detik - t) / (detik * 0.5))
        contoh.append(math.sin(fase) * volume * serang * redam)
    return contoh


def sunyi(detik):
    return [0.0] * int(LAJU * detik)


def campur(*lapisan):
    panjang = max(len(l) for l in lapisan)
    hasil = [0.0] * panjang
    for l in lapisan:
        for i, v in enumerate(l):
            hasil[i] += v
    return hasil


def tulis(nama, contoh):
    TUJUAN.mkdir(parents=True, exist_ok=True)
    p = TUJUAN / nama
    with wave.open(str(p), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(LAJU)
        data = b"".join(
            struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32000))
            for v in contoh
        )
        w.writeframes(data)
    print(f"{p.name}: {len(contoh) / LAJU:.2f} detik, {p.stat().st_size // 1024} KB")


# Do–Mi naik: pendek, ceria, tidak menghentak.
tulis("benar.wav", nada(880, 0.09) + nada(1318.5, 0.16))

# Turun dua nada, bukan dengung kasar — salah bukan hukuman.
tulis("salah.wav", nada(392, 0.11, gelombang="segitiga")
      + nada(311.1, 0.20, gelombang="segitiga"))

# Arpeggio do–mi–sol–do untuk pos selesai.
tulis("naik_level.wav",
      nada(523.3, 0.11) + nada(659.3, 0.11) + nada(784, 0.11)
      + nada(1046.5, 0.34))

# Bintang ketiga: satu nada tinggi yang berdenting sesudah arpeggio.
tulis("bintang.wav", nada(1568, 0.10, volume=0.4) + nada(2093, 0.26, volume=0.35))

# Dorongan roket: sapuan naik panjang plus dentuman rendah.
tulis("lepas_landas.wav",
      campur(sapuan(180, 900, 1.6, volume=0.42),
             sunyi(0.1) + nada(110, 1.2, volume=0.3, gelombang="segitiga")))

# Detik terakhir Kilat 60: tik pendek.
tulis("tik.wav", nada(1200, 0.05, volume=0.3))
