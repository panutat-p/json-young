#!/usr/bin/env python3
"""Generate AppIcon.png — full-bleed macOS app icon (no white margins)."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "Resources" / "AppIcon.png"

BLUE_TOP = (42, 118, 228)
BLUE_BOTTOM = (32, 98, 208)
BRACE = (255, 255, 255)
MONKEY_FACE = (255, 255, 255)
MONKEY_DETAIL = (34, 104, 216)

FONT_CANDIDATES = [
    ("/System/Library/Fonts/SFNSMono.ttf", 2),
    ("/System/Library/Fonts/SFNSMono.ttf", 0),
    ("/System/Library/Fonts/Supplemental/Menlo.ttc", 1),
    ("/System/Library/Fonts/Supplemental/Menlo.ttc", 0),
    ("/System/Library/Fonts/Monaco.ttf", 0),
    ("/Library/Fonts/SF Mono.ttf", 0),
]

MONKEY_HEAD_RADIUS_RATIO = 0.142
MONKEY_EAR_RADIUS_RATIO = 0.081
BRACE_FONT_SIZE = 520
BRACE_HEIGHT_SCALE = 2.05
BRACE_WIDTH_SCALE = 1.22
ICON_EDGE_MARGIN_RATIO = 0.08
MONKEY_BRACE_GAP_RATIO = 0.038


@dataclass(frozen=True)
class BraceGlyph:
    image: Image.Image
    ink_left: int
    ink_right: int


@dataclass(frozen=True)
class BraceLayout:
    left: BraceGlyph
    right: BraceGlyph
    left_x: float
    right_x: float
    gap: float
    font_size: int


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
    )


def load_brace_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path, index in FONT_CANDIDATES:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size, index=index)
            except OSError:
                continue
    return ImageFont.load_default()


def monkey_half_width() -> float:
    head_radius = SIZE * MONKEY_HEAD_RADIUS_RATIO
    ear_radius = SIZE * MONKEY_EAR_RADIUS_RATIO
    return head_radius * 0.92 + ear_radius


def make_background() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE))
    px = img.load()
    for y in range(SIZE):
        t = y / (SIZE - 1)
        color = lerp_color(BLUE_TOP, BLUE_BOTTOM, t)
        for x in range(SIZE):
            px[x, y] = color
    return img


def make_brace_glyph(char: str, font: ImageFont.FreeTypeFont | ImageFont.ImageFont) -> BraceGlyph:
    probe = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bbox = probe.textbbox((0, 0), char, font=font)
    width = bbox[2] - bbox[0]
    height = bbox[3] - bbox[1]

    glyph = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    ImageDraw.Draw(glyph).text((-bbox[0], -bbox[1]), char, font=font, fill=BRACE)

    scaled_width = max(1, int(width * BRACE_WIDTH_SCALE))
    scaled_height = max(1, int(height * BRACE_HEIGHT_SCALE))
    glyph = glyph.resize((scaled_width, scaled_height), Image.Resampling.LANCZOS)

    ink_bbox = glyph.getbbox()
    if ink_bbox is None:
        ink_bbox = (0, 0, scaled_width, scaled_height)

    return BraceGlyph(
        image=glyph,
        ink_left=ink_bbox[0],
        ink_right=ink_bbox[2],
    )


def layout_for_font(font_size: int) -> BraceLayout | None:
    font = load_brace_font(font_size)
    left = make_brace_glyph("{", font)
    right = make_brace_glyph("}", font)

    cx = SIZE * 0.5
    edge_margin = SIZE * ICON_EDGE_MARGIN_RATIO
    monkey_half_w = monkey_half_width()
    monkey_left = cx - monkey_half_w
    monkey_right = cx + monkey_half_w

    left_x_edge = edge_margin - left.ink_left
    right_x_edge = SIZE - edge_margin - right.ink_right

    max_gap = min(
        monkey_left - (left_x_edge + left.ink_right),
        (right_x_edge + right.ink_left) - monkey_right,
    )
    if max_gap <= 0:
        return None

    gap = min(max_gap, SIZE * MONKEY_BRACE_GAP_RATIO)
    left_x = monkey_left - gap - left.ink_right
    right_x = monkey_right + gap - right.ink_left
    return BraceLayout(left, right, left_x, right_x, gap, font_size)


def find_best_layout() -> BraceLayout:
    best: BraceLayout | None = None

    for font_size in range(BRACE_FONT_SIZE, 279, -20):
        layout = layout_for_font(font_size)
        if layout is None:
            continue
        if best is None or layout.font_size > best.font_size:
            best = layout

    if best is None:
        raise RuntimeError("Could not fit braces and monkey on the icon canvas.")

    return best


def draw_braces(layer: Image.Image) -> None:
    layout = find_best_layout()
    center_y = SIZE * 0.5

    for glyph, x in ((layout.left, layout.left_x), (layout.right, layout.right_x)):
        paste_y = int(center_y - glyph.image.height / 2)
        layer.paste(glyph.image, (int(x), paste_y), glyph.image)


def draw_monkey(layer: Image.Image) -> None:
    draw = ImageDraw.Draw(layer)
    cx = SIZE * 0.5
    cy = SIZE * 0.5
    head_radius = SIZE * MONKEY_HEAD_RADIUS_RATIO
    ear_radius = SIZE * MONKEY_EAR_RADIUS_RATIO
    muzzle_w = SIZE * 0.176
    muzzle_h = SIZE * 0.103

    for ex in (cx - head_radius * 0.92, cx + head_radius * 0.92):
        draw.ellipse(
            (
                ex - ear_radius,
                cy - ear_radius * 0.78,
                ex + ear_radius,
                cy + ear_radius * 0.78,
            ),
            fill=MONKEY_FACE,
        )
        inner_radius = ear_radius * 0.48
        draw.ellipse(
            (
                ex - inner_radius,
                cy - inner_radius * 0.78,
                ex + inner_radius,
                cy + inner_radius * 0.78,
            ),
            fill=MONKEY_DETAIL,
        )

    draw.ellipse(
        (
            cx - head_radius,
            cy - head_radius,
            cx + head_radius,
            cy + head_radius,
        ),
        fill=MONKEY_FACE,
    )
    draw.rounded_rectangle(
        (
            cx - muzzle_w / 2,
            cy + head_radius * 0.12,
            cx + muzzle_w / 2,
            cy + head_radius * 0.12 + muzzle_h,
        ),
        radius=int(muzzle_h * 0.45),
        fill=MONKEY_DETAIL,
    )

    eye_radius = SIZE * 0.018
    for ex in (cx - head_radius * 0.34, cx + head_radius * 0.34):
        draw.ellipse(
            (
                ex - eye_radius,
                cy - head_radius * 0.18 - eye_radius,
                ex + eye_radius,
                cy - head_radius * 0.18 + eye_radius,
            ),
            fill=MONKEY_DETAIL,
        )

    nose_radius = SIZE * 0.015
    draw.ellipse(
        (
            cx - nose_radius,
            cy + head_radius * 0.36 - nose_radius,
            cx + nose_radius,
            cy + head_radius * 0.36 + nose_radius,
        ),
        fill=MONKEY_FACE,
    )


def main() -> None:
    base = make_background()
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_braces(layer)
    draw_monkey(layer)

    result = Image.alpha_composite(base.convert("RGBA"), layer).convert("RGB")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    result.save(OUTPUT, format="PNG", optimize=True)
    print(OUTPUT)


if __name__ == "__main__":
    main()
