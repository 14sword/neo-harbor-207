extends CanvasLayer

var _daily_seed: int = 0
var _daily_profile: Dictionary = {}
var _daily_weather: Dictionary = {}
var _daily_events: Array = []
var _daily_ads: Array = []
var _daily_anomaly_level: float = 0.0

const WEATHER_OPTIONS: Array = [
	{"id": "sunny", "name": "晴", "desc": "空气清澈，城市网络运行稳定", "icon": "☀️", "weight": 26},
	{"id": "cloudy", "name": "多云", "desc": "云层偏厚，傍晚有低空风", "icon": "⛅", "weight": 28},
	{"id": "light_rain", "name": "小雨", "desc": "间歇小雨，建议携带防水外套", "icon": "🌦️", "weight": 18},
	{"id": "thunderstorm", "name": "雷暴", "desc": "雷暴预警，电子设备需防护", "icon": "⛈️", "weight": 8},
	{"id": "fog", "name": "雾霾", "desc": "能见度降低，空气指数偏高", "icon": "🌫️", "weight": 10},
]

const MONTH_MODIFIERS: Dictionary = {
	"frost": {"sunny": 2, "cloudy": 8, "light_rain": -4, "thunderstorm": -4, "fog": 10, "temp": -4, "humidity": 0, "anomaly": 0.03, "mood": "冷空气维护期"},
	"neon": {"sunny": 8, "cloudy": 2, "light_rain": -2, "thunderstorm": 0, "fog": -2, "temp": 1, "humidity": -4, "anomaly": 0.08, "mood": "霓虹商业季"},
	"rain": {"sunny": -10, "cloudy": 8, "light_rain": 16, "thunderstorm": 8, "fog": 2, "temp": 0, "humidity": 16, "anomaly": 0.14, "mood": "雨季通勤压力"},
	"ghost": {"sunny": -6, "cloudy": 4, "light_rain": 4, "thunderstorm": 8, "fog": 10, "temp": -1, "humidity": 8, "anomaly": 0.30, "mood": "幽月信号污染"},
	"ash": {"sunny": -2, "cloudy": 8, "light_rain": 2, "thunderstorm": -2, "fog": 8, "temp": -2, "humidity": 4, "anomaly": 0.18, "mood": "灰月修复管制"},
}

const WEEKDAY_MODIFIERS: Dictionary = {
	"public": {"label": "公共公告", "weather": 0.0, "anomaly": 0.00},
	"commerce": {"label": "娱乐消费", "weather": 0.0, "anomaly": 0.02},
	"weather": {"label": "天气交通", "weather": 0.08, "anomaly": 0.03},
	"industry": {"label": "工业维护", "weather": 0.0, "anomaly": 0.04},
	"rumor": {"label": "异常传闻", "weather": 0.02, "anomaly": 0.10},
	"safety": {"label": "社区安全", "weather": 0.0, "anomaly": 0.05},
}

const EVENT_POOLS: Dictionary = {
	"public": [
		{"title": "社区身份终端升级", "body": "各街区公共终端今日轮换证书，居民无需重复登录。", "image_category": "tv_city", "forum_category": "都市新闻"},
		{"title": "中央广场开放巡游路线", "body": "中央广场完成地面投影校准，午后开放慢行路线。", "image_category": "tv_city", "forum_category": "都市新闻"},
		{"title": "城市安全指数小幅上升", "body": "安全局称网络诈骗拦截率提升，夜间巡检频次同步增加。", "image_category": "tv_city", "forum_category": "都市新闻"},
	],
	"commerce": [
		{"title": "霓虹市集延长营业", "body": "多家小店加入夜间市集，热饮与维修摊位同步开放。", "image_category": "tv_life", "forum_category": "生活杂谈"},
		{"title": "全息茶饮节试运行", "body": "街角茶饮店上线限时口味，投影菜单已通过安全检查。", "image_category": "tv_life", "forum_category": "生活杂谈"},
		{"title": "社区游戏厅更新设备", "body": "旧街游戏厅更换体感模组，下午开放免费测试。", "image_category": "tv_life", "forum_category": "生活杂谈"},
	],
	"weather": [
		{"title": "高架列车调整发车间隔", "body": "受低空风影响，高架列车午后间隔延长至 8 分钟。", "image_category": "tv_traffic", "forum_category": "都市新闻"},
		{"title": "无人机配送改走低空廊道", "body": "配送网络避开强对流云团，部分订单预计延迟。", "image_category": "tv_traffic", "forum_category": "都市新闻"},
		{"title": "气象中心开放实时雷达", "body": "居民可在公共终端查看街区级降雨图层。", "image_category": "tv_weather", "forum_category": "都市新闻"},
	],
	"industry": [
		{"title": "区域电网夜间维护", "body": "电力局将在深夜轮换储能单元，部分楼宇照明可能短暂闪烁。", "image_category": "tv_city", "forum_category": "DATAWHALE公告"},
		{"title": "地下管廊传感器校准", "body": "维护队伍进入地下管廊，预计不影响地面通行。", "image_category": "tv_traffic", "forum_category": "都市新闻"},
		{"title": "DATAWHALE 节点例行巡检", "body": "核心节点进入低负载巡检窗口，终端访问保持在线。", "image_category": "tv_city", "forum_category": "DATAWHALE公告"},
	],
	"rumor": [
		{"title": "旧街低频嗡鸣调查", "body": "多名居民报告短促低频声，监测站称暂未发现危险源。", "image_category": "tv_anomaly", "forum_category": "异常报告"},
		{"title": "紫色反光出现在雨水中", "body": "气象中心提醒居民不要采集未知沉积物。", "image_category": "tv_anomaly", "forum_category": "异常报告"},
		{"title": "区域三信号抖动", "body": "公共网络出现数秒空白帧，运维人员正在回放日志。", "image_category": "tv_anomaly", "forum_category": "异常报告"},
	],
	"safety": [
		{"title": "社区夜巡路线更新", "body": "安全局增加便利店和公寓入口巡查点。", "image_category": "tv_city", "forum_category": "都市新闻"},
		{"title": "防护面罩补给到货", "body": "灰月库存补给已送达 24h 便利站，居民可按需领取。", "image_category": "tv_life", "forum_category": "生活杂谈"},
		{"title": "异常热线响应升级", "body": "异常热线新增自动定位回执，重复报案将优先合并。", "image_category": "tv_anomaly", "forum_category": "异常报告"},
	],
}

const AD_POOL: Array = [
	{"title": "霓虹能量饮", "desc": "低糖配方，适合长时间终端作业。", "category": "ads", "image_category": "tv_life"},
	{"title": "量子咖啡", "desc": "雨夜限定热饮，配送路线已加密。", "category": "ads", "image_category": "tv_life"},
	{"title": "赛博拉面", "desc": "街角面馆今日开放全息菜单。", "category": "ads", "image_category": "tv_life"},
	{"title": "无人机快递", "desc": "小件物品 30 分钟内送达，雷暴时段顺延。", "category": "ads", "image_category": "tv_life"},
	{"title": "家用防雷插座", "desc": "雨月推荐，保护个人终端和宠物喂食器。", "category": "ads", "image_category": "tv_life"},
	{"title": "DATAWHALE招聘", "desc": "开放数据巡检与现场记录岗位。", "category": "ads", "image_category": "terminal_datawhale"},
]

func _ready():
	_refresh_daily_data()
	if has_node("/root/WorldCalendar"):
		get_node("/root/WorldCalendar").day_advanced.connect(_on_day_advanced)

func _on_day_advanced(_new_day):
	_refresh_daily_data()

func _refresh_daily_data():
	if has_node("/root/WorldCalendar"):
		_daily_seed = get_node("/root/WorldCalendar").get_day_seed()
	else:
		_daily_seed = 1

	var rng = RandomNumberGenerator.new()
	rng.seed = _daily_seed
	var date_context = _get_date_context()
	_daily_weather = _generate_weather(rng, date_context)
	_daily_anomaly_level = _generate_anomaly_level(rng, date_context, _daily_weather)
	_daily_ads = _pick_unique(rng, AD_POOL, 2 + rng.randi_range(0, 1))
	var major_event = _generate_major_event(rng, date_context)
	var news_items = _generate_news_items(rng, date_context, major_event)
	var forum_injections = _generate_forum_injections(date_context, major_event, news_items)
	_daily_events = _extract_event_titles(news_items.get("day", []))
	_daily_profile = {
		"date": date_context,
		"weather": _daily_weather.duplicate(true),
		"anomaly_level": _daily_anomaly_level,
		"city_mood": _build_city_mood(date_context),
		"major_event": major_event.duplicate(true),
		"news_items": news_items,
		"forum_injections": forum_injections,
		"ads": _duplicate_array(_daily_ads),
	}

func get_daily_profile() -> Dictionary:
	return _daily_profile.duplicate(true)

func get_daily_weather() -> Dictionary:
	return _daily_weather.duplicate(true)

func get_daily_anomaly_level() -> float:
	return _daily_anomaly_level

func get_daily_events() -> Array:
	return _daily_events.duplicate()

func get_daily_ads() -> Array:
	return _duplicate_array(_daily_ads)

func get_daily_news_items(phase_key: String = "day") -> Array:
	var phase = _normalize_phase_key(phase_key)
	var news_by_phase = _daily_profile.get("news_items", {})
	if news_by_phase.has(phase):
		return _duplicate_array(news_by_phase[phase])
	return _duplicate_array(news_by_phase.get("day", []))

func get_daily_forum_posts(category: String, phase_key: String = "day") -> Array:
	var phase = _normalize_phase_key(phase_key)
	var by_category = _daily_profile.get("forum_injections", {})
	if not by_category.has(category):
		return []
	var by_phase = by_category[category]
	if by_phase.has(phase):
		return _duplicate_array(by_phase[phase])
	return _duplicate_array(by_phase.get("day", []))

func _get_date_context() -> Dictionary:
	if has_node("/root/WorldCalendar"):
		var cal = get_node("/root/WorldCalendar")
		if cal.has_method("get_calendar_context"):
			return cal.get_calendar_context()
		return {
			"day": cal.current_day,
			"date_string": cal.get_date_string(),
			"short_date": cal.get_short_date(),
			"month_index": cal.get_current_month_index(),
			"weekday_index": cal.get_current_weekday_index(),
			"month_id": _month_id_from_index(cal.get_current_month_index()),
			"weekday_id": _weekday_id_from_index(cal.get_current_weekday_index()),
			"month_theme": "城市运行",
			"weekday_theme": "公共公告",
		}
	return {
		"day": 1,
		"date_string": "N.H.207 霜月1 曜日",
		"short_date": "霜月1",
		"month_index": 0,
		"weekday_index": 0,
		"month_id": "frost",
		"weekday_id": "public",
		"month_theme": "冷空气维护期",
		"weekday_theme": "公共公告",
	}

func _generate_weather(rng: RandomNumberGenerator, date_context: Dictionary) -> Dictionary:
	var month_id = date_context.get("month_id", "frost")
	var weekday_id = date_context.get("weekday_id", "public")
	var month_mod = MONTH_MODIFIERS.get(month_id, MONTH_MODIFIERS["frost"])
	var weekday_mod = WEEKDAY_MODIFIERS.get(weekday_id, WEEKDAY_MODIFIERS["public"])
	var weighted = []
	for option in WEATHER_OPTIONS:
		var weather_id = option["id"]
		var weight = int(option["weight"]) + int(month_mod.get(weather_id, 0))
		if weekday_id == "weather" and (weather_id == "light_rain" or weather_id == "thunderstorm"):
			weight += 6
		if weekday_id == "rumor" and (weather_id == "fog" or weather_id == "thunderstorm"):
			weight += 4
		weighted.append({"weight": maxi(weight, 1), "data": option})
	var picked = _pick_weighted(rng, weighted)
	var weather = picked.duplicate(true)
	var temp_base = 24 + int(month_mod.get("temp", 0))
	match weather.get("id", ""):
		"sunny":
			temp_base += 3
		"fog":
			temp_base -= 2
		"thunderstorm":
			temp_base -= 1
	weather["temperature"] = "%d°C" % (temp_base + rng.randi_range(-2, 3))
	var humidity = 48 + int(month_mod.get("humidity", 0)) + int(float(weekday_mod.get("weather", 0.0)) * 100.0)
	match weather.get("id", ""):
		"sunny":
			humidity -= 8
		"light_rain":
			humidity += 20
		"thunderstorm":
			humidity += 28
		"fog":
			humidity += 15
	humidity = clampi(humidity + rng.randi_range(-5, 5), 30, 96)
	weather["humidity"] = "%d%%" % humidity
	weather["image_category"] = "tv_weather"
	return weather

func _generate_anomaly_level(rng: RandomNumberGenerator, date_context: Dictionary, weather: Dictionary) -> float:
	var month_id = date_context.get("month_id", "frost")
	var weekday_id = date_context.get("weekday_id", "public")
	var month_mod = MONTH_MODIFIERS.get(month_id, MONTH_MODIFIERS["frost"])
	var weekday_mod = WEEKDAY_MODIFIERS.get(weekday_id, WEEKDAY_MODIFIERS["public"])
	var base = float(month_mod.get("anomaly", 0.05)) + float(weekday_mod.get("anomaly", 0.0))
	match weather.get("id", ""):
		"thunderstorm":
			base += 0.14
		"fog":
			base += 0.08
		"light_rain":
			base += 0.05
	return clampf(base + rng.randf_range(0.0, 0.22), 0.0, 0.95)

func _generate_major_event(rng: RandomNumberGenerator, date_context: Dictionary) -> Dictionary:
	var weekday_id = date_context.get("weekday_id", "public")
	var pool = EVENT_POOLS.get(weekday_id, EVENT_POOLS["public"])
	var event = pool[rng.randi() % pool.size()].duplicate(true)
	event["severity"] = "normal"
	if event.get("image_category", "") == "tv_anomaly" or _daily_anomaly_level > 0.52:
		event["severity"] = "warning"
	return event

func _generate_news_items(rng: RandomNumberGenerator, date_context: Dictionary, major_event: Dictionary) -> Dictionary:
	var weather_item_day = _make_weather_news("day")
	var weather_item_rain = _make_weather_news("rain")
	var weather_item_night = _make_weather_news("night")
	var city_one = _make_news_item("◆ CH-07 都市新闻", major_event.get("title", ""), major_event.get("body", ""), major_event.get("image_category", "tv_city"), major_event.get("severity", "normal"))
	var city_two_event = _pick_secondary_city_event(rng, date_context, major_event)
	var city_two = _make_news_item("◆ CH-07 都市新闻", city_two_event.get("title", ""), city_two_event.get("body", ""), city_two_event.get("image_category", "tv_city"), city_two_event.get("severity", "normal"))
	var life_ad = _daily_ads[0] if not _daily_ads.is_empty() else AD_POOL[0]
	var life_item = _make_news_item("◆ CH-03 生活频道", life_ad.get("title", ""), life_ad.get("desc", ""), "tv_life", "normal")
	var datawhale_item = _make_datawhale_news(date_context)
	var anomaly_day = _make_anomaly_items("day", rng)
	var anomaly_rain = _make_anomaly_items("rain", rng)
	var anomaly_night = _make_anomaly_items("night", rng)

	var day_items = [weather_item_day, city_one, city_two, life_item, datawhale_item]
	day_items.append_array(anomaly_day)
	var rain_items = [weather_item_rain, _rain_variant(city_one), _rain_variant(city_two), life_item, datawhale_item]
	rain_items.append_array(anomaly_rain)
	var night_items = [weather_item_night, _night_variant(city_one), _night_variant(city_two), _night_variant(life_item), _night_variant(datawhale_item)]
	night_items.append_array(anomaly_night)
	return {"day": day_items, "rain": rain_items, "night": night_items}

func _pick_secondary_city_event(rng: RandomNumberGenerator, date_context: Dictionary, major_event: Dictionary) -> Dictionary:
	var candidates = []
	candidates.append_array(EVENT_POOLS["public"])
	candidates.append_array(EVENT_POOLS["weather"])
	candidates.append_array(EVENT_POOLS["safety"])
	if date_context.get("month_id", "") == "neon":
		candidates.append_array(EVENT_POOLS["commerce"])
	if date_context.get("month_id", "") == "rain":
		candidates.append_array(EVENT_POOLS["industry"])
	var picked = candidates[rng.randi() % candidates.size()].duplicate(true)
	if picked.get("title", "") == major_event.get("title", ""):
		picked = candidates[(rng.randi() + 1) % candidates.size()].duplicate(true)
	return picked

func _make_weather_news(phase: String) -> Dictionary:
	var body = "%s %s | 温度: %s | 湿度: %s\n%s" % [_daily_weather.get("icon", ""), _daily_weather.get("name", ""), _daily_weather.get("temperature", ""), _daily_weather.get("humidity", ""), _daily_weather.get("desc", "")]
	if phase == "rain" or _daily_weather.get("id", "") == "thunderstorm":
		body += "\n雨夜设备防护等级建议提升，公寓窗边终端请远离积水。"
	elif phase == "night":
		body += "\n深夜气象图层出现短暂噪声，气象中心称仍在正常范围。"
	return _make_news_item("◆ CH-12 天气频道", "今日天气档案", body, "tv_weather", "normal")

func _make_datawhale_news(date_context: Dictionary) -> Dictionary:
	var month_id = date_context.get("month_id", "frost")
	var body = "今日主题: %s。核心服务在线，公共终端数据将在低峰时段同步。" % date_context.get("month_theme", "城市运行")
	var title = "DATAWHALE 运行简报"
	var severity = "normal"
	if month_id == "ghost" or _daily_anomaly_level > 0.48:
		title = "DATAWHALE 观测简报"
		body = "现实稳定度监测出现短时抖动，安全部已将异常片段加入夜间复核队列。"
		severity = "warning"
	return _make_news_item("◆ CH-09 DATAWHALE", title, body, "tv_city", severity)

func _make_anomaly_items(phase: String, rng: RandomNumberGenerator) -> Array:
	var items = []
	var threshold = 0.42
	if phase == "night":
		threshold = 0.24
	elif phase == "rain":
		threshold = 0.32
	if _daily_anomaly_level < threshold:
		return items
	var count = 1
	if _daily_anomaly_level > 0.62 and (phase == "rain" or phase == "night"):
		count = 2
	var pool = [
		_make_news_item("◆ CH-?? 异常播报", "未确认信号回放", "区域三捕获到 447.3MHz 短脉冲。来源仍在定位，居民无需重复上报。", "tv_anomaly", "warning"),
		_make_news_item("◆ CH-?? 异常播报", "现实稳定度波动", "监测网记录到微弱折叠噪声，DATAWHALE 已启动低优先级复核。", "tv_anomaly", "warning"),
		_make_news_item("◆ CH-07 都市新闻", "旧街紫色反光调查", "巡查员称反光只持续数秒，现场未发现残留热源。", "tv_anomaly", "warning"),
	]
	return _pick_unique(rng, pool, count)

func _rain_variant(item: Dictionary) -> Dictionary:
	var copy = item.duplicate(true)
	if copy.get("image_category", "") == "tv_city":
		copy["text"] = copy.get("text", "") + "\n雨势影响现场采集，后续画面可能延迟。"
	if copy.get("image_category", "") == "tv_life":
		copy["text"] = copy.get("text", "") + "\n雨夜配送窗口已开启。"
	return copy

func _night_variant(item: Dictionary) -> Dictionary:
	var copy = item.duplicate(true)
	copy["text"] = copy.get("text", "") + "\n深夜信号将进入低功耗转播，若画面闪烁请保持终端在线。"
	if _daily_anomaly_level > 0.5:
		copy["severity"] = "warning"
	return copy

func _generate_forum_injections(date_context: Dictionary, major_event: Dictionary, news_items: Dictionary) -> Dictionary:
	var day_news = news_items.get("day", [])
	var rain_news = news_items.get("rain", [])
	var night_news = news_items.get("night", [])
	return {
		"都市新闻": {
			"day": [
				_make_post("【今日】" + major_event.get("title", ""), "都市快报", "09:20", major_event.get("body", ""), "terminal_news"),
				_make_post("【日历】" + date_context.get("weekday_theme", ""), "社区终端", "10:05", "今天的城市议题偏向%s，公共频道会优先推送相关信息。" % date_context.get("weekday_theme", "公共公告"), "terminal_news"),
			],
			"rain": [
				_make_post("【雨夜】交通与配送同步调整", "交通管理局", "21:10", "雨夜模式下，高架列车和无人机配送将优先避开强降雨廊道。", "terminal_news"),
				_post_from_news(rain_news[1] if rain_news.size() > 1 else day_news[1], "terminal_news"),
			],
			"night": [
				_make_post("【深夜】公共频道进入低功耗转播", "都市快报", "01:20", "深夜新闻将减少画面刷新，异常热线保持在线。", "terminal_news"),
			],
		},
		"异常报告": {
			"day": [
				_make_post("【监测】现实稳定度日间读数", "DATAWHALE", "08:40", "今日异常等级 %.0f%%，处于%s。" % [_daily_anomaly_level * 100.0, _get_anomaly_label()], "terminal_anomaly"),
			],
			"rain": [
				_make_post("【雨夜】信号噪声复核", "信号监测站", "22:15", "雨夜图层会放大低频噪声，如看到紫色拖影请记录时间。", "terminal_anomaly"),
			],
			"night": [
				_make_post("【深夜】未确认信号片段", "???", "02:??", "片段被系统自动遮蔽。重复出现的频率仍是 447.3MHz。", "terminal_anomaly"),
			],
		},
		"生活杂谈": {
			"day": _ads_to_posts("12:00"),
			"rain": [_make_post("【雨夜互助】热饮和防水袋", "夜猫子", "22:30", "便利店说雨夜配送仍在跑，记得给无人机留一个干燥降落点。", "terminal_life")],
			"night": [_make_post("【深夜】还有谁没睡", "匿名用户", "03:10", "街角便利店灯还亮着，电视里却一直在重复天气图。", "terminal_life")],
		},
		"DATAWHALE公告": {
			"day": [_make_post("【公告】" + date_context.get("month_theme", ""), "DATAWHALE", "08:00", "今日运行主题为%s，相关维护信息已推送至个人终端。" % date_context.get("month_theme", "城市运行"), "terminal_datawhale")],
			"rain": [_make_post("【远程】雨夜办公模式", "行政部", "20:00", "若雷暴持续，建议使用加密 VPN 并关闭非必要外设。", "terminal_datawhale")],
			"night": [_make_post("【安全】异常登录尝试复核", "安全部", "01:15", "内部网络出现一次短暂认证回声，系统已记录。", "terminal_datawhale")],
		},
	}

func _ads_to_posts(time_text: String) -> Array:
	var posts = []
	for ad in _daily_ads:
		posts.append(_make_post("【广告】" + ad.get("title", ""), "推广信息", time_text, ad.get("desc", ""), "terminal_life"))
	return posts

func _post_from_news(item: Dictionary, image_category: String) -> Dictionary:
	return _make_post("【快讯】" + item.get("title", ""), "都市快报", "21:40", item.get("text", ""), image_category)

func _make_news_item(channel: String, title: String, text: String, image_category: String, severity: String = "normal") -> Dictionary:
	return {
		"channel": channel,
		"title": title,
		"text": text,
		"image_category": image_category,
		"severity": severity,
	}

func _make_post(title: String, author: String, time_text: String, content: String, image_category: String) -> Dictionary:
	return {
		"title": title,
		"author": author,
		"time": time_text,
		"content": content,
		"image_category": image_category,
	}

func _pick_weighted(rng: RandomNumberGenerator, options: Array) -> Dictionary:
	var total = 0
	for option in options:
		total += int(option.get("weight", 1))
	var roll = rng.randi_range(1, maxi(total, 1))
	var acc = 0
	for option in options:
		acc += int(option.get("weight", 1))
		if roll <= acc:
			return option.get("data", {}).duplicate(true)
	return options[0].get("data", {}).duplicate(true)

func _pick_unique(rng: RandomNumberGenerator, pool: Array, count: int) -> Array:
	var result = []
	var used = {}
	var target = mini(count, pool.size())
	while result.size() < target:
		var idx = rng.randi() % pool.size()
		if used.has(idx):
			continue
		used[idx] = true
		var item = pool[idx]
		if item is Dictionary:
			result.append(item.duplicate(true))
		else:
			result.append(item)
	return result

func _duplicate_array(items: Array) -> Array:
	var result = []
	for item in items:
		if item is Dictionary:
			result.append(item.duplicate(true))
		else:
			result.append(item)
	return result

func _extract_event_titles(items: Array) -> Array:
	var titles = []
	for item in items:
		var channel = item.get("channel", "")
		if "都市" in channel or "DATAWHALE" in channel:
			titles.append(item.get("title", ""))
	return titles

func _build_city_mood(date_context: Dictionary) -> String:
	var weather_name = _daily_weather.get("name", "未知")
	var anomaly_label = _get_anomaly_label()
	return "%s / %s / %s" % [date_context.get("month_theme", "城市运行"), weather_name, anomaly_label]

func _get_anomaly_label() -> String:
	if _daily_anomaly_level >= 0.65:
		return "异常警戒"
	if _daily_anomaly_level >= 0.38:
		return "异常观察"
	return "稳定"

func _normalize_phase_key(phase_key: String) -> String:
	var clean = phase_key.to_lower()
	if clean == "rain_night" or clean == "rain":
		return "rain"
	if clean == "night":
		return "night"
	return "day"

func _month_id_from_index(idx: int) -> String:
	var ids = ["frost", "neon", "rain", "ghost", "ash"]
	return ids[idx % ids.size()]

func _weekday_id_from_index(idx: int) -> String:
	var ids = ["public", "commerce", "weather", "industry", "rumor", "safety"]
	return ids[idx % ids.size()]
