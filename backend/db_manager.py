import sqlite3
import os
import json
from pathlib import Path
from logger import logger

DEFAULT_DB_PATH = str(Path(__file__).resolve().parent / "data" / "cyber_town.db")

try:
    from config import settings
except Exception:
    settings = None

class DatabaseManager:
    """SQLite 数据库管理器，负责记忆和好感度的持久化"""
    
    def __init__(self, db_path: str = ""):
        if not db_path:
            db_path = getattr(settings, "database_path", DEFAULT_DB_PATH) if settings else DEFAULT_DB_PATH
        if not os.path.isabs(db_path):
            db_path = str(Path(__file__).resolve().parent / db_path)
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self.db_path = db_path
        self._init_db()
    
    def _init_db(self):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS memories (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    npc_id TEXT NOT NULL,
                    role TEXT NOT NULL,
                    content TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            conn.execute("""
                CREATE TABLE IF NOT EXISTS relationships (
                    npc_id TEXT NOT NULL,
                    player_name TEXT NOT NULL,
                    score INTEGER DEFAULT 0,
                    level TEXT DEFAULT '陌生',
                    interaction_count INTEGER DEFAULT 0,
                    PRIMARY KEY (npc_id, player_name)
                )
            """)
            conn.commit()
            logger.info(f"Database initialized: {self.db_path}")
    
    # --- 记忆相关 ---
    
    def save_memory(self, npc_id: str, role: str, content: str):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute(
                "INSERT INTO memories (npc_id, role, content) VALUES (?, ?, ?)",
                (npc_id, role, content)
            )
            conn.commit()
    
    def load_memories(self, npc_id: str, limit: int = 20) -> list:
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "SELECT role, content FROM memories WHERE npc_id = ? ORDER BY id DESC LIMIT ?",
                (npc_id, limit)
            )
            rows = cursor.fetchall()
            return [{"role": row[0], "content": row[1]} for row in reversed(rows)]
    
    def clear_memories(self, npc_id: str):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("DELETE FROM memories WHERE npc_id = ?", (npc_id,))
            conn.commit()
    
    # --- 好感度相关 ---
    
    def save_relationship(self, npc_id: str, player_name: str, score: int, level: str, interaction_count: int):
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO relationships (npc_id, player_name, score, level, interaction_count)
                VALUES (?, ?, ?, ?, ?)
            """, (npc_id, player_name, score, level, interaction_count))
            conn.commit()
    
    def load_relationship(self, npc_id: str, player_name: str) -> dict:
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "SELECT score, level, interaction_count FROM relationships WHERE npc_id = ? AND player_name = ?",
                (npc_id, player_name)
            )
            row = cursor.fetchone()
            if row:
                return {
                    "npc_id": npc_id,
                    "player_name": player_name,
                    "score": row[0],
                    "level": row[1],
                    "interaction_count": row[2],
                }
            return None

db_manager = DatabaseManager()
