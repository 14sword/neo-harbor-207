#!/usr/bin/env python3
"""生成赛博小镇角色待机动画 - 二次元动漫风格版本"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select", "idle")
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

ANIME_ANIMATIONS = {
    "cipher": {
        "base_prompt": "anime style cyberpunk girl data analyst, silver short hair, big bright cyan eyes, cute anime face, wearing white and teal tech-wear outfit with holographic data displays, glowing monocle with digital patterns, standing in futuristic data center with blue holographic screens, kawaii cyberpunk aesthetic, vibrant colors, clean anime line art, Japanese animation style, 2D anime illustration, high quality anime art",
        "frame_modifiers": [
            "standing straight with hands behind back, gentle smile, data streams flowing around her, calm expression",
            "head tilted slightly to the side, one finger touching the monocle, curious look, holographic keyboard floating in front",
            "both hands raised typing in the air, excited expression, data rings orbiting around body, determined look",
            "one hand on hip looking confident with a playful wink, holographic data panels slowly rotating in background"
        ],
        "seeds": [442, 443, 444, 445],
    },
    "chrome": {
        "base_prompt": "anime style massive cyberpunk male soldier, muscular build but cute anime proportions, wearing heavy matte-black armor with orange accents, one glowing red mechanical eye, heroic anime character design, standing in industrial warehouse with sparks and embers, dramatic but kawaii cyberpunk style, vibrant anime colors, clean line art, Japanese mecha anime influence, high quality anime illustration",
        "frame_modifiers": [
            "arms crossed with confident smirk, standing proudly, steam puffing from armor vents, heroic pose",
            "one arm raised flexing hydraulic muscles, glowing red eye shining bright, embers floating around, battle ready stance",
            "both arms at sides looking straight ahead, determined expression, smoke venting from shoulders, protective stance",
            "slightly leaning forward with fists clenched, red eye glowing intensely, sparks flying from armor joints, ready for combat"
        ],
        "seeds": [537, 538, 539, 540],
    },
    "echo": {
        "base_prompt": "anime style ethereal psionic character, androgynous cute anime face, big glowing violet eyes, long flowing hair made of purple energy, translucent anime outfit that flows like liquid, surrounded by floating purple magical particles and dimension rift, surreal anime fantasy style, dreamy and mystical, soft pastel purple colors, beautiful anime art style, high quality anime illustration",
        "frame_modifiers": [
            "floating gently with eyes closed peacefully, hands spread outward releasing purple sparkles, serene smile",
            "eyes open with intense violet glow, dimension rift expanding behind, particles swirling around, mystical pose",
            "body slightly tilted, energy beams connecting fingertips to rift, gentle wind blowing hair, ethereal beauty",
            "both hands clasped together at chest, eyes half-closed in concentration, purple aura expanding outward, peaceful meditation pose"
        ],
        "seeds": [656, 657, 658, 659],
    },
    "shadow": {
        "base_prompt": "anime style stealth ninja character, lean male with cool mask, full-face matte black tactical mask with single glowing green strip, big expressive anime eyes visible through mask gap, obsidian-black suit with green accents, standing on rainy midnight street with neon green reflections, mysterious cool anime character, dramatic anime lighting, clean anime line art, Japanese ninja anime style, high quality anime illustration",
        "frame_modifiers": [
            "crouching slightly in cool ninja pose, rain dripping from mask, green sensor pulsing, mysterious vibe",
            "standing upright with one hand raised, holographic data stream flowing from palm, rain intensifying, dramatic pose",
            "leaning casually against wall with arms crossed, hood slightly up, rain pooling around boots, cool attitude",
            "one knee on ground looking up alertly, hand on weapon hilt, rain splashing off shoulders, vigilant stance"
        ],
        "seeds": [789, 790, 791, 792],
    },
}

def download_file(url: str, path: str, retries: int = 5) -> bool:
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

for class_name, data in ANIME_ANIMATIONS.items():
    class_dir = os.path.join(ASSETS_BASE, "anime", class_name)
    os.makedirs(class_dir, exist_ok=True)

    for i in range(4):
        full_prompt = data["base_prompt"] + ", " + data["frame_modifiers"][i]
        encoded = urllib.parse.quote(full_prompt)
        url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=640&seed={data['seeds'][i]}&nologo=true&model=flux"
        path = os.path.join(class_dir, f"{class_name}_idle_{i}.jpg")
        print(f"Generating {class_name} anime frame {i+1}/4...")
        if download_file(url, path):
            size = os.path.getsize(path)
            print(f"  Saved: {path} ({size} bytes)")
        else:
            print(f"  FAILED: {path}")
        time.sleep(3)

print("\nAll 16 anime style frames generated!")
