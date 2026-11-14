extends CharacterBody2D
const SPEED = 100.0
var gravity = 2000.0
var direction = 1
var health = 3

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	if $Raywall.is_colliding() or (is_on_floor() and not $Rayfloor.is_colliding()):
		direction = direction * -1
		
		$Raywall.target_position.x = abs($Raywall.target_position.x) * direction
		$Rayfloor.position.x = abs($Rayfloor.position.x) * direction

	velocity.x = direction * SPEED
	move_and_slide()

func take_damage(amount):
	health -= amount
	
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()
func die():
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	queue_free()
