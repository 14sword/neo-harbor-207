#!/usr/bin/env python3
"""生成赛博小镇角色选择海报 - 使用 Pollinations.ai（无需 API Key）"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select")
os.makedirs(ASSETS_DIR, exist_ok=True)

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

POSTERS = {
    "cipher": {
        "prompt": "Cyberpunk portrait, full body shot, young woman with short silver-white hair, wearing sleek white and teal high-tech bodysuit with glowing cyan circuit patterns on skin, glowing monocle with scrolling data overlay on one eye, standing in a dark data center surrounded by holographic blue screens and streaming binary code, dramatic volumetric cyan lighting, dark background with subtle digital grid, cinematic composition, high detail, 8k resolution, pure white background for transparent PNG cutout later.",
        "seed": 42,
    },
    "chrome": {
        "prompt": "Massive cyberpunk portrait, full body shot, muscular male soldier with heavy matte-black industrial armor plating, one glowing red mechanical eye with hydraulic pistons visible in arms, rugged battle-scarred face, standing in a smog-filled industrial warehouse with orange ember lighting, sparks flying, dramatic low-angle cinematic shot, hyper-realistic metallic textures, dark moody atmosphere, pure white background for transparent PNG cutout later.",
        "seed": 137,
    },
    "echo": {
        "prompt": "Ethereal cyberpunk portrait, full body shot, gender-ambiguous figure with translucent glowing skin, long flowing hair made of purple energy ripples and violet light, eyes intensely glowing, wearing organic luminescent cyber-fabric that flows like liquid, surrounded by floating purple psionic particles and a distorted glitching dimension rift background, surreal dreamlike atmosphere, soft volumetric purple light, cinematic digital art, pure white background for transparent PNG cutout later.",
        "seed": 256,
    },
    "shadow": {
        "prompt": "Stealth cyberpunk portrait, full body shot, lean male operative wearing a full-face matte black tactical mask with a single glowing green sensor strip across eyes, obsidian-black chameleon suit that blends into darkness, standing on a rainy midnight street with neon green reflections on wet pavement, dramatic rim lighting from green neon signs, mysterious and lethal atmosphere, high contrast cinematic shot, rain droplets visible, pure white background for transparent PNG cutout later.",
        "seed": 389,
    },
}

def download_file(url: str, path: str) -> bool:
    req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, context=ctx) as resp:
        data = resp.read()
    with open(path, "wb") as f:
        f.write(data)
    return True

for name, data in POSTERS.items():
    encoded = urllib.parse.quote(data["prompt"])
    url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=768&seed={data['seed']}&nologo=true&model=flux"
    path = os.path.join(ASSETS_DIR, f"{name}.png")
    print(f"Generating {name}...")
    download_file(url, path)
    size = os.path.getsize(path)
    print(f"  Saved: {path} ({size} bytes)")
    time.sleep(1)

print("\nAll 4 posters generated successfully!")
print("Now refresh Godot project (close and reopen) to import the new PNG files.")
