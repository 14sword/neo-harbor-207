extends Area2D

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 1.8
var owner_group: String = "rift_player"
var target_group: String = "rift_enemy"
var pierce: int = 0
var projectile_color: Color = Color(0, 0.92, 1.0, 1.0)
var radius: float = 7.0
var status: String = ""
var status_duration: float = 0.0

var _hit_count: int = 0
var _elapsed: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	queue_redraw()

func configure(new_velocity: Vector2, new_damage: float, new_color: Color, new_target_group: String = "rift_enemy", new_radius: float = 7.0, new_pierce: int = 0) -> void:
	velocity = new_velocity
	damage = new_damage
	projectile_color = new_color
	target_group = new_target_group
	radius = new_radius
	pierce = new_pierce
	queue_redraw()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	global_position += velocity * delta
	rotation = velocity.angle()
	if _elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var tail_color := projectile_color
	tail_color.a = 0.25
	draw_rect(Rect2(Vector2(-radius * 3.5, -radius * 0.35), Vector2(radius * 3.5, radius * 0.7)), tail_color)
	draw_circle(Vector2.ZERO, radius, projectile_color)
	var core := Color(1, 1, 1, 0.85)
	draw_circle(Vector2.ZERO, radius * 0.45, core)

func _on_body_entered(body: Node2D) -> void:
	_try_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(target: Node) -> void:
	if not target or not target.is_in_group(target_group):
		return
	if target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		if not status.is_empty() and target.has_method("apply_status"):
			target.apply_status(status, status_duration)
		RiftFX.impact(get_tree().current_scene, global_position, radius * 4.0, projectile_color)
	_hit_count += 1
	if _hit_count > pierce:
		queue_free()
