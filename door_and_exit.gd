extends Node2D


@export_file("*.tscn") var next_level: String

func _ready() -> void:
	_on_area_2D_area_shape_entered().connect(_on_area_2D_area_shape_entered())

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and next_level != "":
		get_tree().call_deferred("change_scene_to_file", next_level)
