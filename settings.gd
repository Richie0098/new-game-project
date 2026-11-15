extends Control

@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider
@onready var brightness_slider: HSlider = $VBoxContainer/BrightnessSlider
@onready var left_btn: Button = $VBoxContainer/LeftKeyButton
@onready var right_btn: Button = $VBoxContainer/RightKeyButton
@onready var jump_btn: Button = $VBoxContainer/JumpKeyButton
@onready var attack_btn: Button = $VBoxContainer/AttackKeyButton
@onready var back_btn: Button = $VBoxContainer/BackButton

var action_to_remap: String = ""
var active_button: Button = null

func _ready() -> void:
	# Load current volume & brightness values
	var master_bus := AudioServer.get_bus_index("Master")
	volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus))
	brightness_slider.value = SettingsManager.current_brightness

	# Connect UI signals
	volume_slider.value_changed.connect(_on_volume_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	left_btn.pressed.connect(func(): _start_remapping("ui_left", left_btn))
	right_btn.pressed.connect(func(): _start_remapping("ui_right", right_btn))
	jump_btn.pressed.connect(func(): _start_remapping("ui_accept", jump_btn))
	attack_btn.pressed.connect(func(): _start_remapping("ui_attack", attack_btn))
	back_btn.pressed.connect(_on_back_pressed)

	_update_key_labels()

func _on_volume_changed(value: float) -> void:
	var master_bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_bus, linear_to_db(value))
	AudioServer.set_bus_mute(master_bus, value <= 0.01)

func _on_brightness_changed(value: float) -> void:
	SettingsManager.set_brightness(value)

func _start_remapping(action: String, button: Button) -> void:
	action_to_remap = action
	active_button = button
	button.text = "Press any key..."

func _input(event: InputEvent) -> void:
	if action_to_remap != "" and event is InputEventKey and event.pressed:
		InputMap.action_erase_events(action_to_remap)
		InputMap.action_add_event(action_to_remap, event)
		action_to_remap = ""
		active_button = null
		_update_key_labels()
		get_viewport().set_input_as_handled()

func _update_key_labels() -> void:
	left_btn.text = "Move Left: " + _get_action_key("ui_left")
	right_btn.text = "Move Right: " + _get_action_key("ui_right")
	jump_btn.text = "Jump: " + _get_action_key("ui_accept")
	attack_btn.text = "Attack: " + _get_action_key("ui_attack")

func _get_action_key(action: String) -> String:
	var events := InputMap.action_get_events(action)
	for ev in events:
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode)
	return "None"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://title_screen.tscn")
