#!/usr/bin/env python3
"""生成新港·207角色待机动画帧 - 使用 Pollinations.ai（无需 API Key）"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select", "idle")
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

IDLE_ANIMATIONS = {
    "cipher": {
        "base_prompt": "Cyberpunk character portrait, full body shot, young woman with short silver-white hair, wearing sleek white and teal high-tech bodysuit with glowing cyan circuit patterns on skin, glowing monocle with scrolling data overlay, standing in a dark data center surrounded by holographic blue screens and streaming binary code, dramatic volumetric cyan lighting, dark moody background, cinematic composition, high detail, 8k resolution",
        "frame_modifiers": [
            "subtle breathing motion, arms slightly lowered, calm expression, still pose",
            "subtle breathing motion, head tilted slightly up, data streams flowing faster around her",
            "subtle breathing motion, one hand slightly raised as if typing in the air, holographic keyboard glowing"
        ],
        "seeds": [42, 43, 44],
    },
    "chrome": {
        "base_prompt": "Massive cyberpunk character portrait, full body shot, muscular male soldier with heavy matte-black industrial armor plating, one glowing red mechanical eye with hydraulic pistons visible in arms, rugged battle-scarred face, standing in a smog-filled industrial warehouse with orange ember lighting, sparks flying, dramatic low-angle cinematic shot, hyper-realistic metallic textures, dark moody atmosphere",
        "frame_modifiers": [
            "arms crossed, standing still, calm but imposing presence, steam rising from vents",
            "one arm slightly raised showing hydraulic arm flexing, glowing red eye intensifying, embers falling",
            "both arms resting at sides, head turned slightly, steam billowing from shoulder vents, sparks in background"
        ],
        "seeds": [137, 138, 139],
    },
    "echo": {
        "base_prompt": "Ethereal cyberpunk character portrait, full body shot, gender-ambiguous figure with translucent glowing skin, long flowing hair made of purple energy ripples and violet light, eyes intensely glowing, wearing organic luminescent cyber-fabric that flows like liquid, surrounded by floating purple psionic particles and a distorted glitching dimension rift background, surreal dreamlike atmosphere, soft volumetric purple light, cinematic digital art",
        "frame_modifiers": [
            "floating gently in mid-air, hands spread outward releasing purple energy wisps, eyes closed peacefully",
            "eyes open with intense violet glow, dimension rift expanding behind figure, particles swirling in circular pattern",
            "body slightly translucent, dimension rift contracting, purple energy waves emanating from figure's core"
        ],
        "seeds": [256, 257, 258],
    },
    "shadow": {
        "base_prompt": "Stealth cyberpunk character portrait, full body shot, lean male operative wearing a full-face matte black tactical mask with a single glowing green sensor strip across eyes, obsidian-black chameleon suit that blends into darkness, standing on a rainy midnight street with neon green reflections on wet pavement, dramatic rim lighting from green neon signs, mysterious and lethal atmosphere, high contrast cinematic shot, rain droplets visible",
        "frame_modifiers": [
            "crouching slightly, hands ready, rain dripping from mask, green sensor strip pulsing slowly",
            "standing upright, one hand raised with holographic data stream flowing from palm, rain intensifying",
            "partially turned, cloak billowing in wind, rain streaks visible across the scene, sensor strip glowing brighter"
        ],
        "seeds": [389, 390, 391],
    },
}

def download_file(url: str, path: str, retries: int = 3) -> bool:
    for attempt in range(retries):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, context=ctx) as resp:
                data = resp.read()
            with open(path, "wb") as f:
                f.write(data)
            return True
        except Exception as e:
            print(f"  Attempt {attempt+1} failed: {e}")
            if attempt < retries - 1:
                time.sleep(3)
    return False

for class_name, data in IDLE_ANIMATIONS.items():
    class_dir = os.path.join(ASSETS_BASE, class_name)
    os.makedirs(class_dir, exist_ok=True)

    for i in range(3):
        full_prompt = data["base_prompt"] + ", " + data["frame_modifiers"][i]
        encoded = urllib.parse.quote(full_prompt)
        url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=640&seed={data['seeds'][i]}&nologo=true&model=flux"
        path = os.path.join(class_dir, f"{class_name}_idle_{i}.png")
        print(f"Generating {class_name} frame {i+1}/3...")
        download_file(url, path)
        size = os.path.getsize(path)
        print(f"  Saved: {path} ({size} bytes)")
        time.sleep(2)

print("\nAll 12 idle animation frames generated!")
print("Refresh Godot project to import the new PNG files.")
