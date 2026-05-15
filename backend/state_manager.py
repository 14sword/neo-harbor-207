from typing import Dict
import time
import random
from config import NPC_CONFIGS
from logger import logger

NPC_ACTIVITIES = {
    "zhang_san": [
        "正在写Python代码", "正在调试程序", "正在review代码",
        "正在喝咖啡休息", "正在看技术文档", "正在修复bug",
        "正在写单元测试", "正在和同事讨论技术方案", "正在学习新技术",
        "正在整理代码仓库", "正在写技术博客", "正在优化算法"
    ],
    "li_si": [
        "正在写产品需求文档", "正在画原型图", "正在和开发沟通需求",
        "正在分析用户数据", "正在准备产品评审", "正在喝咖啡休息",
        "正在写竞品分析报告", "正在整理用户反馈", "正在规划下个迭代",
        "正在开产品会议", "正在设计用户流程", "正在测试新功能"
    ],
    "wang_wu": [
        "正在设计UI界面", "正在调整配色方案", "正在画图标",
        "正在做设计评审", "正在喝咖啡休息", "正在找设计灵感",
        "正在制作交互动效", "正在优化界面布局", "正在整理设计规范",
        "正在切图标注", "正在做A/B测试对比", "正在画插画"
    ]
}

class StateManager:
    """NPC 状态追踪管理器，支持自主行为生成"""
    
    def __init__(self):
        self._npc_states: Dict[str, dict] = {}
        self._activity_timers: Dict[str, float] = {}
        self._activity_interval: float = 30.0
        self._initialize_states()
    
    def _initialize_states(self):
        for npc_id, config in NPC_CONFIGS.items():
            activity = random.choice(NPC_ACTIVITIES.get(npc_id, ["空闲"]))
            self._npc_states[npc_id] = {
                "npc_id": npc_id,
                "name": config["name"],
                "role": config["role"],
                "is_busy": False,
                "current_action": activity,
                "last_interaction_time": 0,
            }
            self._activity_timers[npc_id] = time.time() + random.uniform(3, 6)
        logger.info(f"Initialized states for {len(NPC_CONFIGS)} NPCs")
    
    def _update_activities(self):
        now = time.time()
        for npc_id in self._npc_states:
            if self._npc_states[npc_id]["is_busy"]:
                continue
            if npc_id in self._activity_timers and now >= self._activity_timers[npc_id]:
                activities = NPC_ACTIVITIES.get(npc_id, ["空闲"])
                new_activity = random.choice(activities)
                self._npc_states[npc_id]["current_action"] = new_activity
                self._activity_timers[npc_id] = now + random.uniform(6, 10)
                logger.debug(f"NPC {npc_id} new activity: {new_activity}")
    
    def get_npc_state(self, npc_id: str) -> dict:
        self._update_activities()
        if npc_id not in self._npc_states:
            return None
        return self._npc_states[npc_id].copy()
    
    def set_busy(self, npc_id: str, busy: bool = True, action: str = "对话中"):
        if npc_id in self._npc_states:
            self._npc_states[npc_id]["is_busy"] = busy
            self._npc_states[npc_id]["current_action"] = action if busy else random.choice(NPC_ACTIVITIES.get(npc_id, ["空闲"]))
            if not busy:
                self._activity_timers[npc_id] = time.time() + random.uniform(20, 60)
            logger.debug(f"NPC {npc_id} state: busy={busy}, action={self._npc_states[npc_id]['current_action']}")
    
    def get_all_states(self) -> list:
        self._update_activities()
        return [state.copy() for state in self._npc_states.values()]

state_manager = StateManager()
