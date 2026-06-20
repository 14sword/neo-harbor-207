# Group 6 集成 QA 与完成度报告

> 生成日期：2026-06-09  
> 工作区：`/Users/xieqing/Desktop/后期/ai agent/赛博小镇`  
> 范围：基于当前工作树做 6 组并行集成修复、静态 QA、完成度归档与验收清单整理。  
> 写入边界：本轮改动集中在 Godot 稳定检查、FastAPI 启动配置、Godot-FastAPI 联动、NPC AI 一致性、素材边界报告和完成度检查；未新增游戏场景。

## 0. 2026-06-09 追加验收记录

### 0.1 地下站台动态层追加

本轮追加完成“地下站台动态元素 AI 素材增强计划”：

- 使用 Image 2 生成并处理地下站台动态视觉素材，正式运行时资源放入 `game/assets/effects/underground/`。
- 新增 `underground_ambient.gd`，通过 `AnimatedSprite2D` 和 `Tween` 播放全息告示、维护屏幕、列车光扫、蒸汽、水面反光、孙悦研究设备和异常入口脉冲。
- `underground.tscn` 新增 `UndergroundAmbient` 节点；动态层无碰撞体，不修改空气墙、传送点、孙悦巡逻范围或 NPC 场景归属。
- `verify_assets.gd` 已纳入 7 张地下动态素材尺寸/加载检查；`verify_special_scene_layout.gd` 已纳入动态节点、z_index、关键点位和无碰撞检查。
- 顺手修复 `underground_ambient.gd` 与 `character_panel.gd` 的 Godot 4 严格类型推断解析问题，避免场景加载测试出现脚本 parse error。

本轮新增/复跑验收：

```text
python3 tools/check_completion.py
=> 46 ok, 0 warn, 0 fail

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_scenes.gd
=> Scene loads passed: 12/12, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_assets.gd
=> Underground ambient effects 7/7, all required assets passed, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_special_scene_layout.gd
=> Special scene layout passed: 2 scenes, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_teleports.gd
=> Teleport and map checks passed, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_npc_scene_presence.gd
=> office 3, street 3, underground sun_yue, anomaly he_zhen, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_npc_animation.gd
=> NPC animation passed: 8/8, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --quit-after 2 res://scenes/underground.tscn
=> 地下站台实际进树运行 2 秒，无新增动态层运行时报错，exit 0
```

本轮追加完成“NPC 场景迁移、AI 地图/传送点与人物裁剪重做计划”：

- NPC 场景归属已更新：办公室仅保留张三、李四、王五；街区保留陈曦、赵霖、刘风；孙悦迁入地下站台；何真迁入异常空间。
- 地下站台与异常空间已接入 Image 2 四相位背景、空气墙、传送点视觉元素和返回/进入逻辑。
- 街区新增地下站台入口；地下站台新增异常空间入口；异常空间返回地下站台。
- 地图 UI 已加入办公室、街区、公寓、地下站台、异常空间，可显示当前场景、NPC 所在地、传送关系和状态，不提供任意瞬移。
- 张三、李四、王五已基于 Image 2 角色表重裁运行时帧：每人 4 向行走各 3 帧、idle 5 帧，统一 316x329；头像切换到 512x512 WebP。

本轮已运行验收：

```text
python3 tools/check_completion.py
=> 44 ok, 0 warn, 0 fail

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_scenes.gd
=> Scene loads passed: 12/12, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_assets.gd
=> NPC runtime frames 96/96, idle frames 40/40, Image2 portraits 8/8, special backgrounds 8/8, map/teleport assets 12/12, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_npc_animation.gd
=> NPC animation passed: 8/8, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_npc_scene_presence.gd
=> office 3, street 3, underground sun_yue, anomaly he_zhen, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_special_scene_layout.gd
=> Special scene layout passed: 2 scenes, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_teleports.gd
=> Teleport and map checks passed, exit 0

python3 -m compileall backend
=> exit 0

python3 -m unittest discover backend/tests
=> Ran 5 tests, OK
```

仍需人工验收：实际操控玩家在街区、地下站台、异常空间走位，确认空气墙手感、传送点提示、地图 UI 展示位置和 NPC 巡逻视觉表现符合玩法预期。

## 1. 结论摘要

当前仓库已经从旧报告的“关键资源缺失”状态推进到“主要文件级缺口已补齐，等待运行验收”的状态。旧报告中的高优先级缺失项，包括 `underground.tscn`、`anomaly_space.tscn`、`class_portrait/`、player 缺失帧，当前工作树均已存在。

本次实际执行的静态完成度检查：

```bash
python3 tools/check_completion.py
```

结果摘要：`27 ok, 0 warn, 0 fail`。Godot 侧 `APIClient` 已移除前端 Groq 直连和硬编码 key，对话、好感度、历史、NPC 状态和批量对话统一走 FastAPI 入口。

已运行 Godot 素材、场景加载、NPC 动画三组 headless 校验，退出码均为 `0`。仍未实际运行的内容：Godot 编辑器/游戏主流程、FastAPI 服务启动、HTTP 接口联调、外部 LLM 调用、性能 profiler。因此本报告不会声称这些测试已经通过。

## 2. 完成度矩阵

| 模块 | 完成度 | 当前状态 | 证据 | 待验收项 |
|------|--------|----------|------|----------|
| Godot 主体 | 92% | 已补齐主要场景和资源引用，Godot headless 验收通过 | `project.godot` 主场景存在；19 个 autoload 脚本存在；23 个 `.tscn` 场景；静态扫描未发现场景 `ext_resource` 缺失；3 个 Godot headless 脚本退出 `0` | 手动走主流程；检查完整 UI/切场景交互体验 |
| 后端 | 82% | FastAPI 主体完整，待启动与接口验收 | `backend/main.py` 存在 17 个路由；包含 `/health`、`/dialogue`、`/story/generate`、`/city/status`、`/character/create` 等入口 | 安装依赖、启动服务、curl 核心接口；检查 DB/状态/日志行为 |
| AI 联动 | 86% | Godot 对话链路已统一接 FastAPI，后端 LLM/RAG/好感度链路具备，待 live 服务联调 | 后端有 Groq/MiMo/DeepSeek 降级封装；NPC Agent 有记忆、向量检索、好感度更新；Godot `config.gd` 定义 `localhost:8000`；`api_client.gd` 不再包含前端 Groq 直连和客户端密钥 | 启动 FastAPI 后做 Godot 端到端对话；用真实 API key 做一次 LLM 验收；确认后端关闭时 UI 错误态 |
| 素材 | 92% | 旧缺失资源已补齐，素材包较完整 | player 13 个基础帧齐全；8 个 NPC runtime 目录齐全；11 个 media 分类齐全；`class_portrait` 有 8 张 webp；资产文件约 952 个 | Godot 实际导入/加载验收；确认未跟踪素材需要纳入版本；检查图片视觉一致性 |
| 性能与体积 | 70% | 有优化产物和本地 fallback，但缺少运行采样 | `game/assets/optimized_preview/`、webp 预览、字体子集产物存在；`MediaManager` 有内存缓存、本地 fallback、请求队列 | Godot profiler 采样 FPS/内存；明确生产引用是否切到优化资源；复核 418MB `game/` 体积是否可接受 |
| 测试 | 82% | 测试入口已补齐，静态 QA 已无警告，Godot 三组 headless 校验已通过 | 存在 `verify_assets.gd`、`verify_scenes.gd`、`verify_npc_animation.gd`；`tools/check_completion.py` 已运行；3 个 Godot headless 脚本均退出 `0` | 启动后端做接口验收；记录真实 HTTP 输出；做手动主流程和性能采样 |

综合判断：当前更接近“集成验收候选”而不是“已发布完成”。文件级缺口已明显收敛，主要风险转移到运行时联动、外部服务配置、性能采样和版本纳入确认。

## 3. 旧报告缺失项更新

| 旧报告项 | 当前状态 | 更新结论 |
|----------|----------|----------|
| `res://scenes/underground.tscn` 缺失 | 当前存在 `game/scenes/underground.tscn`，并由 `special_scene.gd` 支撑 | 已补齐，待 Godot 场景加载验收 |
| `res://scenes/anomaly_space.tscn` 缺失 | 当前存在 `game/scenes/anomaly_space.tscn`，并由 `special_scene.gd` 支撑 | 已补齐，待 Godot 场景加载验收 |
| `res://assets/media/class_portrait/` 缺失 | 当前目录存在，含 `class_portrait_001.webp` 到 `004.webp` 及 `cipher/chrome/echo/shadow.webp` | 已补齐，待角色选择界面验收 |
| player 多个方向帧缺失 | `player_down_2`、`player_up_2`、`player_left_1/2`、`player_right_0/2` 当前均存在 | 已补齐，待动画播放验收 |
| 场景引用可能断裂 | 静态扫描 23 个 `.tscn` 的 `ext_resource` 未发现缺失 | 静态已通过，仍需 Godot 实例化验收 |
| NPC runtime 动画资源缺口 | 8 个 NPC runtime 目录和行走/idle 帧静态检查通过 | 已补齐，待 `verify_npc_animation.gd` 运行 |
| `.uid` 版本管理建议 | 当前仍存在 `.uid` 文件；本任务禁止改实现/配置文件 | 保留为版本策略待办，不在本次范围内处理 |
| 大文件/体积优化 | 已出现 `optimized_preview`、webp 和字体子集产物；原始素材仍在 | 部分补齐，生产引用和体积策略待验收 |

## 4. Godot 完成度

Godot 项目配置完整度较高：主项目位于 `game/`，`project.godot` 声明主场景 `res://scenes/character_select.tscn`，当前有 19 个 autoload 脚本，脚本文件约 44 个，场景文件 23 个。

本次静态确认：

- 主场景存在。
- autoload 脚本均存在。
- `underground.tscn`、`anomaly_space.tscn` 和 `special_scene.gd` 均存在。
- 23 个场景中的 `ext_resource` 路径静态存在。
- `SceneManager` 对缺失场景已有回退到公寓的保护逻辑。
- `verify_scenes.gd` 已覆盖主场景、办公室、街区、公寓、地下站台、异常空间。

已验收：

- `verify_assets.gd` 退出 `0`，素材缺失/损坏检查通过。
- `verify_scenes.gd` 退出 `0`，6 个核心场景均可加载并实例化。
- `verify_npc_animation.gd` 退出 `0`，8 个 NPC idle/walk 帧可推进。

待验收：

- 启动主场景，从角色选择进入游戏，走办公室、街区、公寓、地下站台、异常空间切换。
- 检查 `InteractionPrompt`、`DialogueUI`、`QuestPanel`、`CharacterPanel` 在新场景中是否正常挂载。

## 5. 后端完成度

后端主体位于 `backend/`，当前具备 FastAPI 入口、配置、模型、NPC Agent、故事引擎、数据库、向量存储、关系管理、状态管理和日志模块。`main.py` 当前静态识别到 17 个 FastAPI route。

核心能力已具备：

- `/health` 健康检查。
- `/npcs/status`、`/npcs/all`、`/npcs/batch_dialogue`、`/npcs/interactions`。
- `/dialogue` NPC 对话入口。
- `/affinity/{npc_id}/{player_name}` 与 `/dialogue/history/{npc_id}`。
- `/character/create` 角色创建。
- `/story/generate`、`/story/progress`。
- `/generate/npc-story`、`/generate/dialogue-branch`、`/generate/daily-events`。
- `/city/status`、`/npc/relationship_map`。

待验收：

- 依赖安装与服务启动。
- `/health`、`/npcs/status`、`/npcs/all` 等无 LLM 接口返回。
- `/dialogue`、`/story/generate` 等 LLM 相关接口在有效 API key 下返回，并在失败时有可接受的 fallback 或错误信息。
- 启动时批量对话刷新任务是否符合当前配置预期。

## 6. AI 联动完成度

后端 AI 层已经具备较完整的服务端链路：`HelloAgentsLLM` 包含 Groq、MiMo、DeepSeek 多 provider 降级；`SimpleAgent` 维护 NPC 记忆、RAG 检索、好感度更新；`StoryEngine` 支持章节、NPC 背景、对话分支和每日事件生成，并包含 fallback 内容。

Godot 侧当前联动边界已经收敛到 FastAPI：

- `game/scripts/config.gd` 定义 `API_BASE_URL = "http://localhost:8000"`。
- `game/scripts/api_client.gd` 统一请求 `/dialogue`、`/affinity/{npc_id}/{player_name}`、`/dialogue/history/{npc_id}`、`/npcs/status`、`/npcs/batch_dialogue` 和 `/npcs/interactions`。
- 前端不再保存 Groq key，不再请求 `api.groq.com`，后端不可用时发出 `chat_error` 或使用本地状态 fallback，UI 不应被锁死。
- `main.gd` 保留办公室前三个 NPC 的旧节点路径，同时会按 `npcs` 分组、`npc_name` 和 `display_name` 匹配已加载 NPC，避免状态气泡只覆盖前三个 NPC。

集成风险：

- 当前工作区 Python 环境的已安装依赖仍可能落后于 `backend/requirements.txt`，需要重新安装依赖后做 FastAPI live smoke。
- 外部 LLM 可用性仍依赖有效 key、网络和 provider 配置；mock LLM 测试已覆盖，但不能替代真实 provider 验收。

当前结论：AI 能力链路已经完成主要接线，进入 live 服务联调和真实 LLM 验收阶段。

## 7. 素材完成度

素材侧旧缺失项已补齐，当前静态覆盖较完整：

- player 基础帧：13/13。
- NPC runtime：8 个 NPC，行走方向帧和 idle 帧静态齐全。
- media 分类：11/11。
- media 图片数量：`ads=8`、`anomaly=10`、`city_day=10`、`city_night=10`、`city_rain=10`、`class_portrait=8`、`datawhale=8`、`forum=8`、`surveillance=10`、`talisman=8`、`weather=8`。
- `game/assets/generated/`、`game/assets/optimized_preview/`、NPC 生成头像/runtime 目录均已出现。

注意事项：

- 许多新增素材当前仍是未跟踪文件，版本纳入需要单独确认。
- 本次只做文件存在性检查，没有逐张图片做 Godot 导入、透明通道、尺寸、视觉一致性验收。
- `optimized_preview` 已存在，但不能自动代表生产运行已使用优化资源。

## 8. 性能与体积完成度

当前体积快照：

```text
game      418M
backend   144K
tools     128K
```

已具备的性能/体积相关基础：

- `MediaManager` 有内存缓存、请求队列、本地 fallback 和外部图片请求限流。
- 存在 webp 预览资源和字体子集产物。
- `SceneManager` 对缺失场景有回退保护，降低切场景崩溃风险。

待验收：

- Godot profiler 采样：角色选择、街区、公寓、雨夜/深夜特效、地下站台、异常空间。
- 内存峰值和纹理加载耗时。
- 是否将大型 PNG/BGM/字体替换为实际生产引用的优化版本。
- 打包体积目标是否接受当前 `game/` 规模。

## 9. 测试完成度

当前已有测试入口：

- `game/tests/verify_assets.gd`
- `game/tests/verify_scenes.gd`
- `game/tests/verify_npc_animation.gd`
- `tools/check_completion.py`

本次已运行：

```text
python3 tools/check_completion.py
=> 27 ok, 0 warn, 0 fail

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_assets.gd
=> exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_scenes.gd
=> Scene loads passed: 6/6, exit 0

"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path game --script res://tests/verify_npc_animation.gd
=> NPC animation passed: 8/8, exit 0
```

本次未运行：

- FastAPI 服务启动。
- curl/API 联调。
- 外部 LLM 调用。
- Godot 可视化主流程。
- 性能 profiler。

因此测试状态应写为“测试入口已补齐，静态 QA 和 Godot headless 已过，后端 live smoke、手动主流程与性能验收待执行”。

## 10. 验收命令清单

以下命令是建议验收清单。除 `tools/check_completion.py` 外，本次没有实际执行，不应在验收记录中标为已通过，直到获得真实输出。

### 10.1 静态完成度检查

```bash
python3 tools/check_completion.py
```

通过标准：`fail=0`。若仍有 `warn`，需要在验收记录中解释风险。

### 10.2 Godot 素材检查

```bash
cd game
godot --headless --path . --script res://tests/verify_assets.gd
```

通过标准：退出码为 `0`，输出中没有 `MISSING`、`CORRUPT`。

### 10.3 Godot 场景加载检查

```bash
cd game
godot --headless --path . --script res://tests/verify_scenes.gd
```

通过标准：退出码为 `0`，6 个核心场景均可加载并实例化。

### 10.4 Godot NPC 动画检查

```bash
cd game
godot --headless --path . --script res://tests/verify_npc_animation.gd
```

通过标准：退出码为 `0`，8 个 NPC idle/walk 帧可推进。

### 10.5 后端启动检查

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 127.0.0.1 --port 8000
```

通过标准：服务成功监听 `127.0.0.1:8000`，启动日志无未处理异常。

### 10.6 后端无 LLM 接口冒烟

```bash
curl -s http://127.0.0.1:8000/health
curl -s http://127.0.0.1:8000/npcs/status
curl -s http://127.0.0.1:8000/npcs/all
curl -s http://127.0.0.1:8000/story/progress
curl -s http://127.0.0.1:8000/city/status
curl -s -X POST http://127.0.0.1:8000/character/create \
  -H 'Content-Type: application/json' \
  -d '{"player_name":"QA","player_class":"cipher"}'
```

通过标准：HTTP 2xx，JSON 结构符合预期。

### 10.7 LLM 接口验收

先配置至少一个有效 key：`GROQ_API_KEY`、`MIMO_API_KEY` 或 `DEEPSEEK_API_KEY`。

```bash
curl -s -X POST http://127.0.0.1:8000/dialogue \
  -H 'Content-Type: application/json' \
  -d '{"npc_id":"zhang_san","player_name":"QA","player_message":"你好，今天系统状态怎么样？"}'
```

通过标准：HTTP 2xx，返回 `npc_reply`、`affinity_level`、`affinity_score`；后端日志无未处理异常。

### 10.8 Godot 手动主流程

```bash
cd game
godot --path .
```

通过标准：

- 角色选择界面可进入游戏。
- player 移动和方向动画正常。
- 公寓、办公室、街区、地下站台、异常空间可切换。
- NPC 对话 UI 可打开，错误态可见且不崩溃。
- 若预期走后端，后端日志能看到对应请求；若未看到，应记录为 Godot-FastAPI 接线待办。

### 10.9 性能验收

```bash
du -sh game backend tools
find game/assets -type f | wc -l
```

并在 Godot profiler 中记录：

- 角色选择界面 FPS/内存。
- 街区场景 FPS/内存。
- 雨夜/深夜特效下 FPS/内存。
- 地下站台和异常空间 FPS/内存。
- 首次加载媒体素材的卡顿和峰值内存。

## 11. 待办与风险

1. 外部 LLM 可用性未验收：需要有效 key、网络和 provider 配置。
2. FastAPI live smoke 仍需在安装最新依赖后执行，尤其是 `pydantic-settings`、`chromadb` 和 `openai`。
3. 新增素材和场景多为未跟踪文件：合入前需要确认版本纳入清单。
4. 性能仍缺少实测数据：已有优化产物不等于运行时已优化。
5. `.uid` 是否入库仍是版本策略问题，本次未改 `.gitignore`。

## 12. 本次 QA 改动文件

- `PROJECT_AUDIT_REPORT.md`：更新为当前集成 QA 与完成度报告。
- `tools/check_completion.py`：新增只读静态完成度检查脚本。
