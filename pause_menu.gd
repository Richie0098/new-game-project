extends CanvasLayer

@onready var resume_btn: Button = $VBoxContainer/ResumeButton
@onready var restart_btn: Button = $VBoxContainer/RestartButton
@onready var settings_btn: Button = $VBoxContainer/SettingsButton
@onready var title_btn: Button = $VBoxContainer/TitleButton

var settings_instance: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_btn.pressed.connect(_toggle_pause)
	restart_btn.pressed.connect(_on_restart_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	title_btn.pressed.connect(_on_title_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if is_instance_valid(settings_instance):
			_close_settings()
		else:
			_toggle_pause()
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	var new_pause_state := not get_tree().paused
	get_tree().paused = new_pause_state
	visible = new_pause_state

func _on_settings_pressed() -> void:
	$VBoxContainer.visible = false
	settings_instance = load("res://settings.tscn").instantiate()
	add_child(settings_instance)

func _close_settings() -> void:
	if is_instance_valid(settings_instance):
		settings_instance.queue_free()
		settings_instance = null
	$VBoxContainer.visible = true

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_title_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://title_screen.tscn")
