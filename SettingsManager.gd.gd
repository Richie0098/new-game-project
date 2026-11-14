extends Node

var brightness_overlay: ColorRect
var current_brightness: float = 1.0 # 1.0 = full brightness, 0.2 = dark

func _ready() -> void:
	# Create a CanvasLayer on top of all scenes so brightness works everywhere
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	brightness_overlay = ColorRect.new()
	brightness_overlay.color = Color(0, 0, 0, 0)
	brightness_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brightness_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(brightness_overlay)

func set_brightness(value: float) -> void:
	current_brightness = clamp(value, 0.2, 1.0)
	# Darkens the screen by adjusting the black overlay transparency
	brightness_overlay.color.a = 1.0 - current_brightness
