extends Control

# Variables de estilo
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.9, 0.2, 0.2),  # Rojo para game over
	"button_bg": Color(0.3, 0.3, 0.35),
	"button_hover": Color(0.4, 0.4, 0.45),
	"text": Color(0.9, 0.9, 0.9)
}

signal retry_selected()
signal menu_selected()

func _ready():
	setup_window()
	setup_ui()
	
	# Animación de entrada
	scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)

func setup_window():
	var viewport_size = Vector2(get_viewport().size)
	var window_size = Vector2(800, 600)
	
	position = (viewport_size - window_size) / 2
	size = window_size
	
	# Fondo oscuro
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.85)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.position = -position
	bg.size = viewport_size
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	
	# Panel principal
	var window_panel = Panel.new()
	window_panel.name = "WindowPanel"
	window_panel.size = window_size
	
	var window_style = StyleBoxFlat.new()
	window_style.bg_color = game_colors.bg
	window_style.border_width_top = 6
	window_style.border_width_bottom = 6
	window_style.border_width_left = 6
	window_style.border_width_right = 6
	window_style.border_color = game_colors.border
	window_style.corner_radius_top_left = 20
	window_style.corner_radius_top_right = 20
	window_style.corner_radius_bottom_left = 20
	window_style.corner_radius_bottom_right = 20
	window_panel.add_theme_stylebox_override("panel", window_style)
	add_child(window_panel)

func setup_ui():
	# Título GAME OVER
	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", game_colors.border)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.position = Vector2(190, 150)
	add_child(title)
	
	# Mensaje
	var message = Label.new()
	message.text = "The Robbers have invaded the lab!"
	message.add_theme_font_size_override("font_size", 28)
	message.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	message.position = Vector2(170, 270)
	add_child(message)
	
	# Contenedor de botones
	var button_container = HBoxContainer.new()
	button_container.position = Vector2(230, 350)
	button_container.size = Vector2(400, 100)
	button_container.add_theme_constant_override("separation", 50)
	add_child(button_container)
	
	# Botón Retry
	var retry_button = create_button("TRY AGAIN", game_colors.border)
	retry_button.pressed.connect(_on_retry_pressed)
	button_container.add_child(retry_button)
	
	# Botón Menu
	var menu_button = create_button("MENU", Color(0.5, 0.5, 0.6))
	menu_button.pressed.connect(_on_menu_pressed)
	button_container.add_child(menu_button)
	
	# Animación de título pulsante
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title, "scale", Vector2(1.05, 1.05), 1.0)
	tween.tween_property(title, "scale", Vector2(1.0, 1.0), 1.0)

func create_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 60)
	button.add_theme_font_size_override("font_size", 24)
	
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = color * 0.7
	button_style.border_width_top = 3
	button_style.border_width_bottom = 3
	button_style.border_width_left = 3
	button_style.border_width_right = 3
	button_style.border_color = color
	button_style.corner_radius_top_left = 10
	button_style.corner_radius_top_right = 10
	button_style.corner_radius_bottom_left = 10
	button_style.corner_radius_bottom_right = 10
	
	var button_hover = StyleBoxFlat.new()
	button_hover.bg_color = color * 0.9
	button_hover.border_width_top = 3
	button_hover.border_width_bottom = 3
	button_hover.border_width_left = 3
	button_hover.border_width_right = 3
	button_hover.border_color = color * 1.2
	button_hover.corner_radius_top_left = 10
	button_hover.corner_radius_top_right = 10
	button_hover.corner_radius_bottom_left = 10
	button_hover.corner_radius_bottom_right = 10
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_stylebox_override("hover", button_hover)
	button.add_theme_stylebox_override("pressed", button_style)
	
	return button

func _on_retry_pressed():
	emit_signal("retry_selected")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://lab_3.tscn")

func _on_menu_pressed():
	emit_signal("menu_selected")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://interfaz/menu.tscn")
