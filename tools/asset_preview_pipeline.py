from __future__ import annotations

import shutil
import subprocess
from collections import Counter, deque
from pathlib import Path
from typing import Iterable, Optional

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
GENERATED_DIR = Path("/Users/xieqing/.codex/generated_images/019ea7ae-7f3b-7481-a4b3-5535c44202c4")
EXTERNAL_CLASS_SHEET = GENERATED_DIR / "ig_0728df1a25c6f4d5016a26d70eaf08819a8f2a61a3ed15ae45.png"
EXTERNAL_NPC_SHEET = GENERATED_DIR / "ig_0728df1a25c6f4d5016a26d7e895fc819a9c7b1655833b4325.png"
CLASS_SHEET = EXTERNAL_CLASS_SHEET if EXTERNAL_CLASS_SHEET.exists() else GAME / "assets/generated/image2/class_portraits_sheet.png"
NPC_SHEET = EXTERNAL_NPC_SHEET if EXTERNAL_NPC_SHEET.exists() else GAME / "assets/generated/image2/npc_portraits_sheet.png"

CLASS_NAMES = ["cipher", "chrome", "echo", "shadow"]
NPC_IDS = ["zhang_san", "li_si", "wang_wu", "sun_yue", "he_zhen", "chen_xi", "zhao_lin", "liu_feng"]
NPC_ZH = {
    "zhang_san": "张三",
    "li_si": "李四",
    "wang_wu": "王五",
    "sun_yue": "孙悦",
    "he_zhen": "何真",
    "chen_xi": "陈曦",
    "zhao_lin": "赵霖",
    "liu_feng": "刘风",
}

SPRITE_SIZE = (316, 329)
ASSET_ROOT = GAME / "assets"
NPC_ROOT = ASSET_ROOT / "characters/npcs"
RUNTIME_NPC_DIR = NPC_ROOT / "runtime"
DIALOGUE_AVATAR_DIR = ASSET_ROOT / "characters/avatars"
NPC_STANDEE_DIR = NPC_ROOT / "人物展示界面"
NPC_GENERATED_PORTRAIT_DIR = NPC_ROOT / "generated_portraits"
CLASS_PORTRAIT_DIR = ASSET_ROOT / "media/class_portrait"
GENERATED_ASSET_DIR = ASSET_ROOT / "generated"
GENERATED_ATLAS_DIR = GENERATED_ASSET_DIR / "image2"
OPTIMIZED_PREVIEW_DIR = ASSET_ROOT / "optimized_preview"

GRID3_NPC_IDS = {"zhang_san", "li_si", "wang_wu"}
RUNTIME_DIRECTIONS = ("down", "up", "left", "right")
IMAGE_SUFFIXES = {".png", ".webp", ".jpg", ".jpeg"}

FINAL_RUNTIME_DIRS = (
    RUNTIME_NPC_DIR,
    DIALOGUE_AVATAR_DIR,
    NPC_STANDEE_DIR,
    CLASS_PORTRAIT_DIR,
)
PROMOTE_ONLY_DIRS = (
    NPC_GENERATED_PORTRAIT_DIR,
)
INTERMEDIATE_ONLY_DIRS = (
    GENERATED_ASSET_DIR,
    OPTIMIZED_PREVIEW_DIR,
)


def ensure(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def save_webp(image: Image.Image, path: Path, quality: int = 88) -> None:
    ensure(path.parent)
    image.save(path, "WEBP", quality=quality, method=6)


def file_size(path: Path) -> int:
    return path.stat().st_size if path.exists() else 0


def relpath(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def is_under(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
        return True
    except ValueError:
        return False


def is_intermediate_or_preview(path: Path) -> bool:
    return any(is_under(path, root) for root in INTERMEDIATE_ONLY_DIRS)


def classify_asset_path(path: Path) -> tuple[str, str]:
    if is_under(path, OPTIMIZED_PREVIEW_DIR):
        return "preview_only", "exclude_from_runtime_export"
    if is_under(path, GENERATED_ASSET_DIR):
        return "intermediate_ai_sheet", "exclude_from_runtime_export"
    if any(is_under(path, root) for root in FINAL_RUNTIME_DIRS):
        return "final_runtime_candidate", "include_when_referenced"
    if any(is_under(path, root) for root in PROMOTE_ONLY_DIRS):
        return "promotion_candidate", "promote_by_explicit_reference_only"
    return "source_or_unclassified", "manual_review"


def iter_image_files(root: Path) -> list[Path]:
    if not root.exists():
        return []
    return sorted(
        path
        for path in root.rglob("*")
        if path.is_file() and path.suffix.lower() in IMAGE_SUFFIXES
    )


def image_info(path: Path) -> dict[str, object]:
    try:
        with Image.open(path) as image:
            return {
                "path": relpath(path),
                "width": image.width,
                "height": image.height,
                "mode": image.mode,
                "bytes": file_size(path),
                "ok": True,
            }
    except Exception as exc:  # noqa: BLE001 - report keeps corrupt image detail.
        return {
            "path": relpath(path),
            "width": 0,
            "height": 0,
            "mode": "",
            "bytes": file_size(path),
            "ok": False,
            "error": str(exc),
        }


def inspect_image_paths(paths: Iterable[Path]) -> tuple[list[dict[str, object]], list[str], list[str]]:
    infos: list[dict[str, object]] = []
    missing: list[str] = []
    corrupt: list[str] = []
    for path in paths:
        if not path.exists():
            missing.append(relpath(path))
            continue
        info = image_info(path)
        if info.get("ok"):
            infos.append(info)
        else:
            corrupt.append(f"{info['path']}: {info.get('error', 'unreadable')}")
    return infos, missing, corrupt


def dimension_counts(infos: Iterable[dict[str, object]]) -> Counter[str]:
    counts: Counter[str] = Counter()
    for info in infos:
        width = int(info.get("width", 0) or 0)
        height = int(info.get("height", 0) or 0)
        if width and height:
            counts[f"{width}x{height}"] += 1
    return counts


def describe_dimensions(infos: Iterable[dict[str, object]]) -> str:
    counts = dimension_counts(infos)
    if not counts:
        return "-"
    return ", ".join(f"{size} ({count})" for size, count in sorted(counts.items()))


def expected_runtime_paths() -> list[Path]:
    paths: list[Path] = []
    for npc_id in NPC_IDS:
        for direction in RUNTIME_DIRECTIONS:
            for frame_idx in range(3):
                paths.append(RUNTIME_NPC_DIR / npc_id / f"{npc_id}_{direction}_{frame_idx}.png")
        idle_count = 3 if npc_id in GRID3_NPC_IDS else 5
        for frame_idx in range(idle_count):
            paths.append(RUNTIME_NPC_DIR / npc_id / f"{npc_id}_idle_{frame_idx}.png")
    return paths


def expected_dialogue_avatar_paths() -> list[Path]:
    return [DIALOGUE_AVATAR_DIR / f"{NPC_ZH[npc_id]}头像.png" for npc_id in NPC_IDS]


def expected_generated_portrait_paths() -> list[Path]:
    return [NPC_GENERATED_PORTRAIT_DIR / f"{npc_id}.webp" for npc_id in NPC_IDS]


def expected_class_portrait_paths() -> list[Path]:
    numbered = [CLASS_PORTRAIT_DIR / f"class_portrait_{idx:03d}.webp" for idx in range(1, 5)]
    named = [CLASS_PORTRAIT_DIR / f"{class_name}.webp" for class_name in CLASS_NAMES]
    return numbered + named


def status_text(status: str) -> str:
    return {
        "pass": "PASS",
        "review": "REVIEW",
        "fail": "FAIL",
        "exclude": "EXCLUDE",
    }.get(status, status.upper())


def make_candidate_row(
    group: str,
    path: Path,
    expected: str,
    found: int,
    dimensions: str,
    status: str,
    notes: str,
) -> dict[str, object]:
    role, export_rule = classify_asset_path(path)
    return {
        "group": group,
        "path": relpath(path),
        "role": role,
        "export_rule": export_rule,
        "expected": expected,
        "found": found,
        "dimensions": dimensions,
        "status": status_text(status),
        "notes": notes,
    }


def build_acceptance_rows() -> list[dict[str, object]]:
    rows: list[dict[str, object]] = []

    avatar_infos, avatar_missing, avatar_corrupt = inspect_image_paths(
        expected_dialogue_avatar_paths()
    )
    avatar_sizes = dimension_counts(avatar_infos)
    avatar_non_square = [
        str(info["path"])
        for info in avatar_infos
        if int(info["width"]) != int(info["height"])
    ]
    avatar_status = "pass"
    avatar_notes = ["dialogue avatar files are square"]
    if avatar_missing or avatar_corrupt or avatar_non_square:
        avatar_status = "fail"
        avatar_notes.append("missing/corrupt/non-square files need fixing")
    elif len(avatar_sizes) > 1:
        avatar_status = "review"
        avatar_notes.append("canvas sizes are mixed; normalize only during an explicit avatar pass")
    rows.append(
        make_candidate_row(
            "AI dialogue avatars",
            DIALOGUE_AVATAR_DIR,
            str(len(NPC_IDS)),
            len(avatar_infos),
            describe_dimensions(avatar_infos),
            avatar_status,
            "; ".join(avatar_notes),
        )
    )

    portrait_infos, portrait_missing, portrait_corrupt = inspect_image_paths(
        expected_generated_portrait_paths()
    )
    portrait_wrong_size = [
        str(info["path"])
        for info in portrait_infos
        if (int(info["width"]), int(info["height"])) != (512, 512)
    ]
    portrait_status = "pass"
    portrait_notes = [
        "512x512 AI portrait candidates; not auto-runtime until explicitly referenced"
    ]
    if portrait_missing or portrait_corrupt or portrait_wrong_size:
        portrait_status = "fail"
        portrait_notes.append("expected all Image 2 crops to be 512x512")
    rows.append(
        make_candidate_row(
            "AI NPC portrait candidates",
            NPC_GENERATED_PORTRAIT_DIR,
            str(len(NPC_IDS)),
            len(portrait_infos),
            describe_dimensions(portrait_infos),
            portrait_status,
            "; ".join(portrait_notes),
        )
    )

    standee_paths = iter_image_files(NPC_STANDEE_DIR)
    standee_infos, _standee_missing, standee_corrupt = inspect_image_paths(standee_paths)
    standee_status = "pass"
    standee_notes = ["AI standee/fallback source set; keep full-resolution originals"]
    if standee_corrupt or not standee_infos:
        standee_status = "fail"
        standee_notes.append("missing or unreadable standee files")
    elif len(dimension_counts(standee_infos)) > 1:
        standee_status = "review"
        standee_notes.append(
            "canvas/aspect sizes are mixed; crop only when promoting to a specific UI target"
        )
    rows.append(
        make_candidate_row(
            "AI standees",
            NPC_STANDEE_DIR,
            "current source set",
            len(standee_infos),
            describe_dimensions(standee_infos),
            standee_status,
            "; ".join(standee_notes),
        )
    )

    runtime_expected = expected_runtime_paths()
    runtime_infos, runtime_missing, runtime_corrupt = inspect_image_paths(runtime_expected)
    runtime_wrong_size = [
        str(info["path"])
        for info in runtime_infos
        if (int(info["width"]), int(info["height"])) != SPRITE_SIZE
    ]
    runtime_expected_set = {path.resolve() for path in runtime_expected}
    runtime_extra = [
        path
        for path in iter_image_files(RUNTIME_NPC_DIR)
        if path.resolve() not in runtime_expected_set
    ]
    runtime_status = "pass"
    runtime_notes = [f"runtime sprite canvas target is {SPRITE_SIZE[0]}x{SPRITE_SIZE[1]}"]
    if runtime_missing or runtime_corrupt or runtime_wrong_size:
        runtime_status = "fail"
        runtime_notes.append("missing/corrupt/wrong-size runtime frames found")
    elif runtime_extra:
        runtime_status = "review"
        runtime_notes.append(
            f"{len(runtime_extra)} extra runtime image(s) require manual ownership check"
        )
    rows.append(
        make_candidate_row(
            "NPC runtime frames",
            RUNTIME_NPC_DIR,
            str(len(runtime_expected)),
            len(runtime_infos),
            describe_dimensions(runtime_infos),
            runtime_status,
            "; ".join(runtime_notes),
        )
    )

    class_infos, class_missing, class_corrupt = inspect_image_paths(
        expected_class_portrait_paths()
    )
    class_wrong_size = [
        str(info["path"])
        for info in class_infos
        if (int(info["width"]), int(info["height"])) != (512, 512)
    ]
    class_status = "pass"
    class_notes = ["class portraits are final 512x512 media fallbacks"]
    if class_missing or class_corrupt or class_wrong_size:
        class_status = "fail"
        class_notes.append("expected numbered and named WebP files at 512x512")
    rows.append(
        make_candidate_row(
            "AI class portraits",
            CLASS_PORTRAIT_DIR,
            str(len(expected_class_portrait_paths())),
            len(class_infos),
            describe_dimensions(class_infos),
            class_status,
            "; ".join(class_notes),
        )
    )

    atlas_infos = [image_info(path) for path in iter_image_files(GENERATED_ATLAS_DIR)]
    rows.append(
        make_candidate_row(
            "Generated Image 2 atlases",
            GENERATED_ATLAS_DIR,
            "source sheets only",
            len(atlas_infos),
            describe_dimensions(atlas_infos),
            "exclude",
            "intermediate sheets; crop/promote outputs instead of referencing atlases at runtime",
        )
    )

    preview_count = len(iter_image_files(OPTIMIZED_PREVIEW_DIR))
    rows.append(
        make_candidate_row(
            "Optimized previews",
            OPTIMIZED_PREVIEW_DIR,
            "QA artifacts only",
            preview_count,
            "-",
            "exclude",
            "preview/font/audio artifacts; never use as gameplay resource candidates",
        )
    )
    return rows


def collect_disallowed_runtime_references() -> list[str]:
    references: list[str] = []
    scanned_roots = [GAME / "scripts", GAME / "scenes"]
    scanned_files = [GAME / "project.godot"]
    for root in scanned_roots:
        scanned_files.extend(sorted(root.rglob("*.gd")))
        scanned_files.extend(sorted(root.rglob("*.tscn")))
    disallowed = ("res://assets/optimized_preview/", "res://assets/generated/")
    for path in scanned_files:
        if not path.exists():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line_no, line in enumerate(text.splitlines(), start=1):
            for marker in disallowed:
                if marker in line:
                    references.append(f"{relpath(path)}:{line_no} -> {marker}")
    return references


def build_resource_report_lines(records: Optional[list[dict[str, object]]] = None) -> list[str]:
    title = (
        "# Asset Optimization Preview Report"
        if records is not None
        else "# AI Asset Boundary Report"
    )
    lines = [
        title,
        "",
        "This report separates final runtime candidates from generated atlases and preview-only "
        "artifacts. Original PNG/font/audio assets are not deleted or replaced by this tooling.",
        "",
        "## Resource Candidate List",
        "",
        "| Group | Directory | Role | Export Boundary | Expected | Found | Dimensions | Status | Acceptance Notes |",
        "|---|---|---|---|---:|---:|---|---|---|",
    ]
    for row in build_acceptance_rows():
        lines.append(
            "| {group} | `{path}` | `{role}` | `{export_rule}` | {expected} | {found} | "
            "{dimensions} | {status} | {notes} |".format(**row)
        )

    references = collect_disallowed_runtime_references()
    lines.extend(
        [
            "",
            "## Export Boundary Suggestions",
            "",
            "- Include final assets only from explicit runtime directories such as "
            "`game/assets/characters/npcs/runtime`, `game/assets/characters/avatars`, "
            "`game/assets/characters/npcs/人物展示界面`, and `game/assets/media/class_portrait`.",
            "- Exclude `res://assets/optimized_preview/**` and `res://assets/generated/**` "
            "from runtime promotion/export filters; they are QA previews and AI source atlases.",
            "- Treat `game/assets/characters/npcs/generated_portraits/*.webp` as promotion "
            "candidates, not automatic runtime resources, until scripts/scenes reference them intentionally.",
            "- When a new AI sheet is accepted, crop it into the final directory first; do not point gameplay code at a sheet under `generated`.",
            "",
            "## Runtime Reference Check",
            "",
        ]
    )
    if references:
        lines.append("Disallowed intermediate/preview references found:")
        for ref in references:
            lines.append(f"- `{ref}`")
    else:
        lines.append(
            "No script/scene/project references to `res://assets/optimized_preview/` "
            "or `res://assets/generated/` were found."
        )

    if records is not None:
        lines.extend(
            [
                "",
                "## Generation Records",
                "",
                "| Kind | Source | Output | Original | Preview | Boundary | Status |",
                "|---|---|---|---:|---:|---|---|",
            ]
        )
        for rec in records:
            source = str(rec.get("source", ""))
            output = str(rec.get("output", ""))
            original = int(rec.get("source_bytes", 0) or 0)
            preview = int(rec.get("bytes", 0) or 0)
            status = "ok"
            if int(rec.get("returncode", 0) or 0) != 0:
                status = "failed"
                if rec.get("stderr"):
                    status += ": " + str(rec["stderr"]).replace("\n", " ")
            role, export_rule = classify_asset_path(ROOT / output) if output else ("", "")
            lines.append(
                f"| {rec.get('kind', '')} | `{source}` | `{output}` | {original} | "
                f"{preview} | `{role}/{export_rule}` | {status} |"
            )
    return lines


def crop_grid(sheet: Image.Image, cols: int, rows: int, index: int) -> Image.Image:
    w, h = sheet.size
    cell_w = w // cols
    cell_h = h // rows
    col = index % cols
    row = index // cols
    return sheet.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h))


def remove_sheet_background(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    w, h = image.size
    pixels = image.load()
    mask = bytearray(w * h)
    queue: deque[tuple[int, int]] = deque()
    border_values = []
    for x in range(w):
        border_values.append(max(pixels[x, 0][:3]))
        border_values.append(max(pixels[x, h - 1][:3]))
    for y in range(h):
        border_values.append(max(pixels[0, y][:3]))
        border_values.append(max(pixels[w - 1, y][:3]))
    bright_background = sum(border_values) / max(len(border_values), 1) > 185

    def is_background(x: int, y: int) -> bool:
        r, g, b, a = pixels[x, y]
        if a == 0:
            return True
        mx = max(r, g, b)
        mn = min(r, g, b)
        sat = mx - mn
        if bright_background:
            return mx > 220 and sat < 70
        if mx > 225 and sat < 60:
            return True
        if mx < 165 and sat < 50:
            return True
        return False

    def push(x: int, y: int) -> None:
        if x < 0 or y < 0 or x >= w or y >= h:
            return
        idx = y * w + x
        if mask[idx] or not is_background(x, y):
            return
        mask[idx] = 1
        queue.append((x, y))

    for x in range(w):
        push(x, 0)
        push(x, h - 1)
    for y in range(h):
        push(0, y)
        push(w - 1, y)

    while queue:
        x, y = queue.popleft()
        push(x + 1, y)
        push(x - 1, y)
        push(x, y + 1)
        push(x, y - 1)

    for y in range(h):
        for x in range(w):
            if mask[y * w + x]:
                r, g, b, _a = pixels[x, y]
                pixels[x, y] = (r, g, b, 0)

    bbox = image.getbbox()
    if bbox:
        image = image.crop(bbox)
    return image


def keep_largest_subject(image: Image.Image) -> Image.Image:
    image = remove_sheet_background(image)
    if image.width == 0 or image.height == 0:
        return image

    pixels = image.load()
    w, h = image.size
    seen = bytearray(w * h)
    best: list[tuple[int, int]] = []
    best_score = -1.0

    for y in range(h):
        for x in range(w):
            idx = y * w + x
            if seen[idx] or pixels[x, y][3] == 0:
                continue

            queue = deque([(x, y)])
            seen[idx] = 1
            points: list[tuple[int, int]] = []
            min_x = max_x = x
            min_y = max_y = y

            while queue:
                cx, cy = queue.popleft()
                points.append((cx, cy))
                min_x = min(min_x, cx)
                max_x = max(max_x, cx)
                min_y = min(min_y, cy)
                max_y = max(max_y, cy)
                for nx in range(cx - 1, cx + 2):
                    for ny in range(cy - 1, cy + 2):
                        if nx < 0 or ny < 0 or nx >= w or ny >= h:
                            continue
                        nidx = ny * w + nx
                        if seen[nidx] or pixels[nx, ny][3] == 0:
                            continue
                        seen[nidx] = 1
                        queue.append((nx, ny))

            box_w = max_x - min_x + 1
            box_h = max_y - min_y + 1
            if len(points) < 120 or box_h < h * 0.18 or box_w < w * 0.04:
                continue

            center_bias = 1.0 - min(0.7, abs(((min_x + max_x) / 2.0) - (w / 2.0)) / max(w, 1))
            score = len(points) * center_bias * (1.0 + box_h / max(h, 1))
            if score > best_score:
                best_score = score
                best = points

    if not best:
        return image

    out = Image.new("RGBA", image.size, (0, 0, 0, 0))
    out_pixels = out.load()
    for x, y in best:
        out_pixels[x, y] = pixels[x, y]

    bbox = out.getbbox()
    return out.crop(bbox) if bbox else out


def fit_sprite(image: Image.Image) -> Image.Image:
    image = image.convert("RGBA")
    image.thumbnail((SPRITE_SIZE[0] - 24, SPRITE_SIZE[1] - 16), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", SPRITE_SIZE, (0, 0, 0, 0))
    x = (SPRITE_SIZE[0] - image.width) // 2
    y = SPRITE_SIZE[1] - image.height - 8
    canvas.alpha_composite(image, (x, y))
    return canvas


def crop_sprite_grid3(sheet: Image.Image, col: int, row: int) -> Image.Image:
    w, h = sheet.size
    centers_x = [0.27, 0.49, 0.68]
    centers_y = [0.20, 0.50, 0.80]
    center_x = int(w * centers_x[col])
    center_y = int(h * centers_y[row])
    crop_w = int(w * 0.19)
    crop_h = int(h * 0.30)
    return sheet.crop((center_x - crop_w // 2, center_y - crop_h // 2, center_x + crop_w // 2, center_y + crop_h // 2))


def crop_sprite_grid5(sheet: Image.Image, col: int, row: int, idle: bool = False) -> Image.Image:
    w, h = sheet.size
    centers_x = [0.176, 0.345, 0.514, 0.677, 0.846]
    center_x = int(centers_x[col] * w)
    center_y = int(h * (0.82 if idle else (0.215 if row == 0 else 0.49)))
    crop_w = int(w * (0.145 if not idle else 0.16))
    crop_h = int(h * (0.31 if not idle else 0.25))
    return sheet.crop((center_x - crop_w // 2, center_y - crop_h // 2, center_x + crop_w // 2, center_y + crop_h // 2))


def make_runtime_frames(records: list[dict[str, object]]) -> None:
    base = NPC_ROOT
    runtime = ensure(RUNTIME_NPC_DIR)
    grid3 = {
        "zhang_san": base / "张三.png",
        "li_si": base / "李四.png",
        "wang_wu": base / "王五.png",
    }
    grid5 = {
        "sun_yue": base / "人物移动动作/孙悦.png",
        "he_zhen": base / "人物移动动作/何真.png",
        "chen_xi": base / "人物移动动作/陈曦.png",
        "zhao_lin": base / "人物移动动作/赵霖.png",
        "liu_feng": base / "人物移动动作/刘风.png",
    }

    for npc_id, path in grid3.items():
        sheet = Image.open(path).convert("RGBA")
        out_dir = ensure(runtime / npc_id)
        down_cells = [(1, 0), (2, 0), (1, 0)]
        up_cells = [(0, 0), (0, 0), (0, 0)]
        right_cells = [(0, 1), (1, 1), (2, 1)]
        for direction, cells in {"down": down_cells, "up": up_cells, "right": right_cells}.items():
            for idx, (col, row) in enumerate(cells):
                sprite = fit_sprite(keep_largest_subject(crop_sprite_grid3(sheet, col, row)))
                out = out_dir / f"{npc_id}_{direction}_{idx}.png"
                sprite.save(out)
                records.append({"kind": "runtime_sprite", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})
        for idx, (col, row) in enumerate(right_cells):
            sprite = fit_sprite(ImageOps.mirror(keep_largest_subject(crop_sprite_grid3(sheet, col, row))))
            out = out_dir / f"{npc_id}_left_{idx}.png"
            sprite.save(out)
            records.append({"kind": "runtime_sprite", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})
        for idx, (col, row) in enumerate(down_cells):
            sprite = fit_sprite(keep_largest_subject(crop_sprite_grid3(sheet, col, row)))
            out = out_dir / f"{npc_id}_idle_{idx}.png"
            sprite.save(out)
            records.append({"kind": "runtime_idle_sprite", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})

    for npc_id, path in grid5.items():
        sheet = Image.open(path).convert("RGBA")
        out_dir = ensure(runtime / npc_id)
        direction_cols = {"down": 0, "up": 1, "left": 2, "right": 3}
        for direction, col in direction_cols.items():
            for idx, row in enumerate([0, 1, 0]):
                sprite = fit_sprite(keep_largest_subject(crop_sprite_grid5(sheet, col, row)))
                out = out_dir / f"{npc_id}_{direction}_{idx}.png"
                sprite.save(out)
                records.append({"kind": "runtime_sprite", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})
        for idx in range(5):
            sprite = fit_sprite(keep_largest_subject(crop_sprite_grid5(sheet, idx, 0, idle=True)))
            out = out_dir / f"{npc_id}_idle_{idx}.png"
            sprite.save(out)
            records.append({"kind": "runtime_idle_sprite", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})


def make_generated_assets(records: list[dict[str, object]]) -> None:
    generated = ensure(GENERATED_ATLAS_DIR)
    class_sheet_copy = generated / "class_portraits_sheet.png"
    npc_sheet_copy = generated / "npc_portraits_sheet.png"
    shutil.copy2(CLASS_SHEET, class_sheet_copy)
    shutil.copy2(NPC_SHEET, npc_sheet_copy)
    records.append({
        "kind": "intermediate_ai_sheet",
        "source": relpath(CLASS_SHEET),
        "output": relpath(class_sheet_copy),
        "source_bytes": file_size(CLASS_SHEET),
        "bytes": file_size(class_sheet_copy),
    })
    records.append({
        "kind": "intermediate_ai_sheet",
        "source": relpath(NPC_SHEET),
        "output": relpath(npc_sheet_copy),
        "source_bytes": file_size(NPC_SHEET),
        "bytes": file_size(npc_sheet_copy),
    })

    class_out = ensure(CLASS_PORTRAIT_DIR)
    sheet = Image.open(CLASS_SHEET).convert("RGB")
    for idx, class_name in enumerate(CLASS_NAMES):
        portrait = crop_grid(sheet, 2, 2, idx).resize((512, 512), Image.Resampling.LANCZOS)
        numbered = class_out / f"class_portrait_{idx + 1:03d}.webp"
        named = class_out / f"{class_name}.webp"
        save_webp(portrait, numbered, 92)
        save_webp(portrait, named, 92)
        records.append({"kind": "class_portrait", "source": str(class_sheet_copy.relative_to(ROOT)), "output": str(numbered.relative_to(ROOT)), "bytes": file_size(numbered)})

    npc_out = ensure(NPC_GENERATED_PORTRAIT_DIR)
    sheet = Image.open(NPC_SHEET).convert("RGB")
    for idx, npc_id in enumerate(NPC_IDS):
        portrait = crop_grid(sheet, 4, 2, idx).resize((512, 512), Image.Resampling.LANCZOS)
        out = npc_out / f"{npc_id}.webp"
        save_webp(portrait, out, 90)
        records.append({"kind": "npc_image2_portrait", "source": str(npc_sheet_copy.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "bytes": file_size(out)})


def preview_big_pngs(records: list[dict[str, object]]) -> None:
    preview_root = OPTIMIZED_PREVIEW_DIR / "png_webp"
    source_roots = [
        GAME / "assets/characters/npcs/人物展示界面",
        GAME / "assets/characters/npcs/人物移动动作",
    ]
    for root in source_roots:
        for path in root.glob("*.png"):
            image = Image.open(path).convert("RGB")
            image.thumbnail((1024, 1024), Image.Resampling.LANCZOS)
            rel = path.relative_to(GAME / "assets")
            out = preview_root / rel.with_suffix(".webp")
            save_webp(image, out, 88)
            records.append({"kind": "targeted_webp_preview", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "source_bytes": file_size(path), "bytes": file_size(out)})

    for path in ASSET_ROOT.rglob("*.png"):
        if is_intermediate_or_preview(path):
            continue
        if path.stat().st_size <= 2 * 1024 * 1024:
            continue
        rel = path.relative_to(GAME / "assets")
        out = preview_root / "large_pngs" / rel.with_suffix(".webp")
        if out.exists():
            continue
        image = Image.open(path).convert("RGB")
        image.thumbnail((1280, 1280), Image.Resampling.LANCZOS)
        save_webp(image, out, 88)
        records.append({"kind": "large_png_webp_preview", "source": str(path.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "source_bytes": file_size(path), "bytes": file_size(out)})


def collect_text_for_font_subset() -> Path:
    text_paths = list((GAME / "scripts").rglob("*.gd")) + list((GAME / "scenes").rglob("*.tscn")) + [GAME / "project.godot"]
    chars = set()
    for path in text_paths:
        data = path.read_text(encoding="utf-8", errors="ignore")
        for ch in data:
            if ch == "\n" or ch == "\t" or ord(ch) < 32:
                continue
            chars.add(ch)
    chars.update("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
    out = ensure(OPTIMIZED_PREVIEW_DIR / "fonts") / "subset_chars.txt"
    out.write_text("".join(sorted(chars)), encoding="utf-8")
    return out


def make_font_subsets(records: list[dict[str, object]]) -> None:
    text_file = collect_text_for_font_subset()
    font_dir = GAME / "assets/fonts"
    out_dir = ensure(OPTIMIZED_PREVIEW_DIR / "fonts")
    for font in ["LXGWWenKai-Regular.ttf", "LXGWWenKaiMono-Regular.ttf"]:
        src = font_dir / font
        out = out_dir / font.replace(".ttf", ".subset.ttf")
        cmd = [
            "pyftsubset",
            str(src),
            f"--text-file={text_file}",
            f"--output-file={out}",
            "--layout-features=*",
            "--glyph-names",
            "--symbol-cmap",
            "--legacy-cmap",
            "--notdef-glyph",
            "--notdef-outline",
            "--recommended-glyphs",
        ]
        result = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
        records.append({"kind": "font_subset", "source": str(src.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "source_bytes": file_size(src), "bytes": file_size(out), "returncode": result.returncode})


def make_audio_previews(records: list[dict[str, object]]) -> None:
    out_root = ensure(OPTIMIZED_PREVIEW_DIR / "audio")
    audio_sources = [GAME / "assets/audio/bgm/轻音乐.mp3"] + sorted((GAME / "assets/audio/bgm/赛博").glob("*.ogg"))
    for src in audio_sources:
        rel = src.relative_to(GAME / "assets/audio")
        attempts = [
            (out_root / rel.with_suffix(".ogg"), ["afconvert", "-f", "Oggf", "-d", "vorb", "-b", "96000", str(src)]),
            (out_root / rel.with_suffix(".mp3"), ["afconvert", "-f", "MPG3", "-d", ".mp3", "-b", "96000", str(src)]),
        ]
        failures: list[str] = []
        for out, cmd_base in attempts:
            ensure(out.parent)
            cmd = cmd_base + [str(out)]
            result = subprocess.run(cmd, cwd=ROOT, text=True, capture_output=True)
            if result.returncode == 0 and out.exists() and out.stat().st_size > 0:
                records.append({"kind": "audio_preview", "source": str(src.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "source_bytes": file_size(src), "bytes": file_size(out), "returncode": 0})
                break
            failures.append(out.suffix.lstrip(".") + " failed: " + result.stderr.strip()[:180])
        else:
            out = attempts[-1][0]
            records.append({"kind": "audio_preview", "source": str(src.relative_to(ROOT)), "output": str(out.relative_to(ROOT)), "source_bytes": file_size(src), "bytes": file_size(out), "returncode": 1, "stderr": " | ".join(failures)})


def write_report(records: list[dict[str, object]]) -> None:
    report = OPTIMIZED_PREVIEW_DIR / "asset_optimization_report.md"
    ensure(report.parent)
    lines = build_resource_report_lines(records)
    report.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    records: list[dict[str, object]] = []
    make_generated_assets(records)
    make_runtime_frames(records)
    preview_big_pngs(records)
    make_font_subsets(records)
    make_audio_previews(records)
    write_report(records)
    print(f"Wrote {len(records)} asset records")


if __name__ == "__main__":
    main()
