extends PanelContainer

@onready var message_label: Label = $MarginContainer/MessageLabel
var tween: Tween

func setup(message: String, color: Color, duration: float = 3.0):
	message_label.text = message
	message_label.add_theme_color_override("font_color", color)
	
	# Estilo del panel
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	style_box.border_color = color
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.corner_radius_top_left = 10
	style_box.corner_radius_top_right = 10
	style_box.corner_radius_bottom_left = 10
	style_box.corner_radius_bottom_right = 10
	add_theme_stylebox_override("panel", style_box)
	
	start_fade_out(duration)

func start_fade_out(duration: float):
	if tween:
		tween.kill()
	
	tween = create_tween()
	tween.tween_interval(duration)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _exit_tree():
	if tween:
		tween.kill()
