extends Node

var chargingJump = false
var playerRoot

func _ready() -> void:
	playerRoot = $CharacterBody2D

func _physics_process(delta: float) -> void:
	StateMachine()

func StateMachine() -> void:
	if GetDist(playerRoot.position.x , playerRoot.position.y, self.position.x, self.position.y) < 200:
		pass

func GetDist(x1, y1, x2, y2) -> float:
	return sqrt((x2-x1) ^ 2 + (y2 - y1) ^ 2)
