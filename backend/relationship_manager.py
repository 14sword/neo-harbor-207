from typing import Dict
from logger import logger
from db_manager import db_manager

class AffinityLevel:
    STRANGER = "陌生"
    FAMILIAR = "熟悉"
    FRIENDLY = "友好"
    INTIMATE = "亲密"
    CLOSE_FRIEND = "挚友"
    
    @staticmethod
    def level_to_num(level: str) -> int:
        level_map = {
            AffinityLevel.STRANGER: 1,
            AffinityLevel.FAMILIAR: 2,
            AffinityLevel.FRIENDLY: 3,
            AffinityLevel.INTIMATE: 4,
            AffinityLevel.CLOSE_FRIEND: 5,
        }
        return level_map.get(level, 1)

class RelationshipManager:
    """NPC 与玩家的好感度管理系统（带 SQLite 持久化）
    
    5 级好感度系统:
    - 陌生: 0-20
    - 熟悉: 21-40
    - 友好: 41-60
    - 亲密: 61-80
    - 挚友: 81-100
    """
    
    def __init__(self):
        self._relationships: Dict[str, dict] = {}
    
    def _get_key(self, npc_id: str, player_name: str) -> str:
        return f"{npc_id}:{player_name}"
    
    def get_relationship(self, npc_id: str, player_name: str) -> dict:
        key = self._get_key(npc_id, player_name)
        if key not in self._relationships:
            # 先从数据库加载
            db_rel = db_manager.load_relationship(npc_id, player_name)
            if db_rel:
                self._relationships[key] = db_rel
            else:
                self._relationships[key] = {
                    "npc_id": npc_id,
                    "player_name": player_name,
                    "score": 0,
                    "interaction_count": 0,
                    "level": self.score_to_level(0),
                }
        return self._relationships[key]
    
    @staticmethod
    def score_to_level(score: int) -> str:
        if score <= 20:
            return AffinityLevel.STRANGER
        elif score <= 40:
            return AffinityLevel.FAMILIAR
        elif score <= 60:
            return AffinityLevel.FRIENDLY
        elif score <= 80:
            return AffinityLevel.INTIMATE
        else:
            return AffinityLevel.CLOSE_FRIEND
    
    def update_affinity(self, npc_id: str, player_name: str, score_delta: int) -> dict:
        rel = self.get_relationship(npc_id, player_name)
        old_level = self.score_to_level(rel["score"])
        
        rel["score"] = max(0, min(100, rel["score"] + score_delta))
        rel["interaction_count"] += 1
        
        new_level = self.score_to_level(rel["score"])
        
        if old_level != new_level:
            logger.info(f"Affinity level changed for {npc_id} & {player_name}: {old_level} -> {new_level}")
        
        rel["level"] = new_level
        
        # 持久化到数据库
        db_manager.save_relationship(
            npc_id, player_name,
            rel["score"], rel["level"], rel["interaction_count"]
        )
        
        return rel

relationship_manager = RelationshipManager()
