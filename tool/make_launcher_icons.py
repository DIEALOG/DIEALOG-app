#!/usr/bin/env python3
"""Draw every launcher icon from assets/images/diealog_logo.png.

The logo is black line art on transparency, so each icon is the same mark in
black over white. Run from the repository root:

    python3 tool/make_launcher_icons.py
"""

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/images/diealog_logo.png"
BACKGROUND = (0xFF, 0xFF, 0xFF, 0xFF)
MARK = (0x00, 0x00, 0x00, 0xFF)
BACKGROUND_HEX = "#{:02X}{:02X}{:02X}".format(*BACKGROUND[:3])
SUPERSAMPLE = 4
# The logo draws a 25px line across a 965px mark. Shrunk to a 48px icon that
# line lands under a pixel and disappears, so thicken it back to a floor.
STROKE_RATIO = 25 / 965
MIN_STROKE = 1.5

# Android densities for a 48dp launcher icon and a 108dp adaptive canvas.
DENSITIES = {
    "mdpi": 1,
    "hdpi": 1.5,
    "xhdpi": 2,
    "xxhdpi": 3,
    "xxxhdpi": 4,
}


def mark_image() -> Image.Image:
    """The logo cropped to its ink and recoloured white."""
    logo = Image.open(LOGO).convert("RGBA")
    alpha = logo.split()[3]
    cropped = alpha.crop(alpha.getbbox())
    white = Image.new("RGBA", cropped.size, MARK)
    white.putalpha(cropped)
    return white


def place(canvas: Image.Image, mark: Image.Image, scale: float) -> None:
    """Centre the mark so its longest side covers `scale` of the canvas."""
    side = round(min(canvas.size) * scale)
    width, height = mark.size
    factor = side / max(width, height)
    resized = mark.resize(
        (max(1, round(width * factor)), max(1, round(height * factor))),
        Image.LANCZOS,
    )
    floor = MIN_STROKE * SUPERSAMPLE
    if side * STROKE_RATIO < floor:
        grow = max(1, round((floor - side * STROKE_RATIO) / 2))
        thicker = Image.new("RGBA", resized.size, MARK)
        thicker.putalpha(
            resized.split()[3].filter(ImageFilter.MaxFilter(2 * grow + 1))
        )
        resized = thicker
    canvas.alpha_composite(
        resized,
        (
            (canvas.width - resized.width) // 2,
            (canvas.height - resized.height) // 2,
        ),
    )


def render(size: int, mark: Image.Image, *, scale: float, radius: float,
           background: tuple[int, int, int, int] | None) -> Image.Image:
    """One icon, drawn oversized and shrunk so the thin strokes stay clean."""
    big = size * SUPERSAMPLE
    canvas = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    if background is not None:
        if radius > 0:
            ImageDraw.Draw(canvas).rounded_rectangle(
                (0, 0, big - 1, big - 1), radius=big * radius, fill=background
            )
        else:
            canvas.paste(background, (0, 0, big, big))
    place(canvas, mark, scale)
    return canvas.resize((size, size), Image.LANCZOS)


def write(image: Image.Image, path: Path, *, flatten: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if flatten:
        # iOS rejects an alpha channel in app icons.
        opaque = Image.new("RGB", image.size, BACKGROUND[:3])
        opaque.paste(image, mask=image.split()[3])
        image = opaque
    image.save(path)
    print(f"  {path.relative_to(ROOT)}  {image.size[0]}px")


def android(mark: Image.Image) -> None:
    res = ROOT / "android/app/src/main/res"
    print("android")
    for density, factor in DENSITIES.items():
        legacy = round(48 * factor)
        adaptive = round(108 * factor)
        write(
            render(legacy, mark, scale=0.60, radius=0.22, background=BACKGROUND),
            res / f"mipmap-{density}/ic_launcher.png",
        )
        # The adaptive foreground has to stay inside the 72dp safe zone: a
        # square inscribed in that circle is 47% of the 108dp canvas.
        write(
            render(adaptive, mark, scale=0.44, radius=0, background=None),
            res / f"mipmap-{density}/ic_launcher_foreground.png",
        )

    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26/ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@mipmap/ic_launcher_foreground" />\n'
        "</adaptive-icon>\n"
    )
    (res / "values/ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        f'    <color name="ic_launcher_background">{BACKGROUND_HEX}</color>\n'
        "</resources>\n"
    )
    print("  mipmap-anydpi-v26/ic_launcher.xml, values/ic_launcher_background.xml")


def ios(mark: Image.Image) -> None:
    appicon = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    contents = json.loads((appicon / "Contents.json").read_text())
    print("ios")
    for entry in contents["images"]:
        filename = entry.get("filename")
        if not filename:
            continue
        points = float(entry["size"].split("x")[0])
        pixels = round(points * float(entry["scale"].rstrip("x")))
        # iOS rounds the corners itself, so the artwork stays square.
        write(
            render(pixels, mark, scale=0.62, radius=0, background=BACKGROUND),
            appicon / filename,
            flatten=True,
        )


def web(mark: Image.Image) -> None:
    icons = ROOT / "web/icons"
    print("web")
    for size in (192, 512):
        write(
            render(size, mark, scale=0.60, radius=0.22, background=BACKGROUND),
            icons / f"Icon-{size}.png",
        )
        # A maskable icon is cropped to its middle 80%, so the mark sits small.
        write(
            render(size, mark, scale=0.46, radius=0, background=BACKGROUND),
            icons / f"Icon-maskable-{size}.png",
        )
    write(
        render(32, mark, scale=0.72, radius=0.22, background=BACKGROUND),
        ROOT / "web/favicon.png",
    )


def main() -> None:
    mark = mark_image()
    android(mark)
    ios(mark)
    web(mark)


if __name__ == "__main__":
    main()
