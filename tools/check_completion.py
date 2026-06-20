#!/usr/bin/env python3
"""Static completion checks for Neo Harbor 207.

This script verifies repository shape and required assets without launching
Godot, starting the backend, calling external services, or writing files.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
BACKEND = ROOT / "backend"


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def res_to_path(res_path: str) -> Path:
    if not res_path.startswith("res://"):
        raise ValueError(f"Unsupported resource path: {res_path}")
    return GAME / res_path.removeprefix("res://")


class CheckReport:
    def __init__(self) -> None:
        self.failures: list[str] = []
        self.warnings: list[str] = []
        self.notes: list[str] = []

    def ok(self, message: str) -> None:
        self.notes.append(f"OK   {message}")

    def warn(self, message: str) -> None:
        self.warnings.append(f"WARN {message}")

    def fail(self, message: str) -> None:
        self.failures.append(f"FAIL {message}")

    def exists(self, path: Path, label: str) -> bool:
        if path.exists():
            self.ok(f"{label}: {rel(path)}")
            return True
        self.fail(f"{label} missing: {rel(path)}")
        return False

    def print(self) -> None:
        for line in self.notes:
            print(line)
        for line in self.warnings:
            print(line)
        for line in self.failures:
            print(line)
        print()
        print(f"Summary: {len(self.notes)} ok, {len(self.warnings)} warn, {len(self.failures)} fail")


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def check_project_config(report: CheckReport) -> None:
    project = GAME / "project.godot"
    if not report.exists(project, "Godot project config"):
        return

    text = read_text(project)
    main_scene = re.search(r'run/main_scene="([^"]+)"', text)
    if main_scene:
        report.exists(res_to_path(main_scene.group(1)), "Godot main scene")
    else:
        report.fail("Godot main scene not declared")

    autoloads = re.findall(r'^\w+="\*?(res://[^"]+)"', text, re.MULTILINE)
    if autoloads:
        missing = [path for path in autoloads if not res_to_path(path).exists()]
        if missing:
            for path in missing:
                report.fail(f"Autoload missing: {path}")
        else:
            report.ok(f"Autoload scripts present: {len(autoloads)}")
    else:
        report.warn("No autoload entries found")


def check_scene_resources(report: CheckReport) -> None:
    scene_files = sorted((GAME / "scenes").glob("*.tscn"))
    report.ok(f"Scene files detected: {len(scene_files)}")

    missing: list[tuple[str, str]] = []
    resource_re = re.compile(r'path="(res://[^"]+)"')
    for scene in scene_files:
        for res_path in resource_re.findall(read_text(scene)):
            if not res_to_path(res_path).exists():
                missing.append((rel(scene), res_path))

    if missing:
        for source, res_path in missing:
            report.fail(f"Broken scene resource in {source}: {res_path}")
    else:
        report.ok("Scene ext_resource paths present")

    for path in [
        GAME / "scenes" / "underground.tscn",
        GAME / "scenes" / "anomaly_space.tscn",
        GAME / "scripts" / "special_scene.gd",
        GAME / "scripts" / "underground_ambient.gd",
    ]:
        report.exists(path, "Special scene support")


def check_assets(report: CheckReport) -> None:
    player_files = [
        "player_down_0.png",
        "player_down_1.png",
        "player_down_2.png",
        "player_up_0.png",
        "player_up_1.png",
        "player_up_2.png",
        "player_left_0.png",
        "player_left_1.png",
        "player_left_2.png",
        "player_right_0.png",
        "player_right_1.png",
        "player_right_2.png",
        "player_idle.png",
    ]
    player_dir = GAME / "assets" / "characters" / "player"
    missing_player = [name for name in player_files if not (player_dir / name).exists()]
    if missing_player:
        for name in missing_player:
            report.fail(f"Player frame missing: {rel(player_dir / name)}")
    else:
        report.ok(f"Player frames present: {len(player_files)}")

    npc_ids = ["zhang_san", "li_si", "wang_wu", "sun_yue", "he_zhen", "chen_xi", "zhao_lin", "liu_feng"]
    directions = ["down", "up", "left", "right"]
    runtime_dir = GAME / "assets" / "characters" / "npcs" / "runtime"
    runtime_missing: list[Path] = []
    for npc_id in npc_ids:
        for direction in directions:
            for idx in range(3):
                path = runtime_dir / npc_id / f"{npc_id}_{direction}_{idx}.png"
                if not path.exists():
                    runtime_missing.append(path)
        expected_idle = 5
        for idx in range(expected_idle):
            path = runtime_dir / npc_id / f"{npc_id}_idle_{idx}.png"
            if not path.exists():
                runtime_missing.append(path)
    if runtime_missing:
        for path in runtime_missing[:20]:
            report.fail(f"NPC runtime frame missing: {rel(path)}")
        if len(runtime_missing) > 20:
            report.fail(f"NPC runtime frame missing: {len(runtime_missing) - 20} additional files")
    else:
        report.ok("NPC runtime walking and idle frames present")

    media_counts = {
        category.name: len([p for p in category.iterdir() if p.is_file() and p.suffix.lower() in {".png", ".jpg", ".webp"}])
        for category in sorted((GAME / "assets" / "media").iterdir())
        if category.is_dir()
    }
    required_media = {
        "city_day",
        "city_rain",
        "city_night",
        "surveillance",
        "forum",
        "datawhale",
        "anomaly",
        "ads",
        "weather",
        "talisman",
        "class_portrait",
    }
    missing_categories = sorted(required_media.difference(media_counts))
    if missing_categories:
        for category in missing_categories:
            report.fail(f"Media category missing: game/assets/media/{category}")
    else:
        report.ok(f"Media categories present: {len(required_media)}")
    for category, count in media_counts.items():
        if count == 0:
            report.fail(f"Media category has no images: {category}")
    report.ok("Media image counts: " + ", ".join(f"{k}={v}" for k, v in sorted(media_counts.items())))

    for scene_name in ["underground", "anomaly_space"]:
        background_dir = GAME / "assets" / "backgrounds" / scene_name
        missing_backgrounds = [
            phase_name
            for phase_name in ["白天.png", "傍晚.png", "黑夜.png", "雨夜.png"]
            if not (background_dir / phase_name).exists()
        ]
        if missing_backgrounds:
            for name in missing_backgrounds:
                report.fail(f"Special scene background missing: {rel(background_dir / name)}")
        else:
            report.ok(f"Special scene time backgrounds present: {rel(background_dir)}")

    underground_effects = [
        GAME / "assets" / "effects" / "underground" / "holo_notice_sheet.png",
        GAME / "assets" / "effects" / "underground" / "maintenance_monitor_sheet.png",
        GAME / "assets" / "effects" / "underground" / "train_light_sweep.png",
        GAME / "assets" / "effects" / "underground" / "steam_puff_sheet.png",
        GAME / "assets" / "effects" / "underground" / "drip_reflection_sheet.png",
        GAME / "assets" / "effects" / "underground" / "sun_yue_research_kit.png",
        GAME / "assets" / "effects" / "underground" / "portal_pulse_sheet.png",
    ]
    missing_effects = [path for path in underground_effects if not path.exists()]
    if missing_effects:
        for path in missing_effects:
            report.fail(f"Underground ambient effect missing: {rel(path)}")
    else:
        report.ok(f"Underground Image2 ambient effects present: {len(underground_effects)}")

    for path in [
        GAME / "assets" / "ui" / "map" / "cyber_town_overview.webp",
        GAME / "assets" / "ui" / "map" / "office.png",
        GAME / "assets" / "ui" / "map" / "street.png",
        GAME / "assets" / "ui" / "map" / "apartment.png",
        GAME / "assets" / "ui" / "map" / "underground.png",
        GAME / "assets" / "ui" / "map" / "anomaly.png",
        GAME / "assets" / "ui" / "map" / "locked.png",
        GAME / "assets" / "ui" / "map" / "current_beacon.png",
        GAME / "assets" / "ui" / "teleport" / "street_underground_entrance.png",
        GAME / "assets" / "ui" / "teleport" / "return_to_street_pad.png",
        GAME / "assets" / "ui" / "teleport" / "underground_anomaly_portal.png",
        GAME / "assets" / "ui" / "teleport" / "return_to_underground_rift.png",
    ]:
        report.exists(path, "Image2 map or teleport UI asset")


def check_backend(report: CheckReport) -> None:
    for path in [
        BACKEND / "main.py",
        BACKEND / "config.py",
        BACKEND / "models.py",
        BACKEND / "agents.py",
        BACKEND / "story_engine.py",
        BACKEND / "requirements.txt",
    ]:
        report.exists(path, "Backend file")

    main = BACKEND / "main.py"
    if main.exists():
        text = read_text(main)
        routes = re.findall(r'@app\.(get|post)\("([^"]+)"', text)
        report.ok(f"FastAPI routes declared: {len(routes)}")
        for required in ["/", "/dialogue", "/story/generate", "/city/status", "/character/create"]:
            if required not in {route for _, route in routes}:
                report.fail(f"FastAPI route missing: {required}")

    llm = BACKEND / "hello_agents_llm.py"
    if llm.exists():
        text = read_text(llm)
        for provider in ["groq", "mimo", "deepseek"]:
            if provider not in text.lower():
                report.warn(f"LLM provider marker not found: {provider}")
        report.ok("LLM provider fallback code present")


def check_godot_ai_link(report: CheckReport) -> None:
    api_client = GAME / "scripts" / "api_client.gd"
    config = GAME / "scripts" / "config.gd"
    for path in [api_client, config]:
        report.exists(path, "Godot AI linkage file")

    if api_client.exists():
        text = read_text(api_client)
        if "https://api.groq.com" in text or "YOUR_GROQ_API_KEY" in text or "Authorization: Bearer" in text:
            report.fail("Godot APIClient still contains client-side Groq credentials or direct provider calls")
        else:
            report.ok("Godot APIClient uses backend-owned AI provider boundary")

        required_methods = [
            "send_chat",
            "get_npc_status",
            "get_batch_dialogue",
            "get_affinity",
            "get_dialogue_history",
            "get_npc_interactions",
        ]
        for method in required_methods:
            if f"func {method}" not in text:
                report.fail(f"Godot APIClient method missing: {method}")

        for endpoint in ["/dialogue", "/npcs/status", "/npcs/batch_dialogue", "/affinity", "/dialogue/history", "/npcs/interactions"]:
            if endpoint not in text and endpoint not in read_text(config):
                report.fail(f"Godot APIClient backend endpoint marker missing: {endpoint}")

    if config.exists() and "http://localhost:8000" in read_text(config):
        report.ok("Godot backend base URL configured")


def check_tests(report: CheckReport) -> None:
    for path in [
        GAME / "tests" / "verify_assets.gd",
        GAME / "tests" / "verify_scenes.gd",
        GAME / "tests" / "verify_npc_animation.gd",
        GAME / "tests" / "verify_npc_scene_presence.gd",
        GAME / "tests" / "verify_special_scene_layout.gd",
        GAME / "tests" / "verify_teleports.gd",
    ]:
        report.exists(path, "Godot verification script")


def main() -> int:
    report = CheckReport()
    check_project_config(report)
    check_scene_resources(report)
    check_assets(report)
    check_backend(report)
    check_godot_ai_link(report)
    check_tests(report)
    report.print()
    return 1 if report.failures else 0


if __name__ == "__main__":
    sys.exit(main())
