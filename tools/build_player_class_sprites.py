#!/usr/bin/env python3
"""Build player class runtime sprites from AI-generated pose sheets."""

from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "game/assets/generated/player_classes/source"
OUTPUT_ROOT = ROOT / "game/assets/characters/player/classes"
REPORT_PATH = ROOT / "game/assets/generated/player_classes/player_class_sprite_report.md"

CLASS_IDS = ("cipher", "chrome", "echo", "shadow")
POSE_COUNT = 7
CANVAS_SIZE = (316, 329)
MAX_SPRITE_SIZE = (292, 322)

POSE_INDEX = {
    "front_idle": 0,
    "front_walk": 1,
    "back_idle": 2,
    "back_walk": 3,
    "side_idle": 4,
    "side_walk": 5,
    "idle_alt": 6,
}


def _is_key_color(pixel: tuple[int, int, int, int], key: tuple[int, int, int], threshold: int = 140) -> bool:
    r, g, b, _a = pixel
    kr, kg, kb = key
    return abs(r - kr) + abs(g - kg) + abs(b - kb) <= threshold


def _corner_key(image: Image.Image) -> tuple[int, int, int]:
    rgb = image.convert("RGB")
    w, h = rgb.size
    samples = [
        rgb.getpixel((0, 0)),
        rgb.getpixel((w - 1, 0)),
        rgb.getpixel((0, h - 1)),
        rgb.getpixel((w - 1, h - 1)),
    ]
    return tuple(sum(px[i] for px in samples) // len(samples) for i in range(3))


def remove_connected_chroma(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    key = _corner_key(rgba)
    pixels = rgba.load()
    visited: set[tuple[int, int]] = set()
    queue: deque[tuple[int, int]] = deque()

    for x in range(w):
        queue.append((x, 0))
        queue.append((x, h - 1))
    for y in range(h):
        queue.append((0, y))
        queue.append((w - 1, y))

    while queue:
        x, y = queue.popleft()
        if (x, y) in visited or x < 0 or y < 0 or x >= w or y >= h:
            continue
        visited.add((x, y))
        if not _is_key_color(pixels[x, y], key):
            continue
        pixels[x, y] = (0, 0, 0, 0)
        queue.append((x + 1, y))
        queue.append((x - 1, y))
        queue.append((x, y + 1))
        queue.append((x, y - 1))

    return rgba


def alpha_bbox(image: Image.Image) -> tuple[int, int, int, int] | None:
    return image.getchannel("A").getbbox()


def keep_significant_components(image: Image.Image) -> Image.Image:
    rgba = image.convert("RGBA")
    w, h = rgba.size
    alpha = rgba.getchannel("A")
    visited: set[tuple[int, int]] = set()
    components: list[list[tuple[int, int]]] = []

    for start_y in range(h):
        for start_x in range(w):
            if (start_x, start_y) in visited or alpha.getpixel((start_x, start_y)) <= 20:
                continue
            queue: deque[tuple[int, int]] = deque([(start_x, start_y)])
            component: list[tuple[int, int]] = []
            while queue:
                x, y = queue.popleft()
                if (x, y) in visited or x < 0 or y < 0 or x >= w or y >= h:
                    continue
                visited.add((x, y))
                if alpha.getpixel((x, y)) <= 20:
                    continue
                component.append((x, y))
                queue.append((x + 1, y))
                queue.append((x - 1, y))
                queue.append((x, y + 1))
                queue.append((x, y - 1))
            if component:
                components.append(component)

    if not components:
        return rgba

    largest = max(len(component) for component in components)
    min_area = max(500, int(largest * 0.035))
    keep_pixels = set()
    for component in components:
        if len(component) >= min_area or len(component) == largest:
            keep_pixels.update(component)

    pixels = rgba.load()
    for y in range(h):
        for x in range(w):
            if alpha.getpixel((x, y)) > 0 and (x, y) not in keep_pixels:
                pixels[x, y] = (0, 0, 0, 0)
    return rgba


def extract_pose(sheet: Image.Image, pose_idx: int) -> Image.Image:
    w, h = sheet.size
    cell_w = w / POSE_COUNT
    margin = cell_w * 0.015
    left = max(0, int((pose_idx * cell_w) + margin))
    right = min(w, int(((pose_idx + 1) * cell_w) - margin))
    cell = sheet.crop((left, 0, right, h))
    bbox = alpha_bbox(cell)
    if bbox == None:
        return Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    pad = 12
    x1 = max(0, bbox[0] - pad)
    y1 = max(0, bbox[1] - pad)
    x2 = min(cell.width, bbox[2] + pad)
    y2 = min(cell.height, bbox[3] + pad)
    return keep_significant_components(cell.crop((x1, y1, x2, y2)))


def normalize_sprite(sprite: Image.Image) -> Image.Image:
    sprite = sprite.convert("RGBA")
    bbox = alpha_bbox(sprite)
    if bbox == None:
        return Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    sprite = sprite.crop(bbox)
    scale = min(MAX_SPRITE_SIZE[0] / sprite.width, MAX_SPRITE_SIZE[1] / sprite.height)
    size = (max(1, int(sprite.width * scale)), max(1, int(sprite.height * scale)))
    sprite = sprite.resize(size, Image.Resampling.LANCZOS)

    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    x = (CANVAS_SIZE[0] - sprite.width) // 2
    y = CANVAS_SIZE[1] - sprite.height
    canvas.alpha_composite(sprite, (x, y))
    return canvas


def offset_sprite(sprite: Image.Image, dx: int = 0, dy: int = 0) -> Image.Image:
    canvas = Image.new("RGBA", CANVAS_SIZE, (0, 0, 0, 0))
    canvas.alpha_composite(sprite, (dx, dy))
    return canvas


def save_frames(class_id: str, poses: dict[str, Image.Image]) -> list[Path]:
    out_dir = OUTPUT_ROOT / class_id
    out_dir.mkdir(parents=True, exist_ok=True)
    saved: list[Path] = []

    frames = {
        "down": [
            poses["front_idle"],
            poses["front_walk"],
            offset_sprite(poses["front_idle"], dy=2),
        ],
        "up": [
            poses["back_idle"],
            poses["back_walk"],
            offset_sprite(poses["back_idle"], dy=2),
        ],
        "right": [
            poses["side_idle"],
            poses["side_walk"],
            offset_sprite(poses["side_idle"], dy=2),
        ],
        "left": [
            poses["side_idle"].transpose(Image.Transpose.FLIP_LEFT_RIGHT),
            poses["side_walk"].transpose(Image.Transpose.FLIP_LEFT_RIGHT),
            offset_sprite(poses["side_idle"].transpose(Image.Transpose.FLIP_LEFT_RIGHT), dy=2),
        ],
    }

    for direction, direction_frames in frames.items():
        for idx, frame in enumerate(direction_frames):
            path = out_dir / f"{class_id}_{direction}_{idx}.png"
            frame.save(path)
            saved.append(path)

    idle_frames = [
        poses["front_idle"],
        offset_sprite(poses["front_idle"], dy=-2),
        poses["idle_alt"],
        offset_sprite(poses["front_idle"], dy=1),
        offset_sprite(poses["idle_alt"], dy=-1),
    ]
    for idx, frame in enumerate(idle_frames):
        path = out_dir / f"{class_id}_idle_{idx}.png"
        frame.save(path)
        saved.append(path)

    return saved


def build_class(class_id: str) -> list[Path]:
    source = SOURCE_DIR / f"{class_id}_sheet.png"
    if not source.exists():
        raise FileNotFoundError(source)
    sheet = remove_connected_chroma(Image.open(source))
    poses = {}
    for pose_name, pose_idx in POSE_INDEX.items():
        poses[pose_name] = normalize_sprite(extract_pose(sheet, pose_idx))
    return save_frames(class_id, poses)


def main() -> int:
    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# Player Class Sprite Report", ""]
    total = 0
    for class_id in CLASS_IDS:
        saved = build_class(class_id)
        total += len(saved)
        lines.append(f"- `{class_id}`: {len(saved)} runtime frames")
    lines.append("")
    lines.append(f"Generated frames: {total}")
    REPORT_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"Generated {total} player class frames")
    print(REPORT_PATH)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
