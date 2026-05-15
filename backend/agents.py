from typing import List, Dict, Optional
from config import NPC_CONFIGS, settings
from hello_agents_llm import HelloAgentsLLM
from relationship_manager import relationship_manager, AffinityLevel
from state_manager import state_manager
from db_manager import db_manager
from vector_store import add_memory, search_memories
from logger import logger

AFFINITY_PROMPTS = {
    AffinityLevel.STRANGER: "你对玩家还很陌生，态度比较客气但保持距离，不会主动分享太多信息。",
    AffinityLevel.FAMILIAR: "你对玩家有些熟悉了，态度比较友好，愿意分享一些日常话题。",
    AffinityLevel.FRIENDLY: "你和玩家已经是朋友了，态度热情开朗，愿意分享更多想法和故事。",
    AffinityLevel.INTIMATE: "你和玩家关系很亲密，会主动关心对方，分享内心想法和秘密。",
    AffinityLevel.CLOSE_FRIEND: "你和玩家是挚友，无话不谈，会毫无保留地分享一切，语气非常亲切自然。",
}

class SimpleAgent:
    """NPC Agent 基类，封装记忆管理和对话逻辑"""

    def __init__(self, npc_id: str, llm: HelloAgentsLLM):
        self.npc_id = npc_id
        self.config = NPC_CONFIGS[npc_id]
        self.llm = llm
        self.memory: List[Dict] = []
        self.max_memory_length = 20
        self.rag_top_k = 5
        self._load_memory_from_db()

    def _load_memory_from_db(self):
        self.memory = db_manager.load_memories(self.npc_id, self.max_memory_length)
        if self.memory:
            logger.info(f"Loaded {len(self.memory)} memories for NPC {self.npc_id}")

    def get_system_prompt(self, affinity_level: str = "陌生", relevant_memories: str = "") -> str:
        affinity_hint = AFFINITY_PROMPTS.get(affinity_level, AFFINITY_PROMPTS[AffinityLevel.STRANGER])
        memory_section = ""
        if relevant_memories:
            memory_section = f"\n\n【相关记忆】\n{relevant_memories}\n\n请根据以上相关记忆来回应玩家，如果记忆中的信息与当前对话相关，可以提及或引用。"
        return (
            f"你是{self.config['name']}，一名{self.config['role']}。\n"
            f"性格特点：{self.config['personality']}\n"
            f"当前与玩家的关系：{affinity_level}。{affinity_hint}{memory_section}\n"
            f"请用符合你角色身份、性格和当前关系状态的方式与玩家对话。"
        )

    def _get_relevant_memories(self, query: str) -> str:
        """使用ChromaDB语义搜索获取相关记忆"""
        try:
            results = search_memories(self.npc_id, query, self.rag_top_k)
            if not results:
                return ""
            memory_lines = []
            for i, result in enumerate(results, 1):
                role = result["metadata"].get("role", "unknown")
                memory_lines.append(f"{i}. [{role}] {result['text']}")
            return "\n".join(memory_lines)
        except Exception as e:
            logger.warning(f"Failed to search memories: {e}")
            return ""

    def add_to_memory(self, role: str, content: str):
        self.memory.append({"role": role, "content": content})
        if len(self.memory) > self.max_memory_length:
            self.memory = self.memory[-self.max_memory_length:]
        db_manager.save_memory(self.npc_id, role, content)
        try:
            add_memory(self.npc_id, content, {"role": role})
        except Exception as e:
            logger.warning(f"Failed to add memory to vector store: {e}")

    def chat(self, player_name: str, player_message: str) -> str:
        rel = relationship_manager.get_relationship(self.npc_id, player_name)
        affinity_level = rel["level"]
        affinity_score = rel["score"]

        state_manager.set_busy(self.npc_id, True, f"与 {player_name} 对话中")

        try:
            relevant_memories = self._get_relevant_memories(player_message)

            messages = [{"role": "system", "content": self.get_system_prompt(affinity_level, relevant_memories)}]
            messages.extend(self.memory)
            messages.append({"role": "user", "content": player_message})

            reply = self.llm.invoke(messages)

            self.add_to_memory("user", player_message)
            self.add_to_memory("assistant", reply)

            score_delta = 1 + (affinity_score // 20)
            relationship_manager.update_affinity(self.npc_id, player_name, score_delta)

            logger.info(f"NPC {self.npc_id} replied to {player_name} (affinity: {affinity_level}, score: {affinity_score})")
            return reply
        finally:
            state_manager.set_busy(self.npc_id, False)

class AgentManager:
    """管理所有 NPC Agent 的实例"""

    def __init__(self):
        self.llm = HelloAgentsLLM()
        self.agents: Dict[str, SimpleAgent] = {}
        self._initialize_agents()

    def _initialize_agents(self):
        for npc_id in NPC_CONFIGS:
            self.agents[npc_id] = SimpleAgent(npc_id, self.llm)
            logger.info(f"Initialized agent for NPC: {npc_id}")

    def get_agent(self, npc_id: str) -> Optional[SimpleAgent]:
        return self.agents.get(npc_id)

agent_manager = AgentManager()
