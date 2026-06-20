import json
import random
from typing import Dict, List, Optional, Tuple
from hello_agents_llm import HelloAgentsLLM
from config import NPC_CONFIGS
from logger import logger


WORLD_CONTEXT = (
    "新港·207是被维度裂缝影响的赛博朋克小镇。DATAWHALE维护城市数据基础设施，"
    "办公室、街区、量子咖啡店和黑市暗巷都可能出现异常信号。NPC的台词应带有日常工作/生活质感，"
    "同时保留轻微的裂缝、AI失序或跨维度线索。"
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


class NPCBatchGenerator:
    def __init__(self):
        self.llm = HelloAgentsLLM()

    def generate_batch_dialogues(self, context: Optional[str] = None) -> Dict[str, str]:
        if context is None:
            context = self._get_current_context()

        prompt = self._build_batch_prompt(context)

        try:
            response = self.llm.invoke([
                {"role": "system", "content": "你是一个游戏NPC对话生成器，擅长创作自然真实的办公室对话。必须严格按照JSON格式返回。"},
                {"role": "user", "content": prompt}
            ])

            dialogues = self._complete_dialogues(self._parse_response(response))
            logger.info(f"Batch dialogue generated for {len(dialogues)} NPCs")
            return dialogues
        except Exception as e:
            logger.error(f"Batch dialogue generation failed: {e}")
            return self._get_fallback_dialogues()

    def _build_batch_prompt(self, context: str) -> str:
        npc_descriptions = []
        for npc_id, cfg in NPC_CONFIGS.items():
            desc = (
                f"- {cfg['name']}（id: {npc_id}，{cfg['role']}）："
                f"性格{cfg['personality']}；"
                f"所属场景：{self._format_scene(cfg.get('scene', 'office'))}；"
                f"日程：{self._format_routine(cfg.get('routine', {}))}；"
                f"背景线索：{cfg.get('backstory', '无')}"
            )
            npc_descriptions.append(desc)

        npc_desc_text = "\n".join(npc_descriptions)
        output_format = json.dumps(
            {cfg["name"]: "..." for cfg in NPC_CONFIGS.values()},
            ensure_ascii=False
        )

        prompt = f"""请为Datawhale办公室和新港街区的{len(NPC_CONFIGS)}个NPC生成当前的对话或行为描述。

【世界上下文】
{WORLD_CONTEXT}

【当前场景】
{context}

【NPC信息】
{npc_desc_text}

【生成要求】
1. 必须覆盖全部{len(NPC_CONFIGS)}个NPC，每个NPC生成1句话(20-40字)
2. 内容要符合角色设定、所属scene、routine和当前场景氛围
3. 可以是自言自语、工作状态描述、或简单的思考
4. 要自然真实，像真实的同事、街坊或信息交换者
5. 必须严格按照JSON格式返回
6. JSON键必须使用NPC中文名，不要遗漏、合并或替换NPC

【输出格式】(严格遵守)
{output_format}

请生成(只返回JSON，不要其他内容):"""
        return prompt

    def _parse_response(self, response: str) -> Dict[str, str]:
        response = response.strip()
        if response.startswith("```"):
            lines = response.split("\n")
            lines = [l for l in lines if not l.startswith("```")]
            response = "\n".join(lines)

        try:
            dialogues = json.loads(response)
            if isinstance(dialogues, dict):
                return {str(k): str(v) for k, v in dialogues.items()}
            logger.warning("Batch dialogue JSON was not an object, using fallback")
            return {}
        except json.JSONDecodeError:
            for start in range(len(response)):
                if response[start] == '{':
                    for end in range(len(response) - 1, start, -1):
                        if response[end] == '}':
                            try:
                                dialogues = json.loads(response[start:end + 1])
                                if isinstance(dialogues, dict):
                                    return {str(k): str(v) for k, v in dialogues.items()}
                                return {}
                            except json.JSONDecodeError:
                                continue
                    break
            logger.warning("Failed to parse batch dialogue JSON, using fallback")
            return {}

    def _complete_dialogues(self, dialogues: Dict[str, str]) -> Dict[str, str]:
        fallback = self._get_fallback_dialogues()
        completed = {}
        for npc_id, cfg in NPC_CONFIGS.items():
            name = cfg["name"]
            value = dialogues.get(name) or dialogues.get(npc_id)
            if not value or not str(value).strip():
                value = fallback[name]
            completed[name] = str(value).strip()
        return completed

    def _get_fallback_dialogues(self) -> Dict[str, str]:
        return {
            cfg["name"]: self._fallback_dialogue_for(npc_id, cfg)
            for npc_id, cfg in NPC_CONFIGS.items()
        }

    def _fallback_dialogue_for(self, npc_id: str, cfg: Dict) -> str:
        scene = self._format_scene(cfg.get("scene", "office"))
        routine = self._current_routine(cfg)
        name = cfg["name"]
        role = cfg["role"]
        options = [
            f"{name}一边{routine}，一边留意{scene}里闪过的异常信号。",
            f"{name}低声整理着{role}的线索，觉得今天的数据边缘有些不稳。",
            f"{name}停下手头的{routine}，像是听见了维度裂缝里传来的回声。",
        ]
        if npc_id == "zhao_lin":
            options.append("赵霖把情报终端扣在掌心，笑着说今晚的消息要另算价。")
        elif npc_id == "chen_xi":
            options.append("陈曦擦拭咖啡杯，轻声说杯中倒影比街灯更接近真相。")
        elif npc_id == "liu_feng":
            options.append("刘风拧紧义体关节，嘟囔这枚零件像是从别的世界掉下来的。")
        elif npc_id == "he_zhen":
            options.append("何真盯着系统日志，机械语调里短暂浮出一丝困惑。")
        return random.choice(options)

    def _get_current_context(self) -> str:
        from datetime import datetime
        hour = datetime.now().hour
        if 6 <= hour < 12:
            return "上午工作时间，办公室里忙碌而有序"
        elif 12 <= hour < 14:
            return "午休时间，有人在吃饭有人在休息"
        elif 14 <= hour < 18:
            return "下午工作时间，大家都在专注工作"
        else:
            return "加班时间，办公室比较安静"

    def generate_npc_interactions(self) -> list:
        pairs = self._build_interaction_pairs()
        pair = random.choice(pairs)
        npc1_cfg = NPC_CONFIGS.get(pair[0], {})
        npc2_cfg = NPC_CONFIGS.get(pair[1], {})
        npc1_name = npc1_cfg.get("name", pair[0])
        npc2_name = npc2_cfg.get("name", pair[1])

        context = self._get_current_context()
        prompt = f"""请为Datawhale办公室的两个NPC生成一段简短的互动对话。

【世界上下文】
{WORLD_CONTEXT}

【当前场景】
{context}

【NPC信息】
- {self._format_interaction_npc(pair[0])}
- {self._format_interaction_npc(pair[1])}

【生成要求】
1. 每人1-2句话，简短自然
2. 内容符合角色设定、所属scene、routine和当前场景
3. 可以是工作讨论、闲聊、或互相打招呼
4. 必须严格按照JSON格式返回

【输出格式】
{{"npc1": "{{name}}: ...", "npc2": "{{name}}: ..."}}

请生成(只返回JSON):"""

        try:
            response = self.llm.invoke([
                {"role": "system", "content": "你是一个游戏NPC对话生成器。必须严格按照JSON格式返回。"},
                {"role": "user", "content": prompt}
            ])
            result = self._parse_response(response)
            return [{
                "npc1_id": pair[0],
                "npc1_name": npc1_name,
                "npc1_dialogue": result.get("npc1", f"{npc1_name}：最近怎么样？"),
                "npc2_id": pair[1],
                "npc2_name": npc2_name,
                "npc2_dialogue": result.get("npc2", f"{npc2_name}：还不错，你呢？"),
            }]
        except Exception as e:
            logger.error(f"NPC interaction generation failed: {e}")
            fallback_pairs = [
                (npc1_name, f"{npc1_name}：你那边有没有发现新的异常？", npc2_name, f"{npc2_name}：有一点，但还需要再确认。"),
                (npc1_name, f"{npc1_name}：今天的信号比昨天更乱。", npc2_name, f"{npc2_name}：先记录下来，别让系统漏掉。"),
                (npc1_name, f"{npc1_name}：忙完这段routine再聊？", npc2_name, f"{npc2_name}：好，我也正想交换线索。"),
            ]
            fb = random.choice(fallback_pairs)
            return [{
                "npc1_id": pair[0],
                "npc1_name": fb[0],
                "npc1_dialogue": fb[1],
                "npc2_id": pair[1],
                "npc2_name": fb[2],
                "npc2_dialogue": fb[3],
            }]

    def _format_scene(self, scene: str) -> str:
        return SCENE_LABELS.get(scene, scene or "未知场景")

    def _format_routine(self, routine: Dict[str, str]) -> str:
        if not routine:
            return "暂无固定日程"
        return "；".join(
            f"{PERIOD_LABELS.get(period, period)}：{activity}"
            for period, activity in routine.items()
        )

    def _current_time_period(self) -> str:
        from datetime import datetime
        hour = datetime.now().hour
        if 6 <= hour < 17:
            return "day"
        if 17 <= hour < 21:
            return "dusk"
        return "night"

    def _current_routine(self, cfg: Dict) -> str:
        routine = cfg.get("routine", {})
        if not routine:
            return "观察周围动静"
        return routine.get(self._current_time_period()) or next(iter(routine.values()))

    def _format_interaction_npc(self, npc_id: str) -> str:
        cfg = NPC_CONFIGS[npc_id]
        return (
            f"{cfg['name']}（id: {npc_id}，{cfg['role']}）："
            f"性格{cfg['personality']}；"
            f"所属场景：{self._format_scene(cfg.get('scene', 'office'))}；"
            f"日程：{self._format_routine(cfg.get('routine', {}))}"
        )

    def _build_interaction_pairs(self) -> List[Tuple[str, str]]:
        pairs = []
        seen = set()
        for npc_id, cfg in NPC_CONFIGS.items():
            for linked_id in cfg.get("social_links", {}):
                if linked_id not in NPC_CONFIGS:
                    continue
                key = tuple(sorted((npc_id, linked_id)))
                if key in seen:
                    continue
                seen.add(key)
                pairs.append((npc_id, linked_id))

        if pairs:
            return pairs

        npc_ids = list(NPC_CONFIGS.keys())
        return list(zip(npc_ids, npc_ids[1:])) or [(npc_ids[0], npc_ids[0])]

batch_generator = NPCBatchGenerator()
