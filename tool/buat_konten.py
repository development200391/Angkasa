"""Bangkitkan berkas seed Planet Mula dan Planet Puluh.

Tiap zona ditulis sebagai satu konfigurasi dasar untuk Pos 1 lalu empat
delta — satu delta, satu sumbu. Aturan emas ("satu pos hanya menaikkan
satu sumbu") jadi tidak bisa dilanggar tanpa terlihat di sini, dan
`test/engine/seed_content_test.dart` memeriksanya lagi atas hasilnya.

    python tool/buat_konten.py
"""
import json
import pathlib

TUJUAN = pathlib.Path(__file__).resolve().parent.parent / \
    "lib/data/local/database/seed/content"

DASAR = {
    "operations": ["tambah"],
    "minOperand": 1,
    "maxOperand": 10,
    "maxResult": None,
    "allowCarry": False,
    "allowNegativeResult": False,
    "unknown": "hasil",
    "formats": ["pilihanGanda"],
    "optionCount": 3,
    "visualAid": "benda",
    "timeLimitSeconds": None,
    "questionCount": 10,
}


def cfg(**ubah):
    c = dict(DASAR)
    c.update(ubah)
    return c


# ---------------------------------------------------------------- zona
# (judul, ikon, konfigurasi pos 1, [delta pos 2..5], delta gerbang)
MULA = [
    (
        "Bilangan sampai 10", "hitung",
        cfg(minOperand=1, maxOperand=5, maxResult=8),
        [
            {"maxOperand": 9, "maxResult": 10},          # S1
            {"optionCount": 4},                          # S2
            {"visualAid": "garisBilangan"},              # S3
            {"formats": ["isian"]},                      # S2
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Penjumlahan sampai 20", "tambah",
        cfg(minOperand=1, maxOperand=5, maxResult=10),
        [
            {"maxOperand": 10, "maxResult": 20},         # S1
            {"visualAid": "garisBilangan"},              # S3
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKanan"},                  # S5
        ],
        {"timeLimitSeconds": 20},
    ),
    (
        "Pengurangan sampai 20", "kurang",
        cfg(operations=["kurang"], minOperand=1, maxOperand=10, maxResult=10),
        [
            {"maxOperand": 20, "maxResult": 20},         # S1
            {"visualAid": "garisBilangan"},              # S3
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKanan"},                  # S5
        ],
        {"timeLimitSeconds": 20},
    ),
    (
        "Tambah dan kurang sampai 20", "campur",
        cfg(operations=["tambah", "kurang"], minOperand=1, maxOperand=10,
            maxResult=20, visualAid="garisBilangan"),
        [
            {"optionCount": 4},                          # S2
            {"visualAid": "tidakAda"},                   # S3
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKiri"},                   # S5
        ],
        {"timeLimitSeconds": 20},
    ),
    (
        "Puluhan sampai 100", "puluhan",
        cfg(minOperand=10, maxOperand=40, maxResult=50,
            visualAid="garisBilangan"),
        [
            {"maxOperand": 50, "maxResult": 100},        # S1
            {"visualAid": "tidakAda"},                   # S3
            {"optionCount": 4},                          # S2
            {"formats": ["isian"]},                      # S2
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Tambah kurang tanpa menyimpan", "campur",
        cfg(operations=["tambah", "kurang"], minOperand=10, maxOperand=50,
            maxResult=100, optionCount=4, visualAid="tidakAda"),
        [
            {"maxOperand": 99},                          # S1
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKanan"},                  # S5
            {"timeLimitSeconds": 30},                    # S6
        ],
        {"timeLimitSeconds": 20},
    ),
]

PULUH = [
    (
        "Nilai tempat sampai 100", "nilaitempat",
        cfg(minOperand=10, maxOperand=50, maxResult=100,
            visualAid="tidakAda"),
        [
            {"maxOperand": 90},                          # S1
            {"optionCount": 4},                          # S2
            {"unknown": "operanKanan"},                  # S5
            {"formats": ["isian"]},                      # S2
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Penjumlahan dengan menyimpan", "simpan",
        cfg(minOperand=10, maxOperand=30, maxResult=100, allowCarry=True,
            visualAid="tidakAda"),
        [
            {"maxOperand": 50},                          # S1
            {"optionCount": 4},                          # S2
            {"maxOperand": 89},                          # S1
            {"formats": ["isian"]},                      # S2
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Pengurangan dengan meminjam", "pinjam",
        cfg(operations=["kurang"], minOperand=10, maxOperand=30,
            maxResult=100, allowCarry=True, visualAid="tidakAda"),
        [
            {"maxOperand": 50},                          # S1
            {"optionCount": 4},                          # S2
            {"maxOperand": 99},                          # S1
            {"formats": ["isian"]},                      # S2
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Campur menyimpan dan meminjam", "campur",
        cfg(operations=["tambah", "kurang"], minOperand=10, maxOperand=50,
            maxResult=100, allowCarry=True, visualAid="tidakAda"),
        [
            {"maxOperand": 99},                          # S1
            {"optionCount": 4},                          # S2
            {"unknown": "operanKanan"},                  # S5
            {"unknown": "operator"},                     # S5
        ],
        {"timeLimitSeconds": 25, "formats": ["pilihanGanda"]},
    ),
    (
        "Perkalian dasar", "kali",
        cfg(operations=["kali"], minOperand=2, maxOperand=5, maxResult=50,
            visualAid="tidakAda"),
        [
            {"maxOperand": 10, "maxResult": 100},        # S1
            {"optionCount": 4},                          # S2
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKanan"},                  # S5
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Pembagian dasar", "bagi",
        cfg(operations=["bagi"], minOperand=2, maxOperand=5, maxResult=50,
            visualAid="tidakAda"),
        [
            {"maxOperand": 10, "maxResult": 100},        # S1
            {"optionCount": 4},                          # S2
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKiri"},                   # S5
        ],
        {"timeLimitSeconds": 25},
    ),
    (
        "Campur empat operasi", "campur",
        cfg(operations=["tambah", "kurang", "kali"], minOperand=2,
            maxOperand=10, maxResult=100, optionCount=4,
            visualAid="tidakAda"),
        [
            {"operations": ["tambah", "kurang", "kali", "bagi"]},  # operasi
            {"formats": ["isian"]},                      # S2
            {"unknown": "operanKanan"},                  # S5
            {"timeLimitSeconds": 25},                    # S6
        ],
        {"timeLimitSeconds": 20},
    ),
]


def bangun(grade_id, nama, urutan, ikon, warna, zona_zona):
    chapters = []
    for zi, (judul, ikon_zona, dasar, delta, gerbang) in enumerate(
            zona_zona, start=1):
        levels = []
        sekarang = dict(dasar)
        levels.append({
            "id": f"l-{urutan}-{zi}-1",
            "orderIndex": 1,
            "title": "Pos 1",
            "type": "practice",
            "xpReward": 10,
            "difficultyConfig": sekarang,
        })
        for pi, d in enumerate(delta, start=2):
            sekarang = dict(sekarang)
            sekarang.update(d)
            levels.append({
                "id": f"l-{urutan}-{zi}-{pi}",
                "orderIndex": pi,
                "title": f"Pos {pi}",
                "type": "practice",
                "xpReward": 10,
                "difficultyConfig": sekarang,
            })

        # Gerbang Planet: 15 soal campuran pos 1–5, tanpa bantuan visual.
        boss = dict(sekarang)
        boss.update({
            "formats": ["pilihanGanda", "isian"],
            "optionCount": 4,
            "visualAid": "tidakAda",
            "unknown": "hasil",
            "questionCount": 15,
        })
        boss.update(gerbang)
        levels.append({
            "id": f"l-{urutan}-{zi}-6",
            "orderIndex": 6,
            "title": "Gerbang Planet",
            "type": "boss",
            "xpReward": 30,
            "difficultyConfig": boss,
        })

        chapters.append({
            "id": f"c-{urutan}-{zi}",
            "title": judul,
            "icon": ikon_zona,
            "color": warna,
            "orderIndex": zi,
            "levels": levels,
        })

    return {
        "grade": {
            "id": grade_id,
            "name": nama,
            "orderIndex": urutan,
            "icon": ikon,
            "color": warna,
        },
        "chapters": chapters,
    }


def tulis(nama_berkas, isi):
    TUJUAN.mkdir(parents=True, exist_ok=True)
    p = TUJUAN / nama_berkas
    p.write_text(json.dumps(isi, ensure_ascii=False, indent=2) + "\n",
                 encoding="utf-8")
    pos = sum(len(c["levels"]) for c in isi["chapters"])
    print(f"{p.name}: {len(isi['chapters'])} zona, {pos} pos")


if __name__ == "__main__":
    tulis("planet_mula.json",
          bangun("grade-1", "Planet Mula", 1, "mula", "#4FA3D9", MULA))
    tulis("planet_puluh.json",
          bangun("grade-2", "Planet Puluh", 2, "puluh", "#3E9E77", PULUH))
