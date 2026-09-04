"""Memeriksa aturan keamanan Firestore yang **sedang aktif di server**.

Bukan pengganti `flutter test`. Yang diuji di sini justru yang tidak bisa
disentuh uji Dart mana pun: apakah `firestore.rules` yang barusan
di-deploy benar-benar menolak hal yang seharusnya ditolak, di proyek
sungguhan, lewat jaringan sungguhan.

Kenapa ini perlu ada sebagai berkas, bukan sekadar dijalankan sekali:
aturan keamanan adalah satu-satunya bagian sistem ini yang **tidak ikut
dikompilasi**. Salah ketik di dalamnya tidak membuat satu pun uji merah
dan tidak membuat aplikasinya gagal jalan — kegagalannya diam, dan
bentuknya adalah data anak yang bisa dibaca orang lain. Satu-satunya
cara tahu adalah mencobanya.

Dipakai memakai API key publik saja, yang sama persis dengan yang ikut
masuk ke tiap APK. Tidak ada kredensial istimewa dan tidak ada akun
layanan: kalau skrip ini bisa menembus sesuatu, aplikasi hasil bongkaran
pun bisa.

    python tool/periksa_aturan.py            # membaca env.json
    python tool/periksa_aturan.py env.lain.json

Akun anonim dan seluruh dokumen yang dibuatnya dihapus di akhir.
"""

import json
import sys
import urllib.error
import urllib.request

berkas = sys.argv[1] if len(sys.argv) > 1 else 'env.json'
with open(berkas, encoding='utf-8') as f:
    env = json.load(f)

KUNCI = env['FIREBASE_API_KEY']
PROYEK = env['FIREBASE_PROJECT_ID']
DOK = (
    f'https://firestore.googleapis.com/v1/projects/{PROYEK}'
    '/databases/%28default%29/documents'
)
AUTH = 'https://identitytoolkit.googleapis.com/v1/accounts'
MINGGU = '2026-W36'


def panggil(url, data=None, token=None, metode=None):
    req = urllib.request.Request(url, method=metode)
    if data is not None:
        req.data = json.dumps(data).encode()
        req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', 'Bearer ' + token)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status
    except urllib.error.HTTPError as e:
        return e.code


def baca(url, token):
    """Isi dokumen, atau None kalau tidak ada atau tidak boleh dibaca."""
    req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read()).get('fields')
    except urllib.error.HTTPError:
        return None


def teks(v):
    return {'stringValue': v}


def angka(v):
    return {'integerValue': str(v)}


gagal = []


def catat(nama, dapat, harap):
    if dapat != harap:
        gagal.append(nama)
    tanda = 'ok   ' if dapat == harap else 'GAGAL'
    print(f'{tanda} {dapat} (harap {harap})  {nama}')


def masuk():
    req = urllib.request.Request(
        f'{AUTH}:signUp?key={KUNCI}',
        data=json.dumps({'returnSecureToken': True}).encode(),
        headers={'Content-Type': 'application/json'},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            a = json.loads(r.read())
    except urllib.error.HTTPError as e:
        pesan = json.loads(e.read() or b'{}').get('error', {}).get('message', e.code)
        sys.exit(
            f'Tidak bisa masuk anonim: {pesan}\n'
            'Provider Anonymous sudah dinyalakan di konsol Authentication?'
        )
    return a['localId'], a['idToken']


# Delapan field yang dijanjikan layar "Data yang dikirim", dan bukan yang
# lain. Harus sama persis dengan `ProfilDaring.fieldnya`.
PROFIL = {
    'nickname': teks('RoketUji'),
    'avatarId': teks('roket'),
    'gradeLevel': teks('grade-1'),
    'totalXp': angka(120),
    'streakCount': angka(3),
    'weeklyXp': angka(40),
    'lastSyncAt': teks('2026-09-04T05:00:00Z'),
    'platform': teks('android'),
}

# Sama persis dengan `CadanganProgres.sebagaiPeta`.
CADANGAN = {
    'levels': {'mapValue': {'fields': {'l-1-1-1': teks('3,10')}}},
    'badges': {'arrayValue': {'values': [teks('pos_pertama')]}},
    'updatedAt': teks('2026-09-04T05:00:00Z'),
}

ENTRI = {
    'nickname': teks('RoketUji'),
    'avatarId': teks('roket'),
    'xp': angka(40),
    'league': angka(1),
    'updatedAt': teks('2026-09-04T05:00:00Z'),
}

print(f'Proyek {PROYEK}\n')
uid, tok = masuk()
uid2, tok2 = masuk()
catat('masuk anonim (provider Anonymous menyala)', 200, 200)

# Penghitung liga itu milik bersama seluruh anak di minggu itu, bukan
# milik akun uji ini — dan aturannya sengaja tidak mengizinkan `delete`.
# Jadi nilainya dicatat dulu dan dikembalikan di akhir. Tanpa itu, tiap
# kali skrip ini dijalankan pembagian liga anak sungguhan bergeser satu.
penghitung_awal = baca(f'{DOK}/leaderboard_weekly/{MINGGU}', tok)

# ------------------------------------------------- milik sendiri, boleh
catat(
    'menulis 8 field profil sendiri',
    panggil(f'{DOK}/users/{uid}', {'fields': PROFIL}, tok, 'PATCH'),
    200,
)
catat(
    'menulis cadangan sendiri',
    panggil(
        f'{DOK}/users/{uid}/cadangan/progres', {'fields': CADANGAN}, tok, 'PATCH'
    ),
    200,
)
catat(
    'mendaftar liga (penghitung)',
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}',
        {
            'fields': {
                'ligaTerakhir': angka(1),
                'jumlah': angka(1),
                'ukuran': angka(30),
            }
        },
        tok,
        'PATCH',
    ),
    200,
)
catat(
    'menulis skor sendiri',
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}',
        {'fields': ENTRI},
        tok,
        'PATCH',
    ),
    200,
)
catat(
    'membaca papan liga (memang untuk dibaca bersama)',
    panggil(f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}', None, tok2),
    200,
)

# --------------------------------- field di luar yang dijanjikan, tolak
catat(
    'menyelundupkan nomorHp ke profil',
    panggil(
        f'{DOK}/users/{uid}',
        {'fields': dict(PROFIL, nomorHp=teks('081234567890'))},
        tok,
        'PATCH',
    ),
    403,
)
catat(
    'menyelundupkan jawabanTiapSoal ke cadangan',
    panggil(
        f'{DOK}/users/{uid}/cadangan/progres',
        {'fields': dict(CADANGAN, jawabanTiapSoal=teks('2+3=6'))},
        tok,
        'PATCH',
    ),
    403,
)
catat(
    'menyelundupkan sekolah ke baris papan peringkat',
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}',
        {'fields': dict(ENTRI, sekolah=teks('SDN 1'))},
        tok,
        'PATCH',
    ),
    403,
)
catat(
    'nama 2 huruf di papan peringkat',
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}',
        {'fields': dict(ENTRI, nickname=teks('Ab'))},
        tok,
        'PATCH',
    ),
    403,
)

# --------------------------------------------------- milik orang, tolak
catat(
    'akun lain membaca profil saya',
    panggil(f'{DOK}/users/{uid}', None, tok2),
    403,
)
catat(
    'akun lain menimpa profil saya',
    panggil(f'{DOK}/users/{uid}', {'fields': PROFIL}, tok2, 'PATCH'),
    403,
)
catat(
    'akun lain membaca cadangan saya',
    panggil(f'{DOK}/users/{uid}/cadangan/progres', None, tok2),
    403,
)
catat(
    'akun lain memalsukan skor saya',
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}',
        {'fields': ENTRI},
        tok2,
        'PATCH',
    ),
    403,
)
catat(
    'tanpa masuk sama sekali',
    panggil(f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}'),
    403,
)

# ----------------------------- tombol "Hapus data di server" harus jalan
catat(
    'menghapus cadangan sendiri',
    panggil(f'{DOK}/users/{uid}/cadangan/progres', None, tok, 'DELETE'),
    200,
)
catat(
    'menghapus profil sendiri',
    panggil(f'{DOK}/users/{uid}', None, tok, 'DELETE'),
    200,
)
catat(
    'menghapus skor sendiri',
    panggil(f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid}', None, tok, 'DELETE'),
    200,
)
catat(
    'menghapus skor akun lain',
    panggil(f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{uid2}', None, tok, 'DELETE'),
    403,
)

# ------------------------------------------------------------ bersihkan
if penghitung_awal is not None:
    panggil(
        f'{DOK}/leaderboard_weekly/{MINGGU}',
        {'fields': penghitung_awal},
        tok,
        'PATCH',
    )

for t, u in ((tok, uid), (tok2, uid2)):
    panggil(f'{DOK}/users/{u}/cadangan/progres', None, t, 'DELETE')
    panggil(f'{DOK}/users/{u}', None, t, 'DELETE')
    panggil(f'{DOK}/leaderboard_weekly/{MINGGU}/entries/{u}', None, t, 'DELETE')
    panggil(f'{AUTH}:delete?key={KUNCI}', {'idToken': t})
print('\n(data uji dan kedua akun anonim dihapus; penghitung liga dipulihkan)')

if gagal:
    print(f'\n{len(gagal)} pemeriksaan GAGAL:')
    for g in gagal:
        print(f'  - {g}')
    sys.exit(1)
print('\nSeluruh pemeriksaan sesuai harapan.')
