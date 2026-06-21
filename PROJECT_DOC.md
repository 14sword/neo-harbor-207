# 新港·207 (Neo Harbor 207) 项目完整文档

## 一、项目概览

- **项目名称**: 新港·207 (Neo Harbor 207)
- **游戏类型**: 2D 赛博朋克风格 AI 小镇社交游戏（含角色养成/剧情/战斗）
- **游戏引擎**: Godot 4.6 (GL Compatibility 渲染器)
- **前端语言**: GDScript
- **后端语言**: Python (FastAPI)
- **分辨率**: 1280×720
- **起始场景**: `res://scenes/character_select.tscn`（角色选择 → 公寓）
- **后端地址**: `http://localhost:8000`
- **世界纪元**: N.H.207 (Neo Harbor 207年)

玩家在角色选择界面选择职业后进入公寓，可在公寓、街区和办公室三个场景中自由移动，与 AI 驱动的 NPC 对话，体验昼夜切换、雨夜特效、宠物跟随、任务系统、世界历法、每日世界生成、角色成长、主线剧情等功能。

---

## 二、核心玩法

### 2.1 操作按键

| 按键 | 功能 |
|------|------|
| WASD / 方向键 | 移动主角 |
| E 键 | 与 NPC 对话 / 触发场景交互 |
| C 键 | 打开/关闭**角色面板** |
| T 键 | 手动切换白天/黑夜 |
| Q 键 | 打开/关闭任务面板 |
| L 键 | 打开/关闭日志面板（登录界面自动禁用） |
| Tab 键 | 切换宠物（登录界面自动禁用） |
| P 键 | 触发宠物动作（登录界面自动禁用） |
| F5 | **切换视觉风格**（写实赛博 ↔ 二次元动漫） |
| ← → | 角色选择界面切换职业 |
| Enter | 角色选择界面确认接入 |

### 2.2 NEO HARBOR 城市接入终端（MAJOR REFACTOR）

- **设计理念**：不是"选角色开始游戏"，而是**"接入一个正在运行的未来都市世界"**
- **4个可选职业**，各有独特属性、技能树和专属剧情线：
  - **CIPHER 数据分析师**：INT↑18 PER↓12 — 技能：数据透视/系统入侵/维度映射 — 初始好感：张三+10 — 身份：DATAWHALE Data Analyst / Block 09
  - **CHROME 义体战士**：AGI↓14 CHA↓6 — 技能：义体过载/护盾生成/近战精通 — 初始好感：刘风+10 — 身份：Street Cyborg Operative / Block 17
  - **ECHO 灵能感知者**：PER↑18 EP↓ — 技能：维度感知/灵能冲击/预知闪避/灵魂链接 — 初始好感：孙悦+10 — 身份：Psionic Resonance Specialist / Block 03
  - **SHADOW 暗影潜行者**：AGI↑18 INT↓ — 技能：隐匿行踪/信息网络/暗杀技巧/陷阱布置 — 初始好感：赵霖+10 — 身份：Shadow Network Agent / Block 22

#### 三栏终端布局（NEW）
- **左栏 — IDENTITY ARCHIVE（身份档案）**：
  - 身份类型、居住区域、精神适配率(%)、异常接触等级(LOW RISK/MONITORED/ELEVATED)、城市信用等级(C+/B/A-)、最近网络活动状态
  - 数据以终端格式展示（数据条+动态数字+hologram线条），非传统RPG卡片
- **中栏 — 动态扫描区域**：
  - **12帧平滑待机动画**（0.12秒/帧，1.44秒完整循环）：角色呼吸起伏、发丝飘动、装备光效粒子浮动，AI生成固定seed确保角色外观完全一致
  - 职业代号大字显示(56px) + 扫描线动画 + 中文名称 + 职业描述 + ClassTrait特性标识
  - ClassTrait格式：彩色竖条(TraitBar 3×18px) + "> CIPHER // 数据透视" 样式描述
  - 切换职业时扫描动画重播，背景色调0.6秒过渡，ClassTrait同步切换对应职业色
- **F5 视觉风格切换**（NEW）：写实赛博朋克风格 ↔ 二次元动漫风格，96张动画帧（4×12×2），切换时间<0.1秒无卡顿，右下角显示当前风格状态指示器
- **纹理缓存系统**（NEW）：`_texture_cache` Dictionary 缓存已加载纹理，切换职业/风格零额外加载开销
- **右栏 — NETWORK DATA（网络数据）**：
  - 属性数据条(INT/PER/AGI/CHA) + 技能列表 + 初始好感度NPC链接

#### 动态系统效果（NEW）
- **顶部标题区**："NEO HARBOR / CITY NETWORK" + "N.H.207 · Identity Synchronization Protocol"
- **状态文字循环**：每3秒随机淡入淡出切换（"正在同步城市身份档案..."等8条）
- **动态城市网络背景**：着色器驱动（数据流粒子+网格线+网络节点+噪波），色调随职业变化
- **CRT扫描线叠加**：全屏半透明扫描线效果
- **异常信号系统**：30-45秒随机触发青色故障闪烁+警告文字（WARNING: UNAUTHORIZED SIGNAL DETECTED等），glitch intensity=0.3，0.3-0.8秒自动消失；hover时intensity=0.15轻微闪烁
- **城市信息流**：底部滚动16条城市信息（天气/列车/DATAWHALE通知/异常报告），5秒更新
- **确认流程**：名称输入("Enter Codename...") → "SYNC →"按钮 → 0.5秒glitch同步动画 → 淡出切换到公寓

### 2.3 场景系统
- **角色选择** (character_select.tscn): **NEO HARBOR城市接入终端** — 三栏布局(身份档案/扫描区域/网络数据) + CharacterDisplay动画区(220px高, separation=6) + 动态城市网络背景 + CRT扫描线（2帧更新1次） + 异常信号系统(青色,30-45秒触发) + 城市信息流 + F5风格切换
- **公寓** (apartment.tscn): 9个交互区域（床/电脑/电视/阳台/冰箱/符纸/窗户/宠物碗/门），支持睡觉推进时间、论坛浏览、电视观看、阳台观察等
- **办公室** (main.tscn): 含8个NPC（原3+新5）、5张办公桌、会议桌、盆栽、冰箱等家具碰撞体
- **街区** (street.tscn): 含8个NPC（3办公室+5街区）、建筑碰撞体和气泡消息点
- 场景切换带 0.4 秒淡入淡出过渡动画
- 宠物跨场景持久跟随
- 所有游戏场景内嵌角色面板（按C键打开）

### 2.4 昼夜系统
- **4 个时段**: 白天 → 傍晚 → 黑夜 → 雨夜
- 每个场景各有对应背景图
- 每个时段有独立的 BGM
- 夜间有萤火虫粒子、霓虹粒子、月光等视觉效果
- UI 主题随昼夜自动切换（白天暖色/傍晚橙金/黑夜赛博青）

### 2.5 世界历法系统
- **纪元**: N.H.207 (Neo Harbor 207年)
- **5 月份**: 霜月(Frostmonth)、霓月(Neonmonth)、雨月(Rainmonth)、幽月(Ghostmonth)、灰月(Ashmonth)
- **每月 36 天，每周 6 天**: 曜日、霓日、雨日、铁日、幽日、灰日
- **一年 = 5 × 36 = 180 天**
- 睡觉推进一天，历法自动更新
- 幽月异常概率增加，雨月降雨概率增加

### 2.6 每日世界生成器
- 每天自动生成：天气（晴/多云/小雨/雷暴/雾霾）、异常等级、城市事件（3-5条）、广告（2-3条）
- 基于日历天数的确定性种子，同一天内容一致
- 天气数据接入电视天气频道，事件接入新闻，广告接入论坛

### 2.7 媒体图片系统（多源实时动态模式）
- **三重图片来源**：Unsplash真实照片 + Pollinations.ai AI生成 + 本地fallback离线降级
- **智能来源选择**：按分类自动选择最佳来源
  - Unsplash（真实照片）：city_day、city_rain、city_night、forum、ads、weather — 6个分类使用真实摄影照片
  - Pollinations.ai（AI生成）：surveillance、datawhale、anomaly、talisman — 4个分类使用AI生成图
  - 本地Fallback：所有分类的离线降级图片
- **LRU 内存缓存**（上限20张）：同一会话内不重复请求
- **离线降级**：网络不可用时自动使用本地 fallback 图片
- **10 个分类**，每个分类含动态提示词模板 + 随机场景词库

### 2.8 NPC 对话系统（MAJOR UPDATE: 3→8 NPCs）
- **8 个 NPC**，分布在办公室和街区：
  - **办公室(3)**: 张三(Python工程师)、李四(产品经理)、王五(UI设计师)、孙悦(异常现象研究员)、何真(AI系统管理员)
  - **街区(3)**: 陈曦(咖啡店老板)、赵霖(黑市信息贩子)、刘风(赛博义体技师)
- NPC 有状态机（工作→闲逛→返回），头顶显示对话气泡
- 对话通过后端 LLM 生成（三级降级：Groq→MiMo-Flash→DeepSeek），支持 RAG 语义记忆检索
- 对话 UI 含打字机效果、NPC 头像、好感度心形显示
- 好感度 5 级：陌生(0-20) / 熟悉(21-40) / 友好(41-60) / 亲密(61-80) / 挚友(81-100)
- 新NPC含完整背景故事、性格描述、所属场景

### 2.9 宠物系统
- 4 种宠物：狐狸、负鼠、老鹰、青蛙
- 宠物自动跟随主角，保持 60px 距离
- 待机时随机播放动作
- 场景切换后宠物自动传送

### 2.10 任务系统（EXPANDED: 13→20 tasks, +STORY type）
- **20个任务**，6种类型（对话/探索/收集/日常/隐藏/**剧情**）
- **新增5条主线剧情任务**（Ch1 初来乍到）：
  - story_ch1_meet_team: 认识团队（与3位同事各对话1次）
  - story_ch1_explore_street: 走出办公室（访问街区）
  - story_ch1_mystery_hint: 异常的暗示（查看符纸+阳台）
  - story_ch1_coffee_shop: 量子咖啡（与陈曦交谈）
  - story_ch1_first_anomaly: 第一次异常（深夜触发异常事件）
- **任务奖励扩展**：好感度 + 经验值(EXP) + 异常感知点
- **任务类型图标**：💬对话 / 🔍探索 / 📦收集 / 🔄日常 / 👻隐藏 / 📖剧情

### 2.11 角色成长系统（NEW）
- **6维属性**: HP(生命值)/EP(体力值)/INT(智力)/PER(感知)/AGI(敏捷)/CHA(社交)
- **等级系统**: 升级获得属性点(每次3点)，可自由分配到INT/PER/AGI/CHA
- **经验值**: 任务完成/战斗胜利获取经验，升级公式 `exp_to_next = 100 × 1.5^(level-1)`
- **货币系统**: 信用点，通过任务/战斗/交易获取
- **技能树**: 每职业4分支×3级=12技能，使用技能获得技能经验解锁下一级
- **异常感知**: 影响可发现的隐藏内容和剧情分支

### 2.12 主线剧情系统（NEW）
- **5章主线"维度裂缝"(Dimension Rift)**:
  - Ch1 初来乍到 → Ch2 数据暗流 → Ch3 裂缝显现 → Ch4 诸天交汇 → Ch5 抉择时刻
- 章节解锁条件基于异常等级和前置章节完成度
- 每章含多个故事步骤（对话/探索/观察/事件）
- StoryManager Autoload 管理章节进度、步骤追踪、剧情标志

### 2.13 世界地图与传送系统（NEW）
- **地下站台与异常空间传送**：实现场景之间的双向物理传送，包含完整的空气墙碰撞体，阻挡玩家非法跨越。
- **全景地图 UI 面板**（按C键/通过终端可打开）：显示当前小镇中所有 NPC 的实时位置，以及各区域（公寓、街区、办公室、地下站台、异常空间）之间的连通拓扑图，方便玩家快速掌握地理环境。
- **动态状态同步**：从 APIClient 和 StateManager 中自动同步 NPC 当前位置状态，并在 UI 上实时刷新。

### 2.14 裂隙打怪战斗系统（NEW）
- **2D 动作生存玩法**：玩家进入“维度裂缝”副本，在 9 个不同的战斗节点（Tile）中进行选路挑战。
- **节点词缀选择**（RiftTileSelect）：每个节点拥有不同的随机怪物加成或环境词缀，玩家需要权衡挑战难度与奖励。
- **波次与刷怪管理**（EnemySpawner）：配置每波怪物的类型、数量和刷新速率，通过对象池自动回收并支持连击数（Combo）统计。
- **招式与技能判定**：按 J 键（或鼠标左键）进行普通攻击，按 K 键（或鼠标右键）触发职业技能，按 Space 键触发翻滚/闪避（附带短暂无敌帧与体力消耗）。
- **HUD 交互面板**：包含红条（血量）与绿条（体力）、击杀数、连击数、当前波次、攻击/技能 CD 冷却指示器以及紧急撤退按钮。
- **战斗结算系统**（RiftResultPanel）：根据通关（Cleared）、战败（Defeated）或中途撤退（Evacuated）状态进行积分结算，提供经验值、信用点和异常感知奖励。

---

## 三、UI主题系统

### 3.1 三套时段主题
- **白天(day)**：暖白/琥珀金/深棕色调，星露谷温暖感
- **傍晚(dusk)**：深棕/橙金色调，过渡氛围
- **夜晚(night)**：深蓝黑/青色/赛博朋克风格

### 3.2 UIThemeManager 设计常量
| 常量 | 值 | 用途 |
|------|-----|------|
| CORNER_RADIUS_SM | 4 | 小圆角（标签、进度条） |
| CORNER_RADIUS_MD | 8 | 中圆角（按钮、滚动区） |
| CORNER_RADIUS_LG | 14 | 大圆角（面板） |
| SPACING_SM/MD/LG | 4/8/16 | 间距规范 |
| ANIM_FAST/NORMAL/SLOW | 0.1/0.25/0.4 | 动画时长规范 |
| FONT_SIZE_SM/MD/LG/XL/XXL | 11/14/18/22/36 | 字号规范 |

### 3.3 已适配动态主题的组件（EXPANDED: 9→13）
quest_panel★(对象池架构), log_panel, dialogue_ui, forum_ui, tv_overlay, balcony_overlay, talisman_overlay, ambient_bubble, sleep_overlay, **character_panel**

---

## 四、前端文件清单（EXPANDED）

### 4.1 核心脚本 (scripts/) — 新增文件标注★

| 文件 | 用途 | 关键功能 |
|------|------|----------|
| `player.gd` | 玩家控制 | WASD 移动、对角线模拟翻转、NPC 交互 |
| `npc.gd` | NPC 控制 | 状态机、闲聊气泡、巡逻路径、8方向对角线翻转映射 |
| `apartment.gd` | 公寓场景 | 9个交互区域触发逻辑、随机事件调度 |
| `main.gd` | 办公室场景 | 办公室环境控制、8位 NPC 逻辑更新 |
| `street.gd` | 街区场景 | 气泡消息点、雨夜特效、3位街区 NPC |
| `character_select.gd` ★ | NEO HARBOR接入终端 | 12帧待机动画系统、F5双风格切换、纹理缓存、ClassTrait重新搭建、着色器驱动、CRT扫描线、异常信号、城市信息流 |
| `character_panel.gd` ★ | 角色面板 | C键切换、4标签页(属性/技能/背包/剧情)、卡片式UI(稀有度颜色+类型标签)、null安全 |
| `character_class_manager.gd` ★ | 职业管理 | 4职业参数设置、33技能等级变体、属性分配与应用 |
| `story_manager.gd` ★ | 剧情管理 | 5章主线剧情进度控制器、步骤追踪、标记检测 |
| `dialogue_director.gd` ★ | 对话导演 | 4种对话模式（剧情、日常、好感度、自由对话）节点与离线 Fallback 机制 |
| `dialogue_ui.gd` | 对话界面 | 打字机效果、NPC 头像展示、好感度指示与占位图生成 |
| `special_scene.gd` | 传送点逻辑 | 物理传送、区域进出触发 |
| `map_panel.gd` ★ | 全景地图 UI | 地图拓扑绘制、NPC 位置实时标注与传送 |
| `quest_tracker_hud.gd` | 任务追踪 HUD | 主界面任务目标实时追踪 |
| `quest_panel.gd` ★ | 任务面板 | 对象池架构重写，防模糊与自适应分类过滤 |
| `talisman_overlay.gd` | 符纸界面 | 符纸内容渲染 |
| `tv_overlay.gd` | 电视界面 | 天气预报和新闻节目切换播放 |
| `forum_ui.gd` | 论坛 UI | 帖子加载及回复列表渲染 |
| `forum_data.gd` | 论坛数据模型 | 模拟帖子、评论与离线备用数据 |
| `balcony_overlay.gd` | 阳台界面 | 阳台夜色与天气粒子远眺 |
| `sleep_overlay.gd` | 睡觉界面 | 推进日期过渡动画 |
| `interaction_prompt.gd` | 交互气泡 | 头顶 E 键提示框控制 |
| `ambient_bubble.gd` | 环境气泡 | NPC 场景闲聊文本框 |
| `apartment_effects.gd` / `apartment_ambient.gd` / `underground_ambient.gd` / `rain_night_effects.gd` | 场景特效 | 场景特定粒子、光效和音频环境控制器 |

### 4.2 系统管理脚本 (Autoload 单例) — 新增标注★

在 `project.godot` 中注册的 Autoload 全局单例共 22 个，其用途如下：

| 单例名 | 绑定脚本 | 用途 |
|--------|----------|------|
| `Config` | `config.gd` | 全局 API 地址与参数配置 |
| `APIClient` | `api_client.gd` | 负责 HTTP 通信与 8 位 NPC 的 prompt 初始化 |
| `DialogueDirector` | `dialogue_director.gd` | 负责 NPC 分支对话的分发与控制 |
| `LogPanel` | `log_panel.gd` | 登录界面控制台日志与快捷键屏蔽控制 |
| `AudioManager` | `audio_manager.gd` | BGM、环境音效与 UI 音效混合管理器 |
| `DayNightManager` | `day_night_manager.gd` | 昼夜循环状态更新（白天/傍晚/夜晚/雨夜） |
| `FootstepGenerator` | `footstep_generator.gd` | 根据地表材质与移动速度播放脚步声效 |
| `SaveManager` | `save_manager.gd` | JSON 本地存档持久化（包含角色、任务、剧情、历法） |
| `QuestManager` | `quest_manager.gd` | 20 个任务的状态机（接取、进度校验、奖励发放） |
| `SceneManager` | `scene_manager.gd` | 带渐变转场的场景管理器（公寓/街区/办公室/地下/裂隙） |
| `EnvironmentManager` | `environment_manager.gd` | 场景天气粒子、广告图片源与异常灾害生成器 |
| `GameManager` | `game_manager.gd` | 核心数据（6维属性、经验、等级、背包物品、稀有度） |
| `PetManager` | `pet_manager.gd` | 宠物物理跟随控制（登录场景自动挂起） |
| `UIThemeManager` | `ui_theme_manager.gd` | UI 白天/傍晚/深夜三时段主题色与圆角常量集 |
| `QuestTrackerHUD` | `quest_tracker_hud.gd` | 主界面任务追踪小部件控制器 |
| `WorldCalendar` | `world_calendar.gd` | N.H.207 世界历法（5月36天制）计数与计算器 |
| `MediaManager` | `media_manager.gd` | Unsplash+Pollinations.ai 动态图象抓取及 LRU 缓存 |
| `DailyWorldGenerator` | `daily_world_generator.gd` | 基于日期种子的每日天气、事件、广告确定性生成 |
| `WeatherEffects` | `weather_effects.gd` | 雨雪雾霭等全局天气粒子层控制 |
| `CharacterClassManager` | `character_class_manager.gd` | 职业设定与技能初始化单例 |
| `StoryManager` | `story_manager.gd` | 主线剧情管理单例 |
| `RiftRunManager` | `rift/rift_run_manager.gd` | 裂隙战斗进程控制器 (种子生成、选路、属性继承) |

### 4.3 场景文件 (scenes/) — 新增标注★

| 文件 | 类型 | 描述 |
|------|------|------|
| `character_select.tscn` ★ | Control | 角色选择终端界面（含 3 个新着色器） |
| `character_panel.tscn` ★ | CanvasLayer | 角色面板（嵌入所有游戏场景，C键打开） |
| `apartment.tscn` | Node2D | 公寓场景（含角色面板） |
| `main.tscn` | Node2D | 办公室场景（8 NPC 巡逻） |
| `street.tscn` | Node2D | 街区场景（3 街区 NPC + 雨夜霓虹） |
| `underground.tscn` | Node2D | 地下客运站台传送点场景 |
| `anomaly_space.tscn` | Node2D | 异常空间传送点与战斗入口场景 |
| `rift_run.tscn` ★ | Node2D | 裂隙打怪主战场场景 (120 FPS 高帧率优化) |
| `rift_tile_select.tscn` ★ | CanvasLayer | 战斗关卡/词缀节点选择界面 |
| `rift_enemy.tscn` ★ | CharacterBody2D | 战斗敌人基础实体场景 |
| `rift_projectile.tscn` ★ | Area2D | 战斗投射物 (子弹) 实体场景 |
| `rift_hud.tscn` ★ | CanvasLayer | 战斗血量、能量、击杀、波次与 CD 提示 UI |
| `rift_result_panel.tscn` ★ | CanvasLayer | 战斗结算面板（展示评分与获取奖励） |
| `player.tscn` | CharacterBody2D | 玩家实体场景 (主控角色) |
| `npc.tscn` | CharacterBody2D | NPC 实体场景 (状态机与动作) |
| `dialogue_ui.tscn` | CanvasLayer | 对话 UI (打字机与心形好感度) |
| `quest_panel.tscn` ★ | CanvasLayer | 任务面板 (静态槽位对象池架构) |
| `log_panel.tscn` | CanvasLayer | 登录后台终端日志面板 |
| `forum_ui.tscn` | CanvasLayer | 论坛覆盖层 |
| `tv_overlay.tscn` | CanvasLayer | 电视新闻与天气覆盖层 |
| `balcony_overlay.tscn` | CanvasLayer | 阳台远眺覆盖层 |
| `talisman_overlay.tscn` | CanvasLayer | 符纸信息覆盖层 |
| `sleep_overlay.tscn` | CanvasLayer | 睡觉覆盖层 |
| `interaction_prompt.tscn` | CanvasLayer | 交互 E 按键气泡提示 |
| `ambient_bubble.tscn` | CanvasLayer | NPC 头顶闲聊气泡 |
| `fox.tscn` | Node2D | 狐狸宠物 |
| `frog.tscn` | Node2D | 青蛙宠物 |
| `eagle.tscn` | Node2D | 老鹰宠物 |
| `opossum.tscn` | Node2D | 负鼠宠物 |
| `map_panel.tscn` ★ | CanvasLayer | 全景传送地图面板 |

**总计**: 30个场景文件

### 4.4 战斗相关脚本 (game/scripts/rift/) ★

| 文件 | 用途 | 关键逻辑 |
|------|------|----------|
| `rift_run.gd` | 战局循环 | 控制帧率(120fps)、暂停切换、结算分发、异常空间切换 |
| `rift_player_combat.gd` | 战斗玩家 | 移动控制、8方向精灵反转、普攻(J)与技能(K)触发、翻滚(Space)无敌帧 |
| `rift_enemy.gd` | 敌人 AI | 寻路追踪玩家、自动攻击判定、受击浮空与血条控制 |
| `rift_projectile.gd` | 子弹投射 | 移动速度、伤害穿透、碰撞检测与消亡粒子 |
| `rift_hud.gd` | 战斗 UI | 血条/体力条渲染、击杀连击统计、CD 指示与急撤 |
| `rift_result_panel.gd` | 结算界面 | 提取 RiftRunManager 结束数据，渲染通关评级及经验奖励 |
| `rift_tile_select.gd` | 词缀选择 | 渲染 9 阶段的随机词缀战斗路线及按钮交互 |
| `rift_enemy_spawner.gd` | 刷怪调度 | 波次管理(Wave)、怪物池动态加载与对象池缓存 |
| `rift_run_manager.gd` | 进度单例 | 运行在 Autoload 下的关卡随机种子与进度持久化单例 |
| `rift_fx.gd` | 战斗特效 | 闪光、爆炸和受击粒子播放 |
| `rift_environment_manager.gd` | 战斗背景 | 动态绑定节点背景图并加载异常雨夜材质着色器 |
| `rift_entry_visual.gd` | 传送门特效 | 异常空间入口的黑洞/扭曲动画效果 |

### 4.5 宠物跟随脚本 (game/scripts/PET/)

| 文件 | 用途 | 关键功能 |
|------|------|----------|
| `pet_follow_base.gd` | 宠物基类 | 定义平滑插值跟随、随机待机动作行为树 |
| `fox.gd` / `frog.gd` / `eagle.gd` / `opossum.gd` | 宠物子类 | 实现四种宠物各自动作帧与独立特技动作(P) |

### 4.6 测试与自检脚本 (game/tests/ & tools/) ★

#### Godot Headless 验证脚本 (game/tests/)
共 23 个测试脚本，包含：
- `verify_assets.gd`：静态资源路径与导入合法性检测
- `verify_teleports.gd`：检测地下站台/异常空间等传送逻辑及连通性
- `verify_rift_entry.gd` / `verify_rift_data.gd` / `verify_rift_rewards.gd`：裂隙战斗数据正确性与奖励校验
- `verify_dialogue_director.gd` / `verify_all_dialogue_logic.gd`：分支对话流逻辑与 fallback 兜底正确性测试
- `verify_inventory_ui.gd` / `verify_equipment_system.gd`：背包系统及装备穿戴数据正确性校验

#### 资源与生成工具脚本 (tools/)
共 14 个 Python 脚本工具：
- `generate_characters.py`：利用 SD/DALL-E 生成 4 职业基础立绘与裁切
- `generate_walking.py`：处理 8 方向行走精灵图动画帧
- `generate_smooth_anim.py`：自动插值生成 12 帧平滑角色呼吸动画
- `generate_anime_style.py`：写实风格向二次元动漫风格 AI 转换工具
- `asset_preview_pipeline.py`：生成静态 HTML/图象预览网页便于快速验证游戏内资产
- `check_completion.py`：执行全项目资产完整性自检并生成分析报告
- `regenerate_all.py`：一键全资源重新渲染与编译管线
- `build_player_class_sprites.py`：整合玩家职业立绘及动画层
- `generate_class_posters.py` / `generate_npc_sprites.py` / `generate_shadow_idle.py`：用于特定职业与 NPC 特效及精灵生成的辅助工具


### 4.4 特效/脚本/PET — 同前

---

## 五、资产文件清单（EXPANDED）

### 5.1 背景图片 (assets/backgrounds/)
同前（12张 + 备用）

### 5.2 角色图片 (assets/characters/) — 大幅扩展

| 子目录 | 内容 | 数量 |
|--------|------|------|
| `player/` | 玩家精灵图（9个文件：4方向行走帧+idle+3形态参考图） | 保留 |
| `npcs/` | **NPC精灵图**（张三/李四/王五立绘 + 5人物展示封面 + ChatGPT生成移动动作 + 孙悦素材包） | **重构** |
| `avatars/` | **8个NPC头像**（赛博朋克风格） | 保留 |
| `select/` ★ | **4职业AI立绘**（cipher/chrome/echo/shadow） + 12帧平滑待机动画（写实+动漫双风格各48帧） | 保留 |
| `fox/frog/eagle/opossum/` | 4种宠物（狐狸含8种动画状态） | 保留 |

**NPC素材详情**：
- **立绘**：张三/李四/王五 PNG 静态图（根目录）
- **人物展示界面**：陈曦/赵霖/孙悦/刘风/何真 封面展示图（5张）
- **人物移动动作**：陈曦/赵霖/孙悦(×2)/刘风/何真 ChatGPT生成移动动作（6张）
- **孙悦**：独立素材包（q版本+移动与待机动作+海报）
- **陈曦**：目录已创建，待补充素材

### 5.3 着色器资源 (shaders/) — EXPANDED
| 文件 | 用途 |
|------|------|
| `grid_overlay.gdshader` ★ | 动态扫描网格线 GLSL 着色器（旧版赛博朋克效果） |
| `grid_overlay.tres` ★ | 着色器材质资源 |
| `city_network.gdshader` ★★ | **动态城市网络背景**（数据流粒子+网格线+网络节点+噪波，支持uniform颜色/时间参数） |
| `city_network.tres` ★★ | 城市网络着色器材质 |
| `scan_line.gdshader` ★★ | **CRT扫描线叠加**（全屏半透明扫描线+移动扫描光带） |
| `scan_line.tres` ★★ | 扫描线着色器材质 |
| `glitch.gdshader` ★★ | **故障/异常效果**（像素偏移+RGB通道分离+亮色横条，支持uniform强度参数） |
| `glitch.tres` ★★ | 故障着色器材质 |

**着色器位置**: `game/shaders/`（非assets子目录）

**着色器技术要点及性能优化**：
- `city_network.gdshader`：使用 `hash21` 伪随机函数生成网络节点位置，`sin/cos+time` 驱动节点浮动动画，向量投影法绘制节点连线。**（已优化）** node_count默认8→3，循环上限20+6→5+3，像素运算量降低80%+
- `scan_line.gdshader`：`pow(sin(), 8)` 生成极细扫描线，`fract(time*speed)` 驱动扫描光带
- `glitch.gdshader`：**（已重构）** 移除 `hint_screen_texture` + 3次全屏纹理采样（GL Compatibility下性能极差），改为纯色hash shift+scanline效果；颜色从紫色(0.6,0.1,0.9)改为青色(0.1,0.8,1.0)；`intensity=0` 时完全透明

### 5.4 音频/字体 — 同前

---

## 六、后端文件清单（EXPANDED）

### 6.1 Python 文件 (backend/) — 新增标注★

| 文件 | 用途 |
|------|------|
| `main.py` | FastAPI 主服务，**14个API端点**（原7+新增7） |
| `agents.py` | NPC Agent 系统，RAG记忆检索 |
| `config.py` | **LLM三提供商配置**(Groq/MiMo/DeepSeek) + **8个NPC配置**(含backstory+scene) |
| `hello_agents_llm.py` | **LLM三级降级封装**（Groq快→MiMo中→DeepSeek备）+ quality模式 |
| `vector_store.py` | ChromaDB向量存储 |
| `db_manager.py` | SQLite数据库 |
| `relationship_manager.py` | 好感度系统 |
| `state_manager.py` | NPC状态管理 |
| `batch_generator.py` | 批量对话生成 |
| `story_engine.py` ★ | **AI剧情引擎**（章节生成/NPC背景/对话分支/每日事件） |
| `models.py` | Pydantic数据模型 |
| `logger.py` | 日志系统 |

### 6.2 API 端点（EXPANDED: 7→17）

| 方法 | 路径 | 功能 | 状态 |
|------|------|------|------|
| GET | `/` | 欢迎信息 | ✅ |
| GET | `/health` | 后端健康检查与配置加载状态 | ✅ |
| GET | `/npcs/status` | 获取所有NPC状态 | ✅ |
| GET | `/npcs/batch_dialogue` | 批量对话 | ✅ |
| POST | `/dialogue` | 发送对话 | ✅ |
| GET | `/affinity/{npc_id}/{player_name}` | 获取好感度 | ✅ |
| GET | `/dialogue/history/{npc_id}` | 获取对话历史 | ✅ |
| GET | `/npcs/interactions` | NPC间互动 | ✅ |
| **POST** | **`/character/create`** | **创建角色（职业+名字）** | **★新增** |
| **GET** | **`/npcs/all`** | **获取全部NPC列表** | **★新增** |
| **POST** | **`/story/generate`** | **AI生成章节内容** | **★新增** |
| **GET** | **`/story/progress`** | **获取剧情进度** | **★新增** |
| **POST** | **`/generate/npc-story`** | **AI生成NPC背景故事** | **★新增** |
| **POST** | **`/generate/dialogue-branch`** | **AI生成对话分支** | **★新增** |
| **GET** | **`/generate/daily-events`** | **AI生成每日事件** | **★新增** |
| **GET** | **`/city/status`** | **获取当前城市状态数据 (天气、新闻、异常状态等)** | **★新增** |
| **GET** | **`/npc/relationship_map`** | **获取 NPC 间关系拓扑网络图数据** | **★新增** |

---

## 七、系统架构（UPDATED）

```
┌──────────────────────────────────────────────────────────┐
│                      Godot 前端                           │
│                                                          │
│  character_select.tscn ──→ apartment.tscn              │
│       (4职业选择)            │                          │
│       ├─ street.tscn ←→ main.tscn                   │
│       │                │                              │
│  ┌───── Autoload 单例层 ─────────────────────┐        │
│  │ APIClient     SceneManager                 │        │
│  │ DayNightMgr   AudioManager                  │        │
│  │ SaveManager    QuestManager                   │        │
│  │ GameManager    PetManager                     │        │
│  │ EnvManager    LogPanel                       │        │
│  │ FootstepGen   WorldCalendar                  │        │
│  │ DailyWorldGen  MediaManager                  │        │
│  │ UIThemeMgr    WeatherEffects                 │        │
│  │ CharClassMgr★  StoryManager★               │        │
│  └──────────────────────────────────────────────┘        │
│       │                                                  │
│  ┌───── UI 覆盖层 ────────────────────────────┐        │
│  │ dialogue_ui  quest_panel  log_panel         │        │
│  │ forum_ui  tv_overlay  balcony_overlay      │        │
│  │ talisman_overlay  sleep_overlay           │        │
│  │ interaction_prompt  ambient_bubble         │        │
│  │ character_panel★ (C键打开, 4标签页)      │        │
│  └──────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────┘
                         │ HTTP (localhost:8000)
                         ↓
┌──────────────────────────────────────────────────────────┐
│                Python 后端 (FastAPI)                      │
│                                                          │
│  main.py (14 endpoints)                               │
│    ├── agents.py → hello_agents_llm.py (3-tier)          │
│    │     ├── Groq (fast) → MiMo-Flash (mid) → DeepSeek  │
│    │     relationship_manager.py                      │
│    │                                              │
│    ├── story_engine.py ★ (AI剧情引擎)                │
│    │     └── MiMo-Pro (高质量) / Groq (快速)          │
│    │                                              │
│    ├── config.py (Groq + MiMo + DeepSeek)           │
│    ├── db_manager.py ←→ SQLite                        │
│    └── vector_store.py ←→ ChromaDB                    │
│                                                          │
│  数据层: SQLite + ChromaDB                             │
└──────────────────────────────────────────────────────────┘
```

**LLM调用策略**：
- **实时对话**（NPC聊天）：Groq (<500ms) → MiMo-Flash → DeepSeek
- **高质量创作**（剧情/背景）：MiMo-Pro → DeepSeek → Groq
- **批量生成**（世界事件）：MiMo-Flash → Groq → DeepSeek

---

## 八、碰撞层设计

| 层级 | 使用者 |
|------|--------|
| 层 1 | 玩家 (collision_layer=1) |
| 层 2 | 墙壁/建筑 StaticBody2D (collision_layer=2) |
| 层 4 | 宠物 (collision_layer=4) |

---

## 九、数据存储

| 存储 | 内容 |
|------|------|
| SQLite | 对话记忆、好感度关系 |
| ChromaDB | 语义向量索引 |
| JSON 存档 | 场景/位置/昼夜/任务/历法/游戏状态/**职业**/**剧情** |

---

## 十、项目目录结构（UPDATED）

```
赛博小镇/
├── .trae/
│   ├── rules/git-commit-message.md
│   └── specs/
├── PROJECT_DOC.md                           # 本文件
├── tools/                                   # 资源生成与自检工具目录
│   ├── generate_characters.py ★             # 角色立绘 AI 生成与裁剪
│   ├── generate_walking.py                  # 8方向行走动画生成
│   ├── generate_smooth_anim.py ★            # 12帧待机平滑动画生成
│   ├── generate_anime_style.py              # 二次元风格 AI 转换工具
│   ├── asset_preview_pipeline.py            # 资产 HTML/图象预览网页生成管线
│   ├── check_completion.py                  # 资产完整性自动化自检
│   └── regenerate_all.py                    # 一键重构生成所有资产
├── backend/
│   ├── main.py                              # 17 API端点
│   ├── agents.py
│   ├── config.py                            # 3 LLM + 8 NPC配置
│   ├── hello_agents_llm.py                  # 三级降级封装
│   ├── story_engine.py ★                    # AI剧情引擎
│   ├── vector_store.py
│   ├── db_manager.py
│   ├── relationship_manager.py
│   ├── state_manager.py
│   ├── batch_generator.py
│   ├── models.py
│   ├── logger.py
│   ├── data/
│   ├── .env
│   ├── requirements.txt
│   └── tests/                               # 后端测试目录 (test_npc_ai_quality.py)
└── game/
    ├── project.godot                          # 主场景=character_select
    ├── scenes/
    │   ├── character_select.tscn ★             # 主场景 (城市接入终端)
    │   ├── character_panel.tscn ★              # 角色面板 (C键打开)
    │   ├── apartment.tscn                      # 公寓场景 (含角色面板)
    │   ├── main.tscn                           # 办公室场景 (8 NPC + 角色面板)
    │   ├── street.tscn                         # 街区场景 (5 NPC + 角色面板)
    │   ├── underground.tscn                    # 地下站台场景
    │   ├── anomaly_space.tscn                  # 异常空间场景
    │   ├── rift_run.tscn ★                     # 裂隙战斗主关卡
    │   └── ... (其余22个场景)
    ├── scripts/
    │   ├── character_select.gd ★               # 角色选择（12帧动画+F5切换+纹理缓存）
    │   ├── character_panel.gd ★                 # 角色面板
    │   ├── character_class_manager.gd ★         # 职业管理
    │   ├── story_manager.gd ★                   # 剧情管理
    │   ├── dialogue_director.gd ★               # 对话与 Fallback 管理
    │   ├── game_manager.gd                       # (6维属性+等级+货币)
    │   ├── quest_manager.gd                     # (20任务+STORY)
    │   ├── save_manager.gd                       # (含职业+剧情存档)
    │   ├── npc.gd                                # (8 NPC display_name)
    │   ├── rift/                                # 裂隙打怪战斗系统逻辑目录 (12个脚本)
    │   │   ├── rift_run.gd                      # 战斗主循环
    │   │   ├── rift_player_combat.gd            # 玩家战斗控制
    │   │   └── ...
    │   ├── PET/                                 # 宠物跟随与行为逻辑 (5个脚本)
    │   └── ... (其余44个.gd)
    ├── assets/
    │   ├── characters/
    │   │   ├── select/ ★                        # 12帧待机动画(idle+anime双风格各48帧，共96帧)
    │   │   ├── npcs/                            # NPC精灵图（张三/李四/王五立绘 + 展示与动作帧）
    │   │   └── avatars/                         # 8 NPC头像
    │   ├── backgrounds/
    │   ├── audio/
    │   ├── fonts/
    │   └── media/
    ├── shaders/                                 # 着色器目录（已优化，像素运算↓80%+）
    │   ├── grid_overlay.gdshader ★            # 扫描网格着色器（旧版）
    │   ├── grid_overlay.tres ★
    │   ├── city_network.gdshader ★★          # 动态城市网络背景
    │   ├── city_network.tres ★★
    │   ├── scan_line.gdshader ★★             # CRT扫描线
    │   ├── scan_line.tres ★★
    │   ├── glitch.gdshader ★★                # 故障/异常效果
    │   └── glitch.tres ★★
    └── tests/                                   # 23 个 Godot Headless 验证脚本
        ├── verify_assets.gd
        └── ...
```

---

## 十一、历法体系

同前（5月×36天，6天/周，N.H.207纪元）

---

## 十二、开发路线图（UPDATED）

### Phase 1 ✅ 已完成
- ✅ 媒体图片系统 + 历法 + Bug修复
- ✅ 多源实时媒体 + 天气视觉 + 过场动画
- ✅ UI设计优化 + 项目清理
- ✅ **小米MiMo API集成（14亿TOKEN，三级降级）**
- ✅ **NPC扩展 3→8（陈曦/赵霖/孙悦/刘风/何真）**
- ✅ **角色选择系统（4职业 + 赛博朋克UI + 网格着色器）**
- ✅ **NEO HARBOR城市接入终端重构**（三栏身份档案布局 + 动态城市网络背景 + CRT扫描线 + 异常信号系统 + 城市信息流 + 3新着色器）
- ✅ **角色面板UI（C键 4标签页）**
- ✅ **角色职业系统（CharacterClassManager + 33技能）**
- ✅ **主线剧情系统（StoryManager + 5章维度裂缝）**
- ✅ **GameManager扩展（6维属性 + 等级 + 货币）**
- ✅ **QuestManager扩展（STORY类型 + EXP/异常奖励，20个任务）**
- ✅ **SaveManager扩展（职业+剧情数据持久化）**
- ✅ **后端API扩展（7新端点 + story_engine）**
- ✅ **UI视觉升级（赛博朋克风格 + 动画效果 + 响应式布局）**
- ✅ **Runtime错误修复（着色器引用/tween冲突/null安全）**
- ✅ **4职业独立精灵图生成（色彩区分 + 统一风格）**
- ✅ **12帧平滑待机动画重构**（4帧→12帧，0.12秒/帧，AI生成固定seed，呼吸/光效/粒子循环动画）
- ✅ **F5双视觉风格切换系统**（写实赛博 ↔ 二次元动漫，96帧，<0.1秒切换）
- ✅ **纹理缓存系统**（`_texture_cache` Dictionary，零重复加载开销）
- ✅ **Shader性能优化**（city_network像素运算↓80%+，glitch去全屏纹理采样+换青色）
- ✅ **运行时性能优化**（NPC距离剔除、Autoload引用缓存、_process更新频率门控）
- ✅ **布局修复**（CharacterDisplay 300→220px，间距10→6）
- ✅ **异常系统参数调优**（触发间隔15-25→30-45秒，intensity 0.6→0.3）
- ✅ **全项目Headless零错误验证**（60秒运行，exit code=0）

### Phase 2 — 已实现与待完成
- ✅ **背包UI**（character_panel背包标签页重写，物品卡片式UI，稀有度颜色系统，20种预定义物品）
- ✅ **世界地图与传送系统**（地下站台与异常空间双向传送、空气墙，并在全景地图 UI 完美呈现 NPC 所在地与连通关系）
- ✅ **裂隙打怪战斗系统**（完整的 2D 裂隙战斗玩法，包含刷怪管理、玩家招式/技能判定、血条子弹 HUD、子弹轨迹与结算奖励面板）
- 🔄 **NPC精灵图补充**（陈曦/赵霖/孙悦/刘风/何真待生成）
- ⬜ 商店系统（义体商店/黑市/咖啡店）
- ⬜ 手机系统（消息/任务/地图/通讯）

### Phase 3-6 — 未来
- NPC关系深化 + 日程系统
- 装备系统 + 图鉴系统
- 地下城（维度裂缝副本）+ 多结局
- 房屋装饰 + 小游戏 + 社交功能

---

## 十三、API密钥与外部服务（UPDATED）

| 服务 | 密钥/凭证 | 用途 | 状态 | TOKEN预算 |
|------|-----------|------|------|-----------|
| Unsplash API | ***已隐藏*** | 真实照片搜索 | ✅已集成 | Demo 50/h |
| Pollinations.ai | 无需密钥 | AI图片生成 | ✅已集成 | 无限制 |
| **小米MiMo API** | ***已隐藏*** | **主力LLM/内容生成** | **✅已集成** | **14亿TOKEN** |
| **Groq API** | ***已隐藏*** | **快速对话LLM(优先)** | **✅已集成** | 按Groq限制 |
| **DeepSeek API** | ***已隐藏*** | **备用LLM/深度推理** | **✅已集成** | 按DS限制 |

**LLM分配策略**：
- NPC实时对话：Groq（<500ms）优先
- 剧情/背景创作：MiMo-Pro 高质量
- 批量世界内容：MiMo-Flash 低成本
- 全部不可用：DeepSeek 兜底

---

## 十四、开发规范提示词（UPDATED）

```
你是一个Godot 4.6游戏开发专家，正在维护一个名为"新港·207(Neo Harbor 207)"的2D赛博朋克风格AI小镇社交游戏。
## 项目基本信息
- 游戏引擎: Godot 4.6 (GL Compatibility渲染器)
- 前端语言: GDScript
- 后端语言: Python (FastAPI)
- 分辨率: 1280×720
- 项目路径: /Users/xieqing/Desktop/后期/ai agent/赛博小镇
- 游戏主目录: game/
- 后端目录: backend/

## 核心架构
游戏采用Autoload单例层架构，当前注册的Autoload包括：
Config, APIClient, DialogueDirector, LogPanel, AudioManager, DayNightManager, FootstepGenerator, SaveManager, QuestManager, SceneManager, EnvironmentManager, GameManager, PetManager, UIThemeManager, QuestTrackerHUD, WorldCalendar, MediaManager, DailyWorldGenerator, WeatherEffects, CharacterClassManager, StoryManager, RiftRunManager

## 已完成功能（全面更新版）
- 角色选择系统（4职业：CIPHER/CHROME/ECHO/SHADOW，NEO HARBOR城市接入终端，三栏身份档案布局，动态城市网络背景+CRT扫描线+异常信号系统+城市信息流，3新着色器city_network/scan_line/glitch）
- 8个AI NPC（原3+新5：陈曦/赵霖/孙悦/刘风/何真，各有背景故事）
- 4时段昼夜系统 + 动态UI主题切换
- LLM三级降级对话（Groq→MiMo→DeepSeek，14亿TOKEN小米API）
- **20个任务**（6种类型含STORY剧情任务）
- 好感度5级系统 + 4种宠物跟随
- 多源媒体图片 + 5种天气 + 世界历法(N.H.207)
- 角色成长系统（6维属性/等级/货币/33技能树）
- 主线剧情5章"维度裂缝"
- 角色面板（C键，属性/技能/背包/剧情4标签页）
- 存档系统（含职业+剧情数据）
- 世界地图与传送系统（双向传送、空气墙、连通拓扑图、NPC 实时定位）
- 裂隙打怪战斗系统（2D 动作关卡、词缀选路、怪物波次与对象池、普攻/技能/翻滚无敌帧、战斗 HUD、结算系统、120 FPS 优化）
- 后端17个API端点 + AI剧情引擎

## 当前脚本清单（61个.gd + 23个测试脚本）
核心: config/player/npc/apartment/main/street/character_select/character_panel/character_class_manager/story_manager/dialogue_director/special_scene/map_panel/quest_tracker_hud/dialogue_ui
系统单例(22): Config/APIClient/DialogueDirector/LogPanel/AudioManager/DayNightManager/FootstepGenerator/SaveManager/QuestManager/SceneManager/EnvironmentManager/GameManager/PetManager/UIThemeManager/QuestTrackerHUD/WorldCalendar/MediaManager/DailyWorldGenerator/WeatherEffects/CharacterClassManager/StoryManager/RiftRunManager
UI/特效: dialogue_ui/interaction_prompt/quest_panel/forum_ui/forum_data/tv_overlay/balcony_overlay/talisman_overlay/sleep_overlay/ambient_bubble/character_panel/rain_night_effects/apartment_effects/apartment_ambient/underground_ambient
宠物: fox/opossum/eagle/frog/pet_follow_base
战斗(12): rift_run/rift_player_combat/rift_enemy/rift_projectile/rift_hud/rift_result_panel/rift_tile_select/rift_enemy_spawner/rift_run_manager/rift_fx/rift_environment_manager/rift_entry_visual

## 开发规范
1. 修改代码前先读取文件，理解上下文
2. 每次修改后验证无报错再交付
3. 不添加代码注释（除非明确要求）
4. 不创建新文件（除非绝对必要）
5. 遵循现有代码风格和命名约定
6. 所有UI颜色从UIThemeManager获取，不硬编码
7. has_node检查Autoload存在性
8. 不要覆盖内置方法
```

---

## 十五、技术改进和Bug修复历史（NEW）

### 15.1 UI视觉升级 (2024-05)
- **赛博朋克风格重构**：角色选择界面完全重新设计
  - 深色背景 + 动态扫描网格线着色器
  - 霓虹色彩系（青/橙/粉/绿对应4职业）
  - 卡片悬停/选中动画效果
  - 0.8秒入场淡入 + 0.4秒确认淡出过渡
- **响应式布局优化**：
  - 卡片自适应窗口大小
  - 键盘导航支持（←→切换，Enter确认）
  - 详情面板实时更新

### 15.2 NEO HARBOR 城市接入终端重构 (2026-05)
- **完全重构**：从"传统RPG职业卡片选择"改为"城市身份档案接入终端"
- **三栏终端布局**：左栏(身份档案) + 中栏(扫描区域) + 右栏(网络数据)
- **3个新着色器**：city_network(动态城市网络背景)、scan_line(CRT扫描线)、glitch(故障/异常效果)
- **7大动态系统**：状态文字循环、城市网络背景、CRT扫描线、异常信号、城市信息流、职业色调过渡、属性条增长动画
- **身份档案格式**：每个职业有独特身份类型/居住区域/精神适配率/异常接触等级/城市信用等级/网络活动状态

### 15.3 Runtime错误修复 (2024-05 → 2026-05)

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 着色器UID引用错误 | .tres/.tscn中硬编码UID | 移除硬编码引用，让Godot自动管理 |
| _on_card_unhover逻辑错误 | 缺少index参数 | 修改函数签名接收index参数 |
| Tween闭包变量捕获 | 回调中引用循环变量 | 移除tween回调，直接设置样式 |
| Tween动画冲突 | 多个tween同时运行 | 创建新tween前kill旧实例 |
| Sprite容器重复添加 | 条件判断逻辑错误 | 修正条件检查逻辑 |
| Null安全异常 | 未检查节点存在性 | 添加has_node/null检查 |
| .tscn Unicode解析错误 | Godot 4场景解析器不支持\uXXXX转义 | 将.tscn中所有Unicode字符替换为ASCII安全文本 |
| SCREEN_TEXTURE已废弃 | Godot 4.6移除内置SCREEN_TEXTURE | 改用 `uniform sampler2D : hint_screen_texture` |
| fragment()中return语句 | Godot 4着色器fragment()不允许return | 改用step()乘法控制输出透明度 |

### 15.3 资源生成 (2024-05)
- **4职业独立精灵图**：为每个职业生成独特的角色预览图
  - CIPHER：青色调（数据/科技感）
  - CHROME：橙色调（战斗/力量感）
  - ECHO：粉色调（灵能/神秘感）
  - SHADOW：绿色调（潜行/敏捷感）
- **统一美术风格**：所有新NPC精灵图保持一致的像素风格

### 15.4 性能优化 (2024-05)
- **LLM调用优化**：三级降级策略确保服务可用性
  - Groq（<500ms）用于实时对话
  - MiMo-Flash用于批量生成
  - MiMo-Pro用于高质量创作
  - DeepSeek作为最终兜底
- **缓存策略**：批量对话5分钟刷新缓存
- **离线降级**：媒体图片系统支持本地fallback

### 15.5 UI 全面自检与彻底重构（2026-05-05）

#### 任务面板完全重写
- **原问题**：按Q键打开任务面板只有一瞬间清楚，随后变模糊（StyleBoxFlat共享篡改+动态创建节点导致渲染缓存失效）
- **解决方案**：彻底删除旧实现，采用**静态场景+对象池**架构重写
  - `quest_panel.tscn`：预创建10个固定卡片槽位(CardSlot0-9)，一次性初始化所有样式实例
  - `quest_panel.gd`（609行）：`_update_card_data()`替代`_create_quest_card()`，只更新数据不新建节点
  - 样式统一从UIThemeManager获取，确保日夜主题一致
  - 移除所有动态StyleBoxFlat创建，零运行时节点创建/销毁
  - 过滤功能（全部/对话/探索/收集/日常）通过5个预创建按钮实现

#### 登录界面全面修复
- **小狐狸 + 日志L按钮根因**：PetManager和LogPanel都是Autoload，在所有场景中生效，包括登录界面
- **修复方案**：
  - `pet_manager.gd`：添加`_is_on_login_scene()`检测，登录场景跳过宠物生成、忽略Tab/P键
  - `log_panel.gd`：添加`_is_on_login_scene()`检测，登录场景隐藏L按钮、忽略L键

#### 字体重叠修复
- `character_select.tscn`：
  - HeaderArea separation: 2 → 8（解决标题区字体重叠）
  - CenterContent separation: 添加为12（解决中央区域间距不足）
  - RightContent separation: 添加为8（解决右侧区域间距不足）

#### ClassTrait 重新搭建
- 删除旧的 KeywordsBox 蓝色链接标签（重叠问题根因）
- 全新搭建 ClassTrait 组件（HBoxContainer）：
  - TraitBar（3×18px 彩色竖条）+ TraitLabel（"> CIPHER // 数据透视" 格式）
  - 每个职业随选中自动切换对应颜色：CIPHER(青)/CHROME(橙)/ECHO(粉紫)/SHADOW(绿)

#### API修复
- `quest_panel.gd`：14处 `set_theme_stylebox_override()` → `add_theme_stylebox_override()`（Godot 4正确API）

### 15.6 8方向移动与NPC身份映射修复（2026-05-05）

#### 8方向移动动作补全
- **原问题**：主角/NPC对角线移动时视觉无区别（左下=右下=下，左上=右上=上）
- **解决方案**：通过代码实现水平翻转模拟对角线方向
  - `player.gd`：`down_left`/`up_left` 添加 `flip_h = true`，复用down/up帧实现左下/左上视觉效果
  - `npc.gd`：扩展8方向检测逻辑，对角线方向自动计算并应用翻转

#### NPC对话"张三化"修复
- **根因**：`api_client.gd` 的 `_npc_personas` 字典只有3个NPC，新NPC全部回退到张三身份
- **解决方案**：
  - `api_client.gd`：扩展 `_npc_personas` 从3个→8个，包含陈曦、赵霖、孙悦、刘风、何真的独立身份配置
  - 改进 `system_prompt`：添加新港·207世界观背景和严格身份约束
  - `dialogue_ui.gd`：扩展 `name_map`/`title_map`/`avatar_map`/`npc_color_map` 覆盖全部8个NPC
  - 新增 `_generate_placeholder_avatar()`：缺失头像时自动生成带职业主题色的彩色边框占位图

#### NPC性格配置（8人完整）

| NPC ID | 姓名 | 职业 | 性格特点 | 回复风格 |
|--------|------|------|----------|----------|
| zhang_san | 张三 | Python工程师 | 严谨专业，注重代码质量 | 技术化，代码比喻 |
| li_si | 李四 | 产品经理 | 外向沟通，用户导向 | 亲切，用户视角 |
| wang_wu | 王五 | UI设计师 | 温和创意，审美独特 | 文艺，设计感 |
| chen_xi | 陈曦 | 咖啡店老板 | 神秘博学，话中有话 | 诗意朦胧，隐喻哲学 |
| zhao_lin | 赵霖 | 黑市信息贩子 | 狡猾精明，见钱眼开 | 神秘暗示，交易邀约 |
| sun_yue | 孙悦 | 异常现象研究员 | 理性偏执，痴迷异常 | 学术术语，数据驱动 |
| liu_feng | 刘风 | 赛博义体技师 | 粗犷直爽，技术宅 | 豪爽直接，技术黑话 |
| he_zhen | 何真 | AI系统管理员 | 冷静逻辑，偶尔失控 | 程序化表达，偶尔失序 |

---

**文档最后更新**: 2026-06-20
**项目版本**: v2.0.0
**本次更新内容**:
- **世界地图与传送系统**：实现地下站台与异常空间双向传送、空气墙，并在全景地图 UI 完美呈现 NPC 所在地与连通关系。
- **裂隙打怪战斗系统**：完整的 2D 裂隙战斗玩法（刷怪管理、玩家招式/技能判定、血条子弹 HUD、子弹轨迹与结算奖励面板）。
**下次更新计划**: NPC精灵图补充、商店系统（义体商店/黑市/咖啡店）、手机系统
