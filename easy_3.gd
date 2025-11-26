extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Clase Nodo para los virus
class VirusNode:
	var virus_name: String = ""
	var virus_color: Color
	var power: int = 0
	var next: VirusNode = null
	var visual_node: Control = null
	var node_index: int = 0
	var is_captured: bool = false

# Variables del minijuego
var virus_chain_head: VirusNode = null
var current_node: VirusNode = null
var selected_virus: VirusNode = null
var virus_count: int = 0
var score: int = 0
var combo: int = 0
var time_left: float = 30.0
var game_active: bool = false

# Contenedores visuales
var virus_container: Control
var info_label: Label
var score_label: Label
var timer_label: Label
var combo_label: Label
var sequence_display: HBoxContainer
var action_buttons: Dictionary = {}

# Colores vivos y comunes para los virus
var virus_types = [
	{"name": "ROJO", "color": Color(1.0, 0.0, 0.0), "power": 10},
	{"name": "AZUL", "color": Color(0.0, 0.0, 1.0), "power": 15},
	{"name": "VERDE", "color": Color(0.0, 1.0, 0.0), "power": 20},
	{"name": "AMARILLO", "color": Color(1.0, 1.0, 0.0), "power": 25},
	{"name": "NARANJA", "color": Color(1.0, 0.5, 0.0), "power": 30},
	{"name": "MORADO", "color": Color(0.5, 0.0, 1.0), "power": 35},
	{"name": "ROSA", "color": Color(1.0, 0.0, 0.5), "power": 40},
	{"name": "CYAN", "color": Color(0.0, 1.0, 1.0), "power": 45}
]

# Colores del tema
var game_colors = {
	"bg": Color(0.15, 0.1, 0.2),
	"panel": Color(0.2, 0.15, 0.3),
	"border": Color(0.4, 0.8, 1.0),
	"success": Color(0.3, 0.9, 0.3),
	"danger": Color(0.9, 0.3, 0.3),
	"warning": Color(1.0, 0.8, 0.2),
	"info": Color(0.5, 0.8, 1.0)
}

# Efectos y animaciones
var particle_effects = []
var animation_queue = []
var star_particles = []

# Señal de completado
signal virus_hunter_completed()
signal puzzle_completed()

func _ready():
	randomize()
	setup_window()
	setup_game_ui()
	create_tutorial_panel()
	setup_game()

func setup_window():
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
	window_style.border_width_top = 8
	window_style.border_width_bottom = 8
	window_style.border_width_left = 8
	window_style.border_width_right = 8
	window_style.border_color = game_colors.border
	window_style.corner_radius_top_left = 25
	window_style.corner_radius_top_right = 25
	window_style.corner_radius_bottom_left = 25
	window_style.corner_radius_bottom_right = 25
	window_style.shadow_size = 10
	window_style.shadow_color = Color(0, 0, 0, 0.5)
	window_panel.add_theme_stylebox_override("panel", window_style)
	add_child(window_panel)
	
	# Botón cerrar
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.size = Vector2(60, 60)
	close_button.position = Vector2(window_size.x - 80, 20)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.add_theme_color_override("font_color", game_colors.danger)
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func setup_game_ui():
	# Título
	var title = Label.new()
	title.name = "Title"
	title.text = "CAZADOR DE VIRUS"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", game_colors.warning)
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.position = Vector2(360, 50)
	add_child(title)
	
	# Panel de puntuación
	create_score_panel()
	
	# Contenedor de virus
	virus_container = Control.new()
	virus_container.name = "VirusContainer"
	virus_container.position = Vector2(100, 300)
	virus_container.size = Vector2(1000, 400)
	add_child(virus_container)
	
	# Panel de secuencia
	create_sequence_panel()
	
	# Botones de acción
	create_action_buttons()
	
	# Panel de información
	create_info_panel()

func create_score_panel():
	var score_panel = Panel.new()
	score_panel.size = Vector2(1000, 80)
	score_panel.position = Vector2(100, 140)
	
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
	score_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(score_panel)
	
	# Puntuación
	score_label = Label.new()
	score_label.text = "PUNTOS: 0"
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_color_override("font_color", game_colors.warning)
	score_label.position = Vector2(130, 20)
	score_panel.add_child(score_label)
	
	# Combo
	combo_label = Label.new()
	combo_label.text = "COMBO: x0"
	combo_label.add_theme_font_size_override("font_size", 32)
	combo_label.add_theme_color_override("font_color", game_colors.success)
	combo_label.position = Vector2(380, 20)
	score_panel.add_child(combo_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 30"
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", game_colors.danger)
	timer_label.position = Vector2(640, 20)
	score_panel.add_child(timer_label)

func create_sequence_panel():
	var seq_panel = Panel.new()
	seq_panel.size = Vector2(1000, 150)
	seq_panel.position = Vector2(100, 620)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.25)
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_color = game_colors.info
	panel_style.corner_radius_top_left = 15
	panel_style.corner_radius_top_right = 15
	panel_style.corner_radius_bottom_left = 15
	panel_style.corner_radius_bottom_right = 15
	seq_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(seq_panel)
	
	# Título de secuencia
	var seq_title = Label.new()
	seq_title.text = "CAPTURA ESTOS 3 VIRUS EN ORDEN:"
	seq_title.add_theme_font_size_override("font_size", 28)
	seq_title.add_theme_color_override("font_color", game_colors.warning)
	seq_title.position = Vector2(280, 10)
	seq_panel.add_child(seq_title)
	
	# Contenedor de secuencia
	sequence_display = HBoxContainer.new()
	sequence_display.position = Vector2(350, 45)
	sequence_display.size = Vector2(300, 80)
	sequence_display.add_theme_constant_override("separation", 20)
	seq_panel.add_child(sequence_display)

func create_action_buttons():
	var button_container = HBoxContainer.new()
	button_container.position = Vector2(150, 800)
	button_container.size = Vector2(900, 80)
	button_container.add_theme_constant_override("separation", 25)
	add_child(button_container)
	
	# Botón Iniciar
	var start_btn = create_game_button("INICIAR", game_colors.success)
	start_btn.pressed.connect(_on_start_game)
	button_container.add_child(start_btn)
	action_buttons["start"] = start_btn
	
	# Botón Anterior
	var prev_btn = create_game_button("ANTERIOR", game_colors.info)
	prev_btn.pressed.connect(_on_previous_virus)
	prev_btn.disabled = true
	button_container.add_child(prev_btn)
	action_buttons["prev"] = prev_btn
	
	# Botón Siguiente
	var next_btn = create_game_button("SIGUIENTE", game_colors.info)
	next_btn.pressed.connect(_on_next_virus)
	next_btn.disabled = true
	button_container.add_child(next_btn)
	action_buttons["next"] = next_btn
	
	# Botón Capturar
	var capture_btn = create_game_button("CAPTURAR", game_colors.warning)
	capture_btn.pressed.connect(_on_capture_virus)
	capture_btn.disabled = true
	button_container.add_child(capture_btn)
	action_buttons["capture"] = capture_btn

func create_game_button(text: String, color: Color) -> Button:
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(200, 60)
	button.add_theme_font_size_override("font_size", 22)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = color * 0.8
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 4
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_color = color
	style_normal.corner_radius_top_left = 15
	style_normal.corner_radius_top_right = 15
	style_normal.corner_radius_bottom_left = 15
	style_normal.corner_radius_bottom_right = 15
	
	var style_hover = style_normal.duplicate()
	style_hover.bg_color = color
	style_hover.border_color = Color.WHITE
	
	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.3, 0.3, 0.3)
	style_disabled.border_color = Color(0.4, 0.4, 0.4)
	
	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_hover)
	button.add_theme_stylebox_override("disabled", style_disabled)
	
	return button

func create_info_panel():
	info_label = Label.new()
	info_label.name = "InfoLabel"
	info_label.text = "Captura los virus del color correcto en orden"
	info_label.add_theme_font_size_override("font_size", 26)
	info_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	info_label.position = Vector2(310, 900)
	add_child(info_label)

func create_tutorial_panel():
	var tutorial = Panel.new()
	tutorial.name = "Tutorial"
	tutorial.size = Vector2(500, 350)
	tutorial.position = Vector2(350, 240)
	tutorial.visible = true
	
	var tut_style = StyleBoxFlat.new()
	tut_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	tut_style.border_width_top = 4
	tut_style.border_width_bottom = 4
	tut_style.border_width_left = 4
	tut_style.border_width_right = 4
	tut_style.border_color = game_colors.warning
	tut_style.corner_radius_top_left = 20
	tut_style.corner_radius_top_right = 20
	tut_style.corner_radius_bottom_left = 20
	tut_style.corner_radius_bottom_right = 20
	tutorial.add_theme_stylebox_override("panel", tut_style)
	add_child(tutorial)
	
	var tut_title = Label.new()
	tut_title.text = "COMO JUGAR"
	tut_title.add_theme_font_size_override("font_size", 36)
	tut_title.add_theme_color_override("font_color", game_colors.warning)
	tut_title.position = Vector2(140, 20)
	tutorial.add_child(tut_title)
	
	var tut_text = Label.new()
	tut_text.text = "1. CAPTURA los 3 virus en el orden\n   que aparece en la parte inferior\n\n2. Usa ANTERIOR y SIGUIENTE\n   para moverte por la cadenidir"
	tut_text.add_theme_font_size_override("font_size", 26)
	tut_text.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	tut_text.position = Vector2(40, 70)
	tutorial.add_child(tut_text)
	
	# Botón cerrar tutorial
	var close_tut_btn = Button.new()
	close_tut_btn.text = "ENTENDIDO"
	close_tut_btn.size = Vector2(150, 50)
	close_tut_btn.position = Vector2(175, 280)
	close_tut_btn.add_theme_font_size_override("font_size", 24)
	close_tut_btn.pressed.connect(func(): tutorial.visible = false)
	tutorial.add_child(close_tut_btn)

func setup_game():
	virus_count = 0
	score = 0
	combo = 0
	time_left = 30.0
	game_active = false
	
	# Limpiar virus anteriores
	for child in virus_container.get_children():
		child.queue_free()
	
	# Limpiar secuencia
	for child in sequence_display.get_children():
		child.queue_free()

func _on_start_game():
	if has_node("Tutorial"):
		get_node("Tutorial").visible = false
	
	setup_game()
	create_virus_chain()
	create_capture_sequence()
	game_active = true
	
	# Habilitar botones
	action_buttons["capture"].disabled = false
	action_buttons["prev"].disabled = false
	action_buttons["next"].disabled = false
	action_buttons["start"].text = "REINICIAR"
	
	# Posicionar en el primer nodo
	current_node = virus_chain_head
	if current_node:
		highlight_current_virus()
	
	info_label.text = "Encuentra y captura los virus del color correcto"
	info_label.position = Vector2(330, 910)

func create_virus_chain():
	var chain_length = 5
	var previous_node: VirusNode = null
	
	for i in range(chain_length):
		var virus = VirusNode.new()
		var type_data = virus_types[randi() % virus_types.size()]
		
		virus.virus_name = type_data.name
		virus.virus_color = type_data.color
		virus.power = type_data.power
		virus.node_index = i
		
		# Crear visual
		var visual = create_virus_visual(virus, type_data)
		virus.visual_node = visual
		virus_container.add_child(visual)
		
		# Posicionar
		var x_pos = 100 + (140 * i)
		var y_pos = 100 + sin(i * 0.8) * 40
		visual.position = Vector2(x_pos, y_pos)
		
		# Enlazar nodos
		if previous_node:
			previous_node.next = virus
			create_connection_line(previous_node.visual_node, visual)
		else:
			virus_chain_head = virus
		
		previous_node = virus
		virus_count += 1

func create_virus_visual(virus: VirusNode, type_data: Dictionary) -> Control:
	var container = Control.new()
	container.size = Vector2(100, 100)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# Panel del virus
	var panel = Panel.new()
	panel.size = Vector2(100, 100)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = virus.virus_color
	style.border_width_top = 5
	style.border_width_bottom = 5
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_color = virus.virus_color * 0.7
	style.corner_radius_top_left = 50
	style.corner_radius_top_right = 50
	style.corner_radius_bottom_left = 50
	style.corner_radius_bottom_right = 50
	panel.add_theme_stylebox_override("panel", style)
	
	# Contenido
	var label = Label.new()
	label.text = virus.virus_name
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.add_child(label)
	
	container.add_child(panel)
	
	# Guardar referencias
	container.set_meta("virus_ref", virus)
	container.set_meta("panel", panel)
	container.set_meta("style", style)
	
	# Animación
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(container, "position:y", container.position.y - 10, 1.0)
	tween.tween_property(container, "position:y", container.position.y + 10, 1.0)
	
	container.gui_input.connect(_on_virus_clicked.bind(container))
	
	return container

func create_connection_line(from_visual: Control, to_visual: Control):
	var line = Line2D.new()
	line.width = 4.0
	line.default_color = game_colors.info * 0.5
	line.add_point(from_visual.position + Vector2(100, 50))
	line.add_point(to_visual.position + Vector2(0, 50))
	
	var mid_point = (line.points[0] + line.points[1]) / 2
	mid_point.y -= 20
	line.add_point(mid_point, 1)
	
	virus_container.add_child(line)
	virus_container.move_child(line, 0)

func create_capture_sequence():
	var sequence_length = 3
	var temp_viruses = []
	
	# Obtener todos los virus
	var current = virus_chain_head
	while current:
		temp_viruses.append(current)
		current = current.next
	
	# Seleccionar aleatoriamente
	temp_viruses.shuffle()
	
	for i in range(sequence_length):
		var virus = temp_viruses[i]
		
		# Crear miniatura
		var mini = Panel.new()
		mini.custom_minimum_size = Vector2(100, 100)
		
		var mini_style = StyleBoxFlat.new()
		mini_style.bg_color = virus.virus_color
		mini_style.border_width_top = 4
		mini_style.border_width_bottom = 4
		mini_style.border_width_left = 4
		mini_style.border_width_right = 4
		mini_style.border_color = virus.virus_color * 0.7
		mini_style.corner_radius_top_left = 50
		mini_style.corner_radius_top_right = 50
		mini_style.corner_radius_bottom_left = 50
		mini_style.corner_radius_bottom_right = 50
		mini.add_theme_stylebox_override("panel", mini_style)
		
		# Número de orden
		var order_label = Label.new()
		order_label.text = str(i + 1)
		order_label.add_theme_font_size_override("font_size", 32)
		order_label.add_theme_color_override("font_color", Color.WHITE)
		order_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		mini.add_child(order_label)
		
		# Guardar datos para comparación
		mini.set_meta("target_color", virus.virus_color)
		mini.set_meta("target_name", virus.virus_name)
		mini.set_meta("captured", false)
		sequence_display.add_child(mini)

func highlight_current_virus():
	if not current_node or not current_node.visual_node:
		return
	
	var style = current_node.visual_node.get_meta("style")
	style.border_width_top = 8
	style.border_width_bottom = 8
	style.border_width_left = 8
	style.border_width_right = 8
	style.border_color = Color.WHITE
	
	var panel = current_node.visual_node.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style)
	
	var tween = create_tween()
	tween.tween_property(current_node.visual_node, "scale", Vector2(1.2, 1.2), 0.2)

func unhighlight_current_virus():
	if not current_node or not current_node.visual_node:
		return
	
	var style = current_node.visual_node.get_meta("style")
	style.border_width_top = 5
	style.border_width_bottom = 5
	style.border_width_left = 5
	style.border_width_right = 5
	style.border_color = current_node.virus_color * 0.7
	
	var panel = current_node.visual_node.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style)
	
	var tween = create_tween()
	tween.tween_property(current_node.visual_node, "scale", Vector2(1.0, 1.0), 0.2)

func _on_virus_clicked(event: InputEvent, virus_visual: Control):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var virus = virus_visual.get_meta("virus_ref")
			info_label.text = "Virus " + virus.virus_name + " - Poder: " + str(virus.power)

func _on_next_virus():
	if not game_active or not current_node:
		return
	
	unhighlight_current_virus()
	
	if current_node.next:
		current_node = current_node.next
		info_label.text = "Moviéndose al siguiente virus..."
		info_label.position = Vector2(370, 910)
	else:
		current_node = virus_chain_head
		info_label.text = "Volviendo al inicio de la cadena..."
	
	highlight_current_virus()

func _on_previous_virus():
	if not game_active or not current_node:
		return
	
	unhighlight_current_virus()
	
	if current_node == virus_chain_head:
		var temp = virus_chain_head
		while temp.next != null:
			temp = temp.next
		current_node = temp
		info_label.text = "Saltando al final de la cadena..."
	else:
		var temp = virus_chain_head
		while temp != null and temp.next != current_node:
			temp = temp.next
		if temp != null:
			current_node = temp
			info_label.text = "Moviéndose al virus anterior..."
			info_label.position = Vector2(370, 910)
	
	highlight_current_virus()

func _on_capture_virus():
	if not game_active or not current_node:
		return
	
	# Buscar el siguiente objetivo no capturado
	var next_target_color = get_next_uncaptured_target()
	
	if next_target_color != null and colors_are_equal(current_node.virus_color, next_target_color):
		capture_success()
	else:
		capture_fail()

func get_next_uncaptured_target():
	for child in sequence_display.get_children():
		if not child.get_meta("captured"):
			return child.get_meta("target_color")
	return null

func colors_are_equal(color1: Color, color2: Color) -> bool:
	# Comparar colores con tolerancia
	var tolerance = 0.01
	return abs(color1.r - color2.r) < tolerance and \
		   abs(color1.g - color2.g) < tolerance and \
		   abs(color1.b - color2.b) < tolerance

func capture_success():
	correcto.play()
	combo += 1
	score += current_node.power * combo
	score_label.text = "PUNTOS: " + str(score)
	combo_label.text = "COMBO: x" + str(combo)
	
	# Marcar virus como capturado
	current_node.is_captured = true
	var style = current_node.visual_node.get_meta("style")
	style.bg_color = Color(0.3, 0.3, 0.3, 0.5)
	var panel = current_node.visual_node.get_meta("panel")
	panel.add_theme_stylebox_override("panel", style)
	
	# Marcar en la secuencia
	for child in sequence_display.get_children():
		if not child.get_meta("captured"):
			var target_color = child.get_meta("target_color")
			if colors_are_equal(current_node.virus_color, target_color):
				child.set_meta("captured", true)
				child.modulate = Color(0.5, 1.0, 0.5)
				break
	
	info_label.text = "Excelente! Virus " + current_node.virus_name + " capturado"
	info_label.add_theme_color_override("font_color", game_colors.success)
	info_label.position = Vector2(370, 910)
	
	if check_win():
		game_complete()

func capture_fail():
	error.play()
	combo = 0
	combo_label.text = "COMBO: x0"
	
	time_left = max(0, time_left - 5)
	
	info_label.text = "Incorrecto! Ese no es el siguiente virus"
	info_label.add_theme_color_override("font_color", game_colors.danger)
	info_label.position = Vector2(370, 910)
	
	# Efecto shake
	var original_pos = current_node.visual_node.position
	var tween = create_tween()
	for i in range(3):
		tween.tween_property(current_node.visual_node, "position:x", original_pos.x + 10, 0.05)
		tween.tween_property(current_node.visual_node, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(current_node.visual_node, "position:x", original_pos.x, 0.05)

func check_win() -> bool:
	for child in sequence_display.get_children():
		if not child.get_meta("captured"):
			return false
	return true

func game_complete():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	
	var win_panel = Panel.new()
	win_panel.size = Vector2(600, 400)
	win_panel.position = Vector2(300, 300)
	
	var win_style = StyleBoxFlat.new()
	win_style.bg_color = Color(0.1, 0.2, 0.1)
	win_style.set_border_width_all(8)
	win_style.border_color = game_colors.success
	win_style.corner_radius_top_left = 30
	win_style.corner_radius_top_right = 30
	win_style.corner_radius_bottom_left = 30
	win_style.corner_radius_bottom_right = 30
	win_panel.add_theme_stylebox_override("panel", win_style)
	add_child(win_panel)
	
	var win_label = Label.new()
	win_label.text = "¡VICTORIA!"
	win_label.add_theme_font_size_override("font_size", 64)
	win_label.add_theme_color_override("font_color", game_colors.warning)
	win_label.position = Vector2(150, 50)
	win_panel.add_child(win_label)
	
	var final_score = Label.new()
	final_score.text = "Puntuación Final: " + str(score) + "\n\nCapturaste los 3 virus!\nFelicidades!"
	final_score.add_theme_font_size_override("font_size", 28)
	final_score.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	final_score.position = Vector2(150, 180)
	final_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	win_panel.add_child(final_score)
	
	win_panel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(win_panel, "scale", Vector2(1.0, 1.0), 0.5)
	
	await get_tree().create_timer(3.0).timeout
	emit_signal("puzzle_completed")
	close_minigame()

func _process(delta):
	if game_active:
		time_left -= delta
		timer_label.text = "TIEMPO: " + str(int(time_left))
		
		if time_left <= 10:
			timer_label.add_theme_color_override("font_color", game_colors.danger)
		
		if time_left <= 0:
			game_over()

func game_over():
	audio.stream_paused=true
	perder.play()
	game_active = false
	info_label.text = "Se acabó el tiempo! Juego terminado"
	info_label.add_theme_color_override("font_color", game_colors.danger)
	
	action_buttons["capture"].disabled = true
	action_buttons["prev"].disabled = true
	action_buttons["next"].disabled = true

	await get_tree().create_timer(2.0).timeout
	close_minigame()

func _on_close_pressed():
	close_minigame()

func close_minigame():
	print("Cerrando minijuego...")

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		player.set("movement_disabled", false)
		print("Movimiento del jugador reactivado")

	# Resetear estados en Lab1.gd
	var root = get_tree().get_root()
	var lab_scene = root.find_child("Lab1", true, false)
	if lab_scene:
		lab_scene.minijuego_en_progreso = false
		lab_scene.minijuego_actual = null
		lab_scene.minijuegos_completados["easy4"] = true

		print("Estado de minijuego reseteado correctamente")

	queue_free()

func show_minigame():
	visible = true
	modulate = Color(1,1,1,0)

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

	# Indica que ya hay un minijuego activo
	var root = get_tree().get_root()
	var lab_scene = root.find_child("Lab1", true, false)
	if lab_scene:
		lab_scene.minijuego_en_progreso = true
		lab_scene.minijuego_actual = self
