from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from config import settings, NPC_CONFIGS
from models import (
    DialogueRequest,
    DialogueResponse,
    NPCStatus,
    NPCStatusResponse,
    AffinityInfo,
    DialogueHistoryResponse,
)
from agents import agent_manager
from relationship_manager import relationship_manager, AffinityLevel
from state_manager import state_manager
from db_manager import db_manager
from logger import logger
from batch_generator import batch_generator
from story_engine import story_engine

app = FastAPI(title="Cyber Town Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_batch_cache: dict = {}

@app.get("/")
def root():
    return {"message": "Welcome to Cyber Town!", "status": "running"}

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "cyber-town-backend",
        "batch_dialogue_refresh_enabled": settings.enable_batch_dialogue_refresh,
        "database_path": db_manager.db_path,
        "llm_configured": {
            "groq": bool(settings.groq_api_key),
            "mimo": bool(settings.mimo_api_key),
            "deepseek": bool(settings.deepseek_api_key),
        },
        "npc_count": len(NPC_CONFIGS),
    }

@app.get("/npcs/status", response_model=NPCStatusResponse)
def get_npcs_status():
    states = state_manager.get_all_states()
    npcs = [
        NPCStatus(
            npc_id=s["npc_id"],
            name=s["name"],
            role=s["role"],
            is_busy=s["is_busy"],
            current_action=s["current_action"],
        )
        for s in states
    ]
    return NPCStatusResponse(npcs=npcs)

@app.get("/npcs/batch_dialogue")
def get_batch_dialogue():
    global _batch_cache
    if not _batch_cache:
        _batch_cache = batch_generator.generate_batch_dialogues()
    return {"dialogues": _batch_cache}

@app.post("/dialogue", response_model=DialogueResponse)
def dialogue(req: DialogueRequest):
    if req.npc_id not in NPC_CONFIGS:
        raise HTTPException(status_code=404, detail=f"NPC '{req.npc_id}' not found")
    
    agent = agent_manager.get_agent(req.npc_id)
    if not agent:
        raise HTTPException(status_code=500, detail="Agent not available")
    
    reply = agent.chat(req.player_name, req.player_message)
    
    rel = relationship_manager.get_relationship(req.npc_id, req.player_name)
    
    return DialogueResponse(
        npc_reply=reply,
        affinity_level=AffinityLevel.level_to_num(rel["level"]),
        affinity_score=rel["score"],
    )

@app.get("/affinity/{npc_id}/{player_name}", response_model=AffinityInfo)
def get_affinity(npc_id: str, player_name: str):
    if npc_id not in NPC_CONFIGS:
        raise HTTPException(status_code=404, detail=f"NPC '{npc_id}' not found")
    
    rel = relationship_manager.get_relationship(npc_id, player_name)
    return AffinityInfo(
        npc_id=rel["npc_id"],
        player_name=rel["player_name"],
        score=rel["score"],
        level=AffinityLevel.level_to_num(rel["level"]),
        interaction_count=rel["interaction_count"],
    )

@app.get("/dialogue/history/{npc_id}", response_model=DialogueHistoryResponse)
def get_dialogue_history(npc_id: str, limit: int = 50):
    if npc_id not in NPC_CONFIGS:
        raise HTTPException(status_code=404, detail=f"NPC '{npc_id}' not found")
    
    memories = db_manager.load_memories(npc_id, limit)
    return DialogueHistoryResponse(npc_id=npc_id, history=memories)

@app.get("/npcs/interactions")
def get_npc_interactions():
    interactions = batch_generator.generate_npc_interactions()
    return {"interactions": interactions}

class CharacterCreateRequest(BaseModel):
    player_name: str = "玩家"
    player_class: str = "cipher"

class StoryGenerateRequest(BaseModel):
    chapter_id: str
    player_class: str = "cipher"
    player_name: str = "玩家"
    anomaly_level: float = 0.0
    completed_chapters: list = []

class NPCStoryRequest(BaseModel):
    npc_id: str

class DialogueBranchRequest(BaseModel):
    npc_id: str
    player_class: str = "cipher"
    current_topic: str = "日常"
    affinity_level: int = 1

@app.post("/character/create")
def create_character(req: CharacterCreateRequest):
    valid_classes = ["cipher", "chrome", "echo", "shadow"]
    if req.player_class not in valid_classes:
        raise HTTPException(status_code=400, detail=f"Invalid class: {req.player_class}")
    return {
        "status": "created",
        "player_name": req.player_name,
        "player_class": req.player_class,
        "class_data": {
            "cipher": {"name": "数据分析师", "codename": "CIPHER"},
            "chrome": {"name": "义体战士", "codename": "CHROME"},
            "echo": {"name": "灵能感知者", "codename": "ECHO"},
            "shadow": {"name": "暗影潜行者", "codename": "SHADOW"},
        }.get(req.player_class, {})
    }

@app.get("/npcs/all")
def get_all_npcs():
    result = []
    for npc_id, config in NPC_CONFIGS.items():
        result.append({
            "npc_id": npc_id,
            "name": config["name"],
            "role": config["role"],
            "scene": config.get("scene", "office"),
            "backstory": config.get("backstory", ""),
        })
    return {"npcs": result}

@app.post("/story/generate")
def generate_story(req: StoryGenerateRequest):
    context = {
        "anomaly_level": req.anomaly_level,
        "completed_chapters": req.completed_chapters,
    }
    result = story_engine.generate_chapter_content(
        req.chapter_id, req.player_class, req.player_name, context
    )
    return result

@app.get("/story/progress")
def get_story_progress():
    return {
        "chapters": {
            "ch1": {"title": "初来乍到", "status": "available"},
            "ch2": {"title": "数据暗流", "status": "locked"},
            "ch3": {"title": "裂缝显现", "status": "locked"},
            "ch4": {"title": "诸天交汇", "status": "locked"},
            "ch5": {"title": "抉择时刻", "status": "locked"},
        }
    }

@app.post("/generate/npc-story")
def generate_npc_story(req: NPCStoryRequest):
    if req.npc_id not in NPC_CONFIGS:
        raise HTTPException(status_code=404, detail=f"NPC '{req.npc_id}' not found")
    return story_engine.generate_npc_backstory(req.npc_id)

@app.post("/generate/dialogue-branch")
def generate_dialogue_branch(req: DialogueBranchRequest):
    if req.npc_id not in NPC_CONFIGS:
        raise HTTPException(status_code=404, detail=f"NPC '{req.npc_id}' not found")
    branches = story_engine.generate_dialogue_branch(
        req.npc_id, req.player_class, req.current_topic, req.affinity_level
    )
    return {"branches": branches}

@app.get("/generate/daily-events")
def generate_daily_events(day: int = 1, month: str = "霜月",
                           weather: str = "晴", anomaly_level: float = 0.0):
    return story_engine.generate_daily_event(day, weather, anomaly_level, month)

@app.get("/city/status")
def city_status():
    import random
    anomaly_level = round(random.uniform(0.01, 0.15), 3)
    anomaly_status = "NOMINAL" if anomaly_level < 0.05 else ("ELEVATED" if anomaly_level < 0.10 else "CRITICAL")
    city_news = [
        "Metro Line 7 Delayed - Signal Interference",
        "DATAWHALE Corp: New Hiring Cycle Open",
        "Harbor District: Cargo Inspection Backlog",
        "Block 09: Network Maintenance Scheduled",
        "Anomaly Research Lab: Routine Scan Complete",
    ]
    selected_news = random.sample(city_news, min(3, len(city_news)))
    weather_map = {0: "Sunny", 1: "Cloudy", 2: "Light Rain", 3: "Thunderstorm", 4: "Fog"}
    time_periods = ["day", "dusk", "night", "rain_night"]
    return {
        "anomaly_level": anomaly_level,
        "anomaly_status": anomaly_status,
        "city_news": selected_news,
        "weather": weather_map.get(random.randint(0, 4), "Unknown"),
        "time_period": random.choice(time_periods),
    }

@app.get("/npc/relationship_map")
def npc_relationship_map(player_name: str = ""):
    relationships = []
    seen = set()
    for npc_id, config in NPC_CONFIGS.items():
        social_links = config.get("social_links", {})
        for linked_id, rel_type in social_links.items():
            pair = tuple(sorted([npc_id, linked_id]))
            if pair not in seen:
                seen.add(pair)
                strength = round(0.5 + hash(rel_type) % 50 / 100.0, 2)
                relationships.append({
                    "from": npc_id,
                    "to": linked_id,
                    "type": rel_type,
                    "strength": strength,
                })
    return {"relationships": relationships, "total": len(relationships)}

@app.on_event("startup")
async def startup_event():
    if not settings.enable_batch_dialogue_refresh:
        logger.info("Background dialogue refresh disabled")
        return

    import asyncio
    refresh_seconds = max(1, settings.batch_dialogue_refresh_seconds)

    async def refresh_batch_dialogues():
        global _batch_cache
        while True:
            try:
                _batch_cache = batch_generator.generate_batch_dialogues()
                logger.info(f"Background dialogues updated for {len(_batch_cache)} NPCs")
            except Exception as e:
                logger.error(f"Background dialogue update failed: {e}")
            await asyncio.sleep(refresh_seconds)

    asyncio.create_task(refresh_batch_dialogues())

if __name__ == "__main__":
    import uvicorn
    logger.info(f"Starting Cyber Town server on {settings.host}:{settings.port}")
    uvicorn.run(app, host=settings.host, port=settings.port)
