from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Resources" / "Icons"
OUT.mkdir(parents=True, exist_ok=True)


def rounded_rect(draw, box, radius, fill, outline=None, width=1):
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def make_app_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))

    # Soft floor shadow.
    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((216, 96, 802, 878), radius=58, fill=(0, 0, 0, 58))
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    img.alpha_composite(shadow)

    # Main sheet.
    paper = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    pd = ImageDraw.Draw(paper)
    rounded_rect(pd, (198, 78, 792, 858), 54, (252, 252, 249, 255))

    # Paper border and a very quiet highlight, keeping the sheet clean.
    pd.rounded_rectangle((198, 78, 792, 858), radius=54, outline=(214, 214, 209, 150), width=3)

    # Bottom curl: a lifted lip with grey underside.
    curl_shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cs = ImageDraw.Draw(curl_shadow)
    cs.pieslice((456, 690, 870, 1024), 194, 344, fill=(0, 0, 0, 56))
    curl_shadow = curl_shadow.filter(ImageFilter.GaussianBlur(18))
    paper.alpha_composite(curl_shadow)

    pd = ImageDraw.Draw(paper)
    pd.pieslice((448, 684, 870, 1026), 194, 344, fill=(226, 226, 220, 255))
    pd.pieslice((418, 638, 830, 984), 198, 342, fill=(252, 252, 249, 255))
    pd.arc((418, 638, 830, 984), 198, 342, fill=(184, 184, 178, 150), width=5)
    pd.line((432, 760, 666, 822), fill=(222, 222, 216, 180), width=4)

    img.alpha_composite(paper)

    # Lower-right skeuomorphic lock, no keyhole.
    lock_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lock_layer)

    # Lock shadow.
    ld.rounded_rectangle((546, 590, 826, 814), radius=46, fill=(0, 0, 0, 72))
    lock_layer = lock_layer.filter(ImageFilter.GaussianBlur(8))
    img.alpha_composite(lock_layer)

    lock = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ld = ImageDraw.Draw(lock)

    # Shackle.
    ld.arc((590, 452, 782, 650), 180, 360, fill=(46, 47, 49, 255), width=42)
    ld.line((590, 552, 590, 638), fill=(46, 47, 49, 255), width=42)
    ld.line((782, 552, 782, 638), fill=(46, 47, 49, 255), width=42)
    ld.arc((604, 468, 768, 640), 180, 360, fill=(92, 93, 96, 130), width=8)

    # Body.
    ld.rounded_rectangle((536, 612, 836, 822), radius=48, fill=(30, 31, 33, 255))
    ld.rounded_rectangle((552, 628, 820, 690), radius=34, fill=(64, 65, 68, 255))
    ld.rounded_rectangle((552, 690, 820, 822), radius=42, fill=(24, 25, 27, 255))
    ld.rounded_rectangle((536, 612, 836, 822), radius=48, outline=(8, 8, 9, 170), width=5)

    # Glossy side highlight, still subtle.
    ld.rounded_rectangle((570, 642, 610, 794), radius=20, fill=(255, 255, 255, 24))
    ld.rounded_rectangle((626, 646, 794, 672), radius=13, fill=(255, 255, 255, 22))

    img.alpha_composite(lock)
    img.save(OUT / "AppIcon.png")


def make_menu_bar_icon():
    canvas = 1024
    final = 256
    img = Image.new("RGBA", (canvas, canvas), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    black = (0, 0, 0, 255)
    clear = (0, 0, 0, 0)

    # Solid paper: square overall, with only the lower-left corner rounded.
    d.rectangle((88, 24, 968, 984), fill=black)
    d.pieslice((88, 808, 264, 984), 90, 180, fill=clear)

    # Minimal hollow lock cut out of the solid paper, no keyhole.
    lock_stroke = 72
    d.rounded_rectangle((300, 478, 756, 782), radius=66, outline=clear, width=lock_stroke)
    d.arc((390, 182, 666, 578), 180, 360, fill=clear, width=lock_stroke)
    d.line((390, 384, 390, 526), fill=clear, width=lock_stroke)
    d.line((666, 384, 666, 526), fill=clear, width=lock_stroke)

    img = img.resize((final, final), Image.Resampling.LANCZOS)
    img.save(OUT / "MenuBarIcon.png")

    preview = Image.new("RGBA", (final, final), (255, 255, 255, 255))
    preview.alpha_composite(img)
    preview.save(OUT / "MenuBarIconPreview.png")


if __name__ == "__main__":
    make_app_icon()
    make_menu_bar_icon()
