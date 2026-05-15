# Neo Harbor 207

> 一个 2D 赛博朋克风格的 AI 驱动社会模拟 RPG —— 基于 Godot 4.6 构建，LLM 驱动的 NPC 对话，动态昼夜与世界系统

**Neo Harbor 207**（原名「新港·207」）是 [Hello-Agents](https://hello-agents.datawhale.cc/) 教程第十五章实战项目的延伸毕业设计。玩家以"城市身份接入终端"的方式登入 N.H.207 年的新港市，在公寓、办公室和街区之间自由探索，与 8 位 AI 驱动的 NPC 建立关系，体验动态昼夜、天气、世界历法和主线剧情。

---

## 📝 项目简介

### 解决了什么问题？

传统 RPG 中的 NPC 对话是预设的、重复的、没有记忆的。Neo Harbor 207 将大语言模型（LLM）接入游戏 NPC，使其具备：

- **上下文感知**：NPC 知道当前时间、天气、节日，回复内容随世界状态变化
- **长期记忆**：通过 ChromaDB 向量检索 + SQLite 对话历史，NPC 记得你之前说过什么
- **性格一致性**：8 个 NPC 各有独立的身份配置、性格描述和回复风格约束
- **三级 LLM 降级**：Groq（快速）→ MiMo-Flash（中速）→ DeepSeek（兜底），确保对话服务高可用

### 有什么特色？

- **城市接入终端**：不是传统"选角色开始游戏"，而是模拟接入一个正在运行的未来都市网络
- **4 职业 RPG 系统**：CIPHER 数据分析师 / CHROME 义体战士 / ECHO 灵能感知者 / SHADOW 暗影潜行者
- **42 技能变体**：每职业 3-4 条技能线 × 3 级
- **AI 剧情引擎**：5 章主线"维度裂缝"，根据异常等级和前置进度动态解锁
- **F5 双视觉风格**：写实赛博朋克 ↔ 二次元动漫，<0.1 秒无缝切换
- **20 个任务**：对话 / 探索 / 收集 / 日常 / 隐藏 / 剧情 六种类型

---

## ✨ 核心功能

### 🎮 游戏系统
- [x] **角色选择终端** — 三栏布局（身份档案 / 扫描区域 / 网络数据）+ 动态城市网络着色器背景 + CRT 扫描线 + 异常信号系统
- [x] **12 帧平滑待机动画** — 0.12 秒/帧，AI 生成固定 seed，角色呼吸/光效/粒子循环
- [x] **4 职业 RPG** — 6 维属性（HP/EP/INT/PER/AGI/CHA）+ 等级 + 经验 + 货币
- [x] **42 技能变体** — 每职业 3-4 条技能线 × 3 级，解锁需技能经验
- [x] **8 个 NPC** — AI 状态机（工作/闲逛/返回/休息/避难）+ 定向帧动画 + 巡逻路径
- [x] **好感度系统** — 5 级（陌生→挚友）+ 每日首次对话奖励 + 升级通知
- [x] **20 个任务** — 6 种类型 + 经验/好感度/异常感知奖励

### 🌍 世界系统
- [x] **昼夜循环** — 白天→傍晚→黑夜→雨夜 4 时段，每时段独立 BGM + 背景 + UI 主题
- [x] **世界历法** — N.H.207 纪元，5 月 × 36 天 = 180 天/年，6 天/周
- [x] **每日世界生成** — 天气/异常等级/城市事件/广告，基于确定性种子
- [x] **5 种天气** — 晴/多云/小雨/雷暴/雾霾 + 雨滴粒子 + 闪电特效
- [x] **媒体图片系统** — Unsplash + Pollinations.ai + 本地 fallback，10 个分类，LRU 缓存

### 🤖 AI 系统
- [x] **LLM 三级降级** — Groq（<500ms）→ MiMo-Flash → DeepSeek
- [x] **RAG 语义记忆** — ChromaDB 向量检索 + SQLite 对话历史
- [x] **AI 剧情引擎** — 章节生成 / NPC 背景故事 / 对话分支 / 每日事件
- [x] **14 个后端 API** — FastAPI + 自动生成的 OpenAPI 文档

### 🎨 视觉与音频
- [x] **4 个自定义着色器** — 城市网络背景 / CRT 扫描线 / 故障效果 / 扫描网格
- [x] **粒子特效** — 萤火虫/霓虹/雨滴/阳光尘埃/职业特效（GL Compatibility 兼容）
- [x] **12 首赛博风格 BGM** — 夜间随机循环 + 昼夜切换
- [x] **F5 风格切换** — 写实赛博 ↔ 二次元动漫（96 帧动画，纹理缓存零开销）

### 🏠 场景与交互
- [x] **公寓** — 9 个交互区域（床/电脑/电视/阳台/冰箱/符纸/窗户/宠物碗/门）
- [x] **办公室** — 5 张办公桌 + 会议桌 + 盆栽 + 冰箱碰撞体
- [x] **街区** — 建筑碰撞体 + 气泡消息点 + 雨夜霓虹特效
- [x] **宠物系统** — 狐狸/负鼠/老鹰/青蛙，自动跟随 + Tab 切换 + P 动作
- [x] **7 个 UI 覆盖层** — 电视新闻/论坛/阳台/符纸/睡觉/对话/角色面板

---

## 🛠️ 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| **游戏引擎** | Godot 4.6 | GL Compatibility 渲染器（跨平台兼容） |
| **前端语言** | GDScript | 44 个脚本文件，~7000 行代码 |
| **后端框架** | Python FastAPI | 14 个 API 端点 |
| **数据库** | SQLite + ChromaDB | 对话记忆 + 语义向量检索 |
| **LLM 提供商** | Groq / MiMo / DeepSeek | 三级降级策略 |
| **图像生成** | Pollinations.ai / Unsplash | AI 图像 + 真实摄影 |
| **着色器** | GLSL (Godot Shader) | 4 个自定义着色器，像素运算优化 ↓80%+ |
| **物理引擎** | Jolt Physics | Godot 4.6 内置 |

---

## 🚀 快速开始

### 环境要求

- **Godot 4.6+**（需 GL Compatibility 渲染器支持）
- **Python 3.10+**
- **ChromaDB**（向量数据库）
- LLM API 密钥（Groq / MiMo / DeepSeek 至少一个）

### 1. 克隆项目

```bash
git clone https://github.com/14sword/neo-harbor-207.git
cd neo-harbor-207
```

### 2. 配置后端

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env
# 编辑 .env 填入你的 LLM API 密钥
```

### 3. 启动后端

```bash
cd backend
uvicorn main:app --reload --port 8000
```

访问 `http://localhost:8000/docs` 可查看自动生成的 API 文档。

### 4. 启动游戏

1. 用 Godot 4.6 打开 `game/project.godot`
2. 确保渲染器设置为 **GL Compatibility**
3. 点击运行（F5）

---

## 📸 游戏截图

| 角色选择终端 | 玩家公寓（白天） |
|:---:|:---:|
| ![登录选角色1](../screenshots/登录选角色1.png) | ![玩家公寓白天](../screenshots/玩家公寓白天.png) |

| 玩家公寓（深夜） | 办公室 |
|:---:|:---:|
| ![玩家公寓深夜](../screenshots/玩家公寓深夜.png) | ![办公室](../screenshots/办公室.png) |

| 角色选择-职业详情 | 小镇全景 |
|:---:|:---:|
| ![登录选角色2](../screenshots/登录选角色2.png) | ![小镇](../screenshots/小镇.png) |

---

## 🎮 操作说明

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 移动主角 |
| E | 与 NPC 对话 / 触发场景交互 |
| C | 打开角色面板（属性/技能/背包/剧情） |
| Q | 打开任务面板 |
| T | 手动切换白天/黑夜 |
| Tab | 切换宠物 |
| P | 触发宠物动作 |
| F5 | 切换视觉风格（写实 ↔ 动漫） |
| L | 打开日志面板 |
| ← → | 角色选择界面切换职业 |
| Enter | 确认接入 |

---

## 🏗️ 系统架构

```
┌──────────────────────────────────────────┐
│              Godot 前端                    │
│                                          │
│  character_select → apartment           │
│       (角色选择)        ↕                │
│                   street ←→ main        │
│                                          │
│  ┌──── 18 个 Autoload 单例 ────┐        │
│  │ APIClient  SceneManager     │        │
│  │ DayNightMgr  AudioManager   │        │
│  │ SaveManager  QuestManager   │        │
│  │ GameManager  PetManager     │        │
│  │ UIThemeMgr   WeatherEffects │        │
│  │ CharClassMgr StoryManager   │        │
│  │ WorldCalendar DailyWorldGen │        │
│  │ MediaManager ...            │        │
│  └─────────────────────────────┘        │
│                                          │
│  4 个着色器: city_network / scan_line    │
│              glitch / grid_overlay       │
└──────────────────────────────────────────┘
                  │ HTTP :8000
                  ↓
┌──────────────────────────────────────────┐
│         Python FastAPI 后端               │
│                                          │
│  main.py (14 endpoints)                  │
│    ├── agents.py → LLM 三级降级          │
│    │   Groq → MiMo-Flash → DeepSeek     │
│    ├── story_engine.py (AI 剧情引擎)     │
│    ├── vector_store.py → ChromaDB       │
│    ├── db_manager.py → SQLite           │
│    └── relationship_manager.py          │
└──────────────────────────────────────────┘
```

---

## 📁 项目结构

```
neo-harbor-207/
├── README.md                          # 本文件
├── PROJECT_DOC.md                      # 详细中文项目文档
├── backend/                           # Python FastAPI 后端
│   ├── main.py                        # 14 API 端点
│   ├── agents.py                      # NPC Agent + RAG 检索
│   ├── config.py                      # LLM 配置 + 8 NPC 设定
│   ├── hello_agents_llm.py            # LLM 三级降级封装
│   ├── story_engine.py                # AI 剧情引擎
│   ├── vector_store.py                # ChromaDB 向量存储
│   ├── db_manager.py                  # SQLite 数据库
│   ├── relationship_manager.py        # 好感度系统
│   ├── state_manager.py               # NPC 状态管理
│   ├── batch_generator.py             # 批量对话生成
│   ├── models.py                      # Pydantic 数据模型
│   ├── logger.py                      # 日志系统
│   ├── requirements.txt
│   ├── .env.example
│   └── data/
├── tools/
│   └── generate_characters.py         # AI 角色立绘生成
└── game/
    ├── project.godot                   # Godot 项目文件
    ├── scenes/                         # 21 个场景
    │   ├── character_select.tscn       # 城市接入终端
    │   ├── apartment.tscn              # 公寓场景
    │   ├── main.tscn                   # 办公室场景
    │   └── street.tscn                 # 街区场景
    ├── scripts/                        # 44 个 GDScript
    │   ├── character_select.gd         # 12帧动画 + F5切换
    │   ├── character_class_manager.gd  # 4职业 + 42技能
    │   ├── story_manager.gd            # 5章主线剧情
    │   ├── npc.gd                      # NPC 状态机
    │   └── ...
    ├── shaders/                        # 4 个 GLSL 着色器
    ├── assets/
    │   ├── characters/                 # 角色精灵 + 头像 + 动画帧
    │   ├── backgrounds/                # 12 张场景背景
    │   ├── audio/bgm/                  # 12 首赛博 BGM
    │   ├── fonts/                      # LXGW WenKai 字体
    │   └── media/                      # 10 个分类的媒体图片
    └── tests/
        └── verify_assets.gd            # Headless 资产验证
```

---

## 🎯 项目亮点

1. **LLM × 游戏引擎的深度融合**：不是简单的"对话框里接个 API"，而是将 AI 对话系统深度嵌入游戏的状态机、好感度、剧情分支中，NPC 的回复随昼夜、天气、关系等级、历史对话动态变化

2. **城市接入终端设计理念**：角色选择不是"选个职业点开始"，而是一个完整运行的赛博朋克终端模拟器——3 个自定义着色器、动态信息流、异常信号系统、96 帧双风格待机动画

3. **工程化程度高**：18 个 Autoload 单例的系统架构、LLM 三级降级策略、对象池优化的 UI 系统、纹理缓存、Headless 零错误验证、完整的 bug 修复历史记录

4. **世界构建深度**：自定义 N.H.207 纪元历法、每日确定性世界生成、5 种天气、10 分类媒体系统——不是"搭了个架子"，而是真的跑起来的世界

5. **全栈能力展示**：Godot 游戏前端 + Python FastAPI 后端 + SQLite + ChromaDB + 多 LLM 提供商集成 + GLSL 着色器编程

---

## 🔮 开发路线图

### Phase 1 ✅ 已完成
- 核心玩法（移动/对话/场景切换）
- 昼夜/天气/世界历法系统
- 8 NPC + AI 对话 + 好感度
- 角色选择终端 + 4 职业系统 + 42 技能
- 20 个任务 + 5 章主线剧情
- 4 着色器 + 粒子特效 + 12 BGM
- 性能优化（shader 运算 ↓80%，NPC 距离剔除）
- Headless 零错误验证通过

### Phase 2 — 待完成
- ⬜ 世界地图系统
- ⬜ 回合制战斗系统
- ⬜ 商店系统（义体商店/黑市/咖啡店）
- ⬜ 手机系统（消息/任务/地图/通讯）
- ⬜ NPC 精灵图完善（陈曦/赵霖/孙悦/刘风/何真）

### Phase 3-6 — 未来
- NPC 关系深化 + 日程系统
- 装备系统 + 图鉴系统
- 维度裂缝副本（地下城）
- 房屋装饰 + 小游戏 + 社交功能

---

## ⚠️ 注意事项

### API 密钥安全
本项目包含多个 LLM 提供商的 API 密钥配置。**切勿将包含真实密钥的 `.env` 或 `config.gd` 提交到公开仓库。** 提交前请：
1. 将 `backend/.env` 添加到 `.gitignore`
2. 使用 `backend/.env.example` 作为模板（不含真实密钥）
3. 检查 Godot 脚本中是否硬编码了密钥（需迁移到配置文件）

### Godot 版本
本项目使用 Godot 4.6 的 **GL Compatibility** 渲染器。着色器和粒子特效均针对此模式优化，切换到 Forward+/Mobile 渲染器可能导致效果异常。

---

## 👤 作者

- **GitHub**: [@14sword](https://github.com/14sword)
- **项目来源**: [Hello-Agents](https://hello-agents.datawhale.cc/) 教程第十五章「构建新港·207」毕业设计延伸

---

## 🙏 致谢

- **Datawhale 社区** — 提供 Hello-Agents 开源教程和 AI 学习生态
- **Hello-Agents 项目** — 智能体框架和实战教程基础
- **Godot 引擎** — 开源 2D/3D 游戏引擎
- **Groq / MiMo / DeepSeek** — LLM API 支持
- **Pollinations.ai / Unsplash** — 图像生成和素材支持

---

*N.H.207 — Neo Harbor Identity Synchronization Protocol*