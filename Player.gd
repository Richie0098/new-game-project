extends CharacterBody2D

const SPEED = 300.0
const ACCELERATION = 1800.0
const FRICTION = 2000.0
const JUMP_VELOCITY = -650.0
const COYOTE_TIME = 0.1

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var health: int = 3
var is_invincible: bool = false
var is_attacking: bool = false
var facing_dir: int = 1

@onready var hearts_container: HBoxContainer = $CanvasLayer/HeartsContainer
@onready var attack_area: Area2D = $AttackArea
@onready var attack_visual: ColorRect = $AttackArea/ColorRect

func _ready() -> void:
	attack_area.monitoring = false
	attack_visual.visible = false
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	_update_hearts_ui()
	$AnimatedSprite2D.play()

func _process(delta: float) -> void:
	if is_on_floor():
		if velocity.x == 0:
			$AnimatedSprite2D.animation = "idle"
		else:
			$AnimatedSprite2D.animation = "walk"
	else:
		if velocity.y < 0:
			$AnimatedSprite2D.animation = "jump"
		else:
			$AnimatedSprite2D.animation = "fall"

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
	elif Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		facing_dir = int(sign(direction))
		# Flip attack hitbox to face left or right
		attack_area.scale.x = facing_dir
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = (facing_dir == -1)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	if Input.is_action_just_pressed("attack") and not is_attacking:
		_perform_attack()

	move_and_slide()

func _perform_attack() -> void:
	is_attacking = true
	attack_area.monitoring = true
	attack_visual.visible = true

	await get_tree().create_timer(0.15).timeout

	if is_instance_valid(self):
		attack_area.monitoring = false
		attack_visual.visible = false
		is_attacking = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("take_damage"):
		body.take_damage(1)

func take_damage(amount: int, enemy_position: Vector2) -> void:
	if is_invincible:
		return

	health = max(health - amount, 0)
	_update_hearts_ui()
	is_invincible = true

	var push_dir: float = sign(global_position.x - enemy_position.x)
	if push_dir == 0:
		push_dir = 1.0
	velocity = Vector2(push_dir * 350.0, -300.0)

	if health <= 0:
		get_tree().call_deferred("reload_current_scene")
		return

	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)
		is_invincible = false

func _update_hearts_ui() -> void:
	var hearts := hearts_container.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = i < health
