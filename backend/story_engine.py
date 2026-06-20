import re
from typing import Dict, List, Optional
from hello_agents_llm import HelloAgentsLLM
from config import NPC_CONFIGS
from logger import logger


WORLD_CONTEXT = (
    "新港·207是被维度裂缝影响的赛博朋克小镇。DATAWHALE维护城市数据基础设施，"
    "城市AI中枢'系统之声'开始产生自主意识，办公室与街区的日常生活正被异常现象悄悄改写。"
)

SCENE_LABELS = {
    "office": "DATAWHALE办公室",
    "street": "新港街区",
}

PERIOD_LABELS = {
    "day": "白天",
    "dusk": "黄昏",
    "night": "夜晚",
}


class StoryEngine:
    """AI驱动的剧情生成引擎"""

    CHAPTER_TEMPLATES = {
        "ch1": {
            "title": "初来乍到",
            "theme": "新来者适应小镇生活，发现异常迹象",
            "key_events": ["入职", "认识同事", "探索街区", "发现异常"],
            "npcs": ["zhang_san", "li_si", "wang_wu", "chen_xi"],
        },
        "ch2": {
            "title": "数据暗流",
            "theme": "公司内部异常数据，AI系统失控",
            "key_events": ["异常数据", "AI失控", "陈曦的暗示", "系统故障"],
            "npcs": ["he_zhen", "zhang_san", "chen_xi"],
        },
        "ch3": {
            "title": "裂缝显现",
            "theme": "维度裂缝出现，异常现象加剧",
            "key_events": ["裂缝出现", "孙悦的研究", "维度旅人", "异常战斗"],
            "npcs": ["sun_yue", "zhao_lin"],
        },
        "ch4": {
            "title": "诸天交汇",
            "theme": "多维度交汇，城市危机",
            "key_events": ["维度交汇", "全NPC卷入", "城市异变", "最终抉择前奏"],
            "npcs": list(NPC_CONFIGS.keys()),
        },
        "ch5": {
            "title": "抉择时刻",
            "theme": "最终选择，决定小镇命运",
            "key_events": ["真相揭示", "最终选择", "多结局"],
            "npcs": list(NPC_CONFIGS.keys()),
        },
    }

    CHAPTER_ALIASES = {
        "ch1_arrival": "ch1",
        "arrival": "ch1",
        "ch2_dark_data": "ch2",
        "dark_data": "ch2",
        "ch3_rift_appears": "ch3",
        "rift_appears": "ch3",
        "ch4_convergence": "ch4",
        "convergence": "ch4",
        "ch5_decision": "ch5",
        "decision": "ch5",
    }

    def __init__(self):
        self.llm = HelloAgentsLLM()

    def generate_chapter_content(self, chapter_id: str, player_class: str = "cipher",
                                  player_name: str = "玩家", context: Dict = None) -> Dict:
        requested_chapter_id = chapter_id
        canonical_chapter_id = self.normalize_chapter_id(chapter_id)
        template = self.CHAPTER_TEMPLATES.get(canonical_chapter_id)
        if not template:
            return {"error": f"Chapter {chapter_id} not found", "chapter_id": chapter_id}

        context = context or {}
        anomaly_level = context.get("anomaly_level", 0)
        completed_chapters = [
            self.normalize_chapter_id(chapter) or str(chapter)
            for chapter in context.get("completed_chapters", [])
        ]

        messages = [
            {"role": "system", "content": self._get_story_system_prompt()},
            {"role": "user", "content": self._build_chapter_prompt(
                template, player_class, player_name, anomaly_level, completed_chapters
            )}
        ]

        try:
            content = self.llm.invoke(messages, quality="high")
            return {
                "chapter_id": canonical_chapter_id,
                "requested_chapter_id": requested_chapter_id,
                "title": template["title"],
                "content": content,
                "generated": True,
            }
        except Exception as e:
            logger.error(f"Story generation failed for {requested_chapter_id}: {e}")
            return {
                "chapter_id": canonical_chapter_id,
                "requested_chapter_id": requested_chapter_id,
                "title": template["title"],
                "content": self._get_fallback_content(canonical_chapter_id),
                "generated": False,
            }

    def generate_npc_backstory(self, npc_id: str) -> Dict:
        npc_config = NPC_CONFIGS.get(npc_id)
        if not npc_config:
            return {"error": f"NPC {npc_id} not found"}

        messages = [
            {"role": "system", "content": (
                "你是一位赛博朋克世界观设定师。请为以下NPC生成详细的背景故事，"
                "包括：过去经历、来到新港·207的原因、隐藏的秘密、与维度裂缝的关联。"
                f"故事风格：赛博朋克+神秘+悬疑。世界上下文：{WORLD_CONTEXT}。字数300-500字。"
            )},
            {"role": "user", "content": (
                f"NPC名称：{npc_config['name']}\n"
                f"职业：{npc_config['role']}\n"
                f"所属scene：{self._format_scene(npc_config.get('scene', 'office'))}\n"
                f"性格：{npc_config['personality']}\n"
                f"routine：{self._format_routine(npc_config.get('routine', {}))}\n"
                f"社交关系：{self._format_social_links(npc_config.get('social_links', {}))}\n"
                f"已有背景：{npc_config.get('backstory', '无')}\n"
                f"请生成详细背景故事。"
            )}
        ]

        try:
            backstory = self.llm.invoke(messages, quality="high")
            return {"npc_id": npc_id, "backstory": backstory, "generated": True}
        except Exception as e:
            logger.error(f"NPC backstory generation failed for {npc_id}: {e}")
            return {"npc_id": npc_id, "backstory": npc_config.get("backstory", ""), "generated": False}

    def generate_dialogue_branch(self, npc_id: str, player_class: str,
                                  current_topic: str, affinity_level: int = 1) -> List[Dict]:
        npc_config = NPC_CONFIGS.get(npc_id)
        if not npc_config:
            return []

        messages = [
            {"role": "system", "content": (
                "你是一位游戏对话设计师。请为以下NPC生成3个对话分支选项，"
                "每个选项包含：选项文本、NPC可能的回应方向、好感度影响。"
                f"格式为JSON数组。世界上下文：{WORLD_CONTEXT}"
            )},
            {"role": "user", "content": (
                f"NPC：{npc_config['name']}（{npc_config['role']}）\n"
                f"所属scene：{self._format_scene(npc_config.get('scene', 'office'))}\n"
                f"性格：{npc_config['personality']}\n"
                f"routine：{self._format_routine(npc_config.get('routine', {}))}\n"
                f"玩家职业：{player_class}\n"
                f"当前话题：{current_topic}\n"
                f"好感度等级：{affinity_level}/5\n"
                f"请生成3个对话分支。"
            )}
        ]

        try:
            result = self.llm.invoke(messages, quality="batch")
            return [{"npc_id": npc_id, "branches": result, "generated": True}]
        except Exception as e:
            logger.error(f"Dialogue branch generation failed: {e}")
            return []

    def generate_daily_event(self, calendar_day: int, weather: str,
                              anomaly_level: float, month: str) -> Dict:
        messages = [
            {"role": "system", "content": (
                "你是新港·207的世界事件生成器。根据当前日期、天气和异常等级，"
                "生成2-3条城市事件。事件应与赛博朋克世界观和维度裂缝主题相关。"
                "格式：每条事件一行，包含标题和简短描述。"
            )},
            {"role": "user", "content": (
                f"历法日期：N.H.207 {month}月{calendar_day}日\n"
                f"天气：{weather}\n"
                f"异常等级：{anomaly_level:.1f}/100\n"
                f"请生成今日城市事件。"
            )}
        ]

        try:
            events = self.llm.invoke(messages, quality="batch")
            return {"day": calendar_day, "month": month, "events": events, "generated": True}
        except Exception as e:
            logger.error(f"Daily event generation failed: {e}")
            return {"day": calendar_day, "month": month, "events": "日常平静", "generated": False}

    def _get_story_system_prompt(self) -> str:
        return (
            "你是'新港·207'游戏的主线剧情编剧。世界观设定：\n"
            f"- {WORLD_CONTEXT}\n"
            "- 时代：N.H.207年，新港市（Neo Harbor）\n"
            "- 核心设定：维度裂缝正在侵蚀现实，赛博朋克与异次元交汇\n"
            "- 公司DATAWHALE是城市数据基础设施的运营者\n"
            "- 异常等级从0到100，越高维度裂缝越明显\n"
            "- 城市AI中枢'系统之声'开始产生自主意识\n\n"
            "请生成引人入胜的剧情内容，包含：\n"
            "1. 场景描写（赛博朋克风格）\n"
            "2. NPC对话\n"
            "3. 玩家选择点（2-3个选项）\n"
            "4. 异常现象描写\n"
            "5. 悬念和伏笔"
        )

    def _build_chapter_prompt(self, template: Dict, player_class: str,
                               player_name: str, anomaly_level: float,
                               completed_chapters: List[str]) -> str:
        class_names = {"cipher": "数据分析师", "chrome": "义体战士",
                       "echo": "灵能感知者", "shadow": "暗影潜行者"}
        npc_ids = template.get("npcs") or list(NPC_CONFIGS.keys())
        npc_names = [
            NPC_CONFIGS.get(npc_id, {}).get("name", npc_id)
            for npc_id in npc_ids
        ]
        return (
            f"章节：{template['title']}\n"
            f"主题：{template['theme']}\n"
            f"关键事件：{', '.join(template['key_events'])}\n"
            f"世界上下文：{WORLD_CONTEXT}\n"
            f"相关NPC：{', '.join(npc_names)}\n"
            f"NPC档案：\n{self._format_npc_roster(npc_ids)}\n"
            f"玩家：{player_name}（{class_names.get(player_class, player_class)}）\n"
            f"当前异常等级：{anomaly_level:.1f}/100\n"
            f"已完成章节：{', '.join(completed_chapters) if completed_chapters else '无'}\n\n"
            f"请生成这一章节的剧情内容。"
        )

    def _get_fallback_content(self, chapter_id: str) -> str:
        chapter_id = self.normalize_chapter_id(chapter_id)
        fallback = {
            "ch1": "你抵达了新港·207，霓虹灯在雨中闪烁。DATAWHALE公司的办公室等待着你，新的生活即将开始...",
            "ch2": "数据流中出现了不该存在的模式。何真盯着屏幕上AI系统的异常输出，眉头紧锁...",
            "ch3": "天空裂开了一道缝隙，紫色的光芒从中溢出。孙悦的研究笔记上写满了关于维度裂缝的记录...",
            "ch4": "多个维度的边界开始模糊，不同世界的碎片在城市中交织。所有人都感受到了那股力量...",
            "ch5": "最终的选择摆在你面前。维度裂缝可以被封闭，也可以被彻底打开。你的决定将改变一切...",
        }
        return fallback.get(chapter_id, "故事继续...")

    def normalize_chapter_id(self, chapter_id: Optional[str]) -> Optional[str]:
        if not chapter_id:
            return chapter_id

        normalized = str(chapter_id).strip().lower().replace("-", "_")
        if normalized in self.CHAPTER_TEMPLATES:
            return normalized
        if normalized in self.CHAPTER_ALIASES:
            return self.CHAPTER_ALIASES[normalized]

        match = re.search(r"(?:^|_)ch([1-5])(?:_|$)", normalized)
        if match:
            candidate = f"ch{match.group(1)}"
            if candidate in self.CHAPTER_TEMPLATES:
                return candidate

        match = re.search(r"chapter_?([1-5])", normalized)
        if match:
            candidate = f"ch{match.group(1)}"
            if candidate in self.CHAPTER_TEMPLATES:
                return candidate

        return normalized

    def _format_scene(self, scene: str) -> str:
        return SCENE_LABELS.get(scene, scene or "未知场景")

    def _format_routine(self, routine: Dict[str, str]) -> str:
        if not routine:
            return "暂无固定日程"
        return "；".join(
            f"{PERIOD_LABELS.get(period, period)}：{activity}"
            for period, activity in routine.items()
        )

    def _format_social_links(self, social_links: Dict[str, str]) -> str:
        if not social_links:
            return "暂无明确社交关系"
        links = []
        for linked_id, relation in social_links.items():
            linked_name = NPC_CONFIGS.get(linked_id, {}).get("name", linked_id)
            links.append(f"{linked_name}：{relation}")
        return "；".join(links)

    def _format_npc_roster(self, npc_ids: List[str]) -> str:
        lines = []
        for npc_id in npc_ids:
            cfg = NPC_CONFIGS.get(npc_id)
            if not cfg:
                continue
            lines.append(
                f"- {cfg['name']}（id: {npc_id}，{cfg['role']}）："
                f"scene={self._format_scene(cfg.get('scene', 'office'))}；"
                f"性格={cfg['personality']}；"
                f"routine={self._format_routine(cfg.get('routine', {}))}；"
                f"背景={cfg.get('backstory', '无')}"
            )
        return "\n".join(lines) or "无"


story_engine = StoryEngine()
