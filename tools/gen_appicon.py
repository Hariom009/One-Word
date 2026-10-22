#!/usr/bin/env python3
"""Build One Word's macOS AppIcon.appiconset from a source icon image.

Usage:  python3 tools/gen_appicon.py [source.png]
        (defaults to tools/appicon_source.png)

The source is expected to be the icon artwork on a flat contrasting background
(e.g. a cream squircle on black). This script lifts the artwork off that
background, drops stray marks, and re-seats it on Apple's macOS icon grid.
"""

import json
import pathlib
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / "OneWord/Assets.xcassets/AppIcon.appiconset"
DEFAULT_SRC = ROOT / "tools/appicon_source.png"

# macOS Big Sur+ icon grid: 824pt body centred in a 1024pt canvas, the rest
# transparent. Skipping the inset makes the icon look oversized in the Dock.
CANVAS, BODY = 1024, 824

BG_LUMA = 60  # pixels darker than this, reachable from the border, are backdrop


def lift_artwork(src: Image.Image) -> Image.Image:
    """Return src with the flat backdrop knocked out to transparency."""
    rgb = src.convert("RGB")
    w, h = rgb.size

    # Dark pixels *anywhere* — this also catches the dark letterform inside the
    # artwork, so it can't be used as the backdrop mask on its own.
    dark = rgb.convert("L").point(lambda v: 255 if v < BG_LUMA else 0)

    # Only the dark region connected to the border is actually backdrop; the
    # letterform is enclosed by the light body and never reached from outside.
    ImageDraw.floodfill(dark, (0, 0), 128, thresh=0)
    ImageDraw.floodfill(dark, (w - 1, 0), 128, thresh=0)
    ImageDraw.floodfill(dark, (0, h - 1), 128, thresh=0)
    ImageDraw.floodfill(dark, (w - 1, h - 1), 128, thresh=0)
    alpha = dark.point(lambda v: 0 if v == 128 else 255)

    # Keep only the blob containing the centre, so watermarks/sparkles floating
    # in the backdrop are discarded rather than welded onto the icon.
    ImageDraw.floodfill(alpha, (w // 2, h // 2), 64, thresh=0)
    alpha = alpha.point(lambda v: 255 if v == 64 else 0)

    art = rgb.convert("RGBA")
    art.putalpha(alpha)
    box = alpha.getbbox()
    if box is None:
        sys.exit("error: no artwork found — is the background flat and dark?")
    return art.crop(box)


def to_icon_grid(art: Image.Image) -> Image.Image:
    """Seat the artwork on the 1024 canvas at macOS body size, with a shadow."""
    # Square it off so a slightly off-square crop doesn't stretch the artwork.
    side = max(art.size)
    square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    square.alpha_composite(art, ((side - art.width) // 2, (side - art.height) // 2))
    body = square.resize((BODY, BODY), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    pos = ((CANVAS - BODY) // 2, (CANVAS - BODY) // 2)

    # Soft contact shadow, offset down — macOS bakes this into the artwork.
    shadow = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 90), pos, body.getchannel("A"))
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(16)).transform(
        (CANVAS, CANVAS), Image.AFFINE, (1, 0, 0, 0, 1, -12), resample=Image.BILINEAR))

    canvas.alpha_composite(body, pos)
    return canvas


def main() -> None:
    src_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_SRC
    if not src_path.exists():
        sys.exit(f"error: no source image at {src_path}\n"
                 f"       save your icon there, or pass a path as an argument.")

    master = to_icon_grid(lift_artwork(Image.open(src_path)))

    OUT.mkdir(parents=True, exist_ok=True)
    for png in OUT.glob("*.png"):
        png.unlink()

    images = []
    for pt in (16, 32, 128, 256, 512):
        for scale in (1, 2):
            name = f"icon_{pt}x{pt}{'@2x' if scale == 2 else ''}.png"
            master.resize((pt * scale, pt * scale), Image.LANCZOS).save(OUT / name)
            images.append({"filename": name, "idiom": "mac",
                           "scale": f"{scale}x", "size": f"{pt}x{pt}"})

    # iOS takes one 1024 and masks its own corners; it must be opaque. The Mac master is
    # flattened onto white so the same artwork serves both, inset and all.
    # ponytail: the icon-mac-*.png files on disk predate this script and were not made
    # by it — running it rewrites the whole set under new names. Mind that before a regen.
    ios = Image.new("RGB", (CANVAS, CANVAS), "white")
    ios.paste(master, mask=master.split()[-1])
    ios.save(OUT / "icon_ios_1024.png")
    images.append({"filename": "icon_ios_1024.png", "idiom": "universal",
                   "platform": "ios", "size": "1024x1024"})

    (OUT / "Contents.json").write_text(
        json.dumps({"images": images, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print(f"wrote {len(images)} icons to {OUT} from {src_path.name}")


if __name__ == "__main__":
    main()
