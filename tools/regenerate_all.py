#!/usr/bin/env python3
"""快速重新生成所有角色精灵图（128×128 LANCZOS）"""
import os, sys, time, requests
from PIL import Image, ImageDraw
from io import BytesIO

GAME_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "helloagents-ai-town", "datawhale-town")
CHARACTERS_DIR = os.path.join(GAME_DIR, "assets", "characters")

CHARACTER_PROMPTS = {
    "cipher": {"name": "CIPHER", "prompt": "cyberpunk female data analyst, cyan glowing circuits on jacket, dark hair with neon cyan streaks, holographic glasses, futuristic terminal operator, standing pose, full body, anime style, dark background with data streams, high detail"},
    "chrome": {"name": "CHROME", "prompt": "cyberpunk male cyborg warrior, orange glowing mechanical arm, red mohawk hair, heavy combat armor with orange neon accents, muscular build, standing pose, full body, anime style, dark industrial background, high detail"},
    "echo": {"name": "ECHO", "prompt": "cyberpunk female psionic specialist, pink purple glowing eyes, long white hair with ethereal glow, psychic energy aura, mystical tech outfit, standing pose, full body, anime style, dark background with purple energy, high detail"},
    "shadow": {"name": "SHADOW", "prompt": "cyberpunk male shadow agent, green glowing visor, dark hooded cloak, stealth tech suit with green neon lines, agile build, standing pose, full body, anime style, dark alley background, high detail"},
    "chen_xi": {"name": "陈曦", "prompt": "cyberpunk mysterious cafe owner, long dark hair, purple elegant outfit, coffee cup with glowing liquid, mysterious smile, standing pose, full body, anime style, neon cafe background, high detail"},
    "zhao_lin": {"name": "赵霖", "prompt": "cyberpunk street information dealer, slicked back hair, golden jacket, sneaky expression, data chips in hand, shady look, standing pose, full body, anime style, dark market alley background, high detail"},
    "sun_yue": {"name": "孙悦", "prompt": "cyberpunk female anomaly researcher, short hair with teal highlights, lab coat with tech gadgets, analytical glasses, scientific instruments, intellectual look, standing pose, full body, anime style, research lab background, high detail"},
    "liu_feng": {"name": "刘风", "prompt": "cyberpunk male cyborg technician, red bandana, muscular build, tool belt, mechanical parts, rugged look, warm smile, standing pose, full body, anime style, workshop background with sparks, high detail"},
    "he_zhen": {"name": "何真", "prompt": "cyberpunk male AI system admin, cold expression, short silver hair, dark blue uniform with blue neon circuit patterns, tablet device, logical demeanor, standing pose, full body, anime style, server room background, high detail"},
}

AVATAR_SIZE = (256, 256)
SPRITE_SIZE = (128, 128)

def download_portrait(character_id, prompt, seed=42):
    url = f"https://image.pollinations.ai/prompt/{requests.utils.quote(prompt)}?width=512&height=768&seed={seed}&nologo=true&model=flux"
    for attempt in range(3):
        print(f"  Downloading {character_id} (attempt {attempt+1}/3)...")
        try:
            resp = requests.get(url, timeout=120)
            if resp.status_code == 200:
                return Image.open(BytesIO(resp.content)).convert("RGBA")
        except Exception as e:
            print(f"  WARNING: {e}")
        time.sleep(3)
    return None

def crop_avatar(portrait):
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
    return avatar.resize(AVATAR_SIZE, Image.LANCZOS)

def create_sprite(portrait, size=SPRITE_SIZE):
    return portrait.resize(size, Image.LANCZOS)

def generate_walking_frames(portrait, direction):
    frames = []
    base = create_sprite(portrait)
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

def save_assets(character_id, portrait, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    avatar = crop_avatar(portrait)
    avatar.save(os.path.join(output_dir, f"{character_id}_头像.png"))
    for direction in ["down", "left", "right", "up"]:
        frames = generate_walking_frames(portrait, direction)
        for idx, frame in enumerate(frames):
            frame.save(os.path.join(output_dir, f"{character_id}_{direction}_{idx}.png"))
    idle = create_sprite(portrait)
    idle.save(os.path.join(output_dir, f"{character_id}_idle.png"))
    static = portrait.resize(SPRITE_SIZE, Image.LANCZOS)
    static.save(os.path.join(output_dir, f"{character_id}_down.png"))

def main():
    print("=" * 60)
    print("Regenerating ALL character sprites at 128x128 (LANCZOS)")
    print("=" * 60)

    npc_ids = ["chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen"]
    class_ids = ["cipher", "chrome", "echo", "shadow"]

    npcs_dir = os.path.join(CHARACTERS_DIR, "npcs")
    avatars_dir = os.path.join(CHARACTERS_DIR, "avatars")
    select_dir = os.path.join(CHARACTERS_DIR, "select")
    player_dir = os.path.join(CHARACTERS_DIR, "player")

    for cid, cfg in CHARACTER_PROMPTS.items():
        print(f"\n[{cfg['name']}]")
        seed = hash(cid) % 999999
        portrait = download_portrait(cid, cfg["prompt"], seed)
        if portrait is None:
            print(f"  SKIPPED (download failed)")
            continue

        if cid in npc_ids:
            save_assets(cid, portrait, npcs_dir)
            avatar = crop_avatar(portrait)
            avatar.save(os.path.join(avatars_dir, f"{cfg['name']}头像.png"))
            print(f"  Saved NPC assets")
        elif cid in class_ids:
            save_assets(cid, portrait, player_dir)
            select_path = os.path.join(select_dir, f"{cid}.png")
            portrait.resize((512, 768), Image.LANCZOS).save(select_path)
            print(f"  Saved player assets")

        time.sleep(1)

    print("\n" + "=" * 60)
    print("Done! All sprites regenerated at 128x128 with LANCZOS.")
    print("=" * 60)

if __name__ == "__main__":
    main()
