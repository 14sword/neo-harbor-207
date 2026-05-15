extends CanvasLayer

signal image_ready(category: String, texture: Texture2D)
signal class_portrait_ready(class_id: int, texture: Texture2D)

const UNSPLASH_ACCESS_KEY = "YOUR_UNSPLASH_ACCESS_KEY"
const MAX_CACHE_SIZE = 20
const UNSPLASH_HOUR_LIMIT = 45

var _http_unsplash_search: HTTPRequest
var _http_unsplash_image: HTTPRequest
var _http_pollinations: HTTPRequest

var _memory_cache: Dictionary = {}
var _cache_order: Array[String] = []
var _dynamic_http_requests: Array[HTTPRequest] = []

var _pending_requests: Dictionary = {}
var _request_queue: Array[Dictionary] = []
var _request_id_counter: int = 0

var _unsplash_request_count: int = 0
var _unsplash_reset_time: float = 0.0

var _categories_base: Dictionary = {
	"city_day": "res://assets/media/city_day/",
	"city_rain": "res://assets/media/city_rain/",
	"city_night": "res://assets/media/city_night/",
	"surveillance": "res://assets/media/surveillance/",
	"forum": "res://assets/media/forum/",
	"datawhale": "res://assets/media/datawhale/",
	"anomaly": "res://assets/media/anomaly/",
	"ads": "res://assets/media/ads/",
	"weather": "res://assets/media/weather/",
	"talisman": "res://assets/media/talisman/",
	"class_portrait": "res://assets/media/class_portrait/",
}

var _size_map: Dictionary = {
	"city_day": Vector2i(1024, 576),
	"city_rain": Vector2i(1024, 576),
	"city_night": Vector2i(1024, 576),
	"surveillance": Vector2i(1024, 576),
	"forum": Vector2i(1024, 576),
	"datawhale": Vector2i(1024, 576),
	"anomaly": Vector2i(1024, 576),
	"ads": Vector2i(576, 1024),
	"weather": Vector2i(1024, 576),
	"talisman": Vector2i(720, 720),
	"class_portrait": Vector2i(512, 512),
}

var _source_map: Dictionary = {
	"city_day": "unsplash",
	"city_rain": "unsplash",
	"city_night": "unsplash",
	"surveillance": "pollinations",
	"forum": "unsplash",
	"datawhale": "pollinations",
	"anomaly": "pollinations",
	"ads": "unsplash",
	"weather": "unsplash",
	"talisman": "pollinations",
	"class_portrait": "pollinations",
}

var _unsplash_queries: Dictionary = {
	"city_day": ["cyberpunk city daytime neon", "futuristic city skyline day", "tokyo street neon signs day", "neon city architecture modern", "urban cityscape bright daylight", "hong kong street neon day", "seoul city lights daytime", "shanghai pudong skyline day", "futuristic metropolis sunny", "city buildings glass steel modern"],
	"city_rain": ["rainy night city neon lights", "city rain reflection neon", "tokyo rain night street", "wet street neon reflections", "cyberpunk rain city night", "rain city lights blur", "neon signs rain puddle", "urban night rain atmosphere", "city downpour neon glow", "rainy cityscape night lights"],
	"city_night": ["dark city night purple lights", "city night skyline neon", "night city street dark mood", "urban night glow purple blue", "city lights night fog", "neon city night empty street", "midnight city atmosphere dark", "city night architecture glow", "nocturnal cityscape neon", "dark urban night mysterious"],
	"forum": ["ramen shop neon sign night", "street food stall steam", "cafe interior warm lighting", "arcade room neon lights", "alley graffiti art urban", "vending machine glowing night", "convenience store shelf", "night market food stall", "bar counter neon atmosphere", "bookstore interior cozy"],
	"ads": ["neon advertisement poster", "holographic display billboard", "led sign commercial bright", "neon sign shop storefront", "digital billboard night city", "illuminated sign urban", "neon light sign product", "retro neon sign vintage", "bright advertisement display", "colorful neon sign street"],
	"weather": ["weather radar screen display", "storm clouds dramatic sky", "satellite view earth clouds", "lightning storm sky night", "fog city skyline misty", "rain clouds dark atmosphere", "sunny sky clear blue", "weather station equipment", "thunderstorm lightning bolt", "aerial view clouds formation"],
}

var _scene_words_surveillance: Array[String] = [
	"empty parking garage at night",
	"rainy street from above",
	"dark corridor with flickering light",
	"underground tunnel pipes steam",
	"empty train station platform",
	"building entrance night visitor",
	"city square from above",
	"server room blue glow",
]

var _scene_words_datawhale: Array[String] = [
	"AI research lab screens matrix",
	"server room racks blue LED",
	"tech conference holographic presentation",
	"data stream visualization flowing",
	"neural network topology display",
	"cyber security command center",
	"quantum computing lab",
	"holographic data charts floating",
]

var _scene_words_anomaly: Array[String] = [
	"massive purple dimensional crack in sky",
	"data corruption glitch effect world fragmenting",
	"strange purple energy field forming",
	"reality distortion buildings melting",
	"purple glowing particles floating",
	"glitch double vision overlapping dimensions",
	"dark dimensional portal on wall",
	"data stream corruption purple rain falling",
	"multiverse overlap two realities merging",
	"reality fracture purple light bleeding",
]

var _scene_words_talisman: Array[String] = [
	"holographic talisman glowing cyan ancient symbols",
	"digital talisman purple anomaly detection runes",
	"electronic amulet circuit board mystical symbols",
	"holographic protective charm hexagonal pattern data matrix",
	"quantum talisman sacred geometry circuit patterns",
	"digital seal ancient script holographic light",
	"holographic ward symbol glowing cyan energy field",
	"data talisman binary code mystical patterns",
]

func _ready():
	layer = -100
	_http_unsplash_search = HTTPRequest.new()
	_http_unsplash_search.request_completed.connect(_on_unsplash_search_response)
	_http_unsplash_search.timeout = 15.0
	add_child(_http_unsplash_search)

	_http_unsplash_image = HTTPRequest.new()
	_http_unsplash_image.request_completed.connect(_on_unsplash_image_response)
	_http_unsplash_image.timeout = 15.0
	add_child(_http_unsplash_image)

	_http_pollinations = HTTPRequest.new()
	_http_pollinations.request_completed.connect(_on_pollinations_response)
	_http_pollinations.timeout = 15.0
	add_child(_http_pollinations)

	_unsplash_reset_time = Time.get_ticks_msec() / 1000.0 + 3600.0
	_scan_local_fallback()

func _scan_local_fallback():
	for cat in _categories_base:
		_memory_cache[cat + "/_fallback"] = null
		var base_path = _categories_base[cat]
		for i in range(1, 6):
			var path = base_path + cat + "_%03d.png" % i
			if ResourceLoader.exists(path):
				var f = FileAccess.open(path, FileAccess.READ)
				if f:
					var data = f.get_buffer(f.get_length())
					f.close()
					if _is_valid_image_data(data):
						var res = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
						if res != null:
							_memory_cache[cat + "/_fallback"] = res
							break

func _exit_tree():
	for req in _dynamic_http_requests:
		if is_instance_valid(req):
			req.cancel_request()
			req.queue_free()
	_dynamic_http_requests.clear()

func _process(_delta):
	if not _request_queue.is_empty():
		_process_queue()

func get_image_count(category: String) -> int:
	return 999

func get_random_image(category: String) -> Texture2D:
	var cache_key = category + "/" + str(randi() % 999999)
	if _memory_cache.has(cache_key) and _memory_cache[cache_key] != null:
		return _memory_cache[cache_key]
	var fallback_key = category + "/_fallback"
	if _memory_cache.has(fallback_key) and _memory_cache[fallback_key] != null:
		_enqueue_request(category, cache_key)
		return _memory_cache[fallback_key]
	_enqueue_request(category, cache_key)
	return null

func get_daily_image(category: String) -> Texture2D:
	var day_seed = 1
	if has_node("/root/WorldCalendar"):
		day_seed = get_node("/root/WorldCalendar").get_day_seed()
	var cache_key = category + "/daily_" + str(day_seed)
	if _memory_cache.has(cache_key) and _memory_cache[cache_key] != null:
		return _memory_cache[cache_key]
	var fallback_key = category + "/_fallback"
	if _memory_cache.has(fallback_key) and _memory_cache[fallback_key] != null:
		_enqueue_request(category, cache_key)
		return _memory_cache[fallback_key]
	_enqueue_request(category, cache_key)
	return null

func get_image_by_index(category: String, _index: int) -> Texture2D:
	return get_random_image(category)

func get_category_for_phase() -> String:
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT:
			return "city_night"
		elif dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			return "city_rain"
	return "city_day"

func _enqueue_request(category: String, cache_key: String):
	var req_id = str(_request_id_counter)
	_request_id_counter += 1
	_request_queue.append({
		"id": req_id,
		"category": category,
		"cache_key": cache_key,
		"source": _source_map.get(category, "pollinations"),
	})

func _process_queue():
	if _request_queue.is_empty():
		return
	var req = _request_queue.pop_front()
	var category = req.category
	var cache_key = req.cache_key
	var source = req.source

	if source == "unsplash" and _can_use_unsplash():
		if _fetch_unsplash(category, cache_key):
			return
		_fetch_pollinations(category, cache_key)
	elif source == "unsplash":
		_fetch_pollinations(category, cache_key)
	else:
		_fetch_pollinations(category, cache_key)

func _can_use_unsplash() -> bool:
	var now = Time.get_ticks_msec() / 1000.0
	if now >= _unsplash_reset_time:
		_unsplash_request_count = 0
		_unsplash_reset_time = now + 3600.0
	return _unsplash_request_count < UNSPLASH_HOUR_LIMIT

func _fetch_unsplash(category: String, cache_key: String) -> bool:
	if _http_unsplash_search.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_request_queue.push_front({"id": str(_request_id_counter), "category": category, "cache_key": cache_key, "source": "unsplash"})
		return false

	var queries = _unsplash_queries.get(category, ["cyberpunk city"])
	var query = queries[randi() % queries.size()]
	var orientation = "landscape"
	if category == "ads":
		orientation = "portrait"

	var url = "https://api.unsplash.com/search/photos?query=%s&orientation=%s&per_page=10&content_filter=high" % [query.uri_encode(), orientation]
	var headers = ["Authorization: Client-ID " + UNSPLASH_ACCESS_KEY]
	var err = _http_unsplash_search.request(url, headers, HTTPClient.METHOD_GET)
	if err == OK:
		_unsplash_request_count += 1
		_pending_requests[_http_unsplash_search.get_instance_id()] = {
			"category": category,
			"cache_key": cache_key,
			"source": "unsplash_search",
		}
		return true
	return false

func _fetch_pollinations(category: String, cache_key: String) -> bool:
	if _http_pollinations.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_request_queue.push_front({"id": str(_request_id_counter), "category": category, "cache_key": cache_key, "source": "pollinations"})
		return false

	var prompt = _build_prompt(category)
	var size = _size_map.get(category, Vector2i(1024, 576))
	var seed_val = randi() % 999999
	var encoded = prompt.uri_encode()
	var url = "https://image.pollinations.ai/prompt/%s?width=%d&height=%d&seed=%d&nologo=true&model=flux" % [encoded, size.x, size.y, seed_val]
	var err = _http_pollinations.request(url)
	if err == OK:
		_pending_requests[_http_pollinations.get_instance_id()] = {
			"category": category,
			"cache_key": cache_key,
			"source": "pollinations",
		}
		return true
	return false

func _on_unsplash_search_response(result, response_code, _headers, body):
	var http_id = _http_unsplash_search.get_instance_id()
	var pending = _pending_requests.get(http_id)
	if not pending:
		return
	_pending_requests.erase(http_id)

	if result != OK or response_code != 200:
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) != OK:
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	var data = json.data
	if not data is Dictionary or not data.has("results"):
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	var results = data.results
	if results.is_empty():
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	var photo = results[randi() % results.size()]
	var image_url = ""
	if photo is Dictionary and photo.has("urls"):
		var urls = photo.urls
		if urls is Dictionary:
			var size_key = _size_map.get(pending.category, Vector2i(1024, 576))
			if size_key.y > size_key.x:
				image_url = urls.get("regular", "")
			else:
				image_url = urls.get("regular", "")
			if image_url == "":
				image_url = urls.get("small", "")

	if image_url == "":
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	if _http_unsplash_image.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		_fetch_pollinations(pending.category, pending.cache_key)
		return

	var img_headers = ["Authorization: Client-ID " + UNSPLASH_ACCESS_KEY, "Accept: image/*"]
	var err = _http_unsplash_image.request(image_url, img_headers, HTTPClient.METHOD_GET)
	if err == OK:
		_unsplash_request_count += 1
		_pending_requests[_http_unsplash_image.get_instance_id()] = {
			"category": pending.category,
			"cache_key": pending.cache_key,
			"source": "unsplash_image",
		}
	else:
		_fetch_pollinations(pending.category, pending.cache_key)

func _on_unsplash_image_response(result, response_code, _headers, body):
	var http_id = _http_unsplash_image.get_instance_id()
	var pending = _pending_requests.get(http_id)
	if not pending:
		return
	_pending_requests.erase(http_id)

	if result == OK and response_code == 200 and body.size() > 0 and _is_valid_image_data(body):
		var image = _load_image_from_buffer(body)
		if image != null:
			var texture = ImageTexture.create_from_image(image)
			_cache_put(texture, pending.cache_key)
			image_ready.emit(pending.category, texture)
			return

	_fetch_pollinations(pending.category, pending.cache_key)

func _on_pollinations_response(result, response_code, _headers, body):
	var http_id = _http_pollinations.get_instance_id()
	var pending = _pending_requests.get(http_id)
	if not pending:
		return
	_pending_requests.erase(http_id)

	if result == OK and response_code == 200 and body.size() > 0 and _is_valid_image_data(body):
		var image = _load_image_from_buffer(body)
		if image != null:
			var texture = ImageTexture.create_from_image(image)
			_cache_put(texture, pending.cache_key)
			image_ready.emit(pending.category, texture)
			return

func _cache_put(texture: Texture2D, key: String = ""):
	if _cache_order.size() >= MAX_CACHE_SIZE:
		var oldest = _cache_order.pop_front()
		if _memory_cache.has(oldest) and not oldest.ends_with("/_fallback"):
			_memory_cache.erase(oldest)
	var cache_key = key if key != "" else "auto_" + str(randi())
	_memory_cache[cache_key] = texture
	_cache_order.append(cache_key)

func _build_prompt(category: String) -> String:
	var words = _get_word_pool(category)
	if words.is_empty():
		words = ["cyberpunk city scene"]
	var scene = words[randi() % words.size()]
	match category:
		"city_day":
			return "cyberpunk city %s daytime bright sunlight neon signs holographic advertisements futuristic architecture ultra detailed digital painting" % scene
		"city_rain":
			return "cyberpunk city %s heavy rain night neon reflections wet asphalt puddles dark moody atmosphere detailed digital art" % scene
		"city_night":
			return "dark cyberpunk city %s empty streets purple glow anomaly crack in sky reality distortion otherworldly detailed digital painting" % scene
		"surveillance":
			return "CCTV security camera footage %s grainy green tint scan lines timestamp overlay REC indicator surveillance monitor detailed digital art" % scene
		"forum":
			return "smartphone photo cyberpunk %s blurry casual snapshot steam neon lights cozy atmosphere detailed digital photography" % scene
		"datawhale":
			return "futuristic DATAWHALE tech %s data visualization holographic display blue cyan glow AI laboratory detailed digital art" % scene
		"anomaly":
			return "%s dimension rift reality distortion purple energy cyberpunk anomaly event glitch effect detailed digital painting" % scene
		"ads":
			return "cyberpunk vertical advertisement %s neon product poster holographic effects commercial futuristic detailed digital art" % scene
		"weather":
			return "futuristic weather radar %s holographic map storm patterns blue cyan glow sci-fi meteorological display detailed digital art" % scene
		"talisman":
			return "holographic talisman %s glowing cyan ancient symbols circuit pattern data stream cyberpunk charm detailed digital art" % scene
		_:
			return "cyberpunk %s futuristic digital art detailed painting" % scene

func _get_word_pool(category: String) -> Array[String]:
	match category:
		"city_day", "city_rain", "city_night":
			var pool: Array[String] = [
				"street with neon signs and holographic billboards",
				"rooftop garden view with city skyline",
				"futuristic train station platform",
				"shopping district with holographic canopies",
				"harbor waterfront with neon reflections",
				"park with cherry blossoms and neon flowers",
				"convenience store exterior at noon",
				"highway overpass with flying vehicles",
				"night market with colorful umbrellas",
				"city skyline through fog",
			]
			return pool
		"surveillance":
			return _scene_words_surveillance
		"forum":
			var pool: Array[String] = [
				"ramen shop neon sign night",
				"street food stall steam rising",
				"cafe interior holographic menu",
				"arcade room neon lights",
				"alley graffiti art",
				"drone delivery in sky",
				"vending machine glowing",
				"convenience store shelf",
			]
			return pool
		"datawhale":
			return _scene_words_datawhale
		"anomaly":
			return _scene_words_anomaly
		"ads":
			var pool: Array[String] = [
				"neon drink advertisement poster",
				"holographic ramen shop poster",
				"DATAWHALE recruitment poster",
				"flying car advertisement poster",
				"cyber fashion clothing ad",
				"insurance holographic shield ad",
				"gaming arcade controller ad",
				"food delivery drone package ad",
			]
			return pool
		"weather":
			var pool: Array[String] = [
				"futuristic weather radar storm pattern",
				"holographic forecast screen temperature",
				"storm warning red alert lightning",
				"satellite view city cloud formations",
				"air quality index holographic bars",
				"weather station exterior sensors",
				"climate monitoring wall multiple screens",
				"weather alert system notification display",
			]
			return pool
		"talisman":
			return _scene_words_talisman
		_:
			return []

func request_class_portrait(class_id: int) -> void:
	if not has_node("/root/CharacterClassManager"):
		return
	var ccm = get_node("/root/CharacterClassManager")
	var prompt = ccm.get_class_image_prompt(class_id)
	if prompt.is_empty():
		return

	var cache_key = "class_portrait/" + str(class_id)
	if _memory_cache.has(cache_key) and _memory_cache[cache_key] != null:
		class_portrait_ready.emit(class_id, _memory_cache[cache_key])
		return

	var size = _size_map.get("class_portrait", Vector2i(512, 512))
	var seed_val = class_id * 1000 + (Time.get_ticks_msec() % 1000)
	var encoded = prompt.uri_encode()
	var url = "https://image.pollinations.ai/prompt/%s?width=%d&height=%d&seed=%d&nologo=true&model=flux" % [encoded, size.x, size.y, seed_val]

	var http_portrait = HTTPRequest.new()
	http_portrait.timeout = 20
	http_portrait.request_completed.connect(_on_portrait_response.bind(class_id, cache_key, http_portrait))
	add_child(http_portrait)
	_dynamic_http_requests.append(http_portrait)
	http_portrait.request(url)

func _on_portrait_response(result, response_code, _headers, body, class_id: int, cache_key: String, http_node: HTTPRequest):
	if result == OK and response_code == 200 and body.size() > 0 and _is_valid_image_data(body):
		var image = _load_image_from_buffer(body)
		if image != null:
			var texture = ImageTexture.create_from_image(image)
			_cache_put(texture, cache_key)
			class_portrait_ready.emit(class_id, texture)

	if is_instance_valid(http_node):
		_dynamic_http_requests.erase(http_node)
		http_node.queue_free()

static func _is_valid_image_data(data: PackedByteArray) -> bool:
	if data.size() < 8:
		return false
	if data[0] == 0x89 and data[1] == 0x50 and data[2] == 0x4E and data[3] == 0x47:
		return true
	if data[0] == 0xFF and data[1] == 0xD8 and data[2] == 0xFF:
		return true
	if data[0] == 0x52 and data[1] == 0x49 and data[2] == 0x46 and data[3] == 0x46:
		return true
	return false

static func _detect_image_format(data: PackedByteArray) -> String:
	if data.size() < 8:
		return "unknown"
	if data[0] == 0x89 and data[1] == 0x50 and data[2] == 0x4E and data[3] == 0x47:
		return "png"
	if data[0] == 0xFF and data[1] == 0xD8 and data[2] == 0xFF:
		return "jpg"
	if data[0] == 0x52 and data[1] == 0x49 and data[2] == 0x46 and data[3] == 0x46:
		return "webp"
	return "unknown"

static func _load_image_from_buffer(body: PackedByteArray) -> Image:
	var image = Image.new()
	var fmt = _detect_image_format(body)
	var err: int = OK
	match fmt:
		"png":
			err = image.load_png_from_buffer(body)
		"jpg":
			err = image.load_jpg_from_buffer(body)
		"webp":
			err = image.load_webp_from_buffer(body)
		_:
			err = image.load_png_from_buffer(body)
			if err != OK:
				err = image.load_jpg_from_buffer(body)
				if err != OK:
					err = image.load_webp_from_buffer(body)
	if err == OK and not image.is_empty():
		return image
	return null
