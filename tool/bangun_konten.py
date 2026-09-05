"""Membangun empat berkas konten Planet Kali, Pecah, Ukur, dan Ruang.

Kenapa sebuah skrip dan bukan JSON yang diketik langsung: **aturan
emas**. Satu pos hanya boleh menaikkan satu sumbu kesulitan dari pos
sebelumnya, dan 172 pos berarti 143 peralihan yang masing-masing harus
diperiksa. Diketik tangan, satu-dua di antaranya pasti salah — dan
akibatnya bukan galat, melainkan anak yang berhenti di pos keempat
karena dua hal berubah sekaligus.

Jadi aturannya diperiksa **di sini, saat berkasnya dibuat**. Skrip ini
menolak menulis apa pun kalau ada satu peralihan yang menaikkan dua
sumbu. `test/engine/seed_content_test.dart` memeriksa hal yang sama
atas berkas hasilnya; yang di sini mencegah, yang di sana menangkap.

    python tool/bangun_konten.py

Aman dijalankan berkali-kali: keluarannya ditentukan sepenuhnya oleh
berkas ini, tidak ada satu pun angka acak.
"""

import json
import os

KELUARAN = 'lib/data/local/database/seed/content'

# Sumbu yang **benar-benar berpengaruh** untuk tiap ranah dan bentuk
# soal. Menaikkan sumbu yang diabaikan generatornya menghasilkan pos
# yang lolos aturan emas dan terasa persis sama waktu dimainkan — itu
# kebohongan yang paling sulit ditemukan belakangan.
#
#   bulat     : semua sumbu
#   pecahan   : S1 (penyebut), S2, S4 (melewati satu utuh), S6, operasi
#   desimal   : S1, S2, S4 (menyeberangi bulat), S6, operasi
#   persen    : S1, S2, S6
#   geometri  : S1 (sisi), S2, S3 (segitiga), S6, operasi (luas/keliling)
#   statistik : S1 (rentang nilai), S2, S6, operasi (modus/median/rata)
#   cerita    : S1, S2, S6, operasi (pola ceritanya)


def cfg(**k):
    """Satu DifficultyConfig, dengan bawaan yang sama seperti di Dart."""
    d = {
        'operations': ['tambah'],
        'domain': 'bulat',
        'minOperand': 1,
        'maxOperand': 10,
        'maxResult': None,
        'allowCarry': False,
        'allowNegativeResult': False,
        'unknown': 'hasil',
        'formats': ['pilihanGanda'],
        'optionCount': 3,
        'visualAid': 'benda',
        'timeLimitSeconds': None,
        'questionCount': 10,
    }
    d.update(k)
    return d


def sumbu(c):
    """Cermin persis `DifficultyConfig.sumbu` di Dart."""
    return {
        'ranah': c['domain'],
        'S1': f"{c['minOperand']}-{c['maxOperand']}/{c['maxResult']}",
        'S2': f"{','.join(c['formats'])}/{c['optionCount']}",
        'S3': c['visualAid'],
        'S4': c['allowCarry'],
        'S5': c['unknown'],
        'S6': c['timeLimitSeconds'],
        'operasi': ','.join(c['operations']),
    }


def beda(a, b):
    sa, sb = sumbu(a), sumbu(b)
    return [k for k in sa if str(sa[k]) != str(sb[k])]


def zona(zid, judul, ikon, warna, dasar, tangga, boss):
    """Satu zona: pos latihan menaik satu sumbu, lalu Gerbang Planet.

    `tangga` berisi perubahan untuk tiap pos sesudah yang pertama.
    Tiap perubahan diperiksa di sini juga — bukan diasumsikan benar.
    """
    pos, sekarang = [], dict(dasar)
    semua = [sekarang]
    for langkah in tangga:
        berikut = dict(semua[-1])
        berikut.update(langkah)
        salah = beda(semua[-1], berikut)
        if len(salah) != 1:
            raise SystemExit(
                f'{zid} pos {len(semua) + 1}: {len(salah)} sumbu berubah '
                f'sekaligus ({", ".join(salah) or "tidak ada"}) — '
                f'aturan emas dilanggar'
            )
        semua.append(berikut)

    for i, c in enumerate(semua, start=1):
        pos.append({
            'id': f'l-{zid[2:]}-{i}',
            'orderIndex': i,
            'title': f'Pos {i}',
            'type': 'practice',
            'xpReward': 10,
            'difficultyConfig': c,
        })

    n = len(semua) + 1
    pos.append({
        'id': f'l-{zid[2:]}-{n}',
        'orderIndex': n,
        'title': 'Gerbang Planet',
        'type': 'boss',
        'xpReward': 30,
        'difficultyConfig': dict(boss),
    })
    return {
        'id': zid,
        'title': judul,
        'icon': ikon,
        'color': warna,
        'orderIndex': int(zid.split('-')[-1]),
        'levels': pos,
    }


def gerbang(dasar, **k):
    """Gerbang Planet: 15 soal, tanpa bantuan visual, selalu bertimer.

    Menguji materinya, bukan mengulang bantuannya — jadi bantuan visual
    selalu dimatikan berapa pun keadaan pos sebelumnya.
    """
    d = dict(dasar)
    d.update({
        'questionCount': 15,
        'visualAid': 'tidakAda',
        'timeLimitSeconds': 25,
        'optionCount': 4,
    })
    d.update(k)
    return d


# =====================================================================
# Planet Kali · kelas 3 · 44 pos
# =====================================================================
KALI = '#E08A2E'


def planet_kali():
    z = []

    dasar = cfg(operations=['kali'], minOperand=2, maxOperand=5, maxResult=25)
    z.append(zona(
        'c-3-1', 'Perkalian sampai 5 × 5', 'kali', KALI, dasar,
        [
            {'maxOperand': 10, 'maxResult': 50},
            {'visualAid': 'tidakAda'},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
        ],
        gerbang(dasar, maxOperand=10, maxResult=50),
    ))

    dasar = cfg(operations=['kali'], minOperand=2, maxOperand=10,
                maxResult=100, visualAid='tidakAda')
    z.append(zona(
        'c-3-2', 'Perkalian sampai 10 × 10', 'kali', KALI, dasar,
        [
            {'maxOperand': 12, 'maxResult': 144},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
        ],
        gerbang(dasar, maxOperand=12, maxResult=144),
    ))

    dasar = cfg(operations=['bagi'], minOperand=2, maxOperand=7, maxResult=50)
    z.append(zona(
        'c-3-3', 'Pembagian sampai 50', 'bagi', KALI, dasar,
        [
            {'maxOperand': 10},
            {'visualAid': 'tidakAda'},
            {'unknown': 'operanKiri'},
            {'optionCount': 4},
        ],
        gerbang(dasar, maxOperand=10),
    ))

    dasar = cfg(operations=['bagi'], minOperand=2, maxOperand=10,
                maxResult=100, visualAid='tidakAda')
    z.append(zona(
        'c-3-4', 'Pembagian sampai 100', 'bagi', KALI, dasar,
        [
            {'maxOperand': 12},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    dasar = cfg(operations=['kali', 'bagi'], minOperand=2, maxOperand=10,
                maxResult=100, visualAid='tidakAda')
    z.append(zona(
        'c-3-5', 'Campur kali dan bagi', 'campur', KALI, dasar,
        [
            {'maxOperand': 12},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
            {'timeLimitSeconds': 25},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    dasar = cfg(operations=['kali', 'bagi'], minOperand=2, maxOperand=10,
                maxResult=100, visualAid='tidakAda', unknown='operanKiri')
    z.append(zona(
        'c-3-6', 'Mencari angka yang hilang', 'campur', KALI, dasar,
        [
            {'maxOperand': 12},
            {'unknown': 'operator'},
            {'optionCount': 4},
            {'timeLimitSeconds': 25},
        ],
        gerbang(dasar, maxOperand=12, unknown='operator'),
    ))

    # Delapan pos: zona cerita sengaja paling panjang. Soal cerita
    # butuh lebih banyak pengulangan sebelum bentuknya terasa akrab.
    dasar = cfg(operations=['kali'], formats=['cerita'], minOperand=2,
                maxOperand=10, visualAid='tidakAda')
    z.append(zona(
        'c-3-7', 'Soal cerita kali dan bagi', 'cerita', KALI, dasar,
        [
            {'maxOperand': 12},
            {'operations': ['bagi']},
            {'optionCount': 4},
            {'timeLimitSeconds': 45},
            {'maxOperand': 15},
            {'operations': ['kali', 'bagi']},
        ],
        gerbang(dasar, maxOperand=12, operations=['kali', 'bagi'],
                timeLimitSeconds=45),
    ))
    return z


# =====================================================================
# Planet Pecah · kelas 4 · 40 pos
# =====================================================================
PECAH = '#8A6BC4'


def planet_pecah():
    z = []

    dasar = cfg(domain='pecahan', operations=['tambah'], minOperand=2,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-4-1', 'Menjumlah pecahan sepenyebut', 'pecahan', PECAH, dasar,
        [
            {'maxOperand': 8},
            {'allowCarry': True},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
        ],
        gerbang(dasar, maxOperand=8, allowCarry=True),
    ))

    dasar = cfg(domain='pecahan', operations=['kurang'], minOperand=2,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-4-2', 'Mengurangi pecahan sepenyebut', 'pecahan', PECAH, dasar,
        [
            {'maxOperand': 10},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
            {'maxOperand': 12},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    dasar = cfg(domain='pecahan', operations=['tambah', 'kurang'],
                minOperand=2, maxOperand=8, visualAid='tidakAda',
                allowCarry=True)
    z.append(zona(
        'c-4-3', 'Pecahan melewati satu utuh', 'pecahan', PECAH, dasar,
        [
            {'maxOperand': 10},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
            {'maxOperand': 12},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    dasar = cfg(formats=['geometri'], operations=['kali'], minOperand=3,
                maxOperand=9, visualAid='tidakAda')
    z.append(zona(
        'c-4-4', 'Luas dan keliling', 'geometri', PECAH, dasar,
        [
            {'maxOperand': 12},
            {'operations': ['tambah']},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    # `garisBilangan` di ranah geometri berarti segitiga. Pemakaian
    # ulang sumbu S3 yang sudah ada, bukan sumbu kedelapan.
    dasar = cfg(formats=['geometri'], operations=['kali'], minOperand=3,
                maxOperand=8, visualAid='garisBilangan')
    z.append(zona(
        'c-4-5', 'Luas segitiga', 'geometri', PECAH, dasar,
        [
            {'maxOperand': 12},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
            {'maxOperand': 14},
        ],
        gerbang(dasar, maxOperand=12),
    ))

    dasar = cfg(domain='pecahan', operations=['kali'], minOperand=4,
                maxOperand=8, visualAid='tidakAda', allowCarry=True)
    z.append(zona(
        'c-4-6', 'Perkalian pecahan', 'pecahan', PECAH, dasar,
        [
            {'maxOperand': 10},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
        ],
        gerbang(dasar, maxOperand=10),
    ))

    dasar = cfg(formats=['cerita'], operations=['kali'], minOperand=2,
                maxOperand=10, visualAid='tidakAda')
    z.append(zona(
        'c-4-7', 'Soal cerita bertingkat', 'cerita', PECAH, dasar,
        [
            {'maxOperand': 12},
            {'operations': ['bagi']},
            {'optionCount': 4},
        ],
        gerbang(dasar, maxOperand=12, operations=['kali', 'bagi'],
                timeLimitSeconds=45),
    ))
    return z


# =====================================================================
# Planet Ukur · kelas 5 · 42 pos
# =====================================================================
UKUR = '#D2624C'


def planet_ukur():
    z = []

    dasar = cfg(domain='desimal', operations=['tambah'], minOperand=1,
                maxOperand=49, visualAid='tidakAda')
    z.append(zona(
        'c-5-1', 'Menjumlah desimal', 'desimal', UKUR, dasar,
        [
            {'maxOperand': 79},
            {'allowCarry': True},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
        ],
        gerbang(dasar, maxOperand=79, allowCarry=True),
    ))

    dasar = cfg(domain='desimal', operations=['kurang'], minOperand=1,
                maxOperand=49, visualAid='tidakAda')
    z.append(zona(
        'c-5-2', 'Mengurangi desimal', 'desimal', UKUR, dasar,
        [
            {'maxOperand': 79},
            {'allowCarry': True},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
        ],
        gerbang(dasar, maxOperand=79, allowCarry=True),
    ))

    dasar = cfg(domain='desimal', operations=['tambah', 'kurang'],
                minOperand=1, maxOperand=79, visualAid='tidakAda',
                allowCarry=True)
    z.append(zona(
        'c-5-3', 'Campur desimal', 'desimal', UKUR, dasar,
        [
            {'maxOperand': 99},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
            {'maxOperand': 129},
        ],
        gerbang(dasar, maxOperand=99),
    ))

    # Lima pos, bukan enam. Ranah persen cuma punya tiga sumbu yang
    # benar-benar berpengaruh — memaksanya jadi enam pos berarti satu
    # peralihan yang tidak mengubah apa pun buat anak.
    dasar = cfg(domain='persen', minOperand=20, maxOperand=100,
                visualAid='tidakAda')
    z.append(zona(
        'c-5-4', 'Persen dasar', 'persen', UKUR, dasar,
        [
            {'maxOperand': 200},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
        ],
        gerbang(dasar, maxOperand=200),
    ))

    dasar = cfg(domain='persen', minOperand=20, maxOperand=300,
                visualAid='tidakAda')
    z.append(zona(
        'c-5-5', 'Persen bilangan besar', 'persen', UKUR, dasar,
        [
            {'maxOperand': 500},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
        ],
        gerbang(dasar, maxOperand=500),
    ))

    dasar = cfg(formats=['statistik'], operations=['tambah'], minOperand=1,
                maxOperand=5, visualAid='tidakAda')
    z.append(zona(
        'c-5-6', 'Membaca diagram batang', 'statistik', UKUR, dasar,
        [
            {'maxOperand': 7},
            {'optionCount': 4},
            {'timeLimitSeconds': 40},
            {'maxOperand': 9},
        ],
        gerbang(dasar, maxOperand=7, timeLimitSeconds=40),
    ))

    dasar = cfg(formats=['statistik'], operations=['kurang'], minOperand=1,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-5-7', 'Median dan rata-rata', 'statistik', UKUR, dasar,
        [
            {'maxOperand': 8},
            {'operations': ['kali']},
            {'optionCount': 4},
            {'timeLimitSeconds': 45},
            {'maxOperand': 10},
            {'operations': ['tambah']},
        ],
        gerbang(dasar, maxOperand=8, operations=['kali'],
                timeLimitSeconds=45),
    ))
    return z


# =====================================================================
# Planet Ruang · kelas 6 · 46 pos
# =====================================================================
RUANG = '#4B5DB0'


def planet_ruang():
    z = []

    dasar = cfg(operations=['kurang'], minOperand=1, maxOperand=20,
                allowNegativeResult=True, visualAid='garisBilangan')
    z.append(zona(
        'c-6-1', 'Bilangan bulat negatif', 'bulat', RUANG, dasar,
        [
            {'maxOperand': 50},
            {'visualAid': 'tidakAda'},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
        ],
        gerbang(dasar, maxOperand=50),
    ))

    dasar = cfg(operations=['tambah', 'kurang'], minOperand=1,
                maxOperand=50, allowNegativeResult=True,
                visualAid='tidakAda')
    z.append(zona(
        'c-6-2', 'Operasi bilangan bulat', 'bulat', RUANG, dasar,
        [
            {'maxOperand': 99},
            {'allowCarry': True},
            {'unknown': 'operanKiri'},
            {'optionCount': 4},
        ],
        gerbang(dasar, maxOperand=99, allowCarry=True),
    ))

    dasar = cfg(operations=['kali', 'bagi'], minOperand=2, maxOperand=12,
                maxResult=144, visualAid='tidakAda')
    z.append(zona(
        'c-6-3', 'Kali dan bagi bilangan besar', 'kali', RUANG, dasar,
        [
            {'maxOperand': 15, 'maxResult': 225},
            {'unknown': 'operanKanan'},
            {'optionCount': 4},
            {'timeLimitSeconds': 25},
        ],
        gerbang(dasar, maxOperand=15, maxResult=225),
    ))

    dasar = cfg(formats=['geometri'], operations=['kali'], minOperand=5,
                maxOperand=14, visualAid='tidakAda')
    z.append(zona(
        'c-6-4', 'Luas bangun datar', 'geometri', RUANG, dasar,
        [
            {'maxOperand': 18},
            {'operations': ['tambah']},
            {'optionCount': 4},
            {'timeLimitSeconds': 30},
        ],
        gerbang(dasar, maxOperand=18),
    ))

    dasar = cfg(formats=['statistik'], operations=['tambah'], minOperand=1,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-6-5', 'Modus', 'statistik', RUANG, dasar,
        [
            {'maxOperand': 8},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
            {'maxOperand': 10},
        ],
        gerbang(dasar, maxOperand=8, timeLimitSeconds=35),
    ))

    dasar = cfg(formats=['statistik'], operations=['kurang'], minOperand=1,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-6-6', 'Median', 'statistik', RUANG, dasar,
        [
            {'maxOperand': 8},
            {'optionCount': 4},
            {'timeLimitSeconds': 35},
            {'maxOperand': 10},
        ],
        gerbang(dasar, maxOperand=8, timeLimitSeconds=35),
    ))

    dasar = cfg(formats=['statistik'], operations=['kali'], minOperand=1,
                maxOperand=6, visualAid='tidakAda')
    z.append(zona(
        'c-6-7', 'Rata-rata', 'statistik', RUANG, dasar,
        [
            {'maxOperand': 8},
            {'optionCount': 4},
            {'timeLimitSeconds': 40},
        ],
        gerbang(dasar, maxOperand=8, timeLimitSeconds=40),
    ))

    dasar = cfg(operations=['tambah', 'kurang', 'kali', 'bagi'],
                minOperand=2, maxOperand=20, maxResult=200,
                visualAid='tidakAda')
    z.append(zona(
        'c-6-8', 'Gerbang Galaksi', 'campur', RUANG, dasar,
        [
            {'maxOperand': 30, 'maxResult': 300},
            {'optionCount': 4},
            {'timeLimitSeconds': 20},
        ],
        gerbang(dasar, maxOperand=30, maxResult=300, timeLimitSeconds=20),
    ))
    return z


PLANET = [
    ('planet_kali', 'grade-3', 'Planet Kali', 3, 'kali', KALI, planet_kali),
    ('planet_pecah', 'grade-4', 'Planet Pecah', 4, 'pecah', PECAH,
     planet_pecah),
    ('planet_ukur', 'grade-5', 'Planet Ukur', 5, 'ukur', UKUR, planet_ukur),
    ('planet_ruang', 'grade-6', 'Planet Ruang', 6, 'ruang', RUANG,
     planet_ruang),
]


def main():
    os.makedirs(KELUARAN, exist_ok=True)
    total = 0
    for berkas, gid, nama, urutan, ikon, warna, buat in PLANET:
        zonas = buat()
        isi = {
            'grade': {
                'id': gid,
                'name': nama,
                'orderIndex': urutan,
                'icon': ikon,
                'color': warna,
            },
            'chapters': zonas,
        }
        n = sum(len(z['levels']) for z in zonas)
        total += n
        jalur = f'{KELUARAN}/{berkas}.json'
        with open(jalur, 'w', encoding='utf-8') as f:
            json.dump(isi, f, ensure_ascii=False, indent=2)
            f.write('\n')
        print(f'{nama:14s} {len(zonas)} zona | {n:3d} pos  -> {jalur}')

    print(f'\n{total} pos baru. Dengan 78 pos Tahap 1–2, totalnya '
          f'{total + 78}.')
    if total != 172:
        raise SystemExit(f'GAGAL: seharusnya 172 pos, dapat {total}')


if __name__ == '__main__':
    main()
