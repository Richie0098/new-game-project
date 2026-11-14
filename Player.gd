extends CharacterBody2D

const SPEED = 300.0
const ACCELERATION = 1800.0
const FRICTION = 2000.0
const JUMP_VELOCITY = -650.0
class_name player
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var coyote_timer: float = 0.0
const COYOTE_TIME = 0.1

func _physics_process(delta: float) -> void:
	# Coyote time tracking
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	else:
		coyote_timer -= delta
		velocity.y += gravity * delta

	# Jump & variable jump height
	if Input.is_action_just_pressed("ui_accept") and coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
	elif Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5

	# Smooth horizontal movement
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	move_and_slide()
