extends CharacterBody2D

signal boss_defeated

const GRAVITY = 1200.0
const HOP_SPEED = 260.0
const HOP_FORCE = -550.0
const SLAM_FORCE = -850.0

@export var max_health: int = 20
var health: int = 20
var is_active: bool = false
var action_timer: float = 1.5
var hop_count: int = 0
var is_slamming: bool = false

@onready var hitbox: Area2D = $Hitbox
@onready var health_bar: ProgressBar = get_node_or_null("CanvasLayer/BossHealthBar")

func _ready() -> void:
	health = max_health
	if is_instance_valid(health_bar):
		health_bar.max_value = max_health
		health_bar.value = health
		health_bar.visible = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func start_fight() -> void:
	is_active = true
	if is_instance_valid(health_bar):
		health_bar.visible = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.x = move_toward(velocity.x, 0, 800 * delta)
		if is_slamming:
			is_slamming = false
			scale = Vector2(1.25, 0.75) # Squish impact effect!

	scale = scale.lerp(Vector2.ONE, 10 * delta)

	if is_active and is_on_floor():
		action_timer -= delta
		if action_timer <= 0.0:
			_choose_attack()

	move_and_slide()

func _choose_attack() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var dir := 1.0
	if is_instance_valid(player):
		dir = sign(player.global_position.x - global_position.x)
		if dir == 0:
			dir = 1.0

	hop_count += 1
	if hop_count % 3 == 0:
		# Every 3rd jump is a Giant High Slam toward the player
		is_slamming = true
		velocity = Vector2(dir * HOP_SPEED * 1.3, SLAM_FORCE)
		scale = Vector2(0.8, 1.3)
		action_timer = 1.8
	else:
		# Standard chase hop
		velocity = Vector2(dir * HOP_SPEED, HOP_FORCE)
		scale = Vector2(0.85, 1.2)
		action_timer = 1.1

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Allow downward stomp bounce off the top of the slime!
	if body.velocity.y > 0 and body.global_position.y < global_position.y - 30:
		body.velocity.y = -550.0
		take_damage(1)
	elif body.has_method("take_damage"):
		body.take_damage(1, global_position)

func take_damage(amount: int) -> void:
	if not is_active:
		start_fight()

	health = max(health - amount, 0)
	if is_instance_valid(health_bar):
		health_bar.value = health

	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)
		if health <= 0:
			_die()

func _die() -> void:
	boss_defeated.emit()
	if is_instance_valid(health_bar):
		health_bar.visible = false
	queue_free()
