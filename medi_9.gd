extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer

# Variables del juego
var sequence = []  # Los 4 colores a presionar
var player_sequence = []  # Colores presionados por el jugador
var can_play = false
var showing_sequence = false
var game_started = false

# Botones de colores
var color_buttons = []
var button_colors = {
	"red": Color(0.9, 0.2, 0.2),
	"blue": Color(0.2, 0.5, 0.9),
	"green": Color(0.2, 0.7, 0.3),
	"yellow": Color(0.9, 0.9, 0.2)
}

# Nombres de seguridad para los colores
var security_names = {
	"red": " ROJO",
	"blue": "AZUL",
	"green": "VERDE",
	"yellow": "AMARILLO"
}

# Colores del tema
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.8, 0.8),
	"success": Color(0.2, 0.8, 0.2),
	"error": Color(0.8, 0.2, 0.2),
	"warning": Color(0.9, 0.9, 0.2),
	"info": Color(0.4, 0.8, 1.0)
}

# Componentes UI
var status_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var buttons_container: GridContainer
var sequence_display: HBoxContainer

# Timer
var time_left: float = 10.0
var max_time: float = 10.0

# Efectos
var flash_overlay: ColorRect

# Señal de completado
signal puzzle_completed
signal puzzle_failed


func _ready():
	randomize()
	setup_window()
	setup_ui()
	create_color_buttons()
	create_effects()
	# Iniciar automáticamente
	await get_tree().create_timer(1.0).timeout
	start_game()

func setup_window():
	# Ventana del mismo tamaño que los otros minijuegos
	var viewport_size = Vector2(get_viewport().size)
	var window_size = Vector2(1200, 1000)
	
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
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "✖"
	close_button.size = Vector2(60, 60)
	close_button.position = Vector2(window_size.x - 80, 20)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.add_theme_color_override("font_color", game_colors.error)
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func setup_ui():
	# Título
	var title = Label.new()
	title.text = "CÓDIGO RÁPIDO DE SEGURIDAD"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", game_colors.border)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.position = Vector2(170, 50)
	add_child(title)
	
	# Panel de tiempo
	create_timer_panel()
	
	# Panel de secuencia
	create_sequence_panel()
	
	# Panel de estado
	create_status_panel()

func create_timer_panel():
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(1000, 100)
	timer_panel.position = Vector2(100, 130)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = game_colors.panel
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_color = game_colors.info
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	timer_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(timer_panel)
	
	# Label del timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 15 segundos"
	timer_label.add_theme_font_size_override("font_size", 36)
	timer_label.add_theme_color_override("font_color", game_colors.warning)
	timer_label.position = Vector2(320, 10)
	timer_panel.add_child(timer_label)
	
	# Barra de tiempo
	timer_bar = ProgressBar.new()
	timer_bar.size = Vector2(900, 20)
	timer_bar.position = Vector2(50, 60)
	timer_bar.min_value = 0
	timer_bar.max_value = 100
	timer_bar.value = 100
	timer_bar.show_percentage = false
	
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.2, 0.2, 0.25)
	bar_style.corner_radius_top_left = 10
	bar_style.corner_radius_top_right = 10
	bar_style.corner_radius_bottom_left = 10
	bar_style.corner_radius_bottom_right = 10
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = game_colors.info
	fill_style.corner_radius_top_left = 10
	fill_style.corner_radius_top_right = 10
	fill_style.corner_radius_bottom_left = 10
	fill_style.corner_radius_bottom_right = 10
	
	timer_bar.add_theme_stylebox_override("background", bar_style)
	timer_bar.add_theme_stylebox_override("fill", fill_style)
	timer_panel.add_child(timer_bar)

func create_sequence_panel():
	var seq_panel = Panel.new()
	seq_panel.size = Vector2(600, 120)
	seq_panel.position = Vector2(300, 250)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_color = game_colors.border
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	seq_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(seq_panel)
	
	# Título
	var seq_title = Label.new()
	seq_title.text = "MEMORIZA ESTOS 4 CÓDIGOS:"
	seq_title.add_theme_font_size_override("font_size", 28)
	seq_title.add_theme_color_override("font_color", game_colors.warning)
	seq_title.position = Vector2(100, 10)
	seq_panel.add_child(seq_title)
	
	# Display de secuencia
	sequence_display = HBoxContainer.new()
	sequence_display.position = Vector2(150, 50)
	sequence_display.size = Vector2(200, 60)
	sequence_display.add_theme_constant_override("separation", 20)
	seq_panel.add_child(sequence_display)

func create_status_panel():
	# Panel de estado/instrucciones
	var status_panel = Panel.new()
	status_panel.size = Vector2(1000, 80)
	status_panel.position = Vector2(100, 750)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12)
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color(0.3, 0.3, 0.35)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	status_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(status_panel)
	
	status_label = Label.new()
	status_label.text = "Observa la secuencia..."
	status_label.add_theme_font_size_override("font_size", 32)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	status_label.position = Vector2(300, 20)
	status_panel.add_child(status_label)

func create_color_buttons():
	# Contenedor para los 4 botones
	buttons_container = GridContainer.new()
	buttons_container.columns = 2
	buttons_container.position = Vector2(350, 400)
	buttons_container.size = Vector2(500, 320)
	buttons_container.add_theme_constant_override("h_separation", 40)
	buttons_container.add_theme_constant_override("v_separation", 40)
	add_child(buttons_container)
	
	var colors_order = ["red", "blue", "green", "yellow"]
	
	for color_name in colors_order:
		var button = create_security_button(color_name)
		buttons_container.add_child(button)
		color_buttons.append(button)

func create_security_button(color_name: String) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(230, 140)
	
	var button = Panel.new()
	button.size = Vector2(230, 140)
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	
	var style = StyleBoxFlat.new()
	style.bg_color = button_colors[color_name] * 0.6
	style.border_width_top = 6
	style.border_width_bottom = 6
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_color = button_colors[color_name]
	style.corner_radius_top_left = 25
	style.corner_radius_top_right = 25
	style.corner_radius_bottom_left = 25
	style.corner_radius_bottom_right = 25
	style.shadow_size = 5
	style.shadow_color = Color(0, 0, 0, 0.3)
	button.add_theme_stylebox_override("panel", style)
	
	# Contenido del botón
	var vbox = VBoxContainer.new()
	vbox.size = button.size
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Texto de seguridad
	var label = Label.new()
	label.text = security_names[color_name]
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	vbox.add_child(label)
	button.add_child(vbox)
	container.add_child(button)
	
	# Metadata y eventos
	container.set_meta("color", color_name)
	container.set_meta("panel", button)
	container.set_meta("style", style)
	container.set_meta("label", label)
	
	button.gui_input.connect(_on_button_input.bind(container))
	
	return container

func _on_button_input(event: InputEvent, button: Control):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and can_play:
			button_pressed(button.get_meta("color"))

func button_pressed(color: String):
	if not can_play or showing_sequence:
		return
	
	# Añadir a la secuencia del jugador
	player_sequence.append(color)
	
	# Efecto visual
	flash_button(color, 0.3)
	
	# Actualizar display
	update_player_display()
	
	# Verificar si completó los 3 colores
	if player_sequence.size() == 4:
		can_play = false
		check_sequence()

func update_player_display():
	# Limpiar display anterior
	for child in sequence_display.get_children():
		child.queue_free()
	
	# Mostrar secuencia del jugador
	for color in player_sequence:
		var indicator = Panel.new()
		indicator.custom_minimum_size = Vector2(60, 60)
		
		var style = StyleBoxFlat.new()
		style.bg_color = button_colors[color]
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color.WHITE
		style.corner_radius_top_left = 30
		style.corner_radius_top_right = 30
		style.corner_radius_bottom_left = 30
		style.corner_radius_bottom_right = 30
		indicator.add_theme_stylebox_override("panel", style)
		
		sequence_display.add_child(indicator)

func check_sequence():
	var correct = true
	
	# Verificar si coincide
	for i in range(4):
		if i >= player_sequence.size() or player_sequence[i] != sequence[i]:
			correct = false
			break
	
	if correct:
		sequence_success()
	else:
		sequence_failed()

func flash_button(color: String, duration: float):
	for button in color_buttons:
		if button.get_meta("color") == color:
			var panel = button.get_meta("panel")
			var style = button.get_meta("style")
			var original_color = style.bg_color
			
			# Iluminar
			style.bg_color = button_colors[color]
			panel.add_theme_stylebox_override("panel", style)
			
			# Animación de escala
			var tween = create_tween()
			tween.tween_property(button, "scale", Vector2(1.1, 1.1), duration * 0.3)
			tween.tween_property(button, "scale", Vector2(1.0, 1.0), duration * 0.7)
			
			# Restaurar color
			await get_tree().create_timer(duration).timeout
			style.bg_color = original_color
			panel.add_theme_stylebox_override("panel", style)
			break

func start_game():
	game_started = true
	can_play = false
	showing_sequence = true
	sequence.clear()
	player_sequence.clear()
	
	# Generar secuencia de 3 colores aleatorios
	var colors = ["red", "blue", "green", "yellow"]
	for i in range(4):
		sequence.append(colors[randi() % colors.size()])
	
	status_label.text = " OBSERVA LA SECUENCIA..."
	status_label.add_theme_color_override("font_color", game_colors.warning)
	
	# Mostrar la secuencia
	await get_tree().create_timer(0.5).timeout
	await show_sequence()
	
	# Empezar el juego
	showing_sequence = false
	can_play = true
	time_left = 15.0
	
	status_label.text = "¡REPITE LA SECUENCIA!"
	status_label.add_theme_color_override("font_color", game_colors.info)

func show_sequence():
	# Mostrar cada color de la secuencia
	for i in range(4):
		await get_tree().create_timer(0.4).timeout
		flash_button(sequence[i], 0.6)
		add_to_sequence_display(sequence[i])
	
	await get_tree().create_timer(1.0).timeout
	
	# Limpiar display para que el jugador empiece
	for child in sequence_display.get_children():
		child.queue_free()

func add_to_sequence_display(color: String):
	var indicator = Panel.new()
	indicator.custom_minimum_size = Vector2(60, 60)
	
	var style = StyleBoxFlat.new()
	style.bg_color = button_colors[color] * 0.7
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = button_colors[color]
	style.corner_radius_top_left = 30
	style.corner_radius_top_right = 30
	style.corner_radius_bottom_left = 30
	style.corner_radius_bottom_right = 30
	indicator.add_theme_stylebox_override("panel", style)
	
	sequence_display.add_child(indicator)

func sequence_success():
	audio.stream_paused=true
	ganar.play()

	status_label.text = " ¡CORRECTO! CÓDIGO DESBLOQUEADO"
	status_label.add_theme_color_override("font_color", game_colors.success)
	status_label.position = Vector2(200, 20)
	
	# Efecto de éxito
	create_success_effect()
	
	# Cerrar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_completed")
	close_minigame()

func sequence_failed():
	audio.stream_paused=true
	perder.play()
	status_label.text = "¡INCORRECTO! ACCESO DENEGADO"
	status_label.add_theme_color_override("font_color", game_colors.error)
	status_label.position = Vector2(240, 20)
	# Mostrar la secuencia correcta
	for child in sequence_display.get_children():
		child.queue_free()
	
	for color in sequence:
		add_to_sequence_display(color)
	
	# Efecto de error
	create_error_effect()
	
	# Cerrar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func time_out():
	audio.stream_paused=true
	perder.play()
	can_play = false
	status_label.text = "¡TIEMPO AGOTADO! ACCESO DENEGADO"
	status_label.add_theme_color_override("font_color", game_colors.error)
	status_label.position = Vector2(190, 20)
	create_error_effect()
	
	# Cerrar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func create_effects():
	# Overlay para flash
	flash_overlay = ColorRect.new()
	flash_overlay.size = size
	flash_overlay.color = Color(1, 1, 1, 0)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)

func create_success_effect():
	# Flash verde
	flash_overlay.color = Color(0, 1, 0, 0.3)
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.3)
	
	# Partículas
	for i in range(15):
		var particle = Label.new()
		particle.text = "✨"
		particle.add_theme_font_size_override("font_size", 36)
		particle.position = Vector2(600, 500) + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		add_child(particle)
		
		var end_pos = particle.position + Vector2(randf_range(-200, 200), randf_range(-200, -50))
		var ptween = create_tween()
		ptween.tween_property(particle, "position", end_pos, 1.0)
		ptween.parallel().tween_property(particle, "modulate:a", 0.0, 1.0)
		ptween.tween_callback(particle.queue_free)

func create_error_effect():
	# Flash rojo
	flash_overlay.color = Color(1, 0, 0, 0.3)
	var tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, 0.3)
	
	# Shake simple
	var original_pos = position
	for i in range(3):
		position = original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		await get_tree().create_timer(0.05).timeout
	position = original_pos

func _process(delta):
	if can_play and game_started:
		# Actualizar timer
		time_left -= delta
		time_left = max(0, time_left)
		
		timer_label.text = "TIEMPO: " + str(int(ceil(time_left))) + " segundos"
		timer_bar.value = (time_left / max_time) * 100
		
		# Cambiar color según tiempo restante
		var fill_style = timer_bar.get_theme_stylebox("fill")
		if time_left <= 3:
			fill_style.bg_color = game_colors.error
			timer_label.add_theme_color_override("font_color", game_colors.error)
		elif time_left <= 5:
			fill_style.bg_color = game_colors.warning
			timer_label.add_theme_color_override("font_color", game_colors.warning)
		else:
			fill_style.bg_color = game_colors.info
			timer_label.add_theme_color_override("font_color", game_colors.info)
		timer_bar.add_theme_stylebox_override("fill", fill_style)
		
		# Tiempo agotado
		if time_left <= 0:
			can_play = false
			time_out()

func _on_close_pressed():
	close_minigame()

func close_minigame():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()
	
	# Reactivar movimiento del jugador
	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		print("🎮 Movimiento del jugador reactivado")


func show_minigame():
	visible = true
