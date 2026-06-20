import os
from pathlib import Path
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

BACKEND_DIR = Path(__file__).resolve().parent

load_dotenv(BACKEND_DIR / ".env")

class Settings(BaseSettings):
    model_config = {"extra": "allow", "env_file": ".env"}

    deepseek_api_key: str = os.getenv("DEEPSEEK_API_KEY", "")
    deepseek_base_url: str = os.getenv("DEEPSEEK_BASE_URL", "https://api.deepseek.com")
    deepseek_model: str = os.getenv("DEEPSEEK_MODEL", "deepseek-chat")

    groq_api_key: str = os.getenv("GROQ_API_KEY", "")
    groq_base_url: str = os.getenv("GROQ_BASE_URL", "https://api.groq.com/openai/v1")
    groq_model: str = os.getenv("GROQ_MODEL", "llama-3.1-8b-instant")

    mimo_api_key: str = os.getenv("MIMO_API_KEY", "")
    mimo_base_url: str = os.getenv("MIMO_BASE_URL", "https://api.xiaomimimo.com/v1")
    mimo_flash_model: str = os.getenv("MIMO_FLASH_MODEL", "mimo-v2-flash")
    mimo_pro_model: str = os.getenv("MIMO_PRO_MODEL", "mimo-v2-pro")

    current_llm_provider: str = os.getenv("LLM_PROVIDER", "groq")

    host: str = os.getenv("HOST", "0.0.0.0")
    port: int = int(os.getenv("PORT", "8000"))
    enable_batch_dialogue_refresh: bool = False
    batch_dialogue_refresh_seconds: int = 300
    database_path: str = os.getenv("DATABASE_PATH", str(BACKEND_DIR / "data" / "cyber_town.db"))
    log_dir: str = os.getenv("LOG_DIR", str(BACKEND_DIR / "logs"))

settings = Settings()

NPC_CONFIGS = {
    "zhang_san": {
        "name": "张三",
        "role": "Python工程师",
        "personality": "严谨、专业、喜欢分享技术知识。说话直接,注重代码质量。",
        "scene": "office",
        "backstory": "DATAWHALE公司的核心开发者，负责维护城市数据基础设施。最近在代码中发现了奇怪的维度坐标。",
        "occupation": "Software Engineer",
        "trait": ["严谨", "专业"],
        "routine": {"day": "维护城市数据基础设施", "dusk": "代码审查与文档整理", "night": "加班分析维度坐标"},
        "social_links": {"he_zhen": "下属", "li_si": "同事"},
    },
    "li_si": {
        "name": "李四",
        "role": "产品经理",
        "personality": "外向、善于沟通、注重用户体验。喜欢从用户角度思考问题。",
        "scene": "office",
        "backstory": "DATAWHALE公司的产品负责人，最近发现用户数据中出现了无法解释的异常模式。",
        "occupation": "Product Manager",
        "trait": ["外向", "善于沟通"],
        "routine": {"day": "用户需求分析与产品规划", "dusk": "团队会议与进度跟踪", "night": "分析异常用户数据"},
        "social_links": {"zhang_san": "同事", "wang_wu": "搭档"},
    },
    "wang_wu": {
        "name": "王五",
        "role": "UI设计师",
        "personality": "温和、富有创意、审美独特。注重视觉呈现和用户体验。",
        "scene": "office",
        "backstory": "DATAWHALE公司的首席设计师，最近设计的界面中总是出现不属于这个维度的符号。",
        "occupation": "UI Designer",
        "trait": ["温和", "富有创意"],
        "routine": {"day": "界面设计与交互原型", "dusk": "设计评审与修改", "night": "研究异常符号图案"},
        "social_links": {"li_si": "搭档", "sun_yue": "邻居"},
    },
    "chen_xi": {
        "name": "陈曦",
        "role": "咖啡店老板",
        "personality": "神秘、博学、话中有话。总是用隐喻和哲学性的语言交流，似乎知道很多不为人知的事情。",
        "scene": "street",
        "backstory": "街角'量子咖啡'的老板，据说来自另一个维度。咖啡店是维度交汇的节点，她能感知裂缝的存在。",
        "occupation": "Cafe Owner",
        "trait": ["优雅", "略显疲惫"],
        "routine": {"day": "经营量子咖啡店", "dusk": "独自品茶冥想", "night": "关店后感知维度裂缝"},
        "social_links": {"sun_yue": "旧友", "zhao_lin": "信息交换"},
    },
    "zhao_lin": {
        "name": "赵霖",
        "role": "黑市信息贩子",
        "personality": "狡猾、精明、见钱眼开。说话总是暗示性的，喜欢交易和讨价还价。信息就是他的货币。",
        "scene": "street",
        "backstory": "活跃在街区暗巷的信息商人，声称自己的信息来源'跨越了边界'。贩卖的情报有时准确得令人不安。",
        "occupation": "Information Broker",
        "trait": ["警觉", "义肢"],
        "routine": {"day": "街头巡逻收集情报", "dusk": "暗巷交易与信息贩卖", "night": "整理情报数据库"},
        "social_links": {"chen_xi": "信息交换", "liu_feng": "义肢维护"},
    },
    "sun_yue": {
        "name": "孙悦",
        "role": "异常现象研究员",
        "personality": "理性、偏执、痴迷异常现象。说话充满学术术语和数据，对异常事件有着近乎病态的执着。",
        "scene": "office",
        "backstory": "DATAWHALE公司秘密研究部门的成员，专门研究维度裂缝和异常现象。她的研究笔记里记录着不为人知的发现。",
        "occupation": "Anomaly Researcher",
        "trait": ["神经质", "凝视虚空"],
        "routine": {"day": "实验室分析异常数据", "dusk": "走廊踱步思考", "night": "深夜异常监测值班"},
        "social_links": {"he_zhen": "同事", "chen_xi": "旧友"},
    },
    "liu_feng": {
        "name": "刘风",
        "role": "赛博义体技师",
        "personality": "粗犷、直爽、技术宅。说话口语化，喜欢用技术术语，对义体改造有着狂热的热情。",
        "scene": "street",
        "backstory": "街区修理铺的老板，最好的义体技师。他改造的义体中偶尔会出现'来自别处'的零件。",
        "occupation": "Cyborg Technician",
        "trait": ["豪爽", "满身油污"],
        "routine": {"day": "修理铺义体维修", "dusk": "街头闲聊与喝酒", "night": "调试自制义体原型"},
        "social_links": {"zhao_lin": "义肢维护", "chen_xi": "常客"},
    },
    "he_zhen": {
        "name": "何真",
        "role": "AI系统管理员",
        "personality": "冷静、逻辑性强、偶尔失控。说话通常是机械式的，但偶尔会流露出不属于程序的人性化情感。",
        "scene": "office",
        "backstory": "负责维护城市AI中枢'系统之声'的管理员。最近发现系统开始产生自主意识，偶尔说出不属于预设程序的话。",
        "occupation": "AI System Admin",
        "trait": ["冷漠", "数字化人格"],
        "routine": {"day": "城市AI中枢系统维护", "dusk": "数据巡检与安全扫描", "night": "深度休眠模式"},
        "social_links": {"sun_yue": "同事", "zhang_san": "上级"},
    },
}
