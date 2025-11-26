extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Variables del minijuego
var grid_size: int = 4
var left_grid = []
var right_grid = []
var differences = []
var found_differences = []
var total_differences: int = 5
var clicks_made: int = 0
var max_clicks: int = 10
var time_left: float = 30.0
var max_time: float = 30.0
var game_active: bool = true

# Componentes visuales
var left_grid_container: GridContainer
var right_grid_container: GridContainer
var left_cells = []
var right_cells = []

# UI Components
var score_label: Label
var clicks_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var status_label: Label

# Colores disponibles para las celdas
var cell_colors = [
	Color(0.8, 0.2, 0.2),    # Rojo
	Color(0.2, 0.2, 0.8),    # Azul
	Color(0.2, 0.8, 0.2),    # Verde
	Color(0.8, 0.8, 0.2),    # Amarillo
	Color(0.8, 0.2, 0.8),    # Magenta
	Color(0.2, 0.8, 0.8),    # Cyan
	Color(0.8, 0.5, 0.2),    # Naranja
	Color(0.5, 0.2, 0.8)     # Púrpura
]

# Colores del tema
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.8, 0.8),
	"success": Color(0.2, 0.9, 0.2),
	"error": Color(0.9, 0.2, 0.2),
	"warning": Color(0.9, 0.9, 0.2),
	"info": Color(0.4, 0.8, 1.0),
	"found": Color(0.3, 1.0, 0.3),
	"wrong": Color(1.0, 0.3, 0.3)
}

signal puzzle_completed
signal puzzle_failed


func _ready():
	randomize()
	setup_window()
	setup_ui()
	setup_grids()
	generate_grids()
	display_grids()

func setup_window():
	var viewport_size = Vector2(get_viewport().size)
	var window_size = Vector2(1200, 900)
	
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
	title.text = "ENCUENTRA LAS DIFERENCIAS"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(260, 50)
	add_child(title)
	
	# Instrucciones
	var instruction = Label.new()
	instruction.text = "Haz click en los cuadros que son diferentes en la imagen derecha"
	instruction.add_theme_font_size_override("font_size", 24)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction.position = Vector2(230, 110)
	add_child(instruction)
	
	# Panel de información
	create_info_panel()
	
	# Panel de timer
	create_timer_panel()
	
	# Estado
	status_label = Label.new()
	status_label.text = "Encuentra las " + str(total_differences) + " diferencias"
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_label.position = Vector2(420, 800)
	add_child(status_label)

func create_info_panel():
	var info_panel = Panel.new()
	info_panel.size = Vector2(1000, 70)
	info_panel.position = Vector2(100, 160)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = game_colors.panel
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = game_colors.info
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	info_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(info_panel)
	
	# Diferencias encontradas
	score_label = Label.new()
	score_label.text = "ENCONTRADAS: 0/" + str(total_differences)
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", game_colors.success)
	score_label.position = Vector2(50, 20)
	info_panel.add_child(score_label)
	
	# Clicks
	clicks_label = Label.new()
	clicks_label.text = "CLICKS: 0/" + str(max_clicks)
	clicks_label.add_theme_font_size_override("font_size", 28)
	clicks_label.add_theme_color_override("font_color", game_colors.warning)
	clicks_label.position = Vector2(400, 20)
	info_panel.add_child(clicks_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 30"
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", game_colors.info)
	timer_label.position = Vector2(700, 20)
	info_panel.add_child(timer_label)

func create_timer_panel():
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(1000, 30)
	timer_panel.position = Vector2(100, 240)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.12)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.3, 0.3, 0.35)
	panel_style.corner_radius_top_left = 5
	panel_style.corner_radius_top_right = 5
	panel_style.corner_radius_bottom_left = 5
	panel_style.corner_radius_bottom_right = 5
	timer_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(timer_panel)
	
	timer_bar = ProgressBar.new()
	timer_bar.size = Vector2(980, 20)
	timer_bar.position = Vector2(10, 5)
	timer_bar.min_value = 0
	timer_bar.max_value = 100
	timer_bar.value = 100
	timer_bar.show_percentage = false
	
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.25)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = game_colors.info
	
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	timer_panel.add_child(timer_bar)

func setup_grids():
	# Panel izquierdo (original)
	var left_panel = Panel.new()
	left_panel.size = Vector2(400, 450)
	left_panel.position = Vector2(100, 300)
	
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
	add_child(left_panel)
	
	# Título izquierdo
	var left_title = Label.new()
	left_title.text = "IMAGEN ORIGINAL"
	left_title.add_theme_font_size_override("font_size", 22)
	left_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	left_title.position = Vector2(100, 10)
	left_panel.add_child(left_title)
	
	# Grid izquierdo
	left_grid_container = GridContainer.new()
	left_grid_container.columns = grid_size
	left_grid_container.position = Vector2(90, 100)
	left_grid_container.add_theme_constant_override("h_separation", 5)
	left_grid_container.add_theme_constant_override("v_separation", 5)
	left_panel.add_child(left_grid_container)
	
	# Panel derecho (con diferencias)
	var right_panel = Panel.new()
	right_panel.size = Vector2(400, 450)
	right_panel.position = Vector2(700, 300)
	
	right_panel.add_theme_stylebox_override("panel", left_style)
	add_child(right_panel)
	
	# Título derecho
	var right_title = Label.new()
	right_title.text = "ENCUENTRA LAS DIFERENCIAS"
	right_title.add_theme_font_size_override("font_size", 22)
	right_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	right_title.position = Vector2(50, 10)
	right_panel.add_child(right_title)
	
	# Grid derecho
	right_grid_container = GridContainer.new()
	right_grid_container.columns = grid_size
	right_grid_container.position = Vector2(100, 100)
	right_grid_container.add_theme_constant_override("h_separation", 5)
	right_grid_container.add_theme_constant_override("v_separation", 5)
	right_panel.add_child(right_grid_container)

func generate_grids():
	# Limpiar grids anteriores
	left_grid.clear()
	right_grid.clear()
	differences.clear()
	found_differences.clear()
	
	# Generar grid base
	for i in range(grid_size * grid_size):
		var color_index = randi() % cell_colors.size()
		left_grid.append(color_index)
		right_grid.append(color_index)
	
	# Crear diferencias aleatorias
	var positions_used = []
	for i in range(total_differences):
		var pos = randi() % (grid_size * grid_size)
		
		# Asegurar que no repitamos posición
		while pos in positions_used:
			pos = randi() % (grid_size * grid_size)
		
		positions_used.append(pos)
		differences.append(pos)
		
		# Cambiar el color en el grid derecho
		var original_color = right_grid[pos]
		var new_color = randi() % cell_colors.size()
		
		# Asegurar que el nuevo color sea diferente
		while new_color == original_color:
			new_color = randi() % cell_colors.size()
		
		right_grid[pos] = new_color

func display_grids():
	# Limpiar celdas anteriores
	for child in left_grid_container.get_children():
		child.queue_free()
	for child in right_grid_container.get_children():
		child.queue_free()
	
	left_cells.clear()
	right_cells.clear()
	
	# Crear celdas izquierdas (no clickeables)
	for i in range(grid_size * grid_size):
		var cell = create_cell(left_grid[i], i, false)
		left_grid_container.add_child(cell)
		left_cells.append(cell)
	
	# Crear celdas derechas (clickeables)
	for i in range(grid_size * grid_size):
		var cell = create_cell(right_grid[i], i, true)
		right_grid_container.add_child(cell)
		right_cells.append(cell)

func create_cell(color_index: int, position: int, is_clickable: bool) -> Panel:
	var cell = Panel.new()
	cell.custom_minimum_size = Vector2(50, 60)
	cell.mouse_filter = Control.MOUSE_FILTER_PASS if is_clickable else Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = cell_colors[color_index]
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.1, 0.1, 0.1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	cell.add_theme_stylebox_override("panel", style)
	
	# Guardar datos
	cell.set_meta("position", position)
	cell.set_meta("color_index", color_index)
	cell.set_meta("is_difference", position in differences)
	cell.set_meta("found", false)
	
	if is_clickable:
		cell.gui_input.connect(_on_cell_clicked.bind(cell))
	
	return cell

func _on_cell_clicked(event: InputEvent, cell: Panel):
	if not game_active:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			check_cell(cell)

func check_cell(cell: Panel):
	var position = cell.get_meta("position")
	var is_difference = cell.get_meta("is_difference")
	var already_found = cell.get_meta("found")
	
	if already_found:
		status_label.text = "Ya encontraste esta diferencia"
		status_label.add_theme_color_override("font_color", game_colors.warning)
		return
	
	clicks_made += 1
	clicks_label.text = "CLICKS: " + str(clicks_made) + "/" + str(max_clicks)
	
	if is_difference:
		# Diferencia encontrada
		cell.set_meta("found", true)
		found_differences.append(position)
		
		score_label.text = "ENCONTRADAS: " + str(found_differences.size()) + "/" + str(total_differences)
		status_label.text = "Bien! Diferencia encontrada"
		status_label.add_theme_color_override("font_color", game_colors.success)
		
		# Marcar visualmente la diferencia
		mark_difference(cell, position)
		
		# Verificar victoria
		if found_differences.size() >= total_differences:
			game_success()
	else:
		# Error
		status_label.text = "No hay diferencia aquí"
		status_label.add_theme_color_override("font_color", game_colors.error)
		
		# Efecto de error
		create_error_effect(cell)
		
		# Verificar si se acabaron los clicks
		if clicks_made >= max_clicks:
			game_over()

func mark_difference(cell: Panel, position: int):
	# Marcar en ambas grids
	var left_cell = left_cells[position]
	var right_cell = cell
	
	# Círculo verde en ambas celdas
	correcto.play()
	for target_cell in [left_cell, right_cell]:
		var marker = Panel.new()
		marker.size = Vector2(50, 60)
		marker.position = Vector2(0, 0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var marker_style = StyleBoxFlat.new()
		marker_style.bg_color = Color(0, 1, 0, 0)
		marker_style.border_width_top = 4
		marker_style.border_width_bottom = 4
		marker_style.border_width_left = 4
		marker_style.border_width_right = 4
		marker_style.border_color = game_colors.found
		marker_style.corner_radius_top_left = 5
		marker_style.corner_radius_top_right = 5
		marker_style.corner_radius_bottom_left = 5
		marker_style.corner_radius_bottom_right = 5
		marker.add_theme_stylebox_override("panel", marker_style)
		target_cell.add_child(marker)
		
		# Animación
		var tween = create_tween()
		tween.set_loops(2)
		tween.tween_property(marker, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(marker, "scale", Vector2(1.0, 1.0), 0.2)

func create_error_effect(cell: Panel):
	# Flash rojo
	error.play()
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.5)
	flash.size = cell.size
	flash.position = Vector2(0, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func _process(delta):
	if not game_active:
		return
	
	# Actualizar timer
	time_left -= delta
	time_left = max(0, time_left)
	
	timer_label.text = "TIEMPO: " + str(int(ceil(time_left)))
	timer_bar.value = (time_left / max_time) * 100
	
	# Cambiar color del timer
	var fill_style = timer_bar.get_theme_stylebox("fill")
	if time_left <= 10:
		fill_style.bg_color = game_colors.error
	elif time_left <= 20:
		fill_style.bg_color = game_colors.warning
	else:
		fill_style.bg_color = game_colors.info
	timer_bar.add_theme_stylebox_override("fill", fill_style)
	
	if time_left <= 0:
		time_out()

func game_success():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	
	# Panel de victoria
	var win_panel = Panel.new()
	win_panel.size = Vector2(600, 350)
	win_panel.position = Vector2(300, 275)
	
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
	win_label.text = "¡TODAS LAS DIFERENCIAS\nENCONTRADAS!"
	win_label.add_theme_font_size_override("font_size", 30)
	win_label.add_theme_color_override("font_color", game_colors.success)
	win_label.position = Vector2(130, 50)
	win_panel.add_child(win_label)
	
	var stats = Label.new()
	stats.text = "Completado!\nClicks usados: " + str(clicks_made) + "/" + str(max_clicks) + "\nTiempo restante: " + str(int(time_left)) + " segundos"
	stats.add_theme_font_size_override("font_size", 26)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats.position = Vector2(90, 150)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_panel.add_child(stats)
	
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
	
	status_label.text = "Sin clicks disponibles! Encontraste " + str(found_differences.size()) + "/" + str(total_differences)
	status_label.add_theme_color_override("font_color", game_colors.error)
	
	# Mostrar las diferencias no encontradas
	show_remaining_differences()
	
	await get_tree().create_timer(3.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func time_out():
	audio.stream_paused=true
	perder.play()
	game_active = false
	
	status_label.text = "Tiempo agotado! Encontraste " + str(found_differences.size()) + "/" + str(total_differences)
	status_label.add_theme_color_override("font_color", game_colors.error)
	
	show_remaining_differences()
	
	await get_tree().create_timer(3.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func show_remaining_differences():
	# Mostrar las diferencias que no se encontraron
	for pos in differences:
		if not pos in found_differences:
			var left_cell = left_cells[pos]
			var right_cell = right_cells[pos]
			
			# Marcar en rojo las no encontradas
			for target_cell in [left_cell, right_cell]:
				var marker = Panel.new()
				marker.size = Vector2(50, 60)
				marker.position = Vector2(0, 0)
				marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
				
				var marker_style = StyleBoxFlat.new()
				marker_style.bg_color = Color(1, 0, 0, 0.2)
				marker_style.border_width_top = 4
				marker_style.border_width_bottom = 4
				marker_style.border_width_left = 4
				marker_style.border_width_right = 4
				marker_style.border_color = game_colors.error
				marker_style.corner_radius_top_left = 5
				marker_style.corner_radius_top_right = 5
				marker_style.corner_radius_bottom_left = 5
				marker_style.corner_radius_bottom_right = 5
				marker.add_theme_stylebox_override("panel", marker_style)
				target_cell.add_child(marker)

func _on_close_pressed():
	audio.stream_paused=true
	perder.play()
	close_minigame()

func close_minigame():
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()
	
			# Reactivar el movimiento del jugador
	var player = get_tree().get_root().find_child("Player2", true, false)
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		print(" Movimiento del jugador reactivado")
	else:
		print("No se encontró el nodo Player en la escena actual")

func show_minigame():
	visible = true
	modulate.a = 1.0
