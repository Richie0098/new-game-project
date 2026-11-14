extends Area2D

class_name Door

@export var destination_level_tag: String
@export var destination_door_tag:String
@export var spawn_destination = "up"

@onready var spawn = $Spawn

func Exit(body: Node2D) -> void:
	if body is Player2:
		get_tree().change_scene_to_file("res://level_2.tscn")
