#!/usr/bin/env python3
"""生成赛博小镇角色待机动画 - 平滑12帧循环版本"""
import os
import urllib.request
import urllib.parse
import ssl
import time

ASSETS_BASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "characters", "select", "idle")
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

# 核心策略: 固定 base_prompt 确保角色外观完全一致
# 每帧仅微调 modifier 实现呼吸/光效/粒子等微小变化
# seed 固定确保角色形象完全不变

REALISTIC_ANIMATIONS = {
    "cipher": {
        "base_prompt": "cyberpunk female data analyst, silver short hair, cyan glowing eyes, sleek white and teal tech-wear outfit with holographic data displays, glowing monocle on one eye with digital code reflections, standing in futuristic high-tech data center with blue holographic screens and data streams in background, cinematic cyberpunk atmosphere, sharp focus, volumetric lighting, detailed metallic and holographic textures, professional cyberpunk illustration, full body portrait centered",
        "seed": 442,
        "frame_modifiers": [
            "subtle breathing motion, calm relaxed stance, hands gently at sides, soft cyan glow pulsing slowly on equipment",
            "subtle breathing motion, slight chest expansion, holographic panels flickering gently, calm expression",
            "very slight head tilt to right, soft hair movement, cyan light shimmering on armor plates, serene look",
            "head back to center, subtle breathing, data streams in background flowing smoothly, steady gaze",
            "slight head tilt to left, gentle hair swaying, holographic displays rotating slowly, focused expression",
            "subtle shift of weight, hands slightly repositioned, soft glow pulse on equipment, composed stance",
            "subtle breathing, cyan energy particles floating up from hands, soft light trails, calm demeanor",
            "cyan particles dissipating, holographic screens reflecting light softly, steady breathing, relaxed posture",
            "subtle breathing, background data streams intensifying slightly, soft glow on face, alert expression",
            "data streams normalizing, gentle light reflection changes on armor, subtle hair movement, steady look",
            "returning to neutral stance, subtle breathing, all lights stabilizing to gentle glow, calm expression",
            "fully neutral relaxed stance, gentle breathing cycle completes, soft ambient glow, serene composure",
        ],
    },
    "chrome": {
        "base_prompt": "massive cyberpunk male soldier, heavy matte-black armor plating with orange glowing accents, one glowing red mechanical eye, rugged scarred face, industrial hydraulic arms with visible pistons and joints, standing in smoggy orange-lit industrial warehouse with sparks and embers floating in air, gritty cyberpunk atmosphere, low angle shot, dramatic rim lighting, hyper-detailed metallic textures and hydraulic mechanisms, professional cyberpunk illustration, full body portrait centered",
        "seed": 537,
        "frame_modifiers": [
            "subtle breathing causing armor plates to shift slightly, steam puffing gently from shoulder vents, stoic expression",
            "chest expanding slightly with breath, red mechanical eye glowing steadily, embers floating slowly in background",
            "very slight head turn to right, hydraulic joints creaking subtly, orange accent lights pulsing softly",
            "head back to center, arms crossed position maintained, steam venting rhythmically from armor, vigilant gaze",
            "slight head tilt left, red eye intensifying briefly then softening, sparks crackling faintly from joints",
            "weight shifting slightly on heavy boots, armor plates settling with subtle clank, steam venting from back vents",
            "hydraulic arm flexing subtly showing mechanical detail, red eye scanning briefly, embers swirling around boots",
            "arm relaxing back to position, steam dissipating, red eye returning to steady glow, battle-ready stance",
            "subtle breathing deepens, armor expanding slightly, orange glow intensifying on chest plate, alert posture",
            "glow stabilizing, steam venting pattern changing, slight smoke wisps rising from shoulders, steady stance",
            "returning to neutral heavy stance, armor plates settling, breathing normalizing, all systems steady",
            "fully neutral relaxed combat stance, gentle breathing cycle, steady red eye glow, calm vigilance",
        ],
    },
    "echo": {
        "base_prompt": "ethereal psionic character, androgynous face with big glowing violet eyes, long flowing hair made of purple energy waves, wearing translucent organic cyber-fabric outfit that shimmers with inner light, standing in a distorted dimension rift environment with glitching neon fragments and floating purple magical particles, surreal dreamlike cyberpunk atmosphere, soft ethereal glow, detailed energy particle effects, professional cyberpunk illustration, full body portrait centered",
        "seed": 656,
        "frame_modifiers": [
            "subtle breathing causing energy fabric to ripple softly, violet eyes glowing steadily, particles floating gently upward",
            "energy hair flowing with subtle movement, dimensional rift background shifting imperceptibly, serene expression",
            "very slight head tilt, energy waves in hair undulating, particles clustering around hands, mystical gaze",
            "head center, hands slightly raised palms up, purple sparkles drifting from fingertips, calm meditation",
            "subtle floating motion, energy fabric expanding and contracting gently, rift background brightening softly",
            "gentle body sway, particles swirling in slow orbit around body, eyes intensifying violet glow slightly",
            "energy beams connecting from fingertips to rift behind, particles accelerating upward, ethereal beauty",
            "energy beams dissolving into sparkles, particles returning to gentle float, eyes softening to normal glow",
            "subtle breathing deepens, energy fabric rippling more intensely, particles forming concentric rings around body",
            "rings expanding outward and fading, energy fabric settling, rift background stabilizing, steady expression",
            "returning to neutral floating stance, gentle hair movement, particles returning to ambient drift, calm composure",
            "fully neutral relaxed ethereal stance, gentle breathing cycle, steady violet glow, peaceful meditation",
        ],
    },
    "shadow": {
        "base_prompt": "stealth ninja operative, lean male build, full-face matte black tactical mask with single glowing green sensor strip, big expressive eyes visible through mask gap, obsidian-black tactical suit with green accent lines, standing on rainy midnight neon-lit street with puddles reflecting green neon light, raindrops falling through dramatic rim lighting, mysterious cyberpunk atmosphere, high contrast sharp details, professional cyberpunk illustration, full body portrait centered",
        "seed": 789,
        "frame_modifiers": [
            "subtle breathing causing tactical suit to shift slightly, rain dripping from mask edges, green sensor pulsing softly",
            "chest expanding slightly with breath, green sensor brightening and dimming rhythmically, rain intensifying briefly",
            "very slight head tilt right, rain splashing differently off mask, green light reflecting on wet surfaces",
            "head back to center, arms relaxed at sides, rain steady, sensor maintaining gentle pulse, vigilant stance",
            "slight head tilt left, green sensor flaring brighter then settling, rain streaking diagonally, intense gaze",
            "weight shifting to one foot, tactical suit adjusting, rain pooling around boots, sensor pulsing in pattern",
            "one hand slightly raising, green data stream flowing from palm, rain drops suspended briefly in air, mysterious",
            "hand lowering back to side, data stream dissipating into mist, rain resuming normal pattern, composed posture",
            "subtle breathing deepens, sensor intensifying glow, rain reflecting more green light, alert and ready",
            "sensor glow stabilizing, rain pattern changing slightly, green reflections shifting on puddles, steady stance",
            "returning to neutral relaxed stance, gentle breathing, sensor returning to soft pulse, calm vigilance",
            "fully neutral stealth stance, gentle breathing cycle, steady rain, soft green sensor glow, patient readiness",
        ],
    },
}

ANIME_ANIMATIONS = {
    "cipher": {
        "base_prompt": "anime style cyberpunk girl data analyst, silver short hair with big bright cyan eyes, cute anime face, wearing white and teal tech-wear outfit with holographic data displays, glowing monocle on one eye with digital code reflections, standing in futuristic data center with blue holographic screens in background, kawaii cyberpunk aesthetic, vibrant anime colors, clean anime line art, Japanese animation style, 2D anime illustration, cel-shaded, detailed anime art, full body portrait centered",
        "seed": 442,
        "frame_modifiers": [
            "subtle breathing motion, calm relaxed stance with gentle smile, soft cyan glow pulsing on holographic panels",
            "slight chest expansion with breathing, holographic keyboard floating gently in front, curious anime expression",
            "very slight head tilt right, hair swaying softly, cyan light shimmering on equipment, cute focused look",
            "head back to center, hands at sides, data streams flowing in background, steady bright-eyed gaze",
            "slight head tilt left, gentle hair movement, holographic displays rotating slowly, determined anime face",
            "subtle weight shift, fingers twitching slightly near keyboard, soft glow pulse, composed kawaii stance",
            "cyan energy particles floating up from fingertips, soft light trails, excited anime expression with sparkles",
            "particles dissipating into sparkles, holographic screens reflecting light softly, calm composed expression",
            "subtle breathing, background data streams intensifying, soft glow on face, alert bright-eyed look",
            "data streams normalizing, gentle light reflection changes, subtle hair swaying, steady kawaii gaze",
            "returning to neutral stance, gentle breathing, lights stabilizing, calm anime composure with soft smile",
            "fully neutral relaxed stance, gentle breathing cycle completes, soft ambient glow, serene kawaii expression",
        ],
    },
    "chrome": {
        "base_prompt": "anime style massive cyberpunk male soldier, muscular build in cute anime proportions, wearing heavy matte-black armor with bright orange glowing accents, one glowing red mechanical eye, heroic anime character design with determined face, standing in industrial warehouse with orange sparks and floating embers in background, dramatic anime lighting, vibrant anime colors, clean line art, Japanese mecha anime influence, cel-shaded 2D anime illustration, detailed anime art, full body portrait centered",
        "seed": 537,
        "frame_modifiers": [
            "subtle breathing causing armor to shift slightly, steam puffing gently from vents, confident anime smirk",
            "chest expanding with breath, red mechanical eye glowing steadily, embers floating slowly, heroic pose",
            "very slight head turn right, hydraulic joints moving subtly, orange lights pulsing softly, battle-ready anime face",
            "head center, arms crossed proudly, steam venting rhythmically, steady determined gaze with cool expression",
            "slight head tilt left, red eye intensifying then softening, sparks crackling faintly, intense anime eyes",
            "weight shifting slightly on heavy boots, armor settling with subtle motion, steam from back vents, alert stance",
            "hydraulic arm flexing showing mechanical detail, red eye scanning, embers swirling, excited battle expression",
            "arm relaxing, steam dissipating, red eye steady glow, calm determined anime face with cool attitude",
            "breathing deepens, armor expanding, orange glow intensifying on chest, alert anime expression with sparkles",
            "glow stabilizing, steam venting pattern changing, smoke wisps from shoulders, steady heroic stance",
            "returning to neutral heavy stance, armor settling, breathing normalizing, all systems calm anime composure",
            "fully neutral relaxed combat stance, gentle breathing, steady red eye glow, calm cool anime expression",
        ],
    },
    "echo": {
        "base_prompt": "anime style ethereal psionic character, cute androgynous anime face with big glowing violet eyes, long flowing hair made of purple energy waves, translucent anime outfit flowing like liquid with inner light, surrounded by floating purple magical particles and dimension rift, surreal anime fantasy style, dreamy pastel purple colors, beautiful anime art style, cel-shaded 2D anime illustration, detailed anime line art, full body portrait centered",
        "seed": 656,
        "frame_modifiers": [
            "subtle breathing causing energy fabric to ripple, violet eyes glowing steadily, particles floating gently, serene anime smile",
            "energy hair flowing with movement, dimensional rift shifting imperceptibly, particles orbiting head, mystical expression",
            "very slight head tilt, energy waves undulating, particles clustering around hands, cute focused anime face",
            "head center, hands slightly raised palms up, purple sparkles from fingertips, calm kawaii meditation pose",
            "subtle floating motion, energy fabric expanding contracting, rift background brightening softly, ethereal beauty",
            "gentle body sway, particles swirling in orbit, eyes intensifying violet glow, dreamy anime expression",
            "energy beams connecting fingertips to rift, particles accelerating upward, intense magical anime face with sparkles",
            "energy beams dissolving, particles returning to gentle float, eyes softening, calm cute expression",
            "breathing deepens, energy fabric rippling intensely, particles forming rings around body, alert mystical expression",
            "rings expanding and fading, energy fabric settling, rift stabilizing, steady serene anime gaze",
            "returning to neutral floating stance, gentle hair movement, ambient particle drift, calm kawaii composure",
            "fully neutral relaxed ethereal stance, gentle breathing, steady violet glow, peaceful cute meditation",
        ],
    },
    "shadow": {
        "base_prompt": "anime style stealth ninja character, lean male with cool anime mask, full-face matte black tactical mask with single glowing green strip, big expressive anime eyes visible through mask gap, obsidian-black tactical suit with green accents, standing on rainy midnight street with neon green reflections in puddles, mysterious cool anime character, dramatic anime lighting with rain effects, clean anime line art, Japanese ninja anime style, cel-shaded 2D anime illustration, detailed anime art, full body portrait centered",
        "seed": 789,
        "frame_modifiers": [
            "subtle breathing causing suit to shift, rain dripping from mask, green sensor pulsing softly, cool anime stance",
            "chest expanding with breath, sensor brightening dimming rhythmically, rain intensifying, mysterious ninja pose",
            "very slight head tilt right, rain splashing off mask differently, green light reflecting on wet surfaces, cool eyes",
            "head center, arms relaxed at sides, rain steady, sensor gentle pulse, vigilant cool anime expression",
            "slight head tilt left, sensor flaring brighter then settling, rain streaking diagonally, intense mysterious gaze",
            "weight shifting to one foot, suit adjusting, rain pooling around boots, sensor pulsing pattern, cool attitude",
            "one hand slightly raising, green data stream from palm, rain suspended in air, dramatic anime pose with sparkles",
            "hand lowering, data stream dissipating, rain resuming normal, composed cool ninja expression through mask",
            "breathing deepens, sensor intensifying, rain reflecting green light, alert mysterious anime face",
            "sensor glow stabilizing, rain pattern changing, green reflections shifting on puddles, steady cool stance",
            "returning to neutral stance, gentle breathing, sensor soft pulse, calm mysterious anime composure",
            "fully neutral stealth stance, gentle breathing, steady rain, soft green sensor glow, patient cool ninja pose",
        ],
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

def generate_style(animations: dict, style_name: str, total_frames: int = 12):
    for class_name, data in animations.items():
        class_dir = os.path.join(ASSETS_BASE, style_name, class_name)
        os.makedirs(class_dir, exist_ok=True)

        base_prompt = data["base_prompt"]
        seed = data["seed"]

        for i in range(total_frames):
            modifier = data["frame_modifiers"][i]
            full_prompt = base_prompt + ", " + modifier
            encoded = urllib.parse.quote(full_prompt)
            url = f"https://image.pollinations.ai/prompt/{encoded}?width=512&height=640&seed={seed}&nologo=true&model=flux"
            path = os.path.join(class_dir, f"{class_name}_idle_{i}.jpg")
            print(f"Generating {class_name} ({style_name}) frame {i+1}/{total_frames}...")
            if download_file(url, path):
                size = os.path.getsize(path)
                print(f"  Saved: {path} ({size} bytes)")
            else:
                print(f"  FAILED: {path}")
            time.sleep(3)

# 先生成写实风格
print("=" * 60)
print("GENERATING REALISTIC CYBERPUNK STYLE (12 frames per character)")
print("=" * 60)
generate_style(REALISTIC_ANIMATIONS, "", 12)

# 再生成二次元风格
print("\n" + "=" * 60)
print("GENERATING ANIME STYLE (12 frames per character)")
print("=" * 60)
generate_style(ANIME_ANIMATIONS, "anime", 12)

print("\n" + "=" * 60)
print(f"ALL 96 FRAMES GENERATED! (4 chars x 12 frames x 2 styles)")
print("=" * 60)
