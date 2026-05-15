#!/usr/bin/env python3
"""
赛博小镇 - 角色立绘与精灵图生成器
使用 Pollinations.ai 生成赛博朋克风格角色立绘，自动裁切为头像和行走帧精灵图。
"""

import os
import sys
import time
import requests
from PIL import Image, ImageDraw, ImageFilter
from io import BytesIO

GAME_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "helloagents-ai-town", "datawhale-town")
CHARACTERS_DIR = os.path.join(GAME_DIR, "assets", "characters")

CHARACTER_PROMPTS = {
    "cipher": {
        "name": "CIPHER",
        "prompt": "cyberpunk female data analyst, cyan glowing circuits on jacket, dark hair with neon cyan streaks, holographic glasses, futuristic terminal operator, standing pose, full body, anime style, dark background with data streams, high detail",
        "color": (0, 230, 255),
    },
    "chrome": {
        "name": "CHROME",
        "prompt": "cyberpunk male cyborg warrior, orange glowing mechanical arm, red mohawk hair, heavy combat armor with orange neon accents, muscular build, standing pose, full body, anime style, dark industrial background, high detail",
        "color": (255, 140, 0),
    },
    "echo": {
        "name": "ECHO",
        "prompt": "cyberpunk female psionic specialist, pink purple glowing eyes, long white hair with ethereal glow, psychic energy aura, mystical tech outfit, standing pose, full body, anime style, dark background with purple energy, high detail",
        "color": (200, 80, 255),
    },
    "shadow": {
        "name": "SHADOW",
        "prompt": "cyberpunk male shadow agent, green glowing visor, dark hooded cloak, stealth tech suit with green neon lines, agile build, standing pose, full body, anime style, dark alley background, high detail",
        "color": (0, 200, 80),
    },
    "chen_xi": {
        "name": "陈曦",
        "prompt": "cyberpunk mysterious cafe owner, long dark hair, purple elegant outfit, coffee cup with glowing liquid, mysterious smile, standing pose, full body, anime style, neon cafe background, high detail",
        "color": (160, 80, 200),
    },
    "zhao_lin": {
        "name": "赵霖",
        "prompt": "cyberpunk street information dealer, slicked back hair, golden jacket, sneaky expression, data chips in hand, shady look, standing pose, full body, anime style, dark market alley background, high detail",
        "color": (255, 200, 0),
    },
    "sun_yue": {
        "name": "孙悦",
        "prompt": "cyberpunk female anomaly researcher, short hair with teal highlights, lab coat with tech gadgets, analytical glasses, scientific instruments, intellectual look, standing pose, full body, anime style, research lab background, high detail",
        "color": (0, 200, 180),
    },
    "liu_feng": {
        "name": "刘风",
        "prompt": "cyberpunk male cyborg technician, red bandana, muscular build, tool belt, mechanical parts, rugged look, warm smile, standing pose, full body, anime style, workshop background with sparks, high detail",
        "color": (255, 80, 60),
    },
    "he_zhen": {
        "name": "何真",
        "prompt": "cyberpunk male AI system admin, cold expression, short silver hair, dark blue uniform with blue neon circuit patterns, tablet device, logical demeanor, standing pose, full body, anime style, server room background, high detail",
        "color": (60, 120, 255),
    },
}

AVATAR_SIZE = (256, 256)
SPRITE_SIZE = (128, 128)
IDLE_SIZE = (128, 128)


def download_portrait(character_id: str, prompt: str, seed: int = 42, max_retries: int = 3) -> Image.Image:
    url = f"https://image.pollinations.ai/prompt/{requests.utils.quote(prompt)}?width=512&height=768&seed={seed}&nologo=true&model=flux"
    for attempt in range(max_retries):
        print(f"  Downloading {character_id} (attempt {attempt + 1}/{max_retries})...")
        try:
            resp = requests.get(url, timeout=120)
            if resp.status_code == 200:
                return Image.open(BytesIO(resp.content)).convert("RGBA")
            print(f"  WARNING: Failed (status {resp.status_code})")
        except Exception as e:
            print(f"  WARNING: {e}")
        if attempt < max_retries - 1:
            time.sleep(3)
    return None


def crop_avatar(portrait: Image.Image) -> Image.Image:
    w, h = portrait.size
    side = min(w, h)
    left = (w - side) // 2
    top = int(h * 0.1)
    right = left + side
    bottom = top + side
    if bottom > h:
        bottom = h
        top = h - side
    avatar = portrait.crop((left, top, right, bottom))
    avatar = avatar.resize(AVATAR_SIZE, Image.LANCZOS)
    return avatar


def create_pixel_sprite(portrait: Image.Image, size: tuple = SPRITE_SIZE) -> Image.Image:
    sprite = portrait.resize(size, Image.LANCZOS)
    return sprite


def generate_walking_frames(portrait: Image.Image, direction: str) -> list:
    frames = []
    base = create_pixel_sprite(portrait)
    w, h = base.size
    for i in range(3):
        frame = base.copy()
        draw = ImageDraw.Draw(frame)
        if direction == "down":
            offset_y = [-2, 0, 2][i]
            draw.rectangle([0, h - 6 + offset_y, w, h], fill=(0, 0, 0, 0))
        elif direction == "up":
            offset_y = [2, 0, -2][i]
            draw.rectangle([0, h - 6 + offset_y, w, h], fill=(0, 0, 0, 0))
        elif direction == "left":
            offset_x = [-2, 0, 2][i]
            draw.rectangle([0, 0, 6 + offset_x, h], fill=(0, 0, 0, 0))
        elif direction == "right":
            offset_x = [2, 0, -2][i]
            draw.rectangle([w - 6 + offset_x, 0, w, h], fill=(0, 0, 0, 0))
        frames.append(frame)
    return frames


def generate_idle_frame(portrait: Image.Image) -> Image.Image:
    return create_pixel_sprite(portrait)


def save_character_assets(character_id: str, portrait: Image.Image, output_dir: str):
    os.makedirs(output_dir, exist_ok=True)
    avatar = crop_avatar(portrait)
    avatar_path = os.path.join(output_dir, f"{character_id}_头像.png")
    avatar.save(avatar_path)
    print(f"  Saved avatar: {avatar_path}")

    directions = ["down", "left", "right", "up"]
    for direction in directions:
        frames = generate_walking_frames(portrait, direction)
        for idx, frame in enumerate(frames):
            frame_path = os.path.join(output_dir, f"{character_id}_{direction}_{idx}.png")
            frame.save(frame_path)
        print(f"  Saved {direction} frames ({len(frames)} frames)")

    idle = generate_idle_frame(portrait)
    idle_path = os.path.join(output_dir, f"{character_id}_idle.png")
    idle.save(idle_path)
    print(f"  Saved idle: {idle_path}")

    static_path = os.path.join(output_dir, f"{character_id}_down.png")
    portrait_resized = portrait.resize((64, 64), Image.LANCZOS)
    portrait_resized.save(static_path)


def main():
    print("=" * 60)
    print("赛博小镇 - 角色立绘与精灵图生成器")
    print("=" * 60)

    npcs_dir = os.path.join(CHARACTERS_DIR, "npcs")
    avatars_dir = os.path.join(CHARACTERS_DIR, "avatars")
    select_dir = os.path.join(CHARACTERS_DIR, "select")
    player_dir = os.path.join(CHARACTERS_DIR, "player")

    os.makedirs(npcs_dir, exist_ok=True)
    os.makedirs(avatars_dir, exist_ok=True)
    os.makedirs(select_dir, exist_ok=True)
    os.makedirs(player_dir, exist_ok=True)

    npc_ids = ["chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen"]
    class_ids = ["cipher", "chrome", "echo", "shadow"]

    print(f"\nGenerating {len(npc_ids)} NPC portraits + {len(class_ids)} class portraits...")
    print(f"Output: {CHARACTERS_DIR}\n")

    for character_id, config in CHARACTER_PROMPTS.items():
        print(f"\n[{config['name']}]")
        seed = hash(character_id) % 999999
        portrait = download_portrait(character_id, config["prompt"], seed)
        if portrait is None:
            print(f"  SKIPPED (download failed)")
            continue

        if character_id in npc_ids:
            save_character_assets(character_id, portrait, npcs_dir)
            avatar = crop_avatar(portrait)
            avatar_path = os.path.join(avatars_dir, f"{config['name']}头像.png")
            avatar.save(avatar_path)
            print(f"  Saved avatar: {avatar_path}")
        elif character_id in class_ids:
            save_character_assets(character_id, portrait, player_dir)
            select_path = os.path.join(select_dir, f"{character_id}.png")
            portrait_select = portrait.resize((512, 768), Image.LANCZOS)
            portrait_select.save(select_path)
            print(f"  Saved select: {select_path}")

        time.sleep(1)

    print("\n" + "=" * 60)
    print("Generation complete!")
    print(f"NPC sprites: {npcs_dir}")
    print(f"Avatars: {avatars_dir}")
    print(f"Player sprites: {player_dir}")
    print(f"Select portraits: {select_dir}")
    print("=" * 60)


if __name__ == "__main__":
    main()
