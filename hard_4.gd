extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Clase Nodo para lista enlazada circular
class TrainNode:
	var value: int = 0
	var color: Color
	var next: TrainNode = null
	var prev: TrainNode = null
	var visual: Control = null
	var position_index: int = 0

# Clase Lista Circular
class CircularList:
	var head: TrainNode = null
	var current: TrainNode = null
	var size: int = 0
	
	func add_node(value: int, color: Color) -> TrainNode:
		var new_node = TrainNode.new()
		new_node.value = value
		new_node.color = color
		
		if head == null:
			head = new_node
			new_node.next = new_node
			new_node.prev = new_node
			current = head
		else:
			var tail = head.prev
			tail.next = new_node
			new_node.prev = tail
			new_node.next = head
			head.prev = new_node
		
		size += 1
		return new_node
	
	func rotate_forward():
		if current != null:
			current = current.next
	
	func rotate_backward():
		if current != null:
			current = current.prev
	
	func remove_current() -> bool:
		if size <= 1:
			return false
		
		var node_to_remove = current
		
		if node_to_remove == head:
			head = head.next
		
		node_to_remove.prev.next = node_to_remove.next
		node_to_remove.next.prev = node_to_remove.prev
		
		current = node_to_remove.next
		size -= 1
		return true
	
	func get_all_values() -> Array:
		var values = []
		if head == null:
			return values
		
		var temp = head
		for i in range(size):
			values.append(temp.value)
			temp = temp.next
		return values

# Variables del juego
var train_list: CircularList
var target_sequence = []
var collected_sequence = []
var score: int = 0
var lives: int = 3
var level: int = 1
var rotation_speed: float = 120.0
var is_rotating: bool = false
var rotation_direction: int = 0
var time_left: float = 20
var max_time: float = 20
var game_active: bool = true

# Componentes visuales
var train_container: Control
var track_center: Vector2
var train_radius: float = 200.0
var station_visual: Control
var target_display: HBoxContainer
var collected_display: HBoxContainer
var rotation_angle: float = 0.0

# UI Components
var score_label: Label
var lives_label: Label
var level_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var status_label: Label

# Colores disponibles - más oscuros para mejor contraste
var wagon_colors = [
	Color(0.7, 0.2, 0.2),  # Rojo oscuro
	Color(0.2, 0.2, 0.6),  # Azul oscuro
	Color(0.2, 0.5, 0.2),  # Verde oscuro
	Color(0.6, 0.6, 0.2),  # Amarillo oscuro
	Color(0.6, 0.2, 0.6),  # Magenta oscuro
	Color(0.2, 0.5, 0.6)   # Cyan oscuro
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
	"track": Color(0.3, 0.3, 0.35)
}

# Señal de completado
signal puzzle_completed
signal puzzle_failed


func _ready():
	randomize()
	setup_window()
	setup_ui()
	setup_game_area()
	start_level()

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
	title.text = "TREN DE DATOS CIRCULAR"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(350, 50)
	add_child(title)
	
	# Panel de información
	create_info_panel()
	
	# Panel de secuencias
	create_sequence_panels()
	
	# Controles
	create_controls()
	
	# Estado
	status_label = Label.new()
	status_label.text = "Recoge los vagones en el orden correcto"
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_label.position = Vector2(380, 820)
	add_child(status_label)

func create_info_panel():
	var info_panel = Panel.new()
	info_panel.size = Vector2(1000, 70)
	info_panel.position = Vector2(100, 110)
	
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
	
	# Nivel
	level_label = Label.new()
	level_label.text = "NIVEL: 1"
	level_label.add_theme_font_size_override("font_size", 28)
	level_label.add_theme_color_override("font_color", game_colors.warning)
	level_label.position = Vector2(50, 20)
	info_panel.add_child(level_label)
	
	# Puntuación
	score_label = Label.new()
	score_label.text = "PUNTOS: 0"
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", game_colors.success)
	score_label.position = Vector2(250, 20)
	info_panel.add_child(score_label)
	
	# Vidas
	lives_label = Label.new()
	lives_label.text = "VIDAS: 3"
	lives_label.add_theme_font_size_override("font_size", 28)
	lives_label.add_theme_color_override("font_color", game_colors.error)
	lives_label.position = Vector2(450, 20)
	info_panel.add_child(lives_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 45"
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", game_colors.info)
	timer_label.position = Vector2(650, 20)
	info_panel.add_child(timer_label)
	
	# Barra de tiempo
	timer_bar = ProgressBar.new()
	timer_bar.size = Vector2(150, 20)
	timer_bar.position = Vector2(800, 25)
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
	info_panel.add_child(timer_bar)

func create_sequence_panels():
	# Panel objetivo
	var target_panel = Panel.new()
	target_panel.size = Vector2(480, 100)
	target_panel.position = Vector2(100, 200)
	
	var target_style = StyleBoxFlat.new()
	target_style.bg_color = Color(0.15, 0.2, 0.15)
	target_style.border_width_top = 3
	target_style.border_width_bottom = 3
	target_style.border_width_left = 3
	target_style.border_width_right = 3
	target_style.border_color = game_colors.success
	target_style.corner_radius_top_left = 10
	target_style.corner_radius_top_right = 10
	target_style.corner_radius_bottom_left = 10
	target_style.corner_radius_bottom_right = 10
	target_panel.add_theme_stylebox_override("panel", target_style)
	add_child(target_panel)
	
	var target_label = Label.new()
	target_label.text = "SECUENCIA OBJETIVO:"
	target_label.add_theme_font_size_override("font_size", 22)
	target_label.add_theme_color_override("font_color", game_colors.success)
	target_label.position = Vector2(20, 10)
	target_panel.add_child(target_label)
	
	target_display = HBoxContainer.new()
	target_display.position = Vector2(20, 40)
	target_display.add_theme_constant_override("separation", 10)
	target_panel.add_child(target_display)
	
	# Panel recolectado
	var collected_panel = Panel.new()
	collected_panel.size = Vector2(480, 100)
	collected_panel.position = Vector2(620, 200)
	
	var collected_style = StyleBoxFlat.new()
	collected_style.bg_color = Color(0.15, 0.15, 0.2)
	collected_style.border_width_top = 3
	collected_style.border_width_bottom = 3
	collected_style.border_width_left = 3
	collected_style.border_width_right = 3
	collected_style.border_color = game_colors.info
	collected_style.corner_radius_top_left = 10
	collected_style.corner_radius_top_right = 10
	collected_style.corner_radius_bottom_left = 10
	collected_style.corner_radius_bottom_right = 10
	collected_panel.add_theme_stylebox_override("panel", collected_style)
	add_child(collected_panel)
	
	var collected_label = Label.new()
	collected_label.text = "TU SECUENCIA:"
	collected_label.add_theme_font_size_override("font_size", 22)
	collected_label.add_theme_color_override("font_color", game_colors.info)
	collected_label.position = Vector2(20, 10)
	collected_panel.add_child(collected_label)
	
	collected_display = HBoxContainer.new()
	collected_display.position = Vector2(20, 40)
	collected_display.add_theme_constant_override("separation", 10)
	collected_panel.add_child(collected_display)

func create_controls():
	var controls_container = HBoxContainer.new()
	controls_container.position = Vector2(250, 730)
	controls_container.add_theme_constant_override("separation", 30)
	add_child(controls_container)
	
	# Botón rotar izquierda
	var left_btn = Button.new()
	left_btn.text = "ROTAR IZQUIERDA"
	left_btn.custom_minimum_size = Vector2(200, 60)
	left_btn.add_theme_font_size_override("font_size", 24)
	left_btn.pressed.connect(_on_rotate_left_pressed)
	left_btn.button_down.connect(_on_rotate_left_down)
	left_btn.button_up.connect(_on_rotate_stop)
	controls_container.add_child(left_btn)
	
	# Botón recoger
	var collect_btn = Button.new()
	collect_btn.text = "RECOGER VAGON"
	collect_btn.custom_minimum_size = Vector2(200, 60)
	collect_btn.add_theme_font_size_override("font_size", 24)
	
	var collect_style = StyleBoxFlat.new()
	collect_style.bg_color = game_colors.success * 0.7
	collect_style.border_width_top = 3
	collect_style.border_width_bottom = 3
	collect_style.border_width_left = 3
	collect_style.border_width_right = 3
	collect_style.border_color = game_colors.success
	collect_style.corner_radius_top_left = 10
	collect_style.corner_radius_top_right = 10
	collect_style.corner_radius_bottom_left = 10
	collect_style.corner_radius_bottom_right = 10
	
	collect_btn.add_theme_stylebox_override("normal", collect_style)
	collect_btn.pressed.connect(_on_collect_pressed)
	controls_container.add_child(collect_btn)
	
	# Botón rotar derecha
	var right_btn = Button.new()
	right_btn.text = "ROTAR DERECHA"
	right_btn.custom_minimum_size = Vector2(200, 60)
	right_btn.add_theme_font_size_override("font_size", 24)
	right_btn.pressed.connect(_on_rotate_right_pressed)
	right_btn.button_down.connect(_on_rotate_right_down)
	right_btn.button_up.connect(_on_rotate_stop)
	controls_container.add_child(right_btn)

func setup_game_area():
	# Contenedor del tren
	train_container = Control.new()
	train_container.position = Vector2(200, 320)
	train_container.size = Vector2(800, 400)
	add_child(train_container)
	
	track_center = Vector2(400, 200)
	
	# Dibujar pista circular
	create_track()
	
	# Crear estación
	create_station()

func create_track():
	# Pista visual
	for i in range(32):
		var angle = (i / 32.0) * TAU
		var pos = track_center + Vector2(cos(angle), sin(angle)) * train_radius
		
		var track_piece = ColorRect.new()
		track_piece.color = game_colors.track
		track_piece.size = Vector2(20, 8)
		track_piece.position = pos - Vector2(10, 4)
		track_piece.rotation = angle
		train_container.add_child(track_piece)

func create_station():
	# Estación en la parte superior
	station_visual = Panel.new()
	station_visual.size = Vector2(80, 80)
	station_visual.position = track_center + Vector2(-40, -train_radius - 40)
	
	var station_style = StyleBoxFlat.new()
	station_style.bg_color = Color(0.3, 0.3, 0.4)
	station_style.border_width_top = 4
	station_style.border_width_bottom = 4
	station_style.border_width_left = 4
	station_style.border_width_right = 4
	station_style.border_color = game_colors.warning
	station_style.corner_radius_top_left = 10
	station_style.corner_radius_top_right = 10
	station_style.corner_radius_bottom_left = 10
	station_style.corner_radius_bottom_right = 10
	station_visual.add_theme_stylebox_override("panel", station_style)
	train_container.add_child(station_visual)
	
	var station_label = Label.new()
	station_label.text = "ESTACION"
	station_label.add_theme_font_size_override("font_size", 16)
	station_label.add_theme_color_override("font_color", Color.WHITE)
	station_label.position = Vector2(10, 30)
	station_visual.add_child(station_label)

func start_level():
	# Limpiar tren anterior
	if train_list:
		var temp = train_list.head
		if temp:
			for i in range(train_list.size):
				if temp.visual:
					temp.visual.queue_free()
				temp = temp.next
	
	# Inicializar lista circular
	train_list = CircularList.new()
	collected_sequence.clear()
	time_left = max_time
	
	# Generar secuencia objetivo
	generate_target_sequence()
	
	# Crear vagones del tren
	create_train_wagons()
	
	# Actualizar displays
	update_displays()
	
	status_label.text = "Nivel " + str(level) + " - Recoge los vagones en orden!"

func generate_target_sequence():
	target_sequence.clear()
	var sequence_length = 3 + level  # Aumenta con el nivel
	
	for i in range(min(sequence_length, 1)):
		target_sequence.append(randi_range(1, 9))

func create_train_wagons():
	# Crear vagones incluyendo los de la secuencia y algunos extra
	var all_values = target_sequence.duplicate()
	
	# Agregar vagones extra para confundir
	for i in range(3):
		all_values.append(randi_range(1, 9))
	
	all_values.shuffle()
	
	# Crear nodos en la lista circular
	for i in range(all_values.size()):
		var color = wagon_colors[i % wagon_colors.size()]
		var node = train_list.add_node(all_values[i], color)
		node.position_index = i
		
		# Crear visual del vagón
		var wagon = create_wagon_visual(node)
		node.visual = wagon
		train_container.add_child(wagon)
	
	update_train_positions()

func create_wagon_visual(node: TrainNode) -> Control:
	var wagon = Control.new()
	wagon.size = Vector2(60, 40)
	wagon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Cuerpo del vagón
	var body = Panel.new()
	body.size = wagon.size
	
	var body_style = StyleBoxFlat.new()
	body_style.bg_color = node.color
	body_style.border_width_top = 3
	body_style.border_width_bottom = 3
	body_style.border_width_left = 3
	body_style.border_width_right = 3
	body_style.border_color = Color(0.1, 0.1, 0.1)  # Borde oscuro
	body_style.corner_radius_top_left = 8
	body_style.corner_radius_top_right = 8
	body_style.corner_radius_bottom_left = 8
	body_style.corner_radius_bottom_right = 8
	body.add_theme_stylebox_override("panel", body_style)
	wagon.add_child(body)
	
	# Número con fondo para mejor contraste
	var number_bg = ColorRect.new()
	number_bg.color = Color(0.1, 0.1, 0.1, 0.7)  # Fondo semi-transparente oscuro
	number_bg.size = Vector2(50, 35)
	number_bg.position = Vector2(5, 2)
	body.add_child(number_bg)
	
	var number = Label.new()
	number.text = str(node.value)
	number.add_theme_font_size_override("font_size", 28)
	number.add_theme_color_override("font_color", Color.WHITE)
	number.add_theme_color_override("font_shadow_color", Color.BLACK)
	number.add_theme_constant_override("shadow_offset_x", 2)
	number.add_theme_constant_override("shadow_offset_y", 2)
	number.position = Vector2(20, 5)
	body.add_child(number)
	
	return wagon

func update_train_positions():
	if not train_list or not train_list.head:
		return
	
	var temp = train_list.head
	var angle_step = TAU / train_list.size
	
	for i in range(train_list.size):
		var angle = rotation_angle + (i * angle_step)
		var pos = track_center + Vector2(cos(angle), sin(angle)) * train_radius
		
		if temp.visual:
			temp.visual.position = pos - Vector2(30, 20)
			temp.visual.rotation = angle + PI/2
			
			# Resaltar el vagón en la estación
			if temp == train_list.current:
				temp.visual.modulate = Color(1.2, 1.2, 1.2)
				temp.visual.scale = Vector2(1.1, 1.1)
			else:
				temp.visual.modulate = Color(1.0, 1.0, 1.0)
				temp.visual.scale = Vector2(1.0, 1.0)
		
		temp = temp.next
# -------------------------------------------------------
# 🧠 DETECCIÓN DE VAGÓN EN LA ESTACIÓN
# -------------------------------------------------------

func update_displays():
	# Actualizar display objetivo
	for child in target_display.get_children():
		child.queue_free()
	
	for value in target_sequence:
		var box = create_sequence_box(value, game_colors.success)
		target_display.add_child(box)
	
	# Actualizar display recolectado
	for child in collected_display.get_children():
		child.queue_free()
	
	for i in range(collected_sequence.size()):
		var value = collected_sequence[i]
		var color = game_colors.success if i < target_sequence.size() and value == target_sequence[i] else game_colors.error
		var box = create_sequence_box(value, color)
		collected_display.add_child(box)

func create_sequence_box(value: int, color: Color) -> Panel:
	var box = Panel.new()
	box.custom_minimum_size = Vector2(50, 50)
	
	var style = StyleBoxFlat.new()
	style.bg_color = color * 0.3
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = color
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	box.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.add_child(label)
	
	return box

func _on_rotate_left_down():
	is_rotating = true
	rotation_direction = -1

func _on_rotate_right_down():
	is_rotating = true
	rotation_direction = 1

func _on_rotate_stop():
	is_rotating = false
	rotation_direction = 0

func _on_rotate_left_pressed():
	if game_active and train_list:
		train_list.rotate_backward()

func _on_rotate_right_pressed():
	if game_active and train_list:
		train_list.rotate_forward()

# Tamaño extra del área de detección de la estación
const STATION_GROW_PX: int = 24  # súbelo/bájalo a gusto

# Devuelve el Rect global expandido de la estación
func _get_station_rect_grown() -> Rect2:
	if not station_visual:
		return Rect2()
	var r: Rect2 = station_visual.get_global_rect()
	return r.grow(STATION_GROW_PX)

# Busca el vagón cuyo rect global interseca el área de estación.
# Si hay varios, toma el más centrado respecto al centro de la estación.
func _get_wagon_in_station() -> TrainNode:
	if not train_list or not train_list.head:
		return null
	
	var station_r: Rect2 = _get_station_rect_grown()
	var station_center: Vector2 = station_r.get_center()
	
	var best_node: TrainNode = null
	var best_dist: float = INF
	
	var node := train_list.head
	for i in range(train_list.size):
		if node.visual:
			var wagon_r: Rect2 = node.visual.get_global_rect()
			if station_r.intersects(wagon_r):
				var wagon_center: Vector2 = wagon_r.get_center()
				var d := station_center.distance_to(wagon_center)
				if d < best_dist:
					best_dist = d
					best_node = node
		node = node.next
	
	return best_node


func _on_collect_pressed():
	if not game_active or not train_list:
		return
	
	var index := collected_sequence.size()
	if index >= target_sequence.size():
		status_label.text = "¡Ya completaste la secuencia!"
		status_label.add_theme_color_override("font_color", game_colors.info)
		return
	
	# 🔍 Buscar el vagón que REALMENTE está en el área (no asumimos current)
	var wagon := _get_wagon_in_station()
	if wagon == null:
		status_label.text = "El vagón no está dentro de la estación"
		status_label.add_theme_color_override("font_color", game_colors.warning)
		status_label.position = Vector2(370, 810)
		return
	
	var current_value := wagon.value
	var required_value: int = target_sequence[index]

	
	if current_value == required_value:
		# ✅ Correcto
		correcto.play()
		collected_sequence.append(current_value)
		score += 10 * level
		score_label.text = "PUNTOS: " + str(score)
		status_label.text = "¡Correcto! Vagón " + str(current_value) + " recogido"
		status_label.add_theme_color_override("font_color", game_colors.success)
		
		# Animación + remover el nodo ENCONTRADO (no necesariamente train_list.current)
		var visual_to_remove := wagon.visual
		if visual_to_remove:
			var tween := create_tween()
			tween.tween_property(visual_to_remove, "scale", Vector2(0, 0), 0.3)
			tween.tween_callback(visual_to_remove.queue_free)
		
		# 🔁 Reenlazar correctamente en la lista circular
		if wagon == train_list.head:
			train_list.head = wagon.next
		if wagon == train_list.current:
			train_list.current = wagon.next
		
		wagon.prev.next = wagon.next
		wagon.next.prev = wagon.prev
		train_list.size -= 1
		
		update_train_positions()
		
		if collected_sequence.size() == target_sequence.size():
			level_complete()
	else:
		# ❌ Incorrecto
		error.play()
		lives -= 1
		lives_label.text = "VIDAS: " + str(lives)
		status_label.text = "Incorrecto, necesitabas el " + str(required_value)
		status_label.add_theme_color_override("font_color", game_colors.error)
		status_label.position = Vector2(420, 810)
		if lives <= 0:
			game_over()
	
	update_displays()

# -------------------------------------------------------
# 🧠 VERIFICAR SI EL VAGÓN ESTÁ EN LA ESTACIÓN
# -------------------------------------------------------
func is_wagon_in_station(wagon: TrainNode) -> bool:
	if not station_visual or not wagon.visual:
		return false
	
	var station_rect = Rect2(station_visual.global_position, station_visual.size)
	var wagon_rect = Rect2(wagon.visual.global_position, wagon.visual.size)
	
	return station_rect.intersects(wagon_rect)



func level_complete():
	status_label.text = "Nivel " + str(level) + " completado!"
	status_label.add_theme_color_override("font_color", game_colors.success)
	status_label.position = Vector2(450, 820)
	level += 1
	level_label.text = "NIVEL: " + str(level)
	
	await get_tree().create_timer(1.5).timeout
	
	if level > 3:
		game_success()
	else:
		start_level()

func _process(delta):
	if not game_active:
		return
	
	# Rotación continua
	if is_rotating:
		rotation_angle += rotation_direction * rotation_speed * delta * 0.01
		train_list.rotate_forward() if rotation_direction > 0 else train_list.rotate_backward()
		update_train_positions()
	
	# Timer
	time_left -= delta
	time_left = max(0, time_left)
	timer_label.text = "TIEMPO: " + str(int(ceil(time_left)))
	timer_bar.value = (time_left / max_time) * 100
	
	if time_left <= 0:
		game_over()

	
	# Timer
	time_left -= delta
	time_left = max(0, time_left)
	timer_label.text = "TIEMPO: " + str(int(ceil(time_left)))
	timer_bar.value = (time_left / max_time) * 100
	
	if time_left <= 0:
		game_over()


func game_success():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	
	var win_panel = Panel.new()
	win_panel.size = Vector2(600, 350)
	win_panel.position = Vector2(300, 275)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.2, 0.15)
	panel_style.set_border_width_all(6)
	panel_style.border_color = game_colors.success
	panel_style.set_corner_radius_all(20)
	win_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(win_panel)
	
	var win_label = Label.new()
	win_label.text = "¡VICTORIA!"
	win_label.add_theme_font_size_override("font_size", 56)
	win_label.add_theme_color_override("font_color", game_colors.success)
	win_label.position = Vector2(160, 50)
	win_panel.add_child(win_label)
	
	var stats = Label.new()
	stats.text = "Juego completado!\nPuntuación final: " + str(score) + "\nTodos los niveles superados"
	stats.add_theme_font_size_override("font_size", 26)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats.position = Vector2(120, 150)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_panel.add_child(stats)
	
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
	status_label.text = "Juego terminado!"
	status_label.add_theme_color_override("font_color", game_colors.error)
	status_label.position = Vector2(460, 810)
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

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
