extends CharacterBody2D

var chargingJump = false
var playerRoot

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * 128 * delta
	else:
		velocity.y = 0
	StateMachine()
	move_and_slide()

func StateMachine() -> void:
	playerRoot = $"../Player"
	print(GetDist(playerRoot.position.x , playerRoot.position.y, position.x, position.y))
	if (GetDist(playerRoot.position.x, playerRoot.position.y, position.x, position.y) < 960 and is_on_floor()):
		velocity += Vector2(0, -400)
	else:
		if playerRoot.position.x < position.x:
			velocity.x = -400
		else:
			velocity.x = 400

func GetDist(x1, y1, x2, y2) -> float:
	return sqrt((x2-x1) ** 2 + (y2 - y1) ** 2)
