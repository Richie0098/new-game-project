extends CharacterBody2D

const SPEED = 100.0
const CENTER_X = 125.0 # Matches your current CollisionShape2D X offset

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction: int = 1
var health: int = 3

@onready var ray_wall: RayCast2D = $Raywall
@onready var ray_floor_right: RayCast2D = $Rayfloor
@onready var ray_floor_left: RayCast2D = $Rayfloor2

func _ready() -> void:
	# Center the wall raycast horizontally and point it forward
	ray_wall.position.x = CENTER_X
	ray_wall.target_position = Vector2(30 * direction, 0)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	var active_floor_ray = ray_floor_right if direction == 1 else ray_floor_left
	var hit_wall = ray_wall.is_colliding()
	var at_ledge = is_on_floor() and not active_floor_ray.is_colliding()

	if hit_wall or at_ledge:
		direction *= -1
		ray_wall.target_position.x = 72 * direction
		$Sprite2D.scale.x *= -1

	velocity.x = direction * SPEED
	move_and_slide()

func take_damage(amount: int) -> void:
	health -= amount
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	
	# Check is_instance_valid in case the enemy died during the 0.1s wait
	if is_instance_valid(self):
		modulate = Color(1, 1, 1)
		if health <= 0:
			die()

func die() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	queue_free()
