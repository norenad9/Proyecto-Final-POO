extends Control

@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer


# Variables del puzzle
var puzzle_pieces = []
var grid_positions = []  # Posiciones de la cuadrícula
var correct_order = [0, 1, 2, 3]
var puzzle_size = 2  # 2x2 = 4 piezas
var piece_size = Vector2(240, 240)  # DUPLICADO: era 120, ahora 240
var grid_spacing = 20  # DUPLICADO: era 10, ahora 20

# Variables para drag & drop
var dragging_piece = null
var drag_offset = Vector2.ZERO
var original_position = Vector2.ZERO
var original_grid_index = -1

# Colores/temas de ciberseguridad
var cyber_colors = {
	"normal": Color(0.5, 0.5, 0.5),  # Verde
	"dragging": Color(0.3, 0.3, 0.3),  # Amarillo
	"hover": Color(0.4, 0.8, 1.0),  # Verde claro
	"correct": Color(0.2, 0.8, 0.8)  # Cyan
}

# Símbolos de ciberseguridad para las piezas
var cyber_texts = ["FIREWALL", "ENCRITAR", "ANTIVIRUS", "BACKUP"]

# Señal para comunicar que el puzzle se completó
signal puzzle_completed()

func _ready():
	setup_window()
	setup_grid_positions()
	setup_puzzle()
	shuffle_puzzle()

func setup_window():
	# Configurar la ventana del popup
	var viewport_size = Vector2(get_viewport().size)  # Convertir Vector2i a Vector2
	
	# Tamaño de la ventana del minijuego - DUPLICADO
	var window_size = Vector2(1200, 1000)  # DUPLICADO: era 600x500, ahora 1200x1000
	
	# Centrar en la pantalla
	position = (viewport_size - window_size) / 2
	size = window_size
	
	# Crear fondo oscuro semi-transparente detrás
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.position = -position  # Compensar para cubrir toda la pantalla
	bg.size = viewport_size
	bg.mouse_filter = Control.MOUSE_FILTER_STOP  # Bloquear clics detrás
	add_child(bg)
	move_child(bg, 0)
	
	# Crear panel de la ventana del minijuego
	var window_panel = Panel.new()
	window_panel.name = "WindowPanel"
	window_panel.size = window_size
	
	var window_style = StyleBoxFlat.new()
	window_style.bg_color = Color(0.1, 0.1, 0.15)
	window_style.border_width_top = 6  # DUPLICADO: era 3, ahora 6
	window_style.border_width_bottom = 6
	window_style.border_width_left = 6
	window_style.border_width_right = 6
	window_style.border_color = Color(0.2, 0.8, 0.8)
	window_style.corner_radius_top_left = 20  # DUPLICADO: era 10, ahora 20
	window_style.corner_radius_top_right = 20
	window_style.corner_radius_bottom_left = 20
	window_style.corner_radius_bottom_right = 20
	window_panel.add_theme_stylebox_override("panel", window_style)
	add_child(window_panel)
	move_child(window_panel, 1)
	
	# Botón de cerrar (X) - más grande
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.size = Vector2(60, 60)  # DUPLICADO: era 30x30, ahora 60x60
	close_button.position = Vector2(window_size.x - 80, 20)  # Ajustado
	close_button.add_theme_font_size_override("font_size", 36)  # DUPLICADO: era 18, ahora 36
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func _on_close_pressed():
	close_minigame()

func setup_grid_positions():
	# Calcular el área total de la cuadrícula
	var total_width = puzzle_size * piece_size.x + (puzzle_size - 1) * grid_spacing
	var total_height = puzzle_size * piece_size.y + (puzzle_size - 1) * grid_spacing
	
	# Centrar la cuadrícula en la ventana
	var start_x = (size.x - total_width) / 2
	var start_y = (size.y - total_height) / 2 + 40  # +40 deja espacio para el título
	
	grid_positions.clear()
	for row in range(puzzle_size):
		for col in range(puzzle_size):
			var pos = Vector2(
				start_x + col * (piece_size.x + grid_spacing),
				start_y + row * (piece_size.y + grid_spacing)
			)
			grid_positions.append(pos)


func setup_puzzle():
	# Crear título del minijuego
	var title = Label.new()
	title.name = "Title"
	title.text = "HACKEO DE SEGURIDAD"
	title.add_theme_font_size_override("font_size", 50)  # DUPLICADO: era 24, ahora 48
	title.add_theme_color_override("font_color", Color(0.2, 0.8, 0.8))
	title.position = Vector2(330, 60)  # DUPLICADO: era 200,20 ahora 400,40
	add_child(title)
	
	# Crear instrucciones
	var instructions = Label.new()
	instructions.name = "Instructions"
	instructions.text = "Ordena el protocolo: 1.Firewall → 2.Encriptar → 3.Antivirus → 4.Backup"
	instructions.position = Vector2(80, 140)  # DUPLICADO: era 80,60 ahora 160,120
	instructions.add_theme_font_size_override("font_size", 30)  # DUPLICADO: era 12, ahora 24
	instructions.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	add_child(instructions)
	
	# Crear indicadores de posición
	create_drop_zones()
	
	# Crear las 4 piezas del puzzle
	for i in range(4):
		var piece = create_puzzle_piece(i)
		puzzle_pieces.append(piece)
		add_child(piece)
	
	# Crear mensaje de victoria
	var win_label = Label.new()
	win_label.name = "WinMessage"
	win_label.text = "¡SISTEMA HACKEADO!"
	win_label.add_theme_font_size_override("font_size", 56)  # DUPLICADO: era 28, ahora 56
	win_label.add_theme_color_override("font_color", cyber_colors.correct)
	win_label.position = Vector2(360, 800)  # DUPLICADO: era 180,400 ahora 360,800
	win_label.visible = false
	add_child(win_label)

func create_drop_zones():
	# Crear zonas visuales donde se pueden soltar las piezas
	for i in range(4):
		var drop_zone = Panel.new()
		drop_zone.size = piece_size
		drop_zone.position = grid_positions[i]
		drop_zone.modulate = Color(1, 1, 1, 0.2)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3, 0.3)
		style.border_width_top = 4  # DUPLICADO: era 2, ahora 4
		style.border_width_bottom = 4
		style.border_width_left = 4
		style.border_width_right = 4
		style.border_color = Color(0.5, 0.5, 0.5, 0.5)
		style.corner_radius_top_left = 20  # DUPLICADO: era 10, ahora 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		drop_zone.add_theme_stylebox_override("panel", style)
		
		add_child(drop_zone)
		move_child(drop_zone, 2)  # Después del background y window panel

func create_puzzle_piece(index: int) -> Control:
	var piece_container = Control.new()
	piece_container.size = piece_size
	piece_container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Panel visual de la pieza
	var panel = Panel.new()
	panel.size = piece_size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Contenido de la pieza
	var vbox = VBoxContainer.new()
	vbox.size = piece_size
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	
	var text_label = Label.new()
	text_label.text = str(index + 1) + ". " + cyber_texts[index]
	text_label.add_theme_font_size_override("font_size", 28)  # DUPLICADO: era 14, ahora 28
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	vbox.add_child(text_label)
	
	# Configurar estilo
	var style = StyleBoxFlat.new()
	style.bg_color = cyber_colors.normal
	style.border_width_top = 6  # DUPLICADO: era 3, ahora 6
	style.border_width_bottom = 6
	style.border_width_left = 6
	style.border_width_right = 6
	style.border_color = Color.WHITE
	style.corner_radius_top_left = 20  # DUPLICADO: era 10, ahora 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	panel.add_theme_stylebox_override("panel", style)
	
	# Añadir elementos a la pieza
	piece_container.add_child(panel)
	panel.add_child(vbox)
	
	# Guardar metadatos
	piece_container.set_meta("panel", panel)
	piece_container.set_meta("style", style)
	piece_container.set_meta("original_index", index)
	piece_container.set_meta("current_grid_index", index)
	
	# Conectar eventos de mouse
	piece_container.gui_input.connect(_on_piece_input.bind(piece_container))
	
	return piece_container

func _on_piece_input(event: InputEvent, piece: Control):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_dragging(piece, event.position)
			else:
				stop_dragging()
	
	elif event is InputEventMouseMotion:
		if dragging_piece == piece:
			drag_piece(event.position)

func start_dragging(piece: Control, mouse_pos: Vector2):
	dragging_piece = piece
	drag_offset = mouse_pos
	original_position = piece.position
	original_grid_index = piece.get_meta("current_grid_index")
	
	# Cambiar apariencia visual
	var style = piece.get_meta("style")
	style.bg_color = cyber_colors.dragging
	style.border_width_top = 8  # DUPLICADO: era 4, ahora 8
	style.border_width_bottom = 8
	style.border_width_left = 8
	style.border_width_right = 8
	var panel = piece.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style)
	
	# Traer la pieza al frente
	move_child(piece, get_child_count() - 1)
	
	# Añadir efecto de elevación
	piece.scale = Vector2(1.1, 1.1)

func drag_piece(mouse_pos: Vector2):
	if dragging_piece:
		var new_pos = get_global_mouse_position() - drag_offset
		# Ajustar para el efecto de escala
		new_pos -= piece_size * 0.05
		dragging_piece.global_position = new_pos

func stop_dragging():
	if not dragging_piece:
		return
	
	# Encontrar la posición de la cuadrícula más cercana
	var piece_center = dragging_piece.position + piece_size / 2
	var closest_grid_index = find_closest_grid_position(piece_center)
	
	# Verificar si hay otra pieza en esa posición
	var occupying_piece = get_piece_at_grid_index(closest_grid_index)
	
	if occupying_piece and occupying_piece != dragging_piece:
		# Intercambiar posiciones
		occupying_piece.position = grid_positions[original_grid_index]
		occupying_piece.set_meta("current_grid_index", original_grid_index)
		
		dragging_piece.position = grid_positions[closest_grid_index]
		dragging_piece.set_meta("current_grid_index", closest_grid_index)
	else:
		# Mover a la posición más cercana
		dragging_piece.position = grid_positions[closest_grid_index]
		dragging_piece.set_meta("current_grid_index", closest_grid_index)
	
	# Restaurar apariencia visual
	var style = dragging_piece.get_meta("style")
	style.bg_color = cyber_colors.normal
	style.border_width_top = 6  # DUPLICADO: era 3, ahora 6
	style.border_width_bottom = 6
	style.border_width_left = 6
	style.border_width_right = 6
	var panel = dragging_piece.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style)
	
	# Restaurar escala
	dragging_piece.scale = Vector2(1.0, 1.0)
	
	dragging_piece = null
	
	# Verificar si ganó
	if check_win():
		show_win_message()

func find_closest_grid_position(pos: Vector2) -> int:
	var closest_index = 0
	var min_distance = pos.distance_to(grid_positions[0])
	
	for i in range(1, grid_positions.size()):
		var distance = pos.distance_to(grid_positions[i])
		if distance < min_distance:
			min_distance = distance
			closest_index = i
	
	return closest_index

func get_piece_at_grid_index(grid_index: int) -> Control:
	for piece in puzzle_pieces:
		if piece.get_meta("current_grid_index") == grid_index and piece != dragging_piece:
			return piece
	return null

func shuffle_puzzle():
	# Mezclar índices
	var indices = [0, 1, 2, 3]
	indices.shuffle()
	
	# Asignar posiciones mezcladas
	for i in range(puzzle_pieces.size()):
		puzzle_pieces[i].position = grid_positions[indices[i]]
		puzzle_pieces[i].set_meta("current_grid_index", indices[i])
	
	# Asegurarse de que no esté ya resuelto
	if check_win():
		shuffle_puzzle()

func check_win() -> bool:
	for piece in puzzle_pieces:
		var original_index = piece.get_meta("original_index")
		var current_grid_index = piece.get_meta("current_grid_index")
		if original_index != current_grid_index:
			return false
	return true

func show_win_message():
	audio.stream_paused=true
	ganar.play()
	var win_label = get_node("WinMessage")
	win_label.visible = true
	
	# Desactivar interacción con las piezas
	for piece in puzzle_pieces:
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		# Animar las piezas con color de victoria
		var panel = piece.get_meta("panel")
		var style = piece.get_meta("style")
		style.bg_color = cyber_colors.correct
		style.border_color = Color(0, 1, 1)
		panel.add_theme_stylebox_override("panel", style)
		
		# Animación de celebración
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_ELASTIC)
		tween.tween_property(piece, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(piece, "scale", Vector2(1.0, 1.0), 0.3)
	
	# Animación del mensaje
	var tween = create_tween()
	tween.tween_property(win_label, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(win_label, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Esperar y cerrar automáticamente
	await get_tree().create_timer(1.0).timeout
	close_minigame()


func close_minigame():
	if check_win():
		emit_signal("puzzle_completed")
	else:
		emit_signal("puzzle_failed")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	queue_free()  # 💥 Cerrar correctamente el minijuego


func reset_puzzle():
	# Limpiar el puzzle para poder jugarlo de nuevo
	for piece in puzzle_pieces:
		piece.queue_free()
	puzzle_pieces.clear()
	
	# El puzzle se volverá a configurar en _ready() la próxima vez que se muestre
func show_minigame():
	visible = true
	# NO borrar el minijuego aquí
