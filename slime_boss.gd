extends CharacterBody2D

@export var max_health: int = 30
@export var hop_speed: float = 310.0
@export var hop_force: float = -660.0
@export var slam_force: float = -960.0
@export var dash_speed: float = 680.0
@export var detection_range: float = 1200.0
@export_file("*.tscn") var victory_scene: String = "res://title_screen.tscn"

var player_root: Node2D = null
var health: int = 30
var is_acting: bool = false
var can_take_damage: bool = true
var is_slamming: bool = false
var is_enraged: bool = false
var move_count: int = 0
var stuck_timer: float = 0.0

@onready var hitbox: Area2D = get_node_or_null("Hitbox")
@onready var health_bar: ProgressBar = get_node_or_null("CanvasLayer/BossHealthBar")
@onready var col_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")

func _ready() -> void:
	health = max_health
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false

	if is_instance_valid(hitbox):
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _get_true_position() -> Vector2:
	# Uses the CollisionShape2D's actual world position in case the sprite is offset from (0,0)
	if is_instance_valid(col_shape):
		return col_shape.global_position
	return global_position

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		var grav_mult := 1.6 if (is_slamming and velocity.y > 0) else 1.0
		velocity += get_gravity() * grav_mult * delta
		stuck_timer += delta
	else:
		stuck_timer = 0.0
		velocity.x = move_toward(velocity.x, 0, 1100.0 * delta)
		if is_slamming:
			is_slamming = false
			scale = Vector2(1.35, 0.65)
			_spawn_shockwaves()
			if is_enraged:
				_spawn_acid_rain(3)

	var base_scale := Vector2(1.1, 1.1) if is_enraged else Vector2.ONE
	scale = scale.lerp(base_scale, 10.0 * delta)

	_state_machine()
	move_and_slide()

func _state_machine() -> void:
	player_root = get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player_root):
		return

	var my_pos := _get_true_position()
	var dist := my_pos.distance_to(player_root.global_position)

	if dist < detection_range:
		if is_instance_valid(health_bar) and not health_bar.visible:
			health_bar.visible = true

		# Attacks when on the floor OR if stuck floating for more than 1.5s
		if (is_on_floor() or stuck_timer > 1.5) and not is_acting:
			stuck_timer = 0.0
			_choose_attack()

func _choose_attack() -> void:
	is_acting = true
	move_count += 1

	var my_pos := _get_true_position()
	var dir: float = sign(player_root.global_position.x - my_pos.x)
	if dir == 0:
		dir = 1.0

	var speed_mult := 1.35 if is_enraged else 1.0
	var cooldown_mult := 0.72 if is_enraged else 1.0

	if move_count % 4 == 0:
		scale = Vector2(1.3, 0.7)
		await get_tree().create_timer(0.35 * cooldown_mult).timeout
		if not is_instance_valid(self):
			return
		velocity.x = dir * dash_speed * speed_mult
		velocity.y = -180.0
		await get_tree().create_timer(0.85 * cooldown_mult).timeout

	elif move_count % 3 == 0:
		is_slamming = true
		velocity.y = slam_force
		velocity.x = dir * hop_speed * 1.35 * speed_mult
		scale = Vector2(0.75, 1.35)
		await get_tree().create_timer(1.35 * cooldown_mult).timeout

	else:
		velocity.y = hop_force
		velocity.x = dir * hop_speed * speed_mult
		scale = Vector2(0.85, 1.2)
		await get_tree().create_timer(0.85 * cooldown_mult).timeout

	if is_instance_valid(self):
		is_acting = false

func _spawn_shockwaves() -> void:
	var origin := _get_true_position()
	for dir in [-1.0, 1.0]:
		var wave := Area2D.new()
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(36, 48)
		col.shape = shape

		var visual := ColorRect.new()
		visual.size = Vector2(36, 48)
		visual.position = Vector2(-18, -24)
		visual.color = Color(0.9, 0.2, 0.4) if is_enraged else Color(0.3, 1.0, 0.5)

		wave.add_child(col)
		wave.add_child(visual)
		wave.global_position = origin + Vector2(dir * 50.0, 10.0)
		get_parent().add_child(wave)

		wave.body_entered.connect(func(body: Node2D):
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(1, wave.global_position)
		)

		var tween := wave.create_tween()
		tween.tween_property(wave, "position:x", wave.position.x + dir * 650.0, 1.1)
		tween.finished.connect(wave.queue_free)

func _spawn_acid_rain(count: int) -> void:
	var origin := _get_true_position()
	for i in range(count):
		var glob := Area2D.new()
		var col := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12.0
		col.shape = shape

		var visual := ColorRect.new()
		visual.size = Vector2(22, 22)
		visual.position = Vector2(-11, -11)
		visual.color = Color(0.85, 0.25, 1.0)

		glob.add_child(col)
		glob.add_child(visual)
		glob.global_position = origin + Vector2(0, -40)
		get_parent().add_child(glob)

		glob.body_entered.connect(func(body: Node2D):
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(1, glob.global_position)
				glob.queue_free()
		)

		var spread_x := randf_range(-380.0, 380.0)
		var peak_y := origin.y - randf_range(260.0, 380.0)
		var tween := glob.create_tween()
		tween.tween_property(glob, "position:x", glob.position.x + spread_x, 1.2)
		tween.parallel().tween_property(glob, "position:y", peak_y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.chain().tween_property(glob, "position:y", origin.y + 300.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.finished.connect(glob.queue_free)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	var my_pos := _get_true_position()
	if body.velocity.y > 0 and body.global_position.y < my_pos.y - 30:
		body.velocity.y = -580.0
		take_damage(1)
	elif body.has_method("take_damage"):
		body.take_damage(1, my_pos)

func take_damage(amount: int) -> void:
	if not can_take_damage:
		return

	can_take_damage = false
	health = max(health - amount, 0)

	if is_instance_valid(health_bar):
		health_bar.visible = true
		health_bar.value = health

	if not is_enraged and health <= max_health / 2:
		is_enraged = true
		_spawn_shockwaves()
		_spawn_acid_rain(5)

	modulate = Color(1, 0.25, 0.25)
	if is_instance_valid(player_root):
		var push_dir: float = sign(_get_true_position().x - player_root.global_position.x)
		if push_dir == 0:
			push_dir = 1.0
		velocity.x = push_dir * 160.0

	await get_tree().create_timer(0.18).timeout
	if is_instance_valid(self):
		modulate = Color(1.0, 0.45, 0.45) if is_enraged else Color(1, 1, 1)
		can_take_damage = true
		if health <= 0:
			_die()

func _die() -> void:
	if is_instance_valid(health_bar):
		health_bar.visible = false
	if is_instance_valid(col_shape):
		col_shape.set_deferred("disabled", true)
	if is_instance_valid(hitbox):
		hitbox.set_deferred("monitoring", false)

	set_physics_process(false)
	modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(1.2).timeout
	if victory_scene != "":
		get_tree().call_deferred("change_scene_to_file", victory_scene)
