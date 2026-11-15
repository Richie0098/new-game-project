extends CharacterBody2D

const SPEED = 100.0
const BOUNCE_VELOCITY = -450.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: int = 1
var health: int = 3
var turn_cooldown: float = 0.0

@onready var ray_floor_right: RayCast2D = $Rayfloor
@onready var ray_floor_left: RayCast2D = $Rayfloor2
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if turn_cooldown > 0.0:
		turn_cooldown -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * SPEED
	move_and_slide()

	var active_floor_ray := ray_floor_right if direction == 1 else ray_floor_left
	var at_ledge := is_on_floor() and is_instance_valid(active_floor_ray) and not active_floor_ray.is_colliding()

	if turn_cooldown <= 0.0 and (is_on_wall() or at_ledge):
		direction *= -1
		turn_cooldown = 0.2
		_flip_visuals()

func _flip_visuals() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.flip_h = (direction == -1)
	elif has_node("AnimatedSprite2D"):
		$AnimatedSprite2D.flip_h = (direction == -1)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Stomp check: Player is falling downward and is above the beetle's center
	var is_falling: bool = body.velocity.y > 0
	var is_above: bool = body.global_position.y < global_position.y

	if is_falling and is_above:
		body.velocity.y = BOUNCE_VELOCITY
		take_damage(1)
	elif body.has_method("take_damage"):
		body.take_damage(1, global_position)

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)
		if health <= 0:
			die()

func die() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	set_physics_process(false)
	queue_free()
