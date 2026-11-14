extends Node2D

@export_file("*.tscn") var next_level: String

func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	# Use the Inspector path if you picked one
	if next_level != "":
		get_tree().call_deferred("change_scene_to_file", next_level)
		return

	# Otherwise, auto-detect based on the current scene's file name
	var current_scene = get_tree().current_scene.scene_file_path
	if "level_1" in current_scene:
		get_tree().call_deferred("change_scene_to_file", "res://level_2.tscn")
	elif "level_2" in current_scene:
		get_tree().call_deferred("change_scene_to_file", "res://level_3.tscn")
