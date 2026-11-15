extends CharacterBody2D

class_name Player2

const SPEED = 300.0
const JUMP_VELOCITY = -650.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()

func _ready() -> void:
	$AnimatedSprite2D.play()

func _process(delta: float) -> void:
	if is_on_floor():
		if velocity.x == 0:
			$AnimatedSprite2D.animation = "idle"
		else:
			$AnimatedSprite2D.animation = "walk"
	else:
		if velocity.y > 0:
			$AnimatedSprite2D.animation = "fall"
		else:
			$AnimatedSprite2D.animation = "jump"
	if velocity.x < 0:
		$AnimatedSprite2D.scale.x = -8
	else:
		$AnimatedSprite2D.scale.x = 8
