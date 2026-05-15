#!/usr/bin/env python3
"""生成赛博小镇角色待机动画第4帧（写实赛博朋克风格）"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select", "idle")
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

FRAME_4 = {
    "cipher": {
        "full_prompt": "Cyberpunk character portrait, full body shot, young woman with short silver-white hair, wearing sleek white and teal high-tech bodysuit with glowing cyan circuit patterns on skin, glowing monocle with scrolling data overlay, standing in a dark data center surrounded by holographic blue screens and streaming binary code, dramatic volumetric cyan lighting, dark moody background, cinematic composition, high detail, 8k resolution, subtle breathing motion, both hands clasped in front, looking straight ahead with calm focused expression, holographic data rings orbiting around her",
        "seed": 45,
    },
    "chrome": {
        "full_prompt": "Massive cyberpunk character portrait, full body shot, muscular male soldier with heavy matte-black industrial armor plating, one glowing red mechanical eye with hydraulic pistons visible in arms, rugged battle-scarred face, standing in a smog-filled industrial warehouse with orange ember lighting, sparks flying, dramatic low-angle cinematic shot, hyper-realistic metallic textures, dark moody atmosphere, arms resting on hips, chest plate glowing with heat signature, smoke venting from back exhaust ports",
        "seed": 140,
    },
    "echo": {
        "full_prompt": "Ethereal cyberpunk character portrait, full body shot, gender-ambiguous figure with translucent glowing skin, long flowing hair made of purple energy ripples and violet light, eyes intensely glowing, wearing organic luminescent cyber-fabric that flows like liquid, surrounded by floating purple psionic particles and a distorted glitching dimension rift background, surreal dreamlike atmosphere, soft volumetric purple light, cinematic digital art, floating at eye level, both arms raised with palms open, energy beams connecting fingertips to dimension rift",
        "seed": 259,
    },
    "shadow": {
        "full_prompt": "Stealth cyberpunk character portrait, full body shot, lean male operative wearing a full-face matte black tactical mask with a single glowing green sensor strip across eyes, obsidian-black chameleon suit that blends into darkness, standing on a rainy midnight street with neon green reflections on wet pavement, dramatic rim lighting from green neon signs, mysterious and lethal atmosphere, high contrast cinematic shot, rain droplets visible, leaning against a graffiti-covered wall, one leg extended, hood slightly up, rain pooling around boots",
        "seed": 392,
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

for class_name, data in FRAME_4.items():
    class_dir = os.path.join(ASSETS_BASE, class_name)
    os.makedirs(class_dir, exist_ok=True)

    encoded = urllib.parse.quote(data["full_prompt"])
    url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=640&seed={data['seed']}&nologo=true&model=flux"
    path = os.path.join(class_dir, f"{class_name}_idle_3.jpg")
    print(f"Generating {class_name} frame 4/4...")
    if download_file(url, path):
        size = os.path.getsize(path)
        print(f"  Saved: {path} ({size} bytes)")
    else:
        print(f"  FAILED: {path}")
    time.sleep(3)

print("\nAll 4 additional frames generated!")
