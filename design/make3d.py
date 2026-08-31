"""Suntikkan tampilan tiga dimensi ke design/ui.html.

Menghasilkan geometri bintang bersegi dan gradien bola untuk node lintasan,
lalu menambal bagian yang perlu di ui.html. Dijalankan sekali; hasilnya
tersimpan permanen di ui.html sehingga berkas itu tetap jadi sumber
yang bisa diedit tangan.

    python design/make3d.py
"""
import math
import re
from pathlib import Path

UI = Path(__file__).resolve().parent / "ui.html"


# ---------------------------------------------------------------- warna
def hx(c):
    c = c.lstrip("#")
    return tuple(int(c[i:i + 2], 16) for i in (0, 2, 4))


def mix(a, b, t):
    ra, rb = hx(a), hx(b)
    return "#%02X%02X%02X" % tuple(round(ra[i] + (rb[i] - ra[i]) * t) for i in range(3))


# ------------------------------------------------- bintang bersegi (3D)
def bintang(dark, mid, light, outline):
    """Bintang lima sudut yang dipecah jadi 10 sisi, tiap sisi diberi
    terang berbeda sesuai arah cahaya dari kiri-atas. Itu yang membuat
    bentuknya terbaca timbul, bukan datar."""
    cx, cy = 50.0, 51.0
    R, r = 47.0, 19.5
    v = []
    for i in range(10):
        a = math.radians(-90 + i * 36)
        rad = R if i % 2 == 0 else r
        v.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))

    lx, ly = -0.42, -0.91          # arah cahaya
    sisi = []
    for i in range(10):
        p1, p2 = v[i], v[(i + 1) % 10]
        mxp = ((p1[0] + p2[0]) / 2 - cx, (p1[1] + p2[1]) / 2 - cy)
        n = math.hypot(*mxp) or 1
        d = (mxp[0] / n) * lx + (mxp[1] / n) * ly       # -1 .. 1
        t = (d + 1) / 2
        warna = mix(dark, light, t) if t > .5 else mix(dark, mid, t * 2)
        sisi.append(
            f'<path d="M{cx:.1f} {cy:.1f}L{p1[0]:.1f} {p1[1]:.1f}'
            f'L{p2[0]:.1f} {p2[1]:.1f}Z" fill="{warna}"/>'
        )

    tepi = "M" + "L".join(f"{x:.1f} {y:.1f}" for x, y in v) + "Z"
    return (
        f'<path d="{tepi}" fill="{dark}" transform="translate(0 2.5)" opacity=".45"/>'
        + "".join(sisi)
        + f'<path d="{tepi}" fill="none" stroke="{outline}" stroke-width="1.1" '
          'stroke-linejoin="round" opacity=".55"/>'
    )


def bola(id_, terang, tengah, gelap):
    """Gradien radial dengan titik cahaya digeser ke kiri-atas."""
    return (
        f'<radialGradient id="{id_}" cx="33%" cy="27%" r="82%">'
        f'<stop offset="0" stop-color="{terang}"/>'
        f'<stop offset="48%" stop-color="{tengah}"/>'
        f'<stop offset="100%" stop-color="{gelap}"/></radialGradient>'
    )


DEFS = (
    '<svg id="defs3d" width="0" height="0" style="position:absolute" aria-hidden="true"><defs>'
    + bola("gDone", "#63CCA3", "#2E8563", "#134A37")
    + bola("gActive", "#FFD98A", "#E9B24C", "#9C5E0B")
    + bola("gLock", "#3A4767", "#232E4A", "#141C31")
    + '<radialGradient id="gGlow" cx="50%" cy="50%" r="50%">'
      '<stop offset="0" stop-color="#E9B24C" stop-opacity=".38"/>'
      '<stop offset="100%" stop-color="#E9B24C" stop-opacity="0"/></radialGradient>'
    + '<symbol id="star3d" viewBox="0 0 100 104">'
    + bintang("#8A5209", "#D99A34", "#FFE7B0", "#7A4707")
    + "</symbol>"
    + '<symbol id="star3dOff" viewBox="0 0 100 104">'
    + bintang("#18213A", "#26314F", "#41507A", "#141C31")
    + "</symbol>"
    + '<symbol id="star3dOffLight" viewBox="0 0 100 104">'
    + bintang("#B6BFCE", "#CFD6E1", "#F1F4F9", "#AAB4C4")
    + "</symbol>"
    + "</defs></svg>"
)


# ----------------------------------------------------------- node bola
def node(cx, cy, r, grad, label=None, warna_teks="#EAF6F1", fs=19):
    """Bola dengan bayangan jatuh, kilau, dan tepi bawah yang lebih gelap."""
    out = [
        f'<ellipse cx="{cx}" cy="{cy + r * .96:.1f}" rx="{r * .82:.1f}" ry="{r * .22:.1f}" fill="#060B18" opacity=".45"/>',
        f'<circle cx="{cx}" cy="{cy + 3}" r="{r}" fill="#060B18" opacity=".35"/>',
        f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="url(#{grad})"/>',
        f'<path d="M {cx - r * .72:.1f} {cy + r * .48:.1f} A {r} {r} 0 0 0 {cx + r * .72:.1f} {cy + r * .48:.1f}" '
        f'fill="none" stroke="#FFFFFF" stroke-width="{r * .09:.1f}" opacity=".16" stroke-linecap="round"/>',
        f'<ellipse cx="{cx - r * .3:.1f}" cy="{cy - r * .42:.1f}" rx="{r * .34:.1f}" ry="{r * .24:.1f}" '
        f'fill="#FFFFFF" opacity=".34" transform="rotate(-28 {cx - r * .3:.1f} {cy - r * .42:.1f})"/>',
    ]
    if label:
        out.append(
            f'<text x="{cx}" y="{cy + fs * .35:.1f}" text-anchor="middle" font-family="Fredoka" '
            f'font-size="{fs}" font-weight="600" fill="{warna_teks}" '
            f'style="paint-order:stroke" stroke="#0B1120" stroke-width=".9" stroke-opacity=".35">{label}</text>'
        )
    return "".join(out)


def deret_bintang(cx, y, n, ukuran=15, jarak=15):
    """Baris bintang kecil di bawah node yang sudah selesai."""
    x0 = cx - (jarak * (n - 1)) / 2 - ukuran / 2
    return "".join(
        f'<use href="#star3d" x="{x0 + i * jarak:.1f}" y="{y}" width="{ukuran}" height="{ukuran * 1.04:.1f}"/>'
        for i in range(n)
    )


# ------------------------------------------------------------- lintasan
JALUR = ("M 92 52 Q 196 78 244 130 Q 288 182 268 232 Q 240 292 168 322 "
         "Q 96 352 96 402 Q 96 448 200 470")


def peta_utama():
    g = [
        # rel bawah lebih gelap → lintasannya terlihat punya ketebalan
        f'<path d="{JALUR}" fill="none" stroke="#060B18" stroke-width="9" stroke-linecap="round" '
        'stroke-dasharray="1 18" opacity=".55" transform="translate(0 3)"/>',
        f'<path d="{JALUR}" fill="none" stroke="rgba(255,255,255,.16)" stroke-width="8" '
        'stroke-linecap="round" stroke-dasharray="1 18"/>',
        node(92, 52, 28, "gDone", "1"), deret_bintang(92, 84, 3),
        node(244, 130, 28, "gDone", "2"), deret_bintang(244, 162, 2),
        node(268, 232, 28, "gDone", "3"), deret_bintang(268, 264, 1),
        # pos aktif
        '<circle cx="168" cy="322" r="58" fill="url(#gGlow)"/>',
        node(168, 322, 31, "gActive", "4", "#3A2405", 21),
        '<rect x="130" y="366" width="76" height="26" rx="13" fill="#8A5209"/>',
        '<rect x="130" y="364" width="76" height="26" rx="13" fill="#E9B24C"/>',
        '<text x="168" y="382" text-anchor="middle" font-family="Fredoka" font-size="12.5" '
        'font-weight="600" fill="#3A2405">MULAI</text>',
        # pos terkunci
        node(96, 402, 27, "gLock"),
        '<rect x="88" y="396" width="16" height="12" rx="2.5" fill="#8C99BC"/>',
        '<path d="M 91.5 396 v-4.5 a4.5 4.5 0 0 1 9 0 v4.5" fill="none" stroke="#8C99BC" stroke-width="2.4"/>',
        # gerbang planet
        '<circle cx="200" cy="470" r="42" fill="none" stroke="#3A4767" stroke-width="2.4" stroke-dasharray="6 8"/>',
        node(200, 470, 30, "gLock"),
        '<use href="#star3dOff" x="186" y="455" width="28" height="29"/>',
    ]
    return "".join(g)


JALUR3 = "M 92 22 Q 196 48 244 100 Q 288 152 268 202 Q 240 262 168 292"


def peta_sheet():
    return "".join([
        f'<path d="{JALUR3}" fill="none" stroke="#060B18" stroke-width="9" stroke-linecap="round" '
        'stroke-dasharray="1 18" opacity=".55" transform="translate(0 3)"/>',
        f'<path d="{JALUR3}" fill="none" stroke="rgba(255,255,255,.16)" stroke-width="8" '
        'stroke-linecap="round" stroke-dasharray="1 18"/>',
        node(92, 22, 28, "gDone", "1"),
        node(244, 100, 28, "gDone", "2"),
        node(268, 202, 28, "gDone", "3"),
    ])


# ------------------------------------------------------------- penambal
def main():
    h = UI.read_text(encoding="utf-8")

    if "defs3d" not in h:
        h = h.replace("<body>\n", "<body>\n" + DEFS + "\n", 1)

    # --- CSS tombol dan pilihan jawaban -------------------------------
    h = h.replace(
        ".btn.primary{background:var(--brand);color:#fff;box-shadow:0 4px 0 #97600C}",
        """.btn.primary{
  background:linear-gradient(180deg,#E6A945 0%,#C98216 44%,#A96A0D 100%);
  color:#fff;text-shadow:0 1.5px 0 rgba(74,44,3,.45);border-radius:20px;
  box-shadow:
    inset 0 2px 0 rgba(255,255,255,.5),
    inset 0 -3px 0 rgba(96,58,4,.35),
    0 7px 0 #7E4E07,
    0 13px 18px -7px rgba(52,32,2,.55);
}""")

    h = h.replace(
        """.opt{
  height:64px;border-radius:18px;background:var(--surface);border:2px solid var(--line);
  box-shadow:0 3px 0 var(--line);
  display:flex;align-items:center;justify-content:center;
  font-size:26px;font-weight:600;font-variant-numeric:tabular-nums;
}""",
        """.opt{
  height:64px;border-radius:20px;
  background:linear-gradient(180deg,#FFFFFF 0%,#F2F5FA 100%);
  border:1.5px solid #D6DDE8;
  box-shadow:
    inset 0 2px 0 #FFFFFF,
    inset 0 -2px 0 rgba(120,133,158,.14),
    0 6px 0 #D2D9E5,
    0 11px 15px -8px rgba(28,40,64,.4);
  display:flex;align-items:center;justify-content:center;
  font-size:26px;font-weight:600;font-variant-numeric:tabular-nums;
}""")

    h = h.replace(
        ".opt.ok{border-color:var(--ok);background:var(--okSoft);color:var(--ok);box-shadow:0 3px 0 #B9DACD}",
        """.opt.ok{
  border-color:#3E9B7C;color:#1C5B49;
  background:linear-gradient(180deg,#EFF9F5 0%,#D8EEE6 100%);
  box-shadow:inset 0 2px 0 #FFFFFF,0 6px 0 #A8CFBF,0 11px 15px -8px rgba(16,64,50,.4);
}""")
    h = h.replace(
        ".opt.no{border-color:var(--wrong);background:var(--wrongSoft);color:var(--wrong);box-shadow:0 3px 0 #EFC3C8}",
        """.opt.no{
  border-color:#C95565;color:#8E2C3A;
  background:linear-gradient(180deg,#FEF2F3 0%,#F7DCE0 100%);
  box-shadow:inset 0 2px 0 #FFFFFF,0 6px 0 #E5B2BA,0 11px 15px -8px rgba(90,20,30,.38);
}""")

    h = h.replace(
        """.key{
  flex:1;height:58px;border-radius:16px;background:var(--surface);border:1.5px solid var(--line);
  box-shadow:0 2px 0 var(--line);display:flex;align-items:center;justify-content:center;
  font-size:24px;font-weight:600;
}""",
        """.key{
  flex:1;height:58px;border-radius:17px;border:1.5px solid #D6DDE8;
  background:linear-gradient(180deg,#FFFFFF 0%,#F1F4FA 100%);
  box-shadow:inset 0 1.5px 0 #FFFFFF,0 4px 0 #D5DCE7,0 8px 11px -7px rgba(28,40,64,.35);
  display:flex;align-items:center;justify-content:center;
  font-size:24px;font-weight:600;
}""")

    # kotak isian jawaban ikut dibuat cekung, kebalikan dari tombol
    h = h.replace(
        'style="height:70px;border-radius:18px;border:2.5px solid var(--brand);background:#fff;',
        'style="height:70px;border-radius:20px;border:2.5px solid var(--brand);'
        'background:linear-gradient(180deg,#F4F6FB 0%,#FFFFFF 62%);'
        'box-shadow:inset 0 3px 7px rgba(40,54,82,.13);')

    # --- peta lintasan -------------------------------------------------
    h = re.sub(r'<path d="M 92 52.*?</svg>', peta_utama() + "</svg>", h, count=1, flags=re.S)
    h = re.sub(r'<path d="M 92 22.*?</svg>', peta_sheet() + "</svg>", h, count=1, flags=re.S)

    # --- bintang di sheet detail pos (tiga bintang kosong) --------------
    h = re.sub(
        r'<div style="display:flex;gap:7px;margin-bottom:16px">.*?</div>\s*(?=<div style="display:flex;gap:10px)',
        '<div style="display:flex;gap:9px;margin-bottom:18px">'
        + '<svg width="34" height="35" viewBox="0 0 100 104"><use href="#star3dOffLight" width="100" height="104"/></svg>' * 3
        + "</div>\n      ",
        h, count=1, flags=re.S)

    # --- bintang besar di layar hasil ----------------------------------
    h = re.sub(
        r'<div style="display:flex;align-items:flex-end;gap:8px;margin:52px 0 26px">.*?</div>\s*(?=<div style="font-size:28px)',
        '<div style="display:flex;align-items:flex-end;gap:6px;margin:50px 0 26px">'
        '<svg width="74" height="77" viewBox="0 0 100 104"><use href="#star3d" width="100" height="104"/></svg>'
        '<svg width="100" height="104" viewBox="0 0 100 104" style="margin-bottom:10px">'
        '<use href="#star3d" width="100" height="104"/></svg>'
        '<svg width="74" height="77" viewBox="0 0 100 104"><use href="#star3dOff" width="100" height="104"/></svg>'
        "</div>\n\n    ",
        h, count=1, flags=re.S)

    # --- bintang kecil di bilah atas peta -------------------------------
    h = h.replace(
        '<svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">'
        '<path d="M12 2l2.9 6.3 6.9.8-5.1 4.7 1.4 6.8L12 17.2 5.9 20.6l1.4-6.8L2.2 9.1l6.9-.8z"/></svg>',
        '<svg width="17" height="18" viewBox="0 0 100 104"><use href="#star3d" width="100" height="104"/></svg>')

    UI.write_text(h, encoding="utf-8")
    print("ui.html diperbarui →", len(h) // 1024, "KB")


if __name__ == "__main__":
    main()
