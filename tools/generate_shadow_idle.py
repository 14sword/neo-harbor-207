#!/usr/bin/env python3
"""生成 shadow 职业待机动画帧"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select", "idle", "shadow")
os.makedirs(ASSETS_DIR, exist_ok=True)

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

SHADOW_PROMPT = "Stealth cyberpunk character portrait, full body shot, lean male operative wearing a full-face matte black tactical mask with a single glowing green sensor strip across eyes, obsidian-black chameleon suit that blends into darkness, standing on a rainy midnight street with neon green reflections on wet pavement, dramatic rim lighting from green neon signs, mysterious and lethal atmosphere, high contrast cinematic shot, rain droplets visible"

FRAME_MODIFIERS = [
    "crouching slightly, hands ready, rain dripping from mask, green sensor strip pulsing slowly",
    "standing upright, one hand raised with holographic data stream flowing from palm, rain intensifying",
    "partially turned, cloak billowing in wind, rain streaks visible across the scene, sensor strip glowing brighter"
]

SEEDS = [389, 390, 391]

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

for i in range(3):
    full_prompt = SHADOW_PROMPT + ", " + FRAME_MODIFIERS[i]
    encoded = urllib.parse.quote(full_prompt)
    url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=640&seed={SEEDS[i]}&nologo=true&model=flux"
    path = os.path.join(ASSETS_DIR, f"shadow_idle_{i}.png")
    print(f"Generating shadow frame {i+1}/3...")
    if download_file(url, path):
        size = os.path.getsize(path)
        print(f"  Saved: {path} ({size} bytes)")
    else:
        print(f"  FAILED to generate shadow_idle_{i}.png")
    time.sleep(3)

print("\nDone!")
