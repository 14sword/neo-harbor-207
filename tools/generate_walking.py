#!/usr/bin/env python3
"""
新港·207 - 角色行走动画帧生成器
为每个角色下载3个不同姿态（站立、迈步、侧身），生成真正的行走动画帧。
"""
import os, sys, time, requests
from PIL import Image, ImageDraw, ImageFilter
from io import BytesIO

GAME_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "game")
CHARACTERS_DIR = os.path.join(GAME_DIR, "assets", "characters")

# 每个角色3个姿态：站立(正面)、迈步(正面走路)、侧身(侧面)
CHARACTER_POSES = {
    "cipher": {
        "name": "CIPHER",
        "base_prompt": "cyberpunk female data analyst, cyan glowing circuits on jacket, dark hair with neon cyan streaks, holographic glasses, futuristic terminal operator, full body, anime style, dark background with data streams, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (0, 230, 255),
    },
    "chrome": {
        "name": "CHROME",
        "base_prompt": "cyberpunk male cyborg warrior, orange glowing mechanical arm, red mohawk hair, heavy combat armor with orange neon accents, muscular build, full body, anime style, dark industrial background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (255, 140, 0),
    },
    "echo": {
        "name": "ECHO",
        "base_prompt": "cyberpunk female psionic specialist, pink purple glowing eyes, long white hair with ethereal glow, psychic energy aura, mystical tech outfit, full body, anime style, dark background with purple energy, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (200, 80, 255),
    },
    "shadow": {
        "name": "SHADOW",
        "base_prompt": "cyberpunk male shadow agent, green glowing visor, dark hooded cloak, stealth tech suit with green neon lines, agile build, full body, anime style, dark alley background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (0, 200, 80),
    },
    "chen_xi": {
        "name": "陈曦",
        "base_prompt": "cyberpunk mysterious cafe owner, long dark hair, purple elegant outfit, coffee cup with glowing liquid, mysterious smile, full body, anime style, neon cafe background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (160, 80, 200),
    },
    "zhao_lin": {
        "name": "赵霖",
        "base_prompt": "cyberpunk street information dealer, slicked back hair, golden jacket, sneaky expression, data chips in hand, full body, anime style, dark market alley background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (255, 200, 0),
    },
    "sun_yue": {
        "name": "孙悦",
        "base_prompt": "cyberpunk female anomaly researcher, short hair with teal highlights, lab coat with tech gadgets, analytical glasses, scientific instruments, intellectual look, full body, anime style, research lab background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (0, 200, 180),
    },
    "liu_feng": {
        "name": "刘风",
        "base_prompt": "cyberpunk male cyborg technician, red bandana, muscular build, tool belt, mechanical parts, rugged look, warm smile, full body, anime style, workshop background with sparks, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (255, 80, 60),
    },
    "he_zhen": {
        "name": "何真",
        "base_prompt": "cyberpunk male AI system admin, cold expression, short silver hair, dark blue uniform with blue neon circuit patterns, tablet device, logical demeanor, full body, anime style, server room background, high detail",
        "poses": {
            "standing": "standing still, arms at sides, facing forward, neutral pose",
            "walk_front": "walking forward towards viewer, one leg stepping forward, dynamic pose, mid-stride",
            "walk_side": "walking to the right, side view, legs in walking motion, one foot lifted",
        },
        "color": (60, 120, 255),
    },
}

AVATAR_SIZE = (256, 256)
SPRITE_SIZE = (128, 128)


def download_image(prompt, seed=42, max_retries=3):
    url = f"https://image.pollinations.ai/prompt/{requests.utils.quote(prompt)}?width=512&height=768&seed={seed}&nologo=true&model=flux"
    for attempt in range(max_retries):
        print(f"    Downloading (attempt {attempt+1}/{max_retries})...")
        try:
            resp = requests.get(url, timeout=180)
            if resp.status_code == 200:
                return Image.open(BytesIO(resp.content)).convert("RGBA")
            print(f"    WARNING: status {resp.status_code}")
        except Exception as e:
            print(f"    WARNING: {e}")
        if attempt < max_retries - 1:
            time.sleep(5)
    return None


def crop_to_sprite(portrait, size=SPRITE_SIZE):
    """从全身立绘中裁切出人物区域并缩放到目标尺寸"""
    w, h = portrait.size
    # 裁切掉顶部20%和底部10%，保留人物主体
    top = int(h * 0.15)
    bottom = int(h * 0.95)
    left = int(w * 0.1)
    right = int(w * 0.9)
    cropped = portrait.crop((left, top, right, bottom))
    return cropped.resize(size, Image.LANCZOS)


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


def generate_walk_frames_from_poses(standing_img, walk_front_img, walk_side_img):
    """
    用3个不同姿态生成4方向行走帧：
    - down: 迈步正面 (帧0=站立, 帧1=迈步, 帧2=站立)
    - up: 站立背面 (帧0=站立, 帧1=站立微偏, 帧2=站立)
    - left: 侧身向左 (镜像侧身)
    - right: 侧身向右 (原始侧身)
    """
    frames = {"down": [], "up": [], "left": [], "right": []}

    # down方向：站立→迈步→站立
    frames["down"] = [standing_img, walk_front_img, standing_img]

    # up方向：站立（背面用站立代替，微调y偏移模拟走路）
    for i in range(3):
        f = standing_img.copy()
        # 轻微上下抖动模拟走路
        offset_y = [-1, 0, 1][i]
        if offset_y != 0:
            draw = ImageDraw.Draw(f)
            # 清除底部几像素，产生"抬脚"效果
            w, h = f.size
            draw.rectangle([0, h - 4 + offset_y, w, h], fill=(0, 0, 0, 0))
        frames["up"].append(f)

    # right方向：侧身
    frames["right"] = [standing_img, walk_side_img, standing_img]

    # left方向：侧身镜像
    frames["left"] = [standing_img, walk_side_img.transpose(Image.FLIP_LEFT_RIGHT), standing_img]

    return frames


def save_character_assets(character_id, frames, portrait, output_dir, avatar_dir=None, select_dir=None, char_name=""):
    os.makedirs(output_dir, exist_ok=True)

    # 保存头像
    avatar = crop_avatar(portrait)
    avatar_path = os.path.join(output_dir, f"{character_id}_头像.png")
    avatar.save(avatar_path)
    print(f"  Saved avatar: {avatar_path}")

    if avatar_dir and char_name:
        os.makedirs(avatar_dir, exist_ok=True)
        avatar.save(os.path.join(avatar_dir, f"{char_name}头像.png"))

    # 保存4方向行走帧
    for direction, dir_frames in frames.items():
        for idx, frame in enumerate(dir_frames):
            frame_path = os.path.join(output_dir, f"{character_id}_{direction}_{idx}.png")
            frame.save(frame_path)
        print(f"  Saved {direction} frames ({len(dir_frames)} frames)")

    # 保存idle帧（站立姿态）
    idle = frames["down"][0]
    idle.save(os.path.join(output_dir, f"{character_id}_idle.png"))
    print(f"  Saved idle")

    # 保存静态帧
    static = crop_to_sprite(portrait)
    static.save(os.path.join(output_dir, f"{character_id}_down.png"))

    # 保存选择界面大图
    if select_dir:
        os.makedirs(select_dir, exist_ok=True)
        portrait_select = portrait.resize((512, 768), Image.LANCZOS)
        portrait_select.save(os.path.join(select_dir, f"{character_id}.png"))
        print(f"  Saved select portrait")


def main():
    print("=" * 60)
    print("新港·207 - 角色行走动画帧生成器（3姿态版）")
    print("=" * 60)

    npcs_dir = os.path.join(CHARACTERS_DIR, "npcs")
    avatars_dir = os.path.join(CHARACTERS_DIR, "avatars")
    select_dir = os.path.join(CHARACTERS_DIR, "select")
    player_dir = os.path.join(CHARACTERS_DIR, "player")

    npc_ids = ["chen_xi", "zhao_lin", "sun_yue", "liu_feng", "he_zhen"]
    class_ids = ["cipher", "chrome", "echo", "shadow"]

    for char_id, config in CHARACTER_POSES.items():
        print(f"\n[{config['name']}]")

        standing_img = None
        walk_front_img = None
        walk_side_img = None

        for pose_name, pose_suffix in config["poses"].items():
            full_prompt = config["base_prompt"] + ", " + pose_suffix
            seed = (hash(char_id) + hash(pose_name)) % 999999

            img = download_image(full_prompt, seed)
            if img is None:
                print(f"  SKIPPED pose {pose_name} (download failed)")
                continue

            sprite = crop_to_sprite(img)

            if pose_name == "standing":
                standing_img = sprite
            elif pose_name == "walk_front":
                walk_front_img = sprite
            elif pose_name == "walk_side":
                walk_side_img = sprite

            time.sleep(2)

        if standing_img is None:
            print(f"  SKIPPED (no standing pose)")
            continue

        # 如果某个姿态下载失败，用站立姿态代替
        if walk_front_img is None:
            walk_front_img = standing_img.copy()
        if walk_side_img is None:
            walk_side_img = standing_img.copy()

        frames = generate_walk_frames_from_poses(standing_img, walk_front_img, walk_side_img)

        # 获取完整立绘用于头像裁切
        full_prompt = config["base_prompt"] + ", " + config["poses"]["standing"]
        seed = hash(char_id) % 999999
        full_portrait = download_image(full_prompt, seed)
        if full_portrait is None:
            full_portrait = Image.new("RGBA", (512, 768), (50, 50, 50, 255))

        if char_id in npc_ids:
            save_character_assets(char_id, frames, full_portrait, npcs_dir, avatars_dir, None, config["name"])
        elif char_id in class_ids:
            save_character_assets(char_id, frames, full_portrait, player_dir, None, select_dir, config["name"])

    print("\n" + "=" * 60)
    print("Done! Walking animation frames generated with 3 distinct poses.")
    print("=" * 60)


if __name__ == "__main__":
    main()
