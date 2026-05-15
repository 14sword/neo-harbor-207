#!/usr/bin/env python3
"""生成赛博小镇 NPC 赛博朋克风格精灵 - 3帧×4方向"""
import os, urllib.request, urllib.parse, ssl, time

ASSETS_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "npcs")
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

DIR_OFFSET = {"down": 0, "up": 1000, "left": 2000, "right": 3000}
DIRECTIONS = ["down", "up", "left", "right"]

NPC_PROMPTS = {
    "zhang_san": {
        "base": "cyberpunk street market shopkeeper, middle-aged chinese man with small round glasses and gray apron over a worn cyberpunk jacket, standing in front of a small market stall with holographic price tags and neon street lights in background, cinematic cyberpunk style, sharp focus, detailed facial features",
        "seeds": [501, 502, 503],
    },
    "li_si": {
        "base": "cyberpunk security guard, young chinese man in a dark blue uniform with neon orange trim, earpiece with glowing wire, holding a stun baton at his side, standing in a corporate building hallway with neon accent lighting, cinematic cyberpunk style, sharp focus",
        "seeds": [511, 512, 513],
    },
    "wang_wu": {
        "base": "cyberpunk street food vendor, overweight chinese man with a stained apron and a cybernetic arm replacement, standing behind a steaming food cart with flickering neon signs, smoke and steam rising, gritty cyberpunk alley background, cinematic style, detailed textures",
        "seeds": [521, 522, 523],
    },
    "chen_xi": {
        "base": "cyberpunk female programmer, young chinese woman with short blue-dyed hair and augmented reality glasses, wearing a oversized tech hoodie with glowing cyan circuit patterns, holographic data streams floating around her, cyberpunk nightclub hacker space background, cinematic style",
        "seeds": [531, 532, 533],
    },
    "zhao_lin": {
        "base": "cyberpunk underground hacker, young chinese man with a gas mask hanging around his neck and a leather cyberpunk jacket with LED strips, thin build, holding a tablet with a glowing green interface, dark server room background with blinking server lights, cinematic cyberpunk style",
        "seeds": [541, 542, 543],
    },
    "sun_yue": {
        "base": "cyberpunk news reporter, young chinese woman with a sleek black bob cut, wearing a professional cyberpunk trench coat with purple trim, holding a floating holographic camera drone, standing on a rainy cyberpunk street with billboard reflections, cinematic style, sharp focus",
        "seeds": [551, 552, 553],
    },
    "liu_feng": {
        "base": "cyberpunk gang member, chinese man with a cybernetic eye patch covering one eye, dragon tattoo on neck visible above a leather cyberpunk vest, muscular arms with reinforced joints, standing in a neon-lit underground fight club, gritty cinematic cyberpunk style",
        "seeds": [561, 562, 563],
    },
    "he_zhen": {
        "base": "cyberpunk underground doctor, chinese woman in her 30s with hair tied back, wearing a white cyberpunk lab coat with red medical cross holograms, holding a medical scanner device, standing in a makeshift clinic with bioluminescent lighting and medical screens, cinematic style",
        "seeds": [571, 572, 573],
    },
}

DIR_MODIFIERS = {
    "down": "facing slightly downward toward camera, looking ahead with neutral expression, full body view from front angle",
    "up": "facing slightly upward away from camera, back visible with shoulder detail, from behind angle showing back of character",
    "left": "facing to the left side, profile view showing side of character, head turned slightly left, body oriented to left",
    "right": "facing to the right side, profile view showing side of character, head turned slightly right, body oriented to right",
}

FRAME_MODIFIERS = [
    "standing still, neutral pose, calm expression",
    "slight shift of weight to one foot, subtle body movement",
    "taking a small step, one foot forward, dynamic walking pose",
]

def download_file(url, path, retries=5):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, context=ctx, timeout=120) as resp:
                data = resp.read()
            with open(path, "wb") as f:
                f.write(data)
            return True
        except Exception as e:
            print(f"  Attempt {attempt+1} failed: {e}")
            if attempt < retries - 1:
                time.sleep(5)
    return False

os.makedirs(ASSETS_BASE, exist_ok=True)

print("=" * 60)
print("GENERATING NPC SPRITES (3 frames x 4 directions x 8 NPCs = 96 images)")
print("=" * 60)

for npc_name, npc_data in NPC_PROMPTS.items():
    for fi, seed in enumerate(npc_data["seeds"]):
        for dir_name in DIRECTIONS:
            dir_mod = DIR_MODIFIERS[dir_name]
            frame_mod = FRAME_MODIFIERS[fi]
            final_seed = seed + DIR_OFFSET[dir_name]
            full_prompt = f"{npc_data['base']}, {dir_mod}, {frame_mod}, full body game character sprite, transparent background, consistent character design, game asset quality"
            encoded = urllib.parse.quote(full_prompt)
            url = f"https://image.pollinations.ai/prompt/{encoded}?width=256&height=256&seed={final_seed}&nologo=true&model=flux"
            path = os.path.join(ASSETS_BASE, f"{npc_name}_{dir_name}_{fi}.png")
            print(f"Generating {npc_name}_{dir_name}_{fi} (seed={final_seed})...")
            if download_file(url, path):
                sz = os.path.getsize(path)
                print(f"  Saved ({sz} bytes)")
            else:
                print(f"  FAILED")
            time.sleep(2)

print("\n" + "=" * 60)
print("ALL 96 NPC SPRITES GENERATED!")
print("=" * 60)
