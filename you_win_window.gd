extends Control

# Variables de estilo
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.9, 0.2),  # Verde para victoria
	"button_bg": Color(0.3, 0.3, 0.35),
	"button_hover": Color(0.4, 0.4, 0.45),
	"text": Color(0.9, 0.9, 0.9)
}

signal next_selected()
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
	# Título YOU WIN!
	var title = Label.new()
	title.text = "YOU WIN!"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", game_colors.border)
	title.add_theme_color_override("font_shadow_color", Color(0.1, 0.4, 0.1))
	title.add_theme_constant_override("shadow_offset_x", 4)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.position = Vector2(220, 150)
	add_child(title)
	
	# Mensaje
	var message = Label.new()
	message.text = "You have save the lab!"
	message.add_theme_font_size_override("font_size", 28)
	message.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	message.position = Vector2(250, 280)
	add_child(message)

	# Contenedor de botones
	var button_container = HBoxContainer.new()
	button_container.position = Vector2(230, 400)
	button_container.size = Vector2(400, 100)
	button_container.add_theme_constant_override("separation", 50)
	add_child(button_container)
	
	# Botón Next
	var next_button = create_button("NEXT", game_colors.border)
	next_button.pressed.connect(_on_next_pressed)
	button_container.add_child(next_button)
	
	# Botón Back to Menu
	var menu_button = create_button("MENU", Color(0.5, 0.5, 0.6))
	menu_button.pressed.connect(_on_menu_pressed)
	button_container.add_child(menu_button)
	
	# Animación de título
	var title_tween = create_tween()
	title_tween.set_loops()
	title_tween.tween_property(title, "scale", Vector2(1.1, 1.1), 0.8)
	title_tween.tween_property(title, "scale", Vector2(1.0, 1.0), 0.8)

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

func create_victory_particles():
	# Crear confeti animado
	for i in range(20):
		var particle = ColorRect.new()
		particle.color = [
			Color(1.0, 0.2, 0.2),
			Color(0.2, 1.0, 0.2),
			Color(0.2, 0.2, 1.0),
			Color(1.0, 1.0, 0.2),
			Color(1.0, 0.2, 1.0)
		][randi() % 5]
		
		particle.size = Vector2(10, 10)
		particle.position = Vector2(randf_range(100, 700), -20)
		add_child(particle)
		
		# Animación de caída
		var tween = create_tween()
		tween.tween_property(particle, "position:y", 650, randf_range(2.0, 4.0))
		tween.parallel().tween_property(particle, "rotation", randf_range(-PI, PI), randf_range(2.0, 4.0))
		tween.tween_callback(particle.queue_free)

func _on_next_pressed():
	emit_signal("next_selected")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://lab_2.tscn")

func _on_menu_pressed():
	emit_signal("menu_selected")
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	get_tree().change_scene_to_file("res://interfaz/menu.tscn")
