extends Node

var master_volume: float = 1.0
var sfx_volume: float = 0.7
var bgm_volume: float = 0.5
var bgm_enabled: bool = true

var sfx_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer

var sfx_path_map = {
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"message_send": "res://assets/audio/sfx/message_send.wav",
	"message_receive": "res://assets/audio/sfx/message_receive.wav",
	"interact": "res://assets/audio/sfx/interact.wav",
	"close": "res://assets/audio/sfx/close.wav"
}

var bgm_day_path: String = "res://assets/audio/bgm/轻音乐.mp3"
var bgm_night_dir: String = "res://assets/audio/bgm/赛博"
var current_bgm_list: Array = []
var current_bgm_index: int = 0
var _initialized: bool = false

func _ready():
	_initialize()

func _initialize():
	if _initialized:
		return

	sfx_player = AudioStreamPlayer.new()
	bgm_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	add_child(bgm_player)
	sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
	bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
	bgm_player.finished.connect(_on_bgm_finished)
	_scan_night_bgm()
	print("[AudioManager] 初始化完成，白天BGM: %s, 夜晚BGM数量: %d" % [bgm_day_path, current_bgm_list.size()])
	_initialized = true

func _scan_night_bgm():
	current_bgm_list.clear()
	var dir = DirAccess.open(bgm_night_dir)
	if dir == null:
		print("[AudioManager] 无法打开夜晚BGM目录: " + bgm_night_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".ogg") or file_name.ends_with(".mp3"):
			current_bgm_list.append(bgm_night_dir + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	current_bgm_list.shuffle()
	print("[AudioManager] 扫描到 %d 首夜晚BGM" % current_bgm_list.size())

func play_sfx(sfx_name: String):
	if not _initialized:
		_initialize()
	if sfx_path_map.has(sfx_name):
		var path = sfx_path_map[sfx_name]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream is AudioStream:
				sfx_player.stream = stream
				sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
				sfx_player.play()
			else:
				print("[AudioManager] 音效加载失败: " + path)
		else:
			print("[AudioManager] 音效文件不存在: " + path)
	else:
		print("[AudioManager] 未知的音效: " + sfx_name)

func play_send_message():
	play_sfx("message_send")

func play_receive_message():
	play_sfx("message_receive")

func play_interact():
	play_sfx("interact")

func play_ui_click():
	play_sfx("ui_click")

func play_close():
	play_sfx("close")

func play_bgm_day():
	if not _initialized:
		_initialize()
	if not bgm_enabled:
		return
	if ResourceLoader.exists(bgm_day_path):
		var stream = load(bgm_day_path)
		if stream:
			bgm_player.stream = stream
			bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
			bgm_player.play()
			print("[AudioManager] 播放白天BGM")
		else:
			print("[AudioManager] 白天BGM加载失败")
	else:
		print("[AudioManager] 白天BGM文件不存在: " + bgm_day_path)

func play_bgm_night():
	if not _initialized:
		_initialize()
	if not bgm_enabled:
		return
	if current_bgm_list.size() > 0:
		var path = current_bgm_list[randi() % current_bgm_list.size()]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				bgm_player.stream = stream
				bgm_player.volume_db = linear_to_db(bgm_volume * master_volume)
				bgm_player.play()
				print("[AudioManager] 播放夜晚BGM: " + path.get_file())
			else:
				print("[AudioManager] 夜晚BGM加载失败")
		else:
			print("[AudioManager] 夜晚BGM文件不存在: " + path)
	else:
		print("[AudioManager] 没有可用的夜晚BGM")

func _on_bgm_finished():
	if not bgm_enabled:
		return
	if has_node("/root/DayNightManager"):
		var dnm = get_node("/root/DayNightManager")
		if dnm.current_phase == dnm.DayPhase.NIGHT or dnm.current_phase == dnm.DayPhase.RAIN_NIGHT:
			play_bgm_night()
		else:
			play_bgm_day()
	else:
		play_bgm_night()

func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	_update_volumes()

func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	_update_volumes()

func set_bgm_volume(value: float):
	bgm_volume = clamp(value, 0.0, 1.0)
	_update_volumes()

func toggle_bgm():
	bgm_enabled = not bgm_enabled
	if bgm_enabled:
		play_bgm_day()
	else:
		bgm_player.stop()

func stop_bgm():
	bgm_player.stop()

func _update_volumes():
	if sfx_player:
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
	if bgm_player:
		bgm_player.volume_db = linear_to_db(bgm_volume * master_volume) if bgm_enabled else -60.0
