import ast
import json
import sys
import types
import unittest
from pathlib import Path


BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))


class NoopLogger:
    def info(self, *args, **kwargs):
        pass

    def warning(self, *args, **kwargs):
        pass

    def error(self, *args, **kwargs):
        pass


class FakeHelloAgentsLLM:
    def invoke(self, messages, quality="fast"):
        raise RuntimeError("FakeHelloAgentsLLM should be replaced in tests")


class FakeAffinityLevel:
    STRANGER = "陌生"
    FAMILIAR = "熟悉"
    FRIENDLY = "友好"
    INTIMATE = "亲密"
    CLOSE_FRIEND = "挚友"


class FakeRelationshipManager:
    def get_relationship(self, npc_id, player_name):
        return {"level": FakeAffinityLevel.STRANGER, "score": 0}

    def update_affinity(self, npc_id, player_name, score_delta):
        pass


class FakeStateManager:
    def set_busy(self, npc_id, is_busy, current_action=""):
        pass


class FakeDbManager:
    def load_memories(self, npc_id, limit=20):
        return []

    def save_memory(self, npc_id, role, content):
        pass


def load_npc_configs_from_source():
    source = (BACKEND_DIR / "config.py").read_text(encoding="utf-8")
    tree = ast.parse(source)
    for node in tree.body:
        if not isinstance(node, ast.Assign):
            continue
        for target in node.targets:
            if isinstance(target, ast.Name) and target.id == "NPC_CONFIGS":
                return ast.literal_eval(node.value)
    raise AssertionError("NPC_CONFIGS not found in backend/config.py")


def install_fake_runtime_modules():
    config_module = types.ModuleType("config")
    config_module.NPC_CONFIGS = load_npc_configs_from_source()
    config_module.settings = types.SimpleNamespace()
    sys.modules["config"] = config_module

    logger_module = types.ModuleType("logger")
    logger_module.logger = NoopLogger()
    sys.modules["logger"] = logger_module

    llm_module = types.ModuleType("hello_agents_llm")
    llm_module.HelloAgentsLLM = FakeHelloAgentsLLM
    sys.modules["hello_agents_llm"] = llm_module

    relationship_module = types.ModuleType("relationship_manager")
    relationship_module.relationship_manager = FakeRelationshipManager()
    relationship_module.AffinityLevel = FakeAffinityLevel
    sys.modules["relationship_manager"] = relationship_module

    state_module = types.ModuleType("state_manager")
    state_module.state_manager = FakeStateManager()
    sys.modules["state_manager"] = state_module

    db_module = types.ModuleType("db_manager")
    db_module.db_manager = FakeDbManager()
    sys.modules["db_manager"] = db_module

    vector_module = types.ModuleType("vector_store")
    vector_module.add_memory = lambda *args, **kwargs: None
    vector_module.search_memories = lambda *args, **kwargs: []
    sys.modules["vector_store"] = vector_module


install_fake_runtime_modules()

from config import NPC_CONFIGS
from agents import SimpleAgent
from batch_generator import NPCBatchGenerator
from story_engine import StoryEngine


class RecordingLLM:
    def __init__(self, response):
        self.response = response
        self.calls = []

    def invoke(self, messages, quality="fast"):
        self.calls.append({"messages": messages, "quality": quality})
        return self.response


class NPCAIQualityTests(unittest.TestCase):
    def test_batch_dialogues_complete_all_npcs_without_real_llm(self):
        response = json.dumps({
            "张三": "张三在复盘异常日志。",
            "li_si": "李四把用户反馈标成裂缝相关。",
            "王五": "王五重新描摹界面里的陌生符号。",
        }, ensure_ascii=False)
        generator = NPCBatchGenerator()
        generator.llm = RecordingLLM(response)

        dialogues = generator.generate_batch_dialogues("雨夜巡检，街区和办公室都出现轻微信号干扰")

        expected_names = {cfg["name"] for cfg in NPC_CONFIGS.values()}
        self.assertEqual(set(dialogues.keys()), expected_names)
        self.assertEqual(len(dialogues), 8)
        self.assertEqual(dialogues["李四"], "李四把用户反馈标成裂缝相关。")

        prompt = generator.llm.calls[0]["messages"][1]["content"]
        self.assertIn("世界上下文", prompt)
        self.assertIn("所属scene", prompt)
        self.assertIn("routine", prompt)
        for npc_id, cfg in NPC_CONFIGS.items():
            self.assertIn(npc_id, prompt)
            self.assertIn(cfg["name"], prompt)
            self.assertIn(cfg["role"], prompt)

    def test_interaction_pairs_are_not_limited_to_first_three_npcs(self):
        generator = NPCBatchGenerator()
        covered_npcs = {
            npc_id
            for pair in generator._build_interaction_pairs()
            for npc_id in pair
        }
        self.assertEqual(covered_npcs, set(NPC_CONFIGS.keys()))

    def test_agent_persona_prompt_covers_scene_routine_world_context_for_all_npcs(self):
        for npc_id, cfg in NPC_CONFIGS.items():
            agent = SimpleAgent.__new__(SimpleAgent)
            agent.npc_id = npc_id
            agent.config = cfg

            prompt = agent.get_system_prompt()

            self.assertIn("世界上下文", prompt)
            self.assertIn("所属scene", prompt)
            self.assertIn("routine", prompt)
            self.assertIn(cfg["name"], prompt)
            self.assertIn(cfg["role"], prompt)
            self.assertIn(cfg.get("backstory", ""), prompt)

    def test_story_aliases_normalize_to_canonical_chapter_ids(self):
        engine = StoryEngine()
        aliases = {
            "ch1": "ch1",
            "ch1_arrival": "ch1",
            "story_ch1_meet_team": "ch1",
            "ch2_dark_data": "ch2",
            "ch3_rift_appears": "ch3",
            "ch4_convergence": "ch4",
            "ch5_decision": "ch5",
        }

        for raw_id, expected_id in aliases.items():
            self.assertEqual(engine.normalize_chapter_id(raw_id), expected_id)

        engine.llm = RecordingLLM("mock story")
        result = engine.generate_chapter_content(
            "ch1_arrival",
            player_class="cipher",
            player_name="测试玩家",
            context={"completed_chapters": ["ch1_arrival"]},
        )

        self.assertEqual(result["chapter_id"], "ch1")
        self.assertEqual(result["requested_chapter_id"], "ch1_arrival")
        self.assertEqual(result["title"], "初来乍到")
        self.assertTrue(result["generated"])

        prompt = engine.llm.calls[0]["messages"][1]["content"]
        self.assertIn("已完成章节：ch1", prompt)
        self.assertIn("世界上下文", prompt)
        self.assertIn("NPC档案", prompt)

    def test_late_story_chapters_include_all_npcs_in_prompt(self):
        engine = StoryEngine()
        prompt = engine._build_chapter_prompt(
            engine.CHAPTER_TEMPLATES["ch4"],
            player_class="echo",
            player_name="测试玩家",
            anomaly_level=65.0,
            completed_chapters=["ch1", "ch2", "ch3"],
        )

        for cfg in NPC_CONFIGS.values():
            self.assertIn(cfg["name"], prompt)
            self.assertIn(cfg["role"], prompt)


if __name__ == "__main__":
    unittest.main()
