extends CanvasLayer

signal evacuate_requested()

@onready var hp_bar: ProgressBar = $Root/TopBar/HpBox/HPBar
@onready var hp_label: Label = $Root/TopBar/HpBox/HPLabel
@onready var ep_bar: ProgressBar = $Root/TopBar/EpBox/EPBar
@onready var ep_label: Label = $Root/TopBar/EpBox/EPLabel
@onready var skill_bar: ProgressBar = $Root/TopBar/SkillBox/SkillBar
@onready var skill_label: Label = $Root/TopBar/SkillBox/SkillLabel
@onready var node_label: Label = $Root/InfoPanel/NodeLabel
@onready var modifier_label: Label = $Root/InfoPanel/ModifierLabel
@onready var wave_label: Label = $Root/InfoPanel/WaveLabel
@onready var kill_label: Label = $Root/InfoPanel/KillLabel
@onready var evacuate_button: Button = $Root/TopBar/EvacuateButton

func _ready() -> void:
	if evacuate_button:
		evacuate_button.pressed.connect(func(): evacuate_requested.emit())
	_apply_fonts()

func _apply_fonts() -> void:
	var tm = get_node_or_null("/root/UIThemeManager")
	if not tm:
		return
	for label in [hp_label, ep_label, skill_label, node_label, modifier_label, wave_label, kill_label]:
		if label:
			tm.apply_font_to_label(label, 13)

func bind_player(player: Node) -> void:
	if not player:
		return
	if player.has_signal("stats_changed"):
		player.stats_changed.connect(_on_player_stats)
	if player.has_signal("skill_cooldown_changed"):
		player.skill_cooldown_changed.connect(_on_skill_cd)

func set_node_info(tile: Dictionary) -> void:
	if node_label:
		node_label.text = "第%d层 %s · %s" % [
			int(tile.get("layer", 1)),
			tile.get("realm_name", "未知镶层"),
			tile.get("name", "裂隙节点"),
		]
	if modifier_label:
		modifier_label.text = "%s / %s\n%s" % [
			tile.get("time_name", tile.get("time_phase", "未知时相")),
			tile.get("weather_name", tile.get("weather", "未知天气")),
			tile.get("modifier", ""),
		]
	if kill_label:
		kill_label.text = "击破 0"

func set_run_progress(cleared: int, total: int) -> void:
	if wave_label:
		wave_label.text = "节点 %d/%d" % [cleared, total]

func set_wave(wave: int, total_waves: int, enemies_alive: int) -> void:
	if wave_label:
		wave_label.text = "波次 %d/%d · 场上 %d" % [wave, total_waves, enemies_alive]

func set_kills(kills: int, combo: int) -> void:
	if kill_label:
		kill_label.text = "击破 %d · 连击 %d" % [kills, combo]

func _on_player_stats(health: float, max_health: float, energy: float, max_energy: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_health
		hp_bar.value = health
	if hp_label:
		hp_label.text = "HP %d/%d" % [int(health), int(max_health)]
	if ep_bar:
		ep_bar.max_value = max_energy
		ep_bar.value = energy
	if ep_label:
		ep_label.text = "EP %d/%d" % [int(energy), int(max_energy)]

func _on_skill_cd(left: float, total: float) -> void:
	if skill_bar:
		skill_bar.max_value = total
		skill_bar.value = total - left
	if skill_label:
		skill_label.text = "技能 %.1fs" % [left] if left > 0.05 else "技能 READY"
