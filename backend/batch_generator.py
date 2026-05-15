import json
from typing import Dict, Optional
from hello_agents_llm import HelloAgentsLLM
from config import NPC_CONFIGS
from logger import logger

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

            dialogues = self._parse_response(response)
            logger.info(f"Batch dialogue generated for {len(dialogues)} NPCs")
            return dialogues
        except Exception as e:
            logger.error(f"Batch dialogue generation failed: {e}")
            return self._get_fallback_dialogues()

    def _build_batch_prompt(self, context: str) -> str:
        npc_descriptions = []
        for npc_id, cfg in NPC_CONFIGS.items():
            desc = f"- {cfg['name']}({cfg['role']}): 性格{cfg['personality']}"
            npc_descriptions.append(desc)

        npc_desc_text = "\n".join(npc_descriptions)

        prompt = f"""请为Datawhale办公室的3个NPC生成当前的对话或行为描述。

【场景】{context}

【NPC信息】
{npc_desc_text}

【生成要求】
1. 每个NPC生成1句话(20-40字)
2. 内容要符合角色设定和场景氛围
3. 可以是自言自语、工作状态描述、或简单的思考
4. 要自然真实，像真实的办公室同事
5. 必须严格按照JSON格式返回

【输出格式】(严格遵守)
{{"张三": "...", "李四": "...", "王五": "..."}}

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
            return dialogues
        except json.JSONDecodeError:
            for start in range(len(response)):
                if response[start] == '{':
                    for end in range(len(response) - 1, start, -1):
                        if response[end] == '}':
                            try:
                                return json.loads(response[start:end + 1])
                            except json.JSONDecodeError:
                                continue
                    break
            logger.warning("Failed to parse batch dialogue JSON, using fallback")
            return self._get_fallback_dialogues()

    def _get_fallback_dialogues(self) -> Dict[str, str]:
        import random
        zhang_dialogues = [
            "这段代码需要重构一下...",
            "Python 3.12的新特性真不错！",
            "这个bug有点棘手，让我再看看...",
            "单元测试覆盖率还不够...",
        ]
        li_dialogues = [
            "用户反馈需要整理一下...",
            "这个功能的优先级需要重新评估...",
            "产品路线图需要更新了...",
            "下周的会议议程准备好了吗？",
        ]
        wang_dialogues = [
            "这个配色方案需要调整...",
            "新的设计稿快完成了...",
            "用户体验还有优化空间...",
            "这个图标需要重新设计...",
        ]
        return {
            "张三": random.choice(zhang_dialogues),
            "李四": random.choice(li_dialogues),
            "王五": random.choice(wang_dialogues),
        }

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
        import random
        pairs = [
            ("zhang_san", "li_si", "张三", "李四"),
            ("zhang_san", "wang_wu", "张三", "王五"),
            ("li_si", "wang_wu", "李四", "王五"),
        ]
        pair = random.choice(pairs)
        npc1_cfg = NPC_CONFIGS.get(pair[0], {})
        npc2_cfg = NPC_CONFIGS.get(pair[1], {})

        context = self._get_current_context()
        prompt = f"""请为Datawhale办公室的两个NPC生成一段简短的互动对话。

【场景】{context}

【NPC信息】
- {pair[2]}({npc1_cfg.get('role', '')}): 性格{npc1_cfg.get('personality', '')}
- {pair[3]}({npc2_cfg.get('role', '')}): 性格{npc2_cfg.get('personality', '')}

【生成要求】
1. 每人1-2句话，简短自然
2. 内容符合角色设定和场景
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
                "npc1_name": pair[2],
                "npc1_dialogue": result.get("npc1", f"{pair[2]}：最近怎么样？"),
                "npc2_id": pair[1],
                "npc2_name": pair[3],
                "npc2_dialogue": result.get("npc2", f"{pair[3]}：还不错，你呢？"),
            }]
        except Exception as e:
            logger.error(f"NPC interaction generation failed: {e}")
            fallback_pairs = [
                (pair[2], f"{pair[2]}：这个需求你觉得怎么样？", pair[3], f"{pair[3]}：我觉得可以再优化一下。"),
                (pair[2], f"{pair[2]}：中午一起吃饭吗？", pair[3], f"{pair[3]}：好啊，去楼下那家？"),
                (pair[2], f"{pair[2]}：最近忙什么呢？", pair[3], f"{pair[3]}：在赶一个项目，你呢？"),
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

batch_generator = NPCBatchGenerator()
