from pydantic import BaseModel
from typing import Optional, Dict

class DialogueRequest(BaseModel):
    npc_id: str
    player_name: str = "玩家"
    player_message: str

class DialogueResponse(BaseModel):
    npc_reply: str
    affinity_level: int
    affinity_score: int

class NPCStatus(BaseModel):
    npc_id: str
    name: str
    role: str
    is_busy: bool
    current_action: str

class NPCStatusResponse(BaseModel):
    npcs: list[NPCStatus]

class AffinityInfo(BaseModel):
    npc_id: str
    player_name: str
    score: int
    level: str
    interaction_count: int

class DialogueHistoryItem(BaseModel):
    role: str
    content: str

class DialogueHistoryResponse(BaseModel):
    npc_id: str
    history: list[DialogueHistoryItem]
