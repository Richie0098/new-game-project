extends CharacterBody2D

const SPEED = 300.0
const ACCELERATION = 1800.0
const FRICTION = 2000.0
const COYOTE_TIME = 0.1

var jump_velocity: float = -650.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
var health: int = 3
var is_invincible: bool = false
var is_attacking: bool = false
var facing_dir: int = 1

@onready var hearts_container: HBoxContainer = get_node_or_null("CanvasLayer/HeartsContainer")
@onready var attack_area: Area2D = get_node_or_null("AttackArea")
@onready var slash_sprite: AnimatedSprite2D = get_node_or_null("AttackArea/SlashSprite")
@onready var player_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

func _ready() -> void:
	if is_instance_valid(attack_area):
		attack_area.monitoring = false
		attack_area.body_entered.connect(_on_attack_area_body_entered)
	if is_instance_valid(slash_sprite):
		slash_sprite.visible = false
	_update_hearts_ui()

func _physics_process(delta: float) -> void:
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0:
		velocity.y = jump_velocity
		coyote_timer = 0.0
	elif Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		facing_dir = int(sign(direction))
		if is_instance_valid(attack_area):
			attack_area.scale.x = facing_dir
		if is_instance_valid(player_sprite):
			player_sprite.flip_h = (facing_dir == -1)
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	_update_player_animation(direction)

	# Triggers on custom "ui_attack", F key, or Left Mouse Click
	var attack_pressed := (InputMap.has_action("ui_attack") and Input.is_action_just_pressed("ui_attack")) \
		or Input.is_key_pressed(KEY_F) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if attack_pressed and not is_attacking:
		print("ATTACK TRIGGERED!")
		_perform_attack()

	move_and_slide()

func _update_player_animation(direction: float) -> void:
	if not is_instance_valid(player_sprite) or not player_sprite.sprite_frames:
		return

	var frames := player_sprite.sprite_frames
	if not is_on_floor() and frames.has_animation("jump"):
		player_sprite.play("jump")
	elif direction != 0:
		for anim_name in ["walk", "run", "move", "default"]:
			if frames.has_animation(anim_name):
				player_sprite.play(anim_name)
				break
	else:
		for anim_name in ["idle", "stand"]:
			if frames.has_animation(anim_name):
				player_sprite.play(anim_name)
				return
		player_sprite.stop()

func _perform_attack() -> void:
	is_attacking = true
	if is_instance_valid(attack_area):
		attack_area.monitoring = true
	else:
		print("ERROR: AttackArea node not found!")

	if is_instance_valid(slash_sprite):
		slash_sprite.visible = true
		slash_sprite.z_index = 10
		slash_sprite.frame = 0
		if slash_sprite.sprite_frames:
			var anim := "slash" if slash_sprite.sprite_frames.has_animation("slash") else "default"
			slash_sprite.play(anim)
			print("Playing slash animation: ", anim)
	else:
		print("ERROR: SlashSprite node not found!")

	await get_tree().create_timer(0.25).timeout
	if is_instance_valid(self):
		if is_instance_valid(attack_area):
			attack_area.monitoring = false
		if is_instance_valid(slash_sprite):
			slash_sprite.visible = false
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
	if not is_instance_valid(hearts_container):
		return
	var hearts := hearts_container.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = i < health

func _on_pad_area_entered(area: Area2D) -> void:
	jump_velocity = -1300

func _on_pad_area_exited(area: Area2D) -> void:
	jump_velocity = -650
