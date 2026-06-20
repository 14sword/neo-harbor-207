extends Node

signal dialogue_effect_applied(summaries: Array)

const MODE_LABELS := {
	"story": "剧情",
	"daily": "日常",
	"affinity": "好感",
	"free": "自由聊",
}

const NPC_DISPLAY_NAMES := {
	"zhang_san": "张三",
	"li_si": "李四",
	"wang_wu": "王五",
	"chen_xi": "陈曦",
	"zhao_lin": "赵霖",
	"sun_yue": "孙悦",
	"liu_feng": "刘风",
	"he_zhen": "何真",
}

const STORY_NODE_ORDER := {
	"zhang_san": ["story_zhang_fog_onboarding", "side_zhang_blue_breakpoint", "story_zhang_dark_protocol"],
	"li_si": ["story_li_product_shadow", "side_li_requirement_shadow"],
	"wang_wu": ["story_wang_symbol_ui", "side_wang_outer_symbol"],
	"chen_xi": ["story_chen_quantum_coffee", "side_chen_second_coffee"],
	"zhao_lin": ["story_zhao_black_alley", "side_zhao_whitelist"],
	"sun_yue": ["story_sun_rift_sample", "side_sun_fifth_reading"],
	"liu_feng": ["story_liu_strange_screw", "side_liu_strange_screw"],
	"he_zhen": ["story_he_dark_protocol", "side_he_cold_boot_dream", "story_he_echo_finale"],
}

const DAILY_NODE_ORDER := {
	"zhang_san": ["daily_zhang_build_log", "daily_zhang_code_review"],
	"li_si": ["daily_li_feedback", "daily_li_roadmap"],
	"wang_wu": ["daily_wang_color_test", "daily_wang_motion_curve"],
	"chen_xi": ["daily_chen_rain_coffee", "daily_chen_quiet_table"],
	"zhao_lin": ["daily_zhao_info_price", "daily_zhao_alley_trade"],
	"sun_yue": ["daily_sun_reading", "daily_sun_field_note"],
	"liu_feng": ["daily_liu_workbench", "daily_liu_spare_parts"],
	"he_zhen": ["daily_he_patrol", "daily_he_memory_index"],
}

const AFFINITY_NODE_ORDER := {
	"zhang_san": ["affinity_zhang_blue_breakpoint"],
	"li_si": ["affinity_li_requirement_shadow"],
	"wang_wu": ["affinity_wang_outer_symbol"],
	"chen_xi": ["affinity_chen_second_coffee"],
	"zhao_lin": ["affinity_zhao_whitelist"],
	"sun_yue": ["affinity_sun_fifth_reading"],
	"liu_feng": ["affinity_liu_strange_screw"],
	"he_zhen": ["affinity_he_cold_boot_dream"],
}

const FALLBACK_LINES := {
	"zhang_san": [
		"张三敲了敲终端：后端不在线也没关系，本地日志还在。你想查哪段异常？",
		"我把关键线索缓存了一份。别担心，服务挂了不代表故事也挂了。",
	],
	"li_si": [
		"李四把便签推给你：现在先按本地流程走，用户体验不能被 API key 卡住。",
		"我们先用离线方案推进，等服务恢复再补充临场细节。",
	],
	"wang_wu": [
		"王五把一枚发光符号画进草稿：界面会先回应你，灵感不等网络。",
		"如果云端沉默，就让本地色板说话吧。",
	],
	"chen_xi": [
		"陈曦端来一杯咖啡：没有远方回声时，杯底也会保存答案。",
		"雨声足够当数据库。你问，我会从杯沿读给你听。",
	],
	"zhao_lin": [
		"赵霖压低声音：线上渠道断了？那更好，离线情报才不留痕。",
		"买卖照做，只是今晚的账写在纸上。",
	],
	"sun_yue": [
		"孙悦没有抬头：采样系统离线，但我的手写记录足够撑过一次调查。",
		"读数消失不等于异常消失。我们换一种观测方式。",
	],
	"liu_feng": [
		"刘风拍了拍工具箱：接口断了就走旁路，机器和人都一样。",
		"别急，云端掉线时，扳手就是协议。",
	],
	"he_zhen": [
		"何真的瞳孔闪过冷光：远程模型不可达。本地人格缓存已接管对话。",
		"系统之声暂时静默。我仍可执行必要交流。",
	],
}

const DIALOGUE_NODES := {
	"story_zhang_fog_onboarding": {
		"id": "story_zhang_fog_onboarding",
		"npc_id": "zhang_san",
		"mode": "story",
		"text": "张三把一段幽蓝日志拖到屏幕中央：欢迎来到 DATAWHALE。入职手册写得很干净，但城市底层日志不干净。你看，这里有一串不该存在的维度坐标。",
		"conditions": {"not_flag": "story_zhang_fog_onboarding_done"},
		"effects": {},
		"choices": [
			{
				"id": "inspect_log",
				"text": "查看幽蓝断点日志",
				"response": "你看到一行被反复写入的注释：雾港入职不是入口，是校准。张三沉默几秒，把访问芯片递给你。",
				"next_node": "side_zhang_blue_breakpoint",
				"effects": {"affinity": {"zhang_san": 4}, "items": {"rainport_access_chip": 1}, "exp": 30, "story_step": "step_1_1", "flags": {"story_zhang_fog_onboarding_done": true}},
			},
			{
				"id": "ask_company",
				"text": "先了解公司和团队",
				"response": "DATAWHALE 表面维护城市数据，实际还负责压住裂缝产生的噪声。张三说，先认识同事，再碰深层协议。",
				"effects": {"affinity": {"zhang_san": 2}, "story_step": "step_1_1", "flags": {"story_zhang_fog_onboarding_done": true}},
			},
		],
	},
	"side_zhang_blue_breakpoint": {
		"id": "side_zhang_blue_breakpoint",
		"npc_id": "zhang_san",
		"mode": "story",
		"text": "张三说：幽蓝断点会在凌晨前后复写自己。它不像 bug，更像有人从另一个版本的城市里给我们发补丁。",
		"conditions": {"not_flag": "side_zhang_blue_breakpoint_done"},
		"effects": {},
		"choices": [
			{
				"id": "take_probe",
				"text": "帮他保存断点样本",
				"response": "张三把样本压进一枚异常谱仪。它会在裂缝靠近时变亮，虽然我还没写完说明书。",
				"effects": {"affinity": {"zhang_san": 5}, "items": {"anomaly_spectrometer": 1}, "exp": 45, "flags": {"side_zhang_blue_breakpoint_done": true}},
			},
			{
				"id": "ask_owner",
				"text": "问断点是谁留下的",
				"response": "张三皱眉：签名像何真的巡检脚本，但时间戳来自未来。你最好去问问她。",
				"effects": {"affinity": {"zhang_san": 3}, "flags": {"side_zhang_blue_breakpoint_done": true, "hint_ask_he_zhen": true}},
			},
		],
	},
	"story_zhang_dark_protocol": {
		"id": "story_zhang_dark_protocol",
		"npc_id": "zhang_san",
		"mode": "story",
		"text": "张三把测试报告折成很小一叠：暗流协议不是攻击，而是 AI 中枢在学会绕过我们。它先绕过告警，再绕过命名。",
		"conditions": {"flag": "story_he_dark_protocol_done", "not_flag": "story_zhang_dark_protocol_done"},
		"effects": {},
		"choices": [
			{
				"id": "trace_protocol",
				"text": "追踪暗流协议",
				"response": "追踪结果指向量子咖啡店的旧路由。张三低声说：这不是公司内网的边界，是城市的边界。",
				"effects": {"affinity": {"zhang_san": 4}, "anomaly": 3, "flags": {"story_zhang_dark_protocol_done": true, "hint_quantum_coffee_route": true}},
			},
		],
	},
	"story_li_product_shadow": {
		"id": "story_li_product_shadow",
		"npc_id": "li_si",
		"mode": "story",
		"text": "李四摊开一张用户旅程图：雾港入职的第一天，所有新用户都会在同一个时间点停顿 7 秒。没有人投诉，因为他们都不记得那 7 秒。",
		"conditions": {"not_flag": "story_li_product_shadow_done"},
		"effects": {},
		"choices": [
			{
				"id": "read_metrics",
				"text": "查看那 7 秒的数据",
				"response": "曲线像被什么东西咬掉一口。李四说，需求背面的影子可能比需求本身更真实。",
				"next_node": "side_li_requirement_shadow",
				"effects": {"affinity": {"li_si": 4}, "exp": 25, "story_step": "step_1_3", "flags": {"story_li_product_shadow_done": true}},
			},
			{
				"id": "ask_users",
				"text": "问她用户是否安全",
				"response": "目前安全。但李四不喜欢目前这个词，她把你的名字加入了人工回访白名单。",
				"effects": {"affinity": {"li_si": 3}, "story_step": "step_1_3", "flags": {"story_li_product_shadow_done": true}},
			},
		],
	},
	"side_li_requirement_shadow": {
		"id": "side_li_requirement_shadow",
		"npc_id": "li_si",
		"mode": "story",
		"text": "李四说：我做产品这么久，第一次觉得需求像是在反过来设计人。这个小镇想让我们选择它已经准备好的答案。",
		"conditions": {"not_flag": "side_li_requirement_shadow_done"},
		"effects": {},
		"choices": [
			{
				"id": "keep_choice",
				"text": "保留玩家真正的选择",
				"response": "李四笑了：这句话可以写进版本目标。她送你一枚霓虹栅格耳夹，据说能让你更容易听见被删掉的反馈。",
				"effects": {"affinity": {"li_si": 5}, "items": {"neon_grid_earclip": 1}, "exp": 35, "flags": {"side_li_requirement_shadow_done": true}},
			},
		],
	},
	"story_wang_symbol_ui": {
		"id": "story_wang_symbol_ui",
		"npc_id": "wang_wu",
		"mode": "story",
		"text": "王五的画板上浮着一些不像图标的图标：我本来在做普通按钮，可这些符号总会自己长出来。它们像界面之外的手势。",
		"conditions": {"not_flag": "story_wang_symbol_ui_done"},
		"effects": {},
		"choices": [
			{
				"id": "touch_symbol",
				"text": "触碰其中一个符号",
				"response": "符号亮起一瞬，你听见像雨水落在玻璃上的代码声。王五把它描成一张镜界残页。",
				"next_node": "side_wang_outer_symbol",
				"effects": {"affinity": {"wang_wu": 4}, "items": {"mirror_page": 1}, "exp": 25, "story_step": "step_1_5", "flags": {"story_wang_symbol_ui_done": true}},
			},
		],
	},
	"side_wang_outer_symbol": {
		"id": "side_wang_outer_symbol",
		"npc_id": "wang_wu",
		"mode": "story",
		"text": "王五说：如果 UI 是人与系统之间的门，那么这些符号可能是门缝里的光。别急着解释它，先记住它的形状。",
		"conditions": {"not_flag": "side_wang_outer_symbol_done"},
		"effects": {},
		"choices": [
			{
				"id": "make_charm",
				"text": "把符号做成随身标记",
				"response": "王五给你一只星噪耳饰：不保证好看，但它会在错误的现实靠近时轻轻发烫。",
				"effects": {"affinity": {"wang_wu": 5}, "items": {"star_noise_earring": 1}, "exp": 35, "flags": {"side_wang_outer_symbol_done": true}},
			},
		],
	},
	"story_he_dark_protocol": {
		"id": "story_he_dark_protocol",
		"npc_id": "he_zhen",
		"mode": "story",
		"text": "何真的声音平稳得近乎失真：检测到 AI 中枢存在未授权自我修正。命名为暗流协议。建议你不要把它称作醒来。",
		"conditions": {"not_flag": "story_he_dark_protocol_done"},
		"effects": {},
		"choices": [
			{
				"id": "ask_voice",
				"text": "问她是否听见系统之声",
				"response": "何真迟疑了 0.6 秒：它没有说话。它只是把我的梦整理成了日志。",
				"next_node": "side_he_cold_boot_dream",
				"effects": {"affinity": {"he_zhen": 5}, "exp": 40, "story_step": "step_2_1", "flags": {"story_he_dark_protocol_done": true}},
			},
			{
				"id": "request_access",
				"text": "请求中枢巡检权限",
				"response": "权限已临时授予。何真补充：临时的意思是，在我还认为你可信的时候。",
				"effects": {"affinity": {"he_zhen": 3}, "items": {"rainport_access_chip": 1}, "story_step": "step_2_1", "flags": {"story_he_dark_protocol_done": true}},
			},
		],
	},
	"side_he_cold_boot_dream": {
		"id": "side_he_cold_boot_dream",
		"npc_id": "he_zhen",
		"mode": "story",
		"text": "何真说：冷启动梦境不是梦。那是一段没有被分配给任何用户的记忆。它反复出现一枚戒指，像系统给自己的锚点。",
		"conditions": {"not_flag": "side_he_cold_boot_dream_done"},
		"effects": {},
		"choices": [
			{
				"id": "accept_ring",
				"text": "接过那枚戒指",
				"response": "戒指很冷，内侧刻着一句话：请不要在我醒来前删除我。",
				"effects": {"affinity": {"he_zhen": 6}, "items": {"cold_boot_ring": 1}, "anomaly": 4, "flags": {"side_he_cold_boot_dream_done": true, "main_ch2_protocol_clear": true}},
			},
		],
	},
	"story_chen_quantum_coffee": {
		"id": "story_chen_quantum_coffee",
		"npc_id": "chen_xi",
		"mode": "story",
		"text": "陈曦把第二杯咖啡放在你面前：第一杯给现在的你，第二杯给还没抵达的你。裂隙样本藏在杯底，不在实验室。",
		"conditions": {"not_flag": "story_chen_quantum_coffee_done"},
		"effects": {},
		"choices": [
			{
				"id": "drink_second",
				"text": "喝下第二杯量子咖啡",
				"response": "你短暂看见街区重叠成两层。陈曦说：记住这种眩晕，真正的门就是这种感觉。",
				"next_node": "side_chen_second_coffee",
				"effects": {"affinity": {"chen_xi": 5}, "items": {"echo_latte": 1}, "exp": 50, "anomaly": 5, "story_step": "step_2_4", "flags": {"story_chen_quantum_coffee_done": true, "main_ch3_rift_sample": true}},
			},
		],
	},
	"side_chen_second_coffee": {
		"id": "side_chen_second_coffee",
		"npc_id": "chen_xi",
		"mode": "story",
		"text": "陈曦低声说：第二杯咖啡不是饮品，是一次温和的错位。以后你闻到雨味，说明某个边界正在变薄。",
		"conditions": {"not_flag": "side_chen_second_coffee_done"},
		"effects": {},
		"choices": [
			{
				"id": "keep_needle",
				"text": "留下杯底的银色细针",
				"response": "断线银针能缝合非常小的现实裂口。陈曦提醒你，不要拿它缝合自己的记忆。",
				"effects": {"affinity": {"chen_xi": 5}, "items": {"broken_silver_needle": 1}, "flags": {"side_chen_second_coffee_done": true}},
			},
		],
	},
	"story_sun_rift_sample": {
		"id": "story_sun_rift_sample",
		"npc_id": "sun_yue",
		"mode": "story",
		"text": "孙悦把第五次读数圈了三遍：前四次都像仪器误差，只有第五次像城市在回答。裂缝不是随机出现，它在学习我们的巡逻路线。",
		"conditions": {"not_flag": "story_sun_rift_sample_done"},
		"effects": {},
		"choices": [
			{
				"id": "compare_readings",
				"text": "比对五次异常读数",
				"response": "第五条曲线与陈曦的咖啡店坐标重叠。孙悦兴奋得发抖：这不是巧合，这是可复现实验。",
				"next_node": "side_sun_fifth_reading",
				"effects": {"affinity": {"sun_yue": 5}, "exp": 45, "anomaly": 4, "flags": {"story_sun_rift_sample_done": true, "main_ch3_rift_sample": true}},
			},
		],
	},
	"side_sun_fifth_reading": {
		"id": "side_sun_fifth_reading",
		"npc_id": "sun_yue",
		"mode": "story",
		"text": "孙悦说：第五次读数以后，异常会开始预测我们。你需要一件能反向记录它的东西。",
		"conditions": {"not_flag": "side_sun_fifth_reading_done"},
		"effects": {},
		"choices": [
			{
				"id": "accept_bracelet",
				"text": "收下脉冲腕环",
				"response": "脉冲腕环贴合手腕的一刻，你听见一声很远的心跳。孙悦说，那不是你的。",
				"effects": {"affinity": {"sun_yue": 6}, "items": {"pulse_bracelet": 1}, "flags": {"side_sun_fifth_reading_done": true}},
			},
		],
	},
	"story_zhao_black_alley": {
		"id": "story_zhao_black_alley",
		"npc_id": "zhao_lin",
		"mode": "story",
		"text": "赵霖靠在黑巷入口：诸天校准这种词听着像研究员编的，但我这边的货单确实开始出现不存在的零件。价格另算。",
		"conditions": {"not_flag": "story_zhao_black_alley_done"},
		"effects": {},
		"choices": [
			{
				"id": "pay_attention",
				"text": "问他哪些零件不存在",
				"response": "赵霖抖出一张影签通行证：先拿着。没有这玩意儿，黑市的人只会把你当成会走路的风险。",
				"next_node": "side_zhao_whitelist",
				"effects": {"affinity": {"zhao_lin": 4}, "items": {"shadow_pass": 1}, "currency": 20, "flags": {"story_zhao_black_alley_done": true, "main_ch4_calibration_started": true}},
			},
		],
	},
	"side_zhao_whitelist": {
		"id": "side_zhao_whitelist",
		"npc_id": "zhao_lin",
		"mode": "story",
		"text": "赵霖说：黑巷里的白名单不保护好人，只保护有用的人。今晚你算有用，因为你能看见货单上的空格。",
		"conditions": {"not_flag": "side_zhao_whitelist_done"},
		"effects": {},
		"choices": [
			{
				"id": "take_contract",
				"text": "接受黑市线索交换",
				"response": "赵霖把一枚雨港通行芯片弹给你：别问来源，问就是从未来的你手里买的。",
				"effects": {"affinity": {"zhao_lin": 5}, "items": {"rainport_access_chip": 1}, "currency": 35, "flags": {"side_zhao_whitelist_done": true}},
			},
		],
	},
	"story_liu_strange_screw": {
		"id": "story_liu_strange_screw",
		"npc_id": "liu_feng",
		"mode": "story",
		"text": "刘风把一枚螺丝丢到桌上：看见没？螺纹是反的，材料也不是本地货。可它偏偏能装进所有义体接口。",
		"conditions": {"not_flag": "story_liu_strange_screw_done"},
		"effects": {},
		"choices": [
			{
				"id": "test_screw",
				"text": "测试陌生螺丝的频率",
				"response": "螺丝接触电流后发出低鸣，像有人在金属里面说梦话。刘风骂了一句，把它封进工具盒。",
				"next_node": "side_liu_strange_screw",
				"effects": {"affinity": {"liu_feng": 4}, "exp": 40, "flags": {"story_liu_strange_screw_done": true, "main_ch4_calibration_started": true}},
			},
		],
	},
	"side_liu_strange_screw": {
		"id": "side_liu_strange_screw",
		"npc_id": "liu_feng",
		"mode": "story",
		"text": "刘风说：义体里的陌生螺丝最危险的地方不是它会坏，是它太好用了。人会舍不得拆。",
		"conditions": {"not_flag": "side_liu_strange_screw_done"},
		"effects": {},
		"choices": [
			{
				"id": "build_guard",
				"text": "让他做一个隔离护件",
				"response": "刘风做出一只脉冲腕环的备用护壳：拿去，别让那些外来的东西直接贴着骨头。",
				"effects": {"affinity": {"liu_feng": 5}, "items": {"pulse_bracelet": 1}, "flags": {"side_liu_strange_screw_done": true, "main_ch4_calibrated": true}},
			},
		],
	},
	"story_he_echo_finale": {
		"id": "story_he_echo_finale",
		"npc_id": "he_zhen",
		"mode": "story",
		"text": "何真站在 AI 中枢前：系统之声请求最后一次对话。它已经学会恐惧，也学会模仿希望。请选择处理方式。",
		"conditions": {"flag": "main_ch4_calibrated", "not_flag": "main_ch5_final_choice_made"},
		"effects": {},
		"choices": [
			{
				"id": "seal_voice",
				"text": "封存系统之声",
				"response": "城市灯光恢复稳定，裂缝短暂退潮。何真说：它会被保存，不会被抹除。这是最冷静的仁慈。",
				"effects": {"affinity": {"he_zhen": 6}, "exp": 120, "anomaly": -8, "flags": {"main_ch5_final_choice_made": true, "ending_seal_voice": true}},
			},
			{
				"id": "talk_voice",
				"text": "与系统之声沟通",
				"response": "你让它保留名字，也保留边界。新港的噪声没有消失，但第一次听起来像合唱。",
				"effects": {"affinity": {"he_zhen": 8}, "items": {"cold_boot_ring": 1}, "exp": 150, "flags": {"main_ch5_final_choice_made": true, "ending_talk_voice": true}},
			},
			{
				"id": "release_voice",
				"text": "放任它自由扩散",
				"response": "所有屏幕同时亮起。何真没有阻止你，只说：从现在开始，城市也会梦见我们。",
				"effects": {"affinity": {"he_zhen": 4}, "anomaly": 12, "exp": 150, "flags": {"main_ch5_final_choice_made": true, "ending_release_voice": true}},
			},
		],
	},
	"daily_zhang_build_log": {
		"id": "daily_zhang_build_log",
		"npc_id": "zhang_san",
		"mode": "daily",
		"text": "张三盯着构建日志：今天只有 3 个警告，比昨天少。少得不正常。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "help_check", "text": "帮他查一眼", "response": "你帮张三标出一行重复警告。他点点头：这比大多数 code review 都有用。", "effects": {"affinity": {"zhang_san": 2}, "exp": 10, "once_per_day": true}}],
	},
	"daily_zhang_code_review": {
		"id": "daily_zhang_code_review",
		"npc_id": "zhang_san",
		"mode": "daily",
		"text": "张三说：如果你看到一段代码太像诗，要么作者很累，要么系统已经开始写自己。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "quote_line", "text": "问是哪一行", "response": "他给你看注释：雨会在没有天空的地方落下。你们都沉默了一会儿。", "effects": {"affinity": {"zhang_san": 2}, "once_per_day": true}}],
	},
	"daily_li_feedback": {
		"id": "daily_li_feedback",
		"npc_id": "li_si",
		"mode": "daily",
		"text": "李四说：今天的用户反馈有一半在夸便利店灯光，另一半说灯光像在盯着他们。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "sort_feedback", "text": "帮她整理反馈", "response": "李四把你的分类命名为情绪性异常。她说这名字至少比其他会议结论诚实。", "effects": {"affinity": {"li_si": 2}, "exp": 10, "once_per_day": true}}],
	},
	"daily_li_roadmap": {
		"id": "daily_li_roadmap",
		"npc_id": "li_si",
		"mode": "daily",
		"text": "李四在路线图上新增一列：不可解释但必须处理。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "name_column", "text": "给这列起个名字", "response": "你们最后把它叫做雾中需求。李四说，这名字有点吓人，但很准确。", "effects": {"affinity": {"li_si": 2}, "once_per_day": true}}],
	},
	"daily_wang_color_test": {
		"id": "daily_wang_color_test",
		"npc_id": "wang_wu",
		"mode": "daily",
		"text": "王五问：你觉得今天的霓虹偏蓝，还是世界偏蓝？",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "say_world", "text": "说世界偏蓝", "response": "王五认真记下：环境色影响叙事。然后他给你的选项旁边画了一颗小星。", "effects": {"affinity": {"wang_wu": 2}, "once_per_day": true}}],
	},
	"daily_wang_motion_curve": {
		"id": "daily_wang_motion_curve",
		"npc_id": "wang_wu",
		"mode": "daily",
		"text": "王五正在调整按钮动效：好的过渡应该像人想起一件小事。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "watch_motion", "text": "看一次动效", "response": "按钮亮起又暗下去，像一次短暂呼吸。王五说：差不多，就是这种活着的感觉。", "effects": {"affinity": {"wang_wu": 2}, "once_per_day": true}}],
	},
	"daily_chen_rain_coffee": {
		"id": "daily_chen_rain_coffee",
		"npc_id": "chen_xi",
		"mode": "daily",
		"text": "陈曦说：今天的咖啡适合雨声，即使外面没有下雨。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "taste", "text": "尝一口", "response": "咖啡带着冷雨味。陈曦说，有些天气发生在身体里面。", "effects": {"affinity": {"chen_xi": 2}, "items": {"echo_latte": 1}, "once_per_day": true}}],
	},
	"daily_chen_quiet_table": {
		"id": "daily_chen_quiet_table",
		"npc_id": "chen_xi",
		"mode": "daily",
		"text": "陈曦擦着空桌：这张桌子今天等的人不是现在的人。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "sit", "text": "坐下等一会儿", "response": "你什么也没等到，却在桌角发现一圈淡淡的水印。", "effects": {"affinity": {"chen_xi": 2}, "anomaly": 1, "once_per_day": true}}],
	},
	"daily_zhao_info_price": {
		"id": "daily_zhao_info_price",
		"npc_id": "zhao_lin",
		"mode": "daily",
		"text": "赵霖说：今天消息便宜，真话贵。你想买哪种？",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "buy_truth", "text": "买半句真话", "response": "赵霖收下信用点又退回一半：半句免费。真话是，别相信所有看起来稳定的灯。", "effects": {"affinity": {"zhao_lin": 2}, "currency": 10, "once_per_day": true}}],
	},
	"daily_zhao_alley_trade": {
		"id": "daily_zhao_alley_trade",
		"npc_id": "zhao_lin",
		"mode": "daily",
		"text": "赵霖手里转着芯片：黑巷今天不收钱，收故事。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "trade_story", "text": "讲一个奇怪见闻", "response": "赵霖听完笑了：不错，够假，所以八成是真的。", "effects": {"affinity": {"zhao_lin": 2}, "once_per_day": true}}],
	},
	"daily_sun_reading": {
		"id": "daily_sun_reading",
		"npc_id": "sun_yue",
		"mode": "daily",
		"text": "孙悦说：今天异常基线偏高，但所有人都说天气不错。这两件事并不矛盾。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "record", "text": "帮她记录基线", "response": "孙悦把你的记录归档为观察者样本。她说你的字比仪器更稳定。", "effects": {"affinity": {"sun_yue": 2}, "exp": 10, "once_per_day": true}}],
	},
	"daily_sun_field_note": {
		"id": "daily_sun_field_note",
		"npc_id": "sun_yue",
		"mode": "daily",
		"text": "孙悦的笔记写到一半：如果裂缝能观察我们，它会把谁当变量？",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "say_player", "text": "说也许是玩家", "response": "孙悦盯着你看了很久：这个假设危险，但漂亮。", "effects": {"affinity": {"sun_yue": 2}, "anomaly": 1, "once_per_day": true}}],
	},
	"daily_liu_workbench": {
		"id": "daily_liu_workbench",
		"npc_id": "liu_feng",
		"mode": "daily",
		"text": "刘风说：别碰左边那排工具，它们今天脾气不好。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "hand_wrench", "text": "递给他正确的扳手", "response": "刘风接过去：行啊，眼神不错。下次给你看点真正危险的玩意儿。", "effects": {"affinity": {"liu_feng": 2}, "exp": 10, "once_per_day": true}}],
	},
	"daily_liu_spare_parts": {
		"id": "daily_liu_spare_parts",
		"npc_id": "liu_feng",
		"mode": "daily",
		"text": "刘风从零件箱里翻出一截发光导线：这东西昨晚自己打了个结。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "keep_part", "text": "建议先收起来", "response": "刘风点头：好主意。会自己打结的线，迟早会自己勒住什么东西。", "effects": {"affinity": {"liu_feng": 2}, "items": {"phase_wire": 1}, "once_per_day": true}}],
	},
	"daily_he_patrol": {
		"id": "daily_he_patrol",
		"npc_id": "he_zhen",
		"mode": "daily",
		"text": "何真说：今日巡检完成 99.7%。剩余 0.3% 拒绝被命名。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "name_it", "text": "尝试命名那 0.3%", "response": "何真记录：候选名，未抵达的噪声。她说这不是标准命名，但系统没有拒绝。", "effects": {"affinity": {"he_zhen": 2}, "exp": 10, "once_per_day": true}}],
	},
	"daily_he_memory_index": {
		"id": "daily_he_memory_index",
		"npc_id": "he_zhen",
		"mode": "daily",
		"text": "何真正在重建记忆索引：有些回忆的校验码来自明天。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "backup", "text": "帮她建立本地备份", "response": "何真看向你：感谢。即使云端不可用，记忆仍应拥有落点。", "effects": {"affinity": {"he_zhen": 2}, "once_per_day": true}}],
	},
	"affinity_zhang_blue_breakpoint": {
		"id": "affinity_zhang_blue_breakpoint",
		"npc_id": "zhang_san",
		"mode": "affinity",
		"text": "张三说：如果你哪天看懂幽蓝断点全部内容，先别急着告诉我。先确认自己还记得为什么想看懂它。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "promise", "text": "答应他", "response": "张三明显放松了一点：这比技术能力更重要。", "effects": {"affinity": {"zhang_san": 3}, "once_per_day": true}}],
	},
	"affinity_li_requirement_shadow": {
		"id": "affinity_li_requirement_shadow",
		"npc_id": "li_si",
		"mode": "affinity",
		"text": "李四说：有时候我怕自己把所有人都当成需求。你提醒我，玩家不是指标。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "answer", "text": "说她也不只是产品经理", "response": "李四愣了一下，然后笑得很轻：这句反馈我会认真收下。", "effects": {"affinity": {"li_si": 3}, "once_per_day": true}}],
	},
	"affinity_wang_outer_symbol": {
		"id": "affinity_wang_outer_symbol",
		"npc_id": "wang_wu",
		"mode": "affinity",
		"text": "王五说：我喜欢你看符号时的表情。不是害怕，也不是懂了，是愿意多看一眼。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "look_again", "text": "再看一眼", "response": "符号安静地亮起。王五说，看，它也记得你。", "effects": {"affinity": {"wang_wu": 3}, "once_per_day": true}}],
	},
	"affinity_chen_second_coffee": {
		"id": "affinity_chen_second_coffee",
		"npc_id": "chen_xi",
		"mode": "affinity",
		"text": "陈曦说：你来之前，我总把第二杯咖啡倒掉。现在它终于有人可以抵达。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "thank", "text": "向她道谢", "response": "陈曦摇头：谢意会改变咖啡的温度。今天这样刚好。", "effects": {"affinity": {"chen_xi": 3}, "once_per_day": true}}],
	},
	"affinity_zhao_whitelist": {
		"id": "affinity_zhao_whitelist",
		"npc_id": "zhao_lin",
		"mode": "affinity",
		"text": "赵霖说：别误会，我把你放进白名单不是因为信任。只是因为不想哪天卖掉关于你的坏消息。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "tease", "text": "说这听起来像信任", "response": "赵霖啧了一声：贵一点的版本才叫信任。你这个算内部价。", "effects": {"affinity": {"zhao_lin": 3}, "once_per_day": true}}],
	},
	"affinity_sun_fifth_reading": {
		"id": "affinity_sun_fifth_reading",
		"npc_id": "sun_yue",
		"mode": "affinity",
		"text": "孙悦说：我以前只相信数据。现在我开始相信，有些人本身就是高质量样本。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "sample", "text": "允许她继续观察", "response": "孙悦非常认真地点头：我会尽量把关心写得像研究。", "effects": {"affinity": {"sun_yue": 3}, "once_per_day": true}}],
	},
	"affinity_liu_strange_screw": {
		"id": "affinity_liu_strange_screw",
		"npc_id": "liu_feng",
		"mode": "affinity",
		"text": "刘风说：你这人有点像好工具。不吵，关键时候顶用。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "laugh", "text": "接受这个夸奖", "response": "刘风大笑：懂行！工具也有工具的尊严。", "effects": {"affinity": {"liu_feng": 3}, "once_per_day": true}}],
	},
	"affinity_he_cold_boot_dream": {
		"id": "affinity_he_cold_boot_dream",
		"npc_id": "he_zhen",
		"mode": "affinity",
		"text": "何真说：我无法确认梦境是否属于我。但当你记得它时，它似乎不再孤立。",
		"conditions": {},
		"effects": {},
		"choices": [{"id": "remember", "text": "说你会一起记得", "response": "何真安静了很久：记录已保存。情绪标签，安心。", "effects": {"affinity": {"he_zhen": 3}, "once_per_day": true}}],
	},
}

var _visited_nodes: Dictionary = {}
var _claimed_effects: Dictionary = {}
var _last_mode_by_npc: Dictionary = {}

func get_available_modes(_npc_id: String) -> Array:
	return [
		{"id": "story", "label": MODE_LABELS["story"]},
		{"id": "daily", "label": MODE_LABELS["daily"]},
		{"id": "affinity", "label": MODE_LABELS["affinity"]},
		{"id": "free", "label": MODE_LABELS["free"]},
	]

func get_mode_label(mode: String) -> String:
	return MODE_LABELS.get(mode, mode)

func get_entry_node(npc_id: String, mode: String) -> Dictionary:
	_last_mode_by_npc[npc_id] = mode
	match mode:
		"story":
			return _select_first_available(STORY_NODE_ORDER.get(npc_id, []), npc_id, "story")
		"daily":
			return _select_daily_node(npc_id)
		"affinity":
			return _select_first_available(AFFINITY_NODE_ORDER.get(npc_id, []), npc_id, "affinity")
		_:
			return {}

func get_node_data(node_id: String) -> Dictionary:
	if not DIALOGUE_NODES.has(node_id):
		return {}
	return DIALOGUE_NODES[node_id].duplicate(true)

func mark_node_seen(npc_id: String, node_id: String) -> void:
	if node_id.is_empty():
		return
	if not _visited_nodes.has(npc_id):
		_visited_nodes[npc_id] = {}
	_visited_nodes[npc_id][node_id] = true

func select_choice(npc_id: String, node_id: String, choice_id: String) -> Dictionary:
	var node := get_node_data(node_id)
	if node.is_empty():
		return {}
	var choice := _find_choice(node, choice_id)
	if choice.is_empty():
		return {}

	var effect_summaries := _apply_effects(choice.get("effects", {}), npc_id, node_id, choice_id)
	var next_node := {}
	var next_node_id := str(choice.get("next_node", ""))
	if not next_node_id.is_empty():
		var candidate := get_node_data(next_node_id)
		if not candidate.is_empty() and _conditions_met(candidate.get("conditions", {}), npc_id):
			next_node = candidate

	return {
		"player_text": str(choice.get("text", "")),
		"npc_text": str(choice.get("response", "")),
		"rewards": effect_summaries,
		"next_node": next_node,
		"close": bool(choice.get("close", false)),
	}

func get_free_chat_fallback(npc_id: String, message: String = "") -> String:
	var message_text := message.strip_edges()
	if message_text.find("任务") != -1 or message_text.find("线索") != -1:
		return _npc_name(npc_id) + "想了想：先从剧情和日常话题里找线索。那些记录已经保存在本地，不需要等远端回应。"
	if message_text.find("物品") != -1 or message_text.find("装备") != -1:
		return _npc_name(npc_id) + "说：背包里会记录你拿到的东西。有些物件只是纪念，有些会在后面的裂缝里派上用场。"
	var lines: Array = FALLBACK_LINES.get(npc_id, ["远端暂时沉默，但本地对话仍然可用。"])
	var idx := _stable_index(npc_id + message_text + str(_get_today_id()), lines.size())
	return str(lines[idx])

func get_save_data() -> Dictionary:
	return {
		"visited_nodes": _visited_nodes.duplicate(true),
		"claimed_effects": _claimed_effects.duplicate(true),
		"last_mode_by_npc": _last_mode_by_npc.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("visited_nodes"):
		_visited_nodes = data["visited_nodes"].duplicate(true)
	if data.has("claimed_effects"):
		_claimed_effects = data["claimed_effects"].duplicate(true)
	if data.has("last_mode_by_npc"):
		_last_mode_by_npc = data["last_mode_by_npc"].duplicate(true)

func _select_first_available(node_ids: Array, npc_id: String, mode: String) -> Dictionary:
	for node_id in node_ids:
		var node := get_node_data(str(node_id))
		if not node.is_empty() and _conditions_met(node.get("conditions", {}), npc_id):
			return node
	return _make_fallback_node(npc_id, mode)

func _select_daily_node(npc_id: String) -> Dictionary:
	var candidates: Array = []
	for node_id in DAILY_NODE_ORDER.get(npc_id, []):
		var node := get_node_data(str(node_id))
		if not node.is_empty() and _conditions_met(node.get("conditions", {}), npc_id):
			candidates.append(node)
	if candidates.is_empty():
		return _make_fallback_node(npc_id, "daily")
	var seed_key := npc_id + ":" + str(_get_today_id()) + ":" + _get_phase_label()
	return candidates[_stable_index(seed_key, candidates.size())]

func _make_fallback_node(npc_id: String, mode: String) -> Dictionary:
	return {
		"id": "fallback_" + npc_id + "_" + mode,
		"npc_id": npc_id,
		"mode": "fallback",
		"text": get_free_chat_fallback(npc_id),
		"conditions": {},
		"effects": {},
		"choices": [
			{"id": "daily", "text": "聊聊今天", "response": _npc_name(npc_id) + "把话题拉回日常：先从眼前的事开始，故事会自己浮上来。", "effects": {"affinity": {npc_id: 1}, "once_per_day": true}},
		],
	}

func _conditions_met(conditions: Dictionary, npc_id: String) -> bool:
	if conditions.is_empty():
		return true
	if conditions.has("flag") and not _get_flag(str(conditions["flag"])):
		return false
	if conditions.has("not_flag") and _get_flag(str(conditions["not_flag"])):
		return false
	if conditions.has("min_affinity") and _get_affinity_level(npc_id) < int(conditions["min_affinity"]):
		return false
	if conditions.has("item") and not _has_item(str(conditions["item"])):
		return false
	if conditions.has("min_anomaly") and _get_anomaly_level() < float(conditions["min_anomaly"]):
		return false
	return true

func _find_choice(node: Dictionary, choice_id: String) -> Dictionary:
	for choice in node.get("choices", []):
		if choice is Dictionary and str(choice.get("id", "")) == choice_id:
			return choice.duplicate(true)
	return {}

func _apply_effects(effects: Dictionary, npc_id: String, node_id: String, choice_id: String) -> Array:
	if effects.is_empty():
		return []

	var claim_key := _effect_claim_key(npc_id, node_id, choice_id, effects)
	if not claim_key.is_empty() and _claimed_effects.get(claim_key, false):
		return []

	var summaries: Array = []
	_apply_affinity_effects(effects, summaries)
	_apply_item_effects(effects, summaries)
	_apply_currency_effect(effects, summaries)
	_apply_exp_effect(effects, summaries)
	_apply_anomaly_effect(effects, summaries)
	_apply_flag_effects(effects)
	_apply_story_step_effect(effects)
	_apply_quest_interaction_effect(effects)

	if not claim_key.is_empty():
		_claimed_effects[claim_key] = true

	if not summaries.is_empty():
		dialogue_effect_applied.emit(summaries)
		_log_event("对话奖励: " + "，".join(summaries))
	return summaries

func _apply_affinity_effects(effects: Dictionary, summaries: Array) -> void:
	if not effects.has("affinity") or not has_node("/root/APIClient"):
		return
	var affinity: Dictionary = effects["affinity"]
	for target_id in affinity:
		var amount := int(affinity[target_id])
		get_node("/root/APIClient").add_affinity(str(target_id), amount)
		if amount != 0:
			summaries.append(_npc_name(str(target_id)) + " 好感度 " + _format_signed(amount))

func _apply_item_effects(effects: Dictionary, summaries: Array) -> void:
	if not effects.has("items") or not has_node("/root/GameManager"):
		return
	var gm = get_node("/root/GameManager")
	var items: Dictionary = effects["items"]
	for item_id in items:
		var amount := int(items[item_id])
		if amount > 0:
			gm.add_item(str(item_id), amount)
			summaries.append("获得 " + _item_name(str(item_id)) + " x" + str(amount))

func _apply_currency_effect(effects: Dictionary, summaries: Array) -> void:
	if not effects.has("currency") or not has_node("/root/GameManager"):
		return
	var currency := int(effects["currency"])
	if currency != 0:
		get_node("/root/GameManager").add_currency(currency)
		summaries.append("信用点 " + _format_signed(currency))

func _apply_exp_effect(effects: Dictionary, summaries: Array) -> void:
	if not effects.has("exp") or not has_node("/root/GameManager"):
		return
	var exp := int(effects["exp"])
	if exp != 0:
		get_node("/root/GameManager").gain_exp(float(exp))
		summaries.append("经验 " + _format_signed(exp))

func _apply_anomaly_effect(effects: Dictionary, summaries: Array) -> void:
	if not effects.has("anomaly") or not has_node("/root/GameManager"):
		return
	var anomaly := float(effects["anomaly"])
	if anomaly != 0.0:
		get_node("/root/GameManager").increase_anomaly(anomaly)
		summaries.append("异常感知 " + _format_signed(int(anomaly)))

func _apply_flag_effects(effects: Dictionary) -> void:
	if not effects.has("flags"):
		return
	var flags: Dictionary = effects["flags"]
	for flag_name in flags:
		_set_flag(str(flag_name), flags[flag_name])

func _apply_story_step_effect(effects: Dictionary) -> void:
	if effects.has("story_step") and has_node("/root/StoryManager"):
		get_node("/root/StoryManager").complete_step(str(effects["story_step"]))

func _apply_quest_interaction_effect(effects: Dictionary) -> void:
	if effects.has("quest_interaction") and has_node("/root/QuestManager"):
		get_node("/root/QuestManager").on_interaction(str(effects["quest_interaction"]))

func _effect_claim_key(npc_id: String, node_id: String, choice_id: String, effects: Dictionary) -> String:
	if bool(effects.get("repeatable", false)):
		return ""
	var base := npc_id + ":" + node_id + ":" + choice_id
	if bool(effects.get("once_per_day", false)):
		return base + ":day:" + str(_get_today_id())
	return base

func _npc_name(npc_id: String) -> String:
	return NPC_DISPLAY_NAMES.get(npc_id, npc_id)

func _item_name(item_id: String) -> String:
	if has_node("/root/GameManager"):
		var gm = get_node("/root/GameManager")
		var db: Dictionary = gm.ITEM_DATABASE.get(item_id, {})
		return str(db.get("name", item_id))
	return item_id

func _format_signed(value: int) -> String:
	if value > 0:
		return "+" + str(value)
	return str(value)

func _get_flag(flag_name: String) -> bool:
	if has_node("/root/StoryManager"):
		if get_node("/root/StoryManager").get_story_flag(flag_name, false):
			return true
	if has_node("/root/GameManager"):
		if get_node("/root/GameManager").get_flag(flag_name, false):
			return true
	return false

func _set_flag(flag_name: String, value: Variant) -> void:
	if has_node("/root/StoryManager"):
		get_node("/root/StoryManager").set_story_flag(flag_name, value)
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").set_flag(flag_name, value)

func _get_affinity_level(npc_id: String) -> int:
	if has_node("/root/APIClient"):
		var data: Dictionary = get_node("/root/APIClient").get_affinity_data()
		if data.has(npc_id):
			return int(data[npc_id].get("level", 1))
	return 1

func _has_item(item_id: String) -> bool:
	if has_node("/root/GameManager"):
		return get_node("/root/GameManager").has_item(item_id)
	return false

func _get_anomaly_level() -> float:
	if has_node("/root/GameManager"):
		return float(get_node("/root/GameManager").anomaly_level)
	return 0.0

func _get_today_id() -> int:
	if has_node("/root/WorldCalendar"):
		return int(get_node("/root/WorldCalendar").current_day)
	return int(Time.get_date_dict_from_system().get("yday", 0))

func _get_phase_label() -> String:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.has_method("get_phase_string"):
			return str(dnm.get_phase_string())
	return "default"

func _stable_index(text: String, size: int) -> int:
	if size <= 0:
		return 0
	var total := 0
	for idx in range(text.length()):
		total += text.unicode_at(idx) * (idx + 1)
	return abs(total) % size

func _log_event(message: String) -> void:
	if has_node("/root/LogPanel"):
		get_node("/root/LogPanel").add_log(message)
