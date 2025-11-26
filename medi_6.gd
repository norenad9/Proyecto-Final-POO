extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Variables del minijuego
var left_cables = []
var right_cables = []
var cable_colors = []
var connections = []
var current_dragging_cable = null
var current_line = null
var completed_connections = 0

# Variables de juego
var time_left: float = 20.0
var max_time: float = 20.0
var game_active: bool = true

# Colores para los cables
var available_colors = [
	Color(1.0, 0.0, 0.0),    # Rojo
	Color(0.0, 0.0, 1.0),    # Azul
	Color(0.0, 1.0, 0.0),    # Verde
	Color(1.0, 1.0, 0.0),    # Amarillo
	Color(1.0, 0.0, 1.0)     # Magenta
]

# Componentes UI
var timer_label: Label
var timer_bar: ProgressBar
var status_label: Label
var cables_container: Control
var lines_container: Control

# Colores del tema
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.8, 0.8),
	"success": Color(0.2, 0.9, 0.2),
	"error": Color(0.9, 0.2, 0.2),
	"warning": Color(0.9, 0.9, 0.2),
	"info": Color(0.4, 0.8, 1.0)
}

signal puzzle_completed
signal puzzle_failed


func _ready():
	randomize()
	setup_window()
	setup_ui()
	setup_cables()

func setup_window():
	var viewport_size = Vector2(get_viewport().size)
	var window_size = Vector2(1200, 800)
	
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
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	close_button.text = "X"
	close_button.size = Vector2(60, 60)
	close_button.position = Vector2(window_size.x - 80, 20)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.add_theme_color_override("font_color", game_colors.error)
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func setup_ui():
	# Título
	var title = Label.new()
	title.text = "REPARACIÓN DE CABLES"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(320, 50)
	add_child(title)
	
	# Instrucciones
	var instruction = Label.new()
	instruction.text = "Conecta los cables del mismo color arrastrando de izquierda a derecha"
	instruction.add_theme_font_size_override("font_size", 24)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction.position = Vector2(200, 110)
	add_child(instruction)
	
	# Panel de timer
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(1000, 70)
	timer_panel.position = Vector2(100, 160)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = game_colors.panel
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = game_colors.warning
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	timer_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(timer_panel)
	
	# Timer label
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 20"
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", game_colors.warning)
	timer_label.position = Vector2(50, 18)
	timer_panel.add_child(timer_label)
	
	# Barra de tiempo
	timer_bar = ProgressBar.new()
	timer_bar.size = Vector2(700, 30)
	timer_bar.position = Vector2(250, 20)
	timer_bar.min_value = 0
	timer_bar.max_value = 100
	timer_bar.value = 100
	timer_bar.show_percentage = false
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.25)
	bar_bg.corner_radius_top_left = 15
	bar_bg.corner_radius_top_right = 15
	bar_bg.corner_radius_bottom_left = 15
	bar_bg.corner_radius_bottom_right = 15
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = game_colors.warning
	bar_fill.corner_radius_top_left = 15
	bar_fill.corner_radius_top_right = 15
	bar_fill.corner_radius_bottom_left = 15
	bar_fill.corner_radius_bottom_right = 15
	
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	timer_panel.add_child(timer_bar)
	
	# Estado
	status_label = Label.new()
	status_label.text = "Conecta todos los cables antes de que se acabe el tiempo"
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_label.position = Vector2(250, 700)
	add_child(status_label)

func setup_cables():
	# Contenedor para cables
	cables_container = Control.new()
	cables_container.position = Vector2(100, 280)
	cables_container.size = Vector2(1000, 400)
	add_child(cables_container)
	
	# Contenedor para líneas (debajo de los cables)
	lines_container = Control.new()
	lines_container.position = Vector2(0, 0)
	lines_container.size = cables_container.size
	lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cables_container.add_child(lines_container)
	
	# Mezclar colores
	cable_colors = available_colors.duplicate()
	cable_colors.shuffle()
	
	# Panel izquierdo
	var left_panel = Panel.new()
	left_panel.size = Vector2(150, 350)
	left_panel.position = Vector2(50, 0)
	
	var left_style = StyleBoxFlat.new()
	left_style.bg_color = Color(0.2, 0.2, 0.25)
	left_style.border_width_top = 4
	left_style.border_width_bottom = 4
	left_style.border_width_left = 4
	left_style.border_width_right = 4
	left_style.border_color = Color(0.4, 0.4, 0.5)
	left_style.corner_radius_top_left = 10
	left_style.corner_radius_top_right = 10
	left_style.corner_radius_bottom_left = 10
	left_style.corner_radius_bottom_right = 10
	left_panel.add_theme_stylebox_override("panel", left_style)
	cables_container.add_child(left_panel)
	
	# Panel derecho
	var right_panel = Panel.new()
	right_panel.size = Vector2(150, 350)
	right_panel.position = Vector2(800, 0)
	
	right_panel.add_theme_stylebox_override("panel", left_style)
	cables_container.add_child(right_panel)
	
	# Crear cables izquierdos
	for i in range(5):
		var cable = create_cable(cable_colors[i], true, i)
		cable.position = Vector2(160, 40 + i * 65)
		cable.z_index = 10     
		cables_container.add_child(cable)
		left_cables.append(cable)
	
	# Crear cables derechos (orden diferente)
	var right_colors = cable_colors.duplicate()
	right_colors.shuffle()
	for i in range(5):
		var cable = create_cable(right_colors[i], false, i)
		cable.position = Vector2(790, 40 + i * 65)
		cable.z_index = 10     
		cables_container.add_child(cable)
		right_cables.append(cable)

func create_cable(color: Color, is_left: bool, index: int) -> Control:
	var cable = Control.new()
	cable.size = Vector2(60, 50)
	cable.mouse_filter = Control.MOUSE_FILTER_STOP

	
	# Base del cable
	var base = Panel.new()
	base.size = Vector2(60, 50)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE  
	
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.3, 0.3, 0.35)
	base_style.border_width_top = 3
	base_style.border_width_bottom = 3
	base_style.border_width_left = 3
	base_style.border_width_right = 3
	base_style.border_color = Color(0.5, 0.5, 0.55)
	base_style.corner_radius_top_left = 10
	base_style.corner_radius_top_right = 10
	base_style.corner_radius_bottom_left = 10
	base_style.corner_radius_bottom_right = 10
	base.add_theme_stylebox_override("panel", base_style)
	cable.add_child(base)
	
	# Núcleo del cable (color)
	var core = ColorRect.new()
	core.color = color
	core.size = Vector2(40, 30)
	core.position = Vector2(10, 10)
	core.mouse_filter = Control.MOUSE_FILTER_IGNORE
	base.add_child(core)
	
	# Conector
	var connector = ColorRect.new()
	if is_left:
		connector.color = Color(0.6, 0.6, 0.65)
		connector.size = Vector2(20, 10)
		connector.position = Vector2(60, 20)
	else:
		connector.color = Color(0.6, 0.6, 0.65)
		connector.size = Vector2(20, 10)
		connector.position = Vector2(-20, 20)
	connector.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cable.add_child(connector)
	
	# Guardar datos
	cable.set_meta("color", color)
	cable.set_meta("is_left", is_left)
	cable.set_meta("index", index)
	cable.set_meta("connected", false)
	cable.set_meta("connection", null)
	
	# Eventos
	if is_left:
		cable.gui_input.connect(_on_left_cable_input.bind(cable))
	else:
		cable.gui_input.connect(_on_right_cable_input.bind(cable))
	
	return cable

func _on_left_cable_input(event: InputEvent, cable: Control):
	if not game_active:
		return
	
	if cable.get_meta("connected"):
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Empezar a arrastrar
				current_dragging_cable = cable
				var line = Line2D.new()
				line.default_color = cable.get_meta("color")
				line.width = 8.0
				line.add_point(cable.position + Vector2(60, 25))
				line.add_point(cable.position + Vector2(60, 25))
				lines_container.add_child(line)
				current_line = line

func _on_right_cable_input(event: InputEvent, cable: Control):
	if not game_active:
		return
	
	if cable.get_meta("connected"):
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if current_dragging_cable != null:
				# Soltar sobre cable derecho
				check_connection(current_dragging_cable, cable)

func _input(event):
	if not game_active:
		return
	
	# Actualizar línea mientras arrastra
	if current_dragging_cable != null and current_line != null:
		if event is InputEventMouseMotion:
			var mouse_pos = lines_container.get_local_mouse_position()
			current_line.set_point_position(1, mouse_pos)
		
		# Soltar en cualquier lugar
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				# Si no soltó sobre un cable derecho, cancelar
				var dropped_on_cable = false
				for cable in right_cables:
					var cable_rect = Rect2(cable.position, cable.size)
					if cable_rect.has_point(cables_container.get_local_mouse_position()):
						if not cable.get_meta("connected"):
							check_connection(current_dragging_cable, cable)
							dropped_on_cable = true
							break
				
				if not dropped_on_cable:
					# Cancelar conexión
					if current_line != null:
						current_line.queue_free()
					current_line = null
					current_dragging_cable = null

func check_connection(left_cable: Control, right_cable: Control):
	var left_color = left_cable.get_meta("color")
	var right_color = right_cable.get_meta("color")
	
	if left_color.is_equal_approx(right_color):
		# Conexión correcta
		correcto.play()
		make_connection(left_cable, right_cable)
		completed_connections += 1
		
		status_label.text = "Correcto! Cables conectados: " + str(completed_connections) + "/5"
		status_label.add_theme_color_override("font_color", game_colors.success)
		
		# Verificar victoria
		if completed_connections >= 5:
			game_success()
	else:
		# Conexión incorrecta
		error.play()
		status_label.text = "Error! Los colores no coinciden"
		status_label.add_theme_color_override("font_color", game_colors.error)
		
		if current_line != null:
			current_line.queue_free()
		
		# Efecto de error
		create_error_effect(right_cable)
	
	current_line = null
	current_dragging_cable = null

func make_connection(left_cable: Control, right_cable: Control):
	# Marcar como conectados
	left_cable.set_meta("connected", true)
	left_cable.set_meta("connection", right_cable)
	right_cable.set_meta("connected", true)
	right_cable.set_meta("connection", left_cable)
	
	# Actualizar línea para que sea permanente
	if current_line != null:
		current_line.set_point_position(1, right_cable.position + Vector2(0, 25))
		# Hacer la línea más gruesa y brillante
		current_line.width = 10.0
		current_line.default_color = current_line.default_color * 1.2
		connections.append(current_line)
	
	# Efecto visual de conexión exitosa
	create_success_effect(left_cable, right_cable)

func create_success_effect(left: Control, right: Control):
	# Flash en ambos cables
	for cable in [left, right]:
		var flash = ColorRect.new()
		flash.color = Color(0, 1, 0, 0.5)
		flash.size = cable.size
		flash.position = Vector2(0, 0)
		cable.add_child(flash)
		
		var tween = create_tween()
		tween.tween_property(flash, "modulate:a", 0.0, 0.3)
		tween.tween_callback(flash.queue_free)

func create_error_effect(cable: Control):
	# Shake del cable
	var original_pos = cable.position
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(cable, "position:x", original_pos.x + 5, 0.05)
		tween.tween_property(cable, "position:x", original_pos.x - 5, 0.05)
	tween.tween_property(cable, "position:x", original_pos.x, 0.05)

func _process(delta):
	if not game_active:
		return
	
	# Actualizar timer
	time_left -= delta
	time_left = max(0, time_left)
	
	timer_label.text = "TIEMPO: " + str(int(ceil(time_left)))
	timer_bar.value = (time_left / max_time) * 100
	
	# Cambiar color de la barra según tiempo
	var bar_fill = timer_bar.get_theme_stylebox("fill")
	if time_left <= 5:
		bar_fill.bg_color = game_colors.error
		timer_label.add_theme_color_override("font_color", game_colors.error)
	elif time_left <= 10:
		bar_fill.bg_color = game_colors.warning
		timer_label.add_theme_color_override("font_color", game_colors.warning)
	else:
		bar_fill.bg_color = game_colors.success
		timer_label.add_theme_color_override("font_color", game_colors.success)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	
	# Tiempo agotado
	if time_left <= 0:
		game_over()

func game_success():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	
	# Panel de victoria
	var win_panel = Panel.new()
	win_panel.size = Vector2(600, 350)
	win_panel.position = Vector2(300, 225)
	win_panel.z_index = 100  
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.2, 0.15)
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_color = game_colors.success
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	win_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(win_panel)
	
	var win_label = Label.new()
	win_label.text = "¡REPARACIÓN EXITOSA!"
	win_label.add_theme_font_size_override("font_size", 48)
	win_label.add_theme_color_override("font_color", game_colors.success)
	win_label.position = Vector2(30, 50)
	win_panel.add_child(win_label)
	
	var info = Label.new()
	info.text = "Todos los cables conectados\nTiempo restante: " + str(int(time_left)) + " segundos\n\nSistema restaurado correctamente"
	info.add_theme_font_size_override("font_size", 26)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info.position = Vector2(80, 150)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_panel.add_child(info)
	
	# Animación
	win_panel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(win_panel, "scale", Vector2(1.0, 1.0), 0.5)
	
	await get_tree().create_timer(2.5).timeout
	emit_signal("puzzle_completed")
	close_minigame()

func game_over():
	audio.stream_paused=true
	perder.play()
	game_active = false
	
	status_label.text = "TIEMPO AGOTADO! No lograste conectar todos los cables"
	status_label.add_theme_color_override("font_color", game_colors.error)
	
	# Panel de game over
	var fail_panel = Panel.new()
	fail_panel.size = Vector2(500, 250)
	fail_panel.position = Vector2(350, 275)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.1, 0.1)
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_color = game_colors.error
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	fail_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(fail_panel)
	
	var fail_label = Label.new()
	fail_label.text = "FALLO EN REPARACIÓN"
	fail_label.add_theme_font_size_override("font_size", 40)
	fail_label.add_theme_color_override("font_color", game_colors.error)
	fail_label.position = Vector2(30, 50)
	fail_panel.add_child(fail_label)
	
	var info = Label.new()
	info.text = "Cables conectados: " + str(completed_connections) + "/5\nSistema no restaurado"
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	info.position = Vector2(110, 130)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fail_panel.add_child(info)
	
	await get_tree().create_timer(2.5).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func _on_close_pressed():
	close_minigame()

func close_minigame():
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()
			# Reactivar el movimiento del jugador
	var player = get_tree().get_root().find_child("Player1", true, false)
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		print(" Movimiento del jugador reactivado")
	else:
		print("No se encontró el nodo Player en la escena actual")


func show_minigame():
	visible = true
	modulate.a = 1.0
