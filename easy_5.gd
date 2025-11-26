
extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer

# Clase Nodo para la lista enlazada
class ListNode:
	var value: int = 0
	var next: ListNode = null
	var visual: Control = null

# Clase Lista Enlazada
class LinkedList:
	var head: ListNode = null
	var size: int = 0
	
	func add_sorted(value: int) -> bool:
		var new_node = ListNode.new()
		new_node.value = value
		
		# Lista vacía o insertar al inicio
		if head == null or head.value > value:
			new_node.next = head
			head = new_node
			size += 1
			return true
		
		# Buscar posición correcta
		var current = head
		while current.next != null and current.next.value < value:
			current = current.next
		
		# Verificar si ya existe
		if current.next != null and current.next.value == value:
			return false  # No permitir duplicados
		
		new_node.next = current.next
		current.next = new_node
		size += 1
		return true
	
	func remove_value(value: int) -> bool:
		if head == null:
			return false
		
		# Si es el primer elemento
		if head.value == value:
			head = head.next
			size -= 1
			return true
		
		# Buscar el nodo
		var current = head
		while current.next != null and current.next.value != value:
			current = current.next
		
		if current.next != null:
			current.next = current.next.next
			size -= 1
			return true
		
		return false
	
	func get_values_array() -> Array:
		var values = []
		var current = head
		while current != null:
			values.append(current.value)
			current = current.next
		return values
	
	func clear():
		head = null
		size = 0

# Variables del juego
var linked_list: LinkedList
var target_list = []  # Lista objetivo a lograr
var available_numbers = []  # Números disponibles para agregar
var time_left: float = 45.0
var max_time: float = 45.0
var game_active: bool = false
var operations_count: int = 0

# Componentes visuales
var list_container: Control
var target_panel: Panel
var available_panel: Panel
var status_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var operations_label: Label
var current_list_display: HBoxContainer
var target_list_display: HBoxContainer
var available_buttons_container: HBoxContainer

# Colores del tema
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.8, 0.8),
	"success": Color(0.2, 0.9, 0.2),
	"error": Color(0.9, 0.2, 0.2),
	"warning": Color(0.9, 0.9, 0.2),
	"info": Color(0.4, 0.8, 1.0),
	"node": Color(0.3, 0.5, 0.8)
}

signal puzzle_completed
signal puzzle_failed



func _ready():
	randomize()
	setup_window()
	setup_ui()
	create_game_panels()
	# Iniciar automáticamente
	await get_tree().create_timer(0.5).timeout
	start_game()

func setup_window():
	var viewport_size = Vector2(get_viewport().size)
	var window_size = Vector2(1200, 1000)
	
	position = (viewport_size - window_size) / 2
	size = window_size
	
	# Fondo
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
	title.text = "GESTIÓN DE LISTA ENLAZADA ORDENADA"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(115, 50)
	add_child(title)
	
	# Panel de información
	create_info_panel()
	
	# Panel de timer
	create_timer_panel()

func create_info_panel():
	var info_panel = Panel.new()
	info_panel.size = Vector2(1000, 70)
	info_panel.position = Vector2(100, 120)
	
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
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 30"
	timer_label.add_theme_font_size_override("font_size", 32)
	timer_label.add_theme_color_override("font_color", game_colors.info)
	timer_label.position = Vector2(50, 18)
	info_panel.add_child(timer_label)
	
	# Operaciones
	operations_label = Label.new()
	operations_label.text = "OPERACIONES: 0"
	operations_label.add_theme_font_size_override("font_size", 32)
	operations_label.add_theme_color_override("font_color", game_colors.warning)
	operations_label.position = Vector2(400, 18)
	info_panel.add_child(operations_label)
	
	# Estado
	status_label = Label.new()
	status_label.text = "PREPARANDO..."
	status_label.add_theme_font_size_override("font_size", 32)
	status_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	status_label.position = Vector2(700, 18)
	info_panel.add_child(status_label)

func create_timer_panel():
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(1000, 30)
	timer_panel.position = Vector2(100, 200)
	
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
	timer_bar.position = Vector2(9, 3)
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

func create_game_panels():
	# Panel de lista objetivo
	target_panel = Panel.new()
	target_panel.size = Vector2(1000, 150)
	target_panel.position = Vector2(100, 250)
	
	var target_style = StyleBoxFlat.new()
	target_style.bg_color = Color(0.15, 0.2, 0.15)
	target_style.border_width_top = 4
	target_style.border_width_bottom = 4
	target_style.border_width_left = 4
	target_style.border_width_right = 4
	target_style.border_color = game_colors.success
	target_style.corner_radius_top_left = 10
	target_style.corner_radius_top_right = 10
	target_style.corner_radius_bottom_left = 10
	target_style.corner_radius_bottom_right = 10
	target_panel.add_theme_stylebox_override("panel", target_style)
	add_child(target_panel)
	
	var target_label = Label.new()
	target_label.text = "LISTA OBJETIVO (mantén la lista ordenada con estos valores):"
	target_label.add_theme_font_size_override("font_size", 26)
	target_label.add_theme_color_override("font_color", game_colors.success)
	target_label.position = Vector2(20, 10)
	target_panel.add_child(target_label)
	
	target_list_display = HBoxContainer.new()
	target_list_display.position = Vector2(30, 50)
	target_list_display.add_theme_constant_override("separation", 15)
	target_panel.add_child(target_list_display)
	
	# Panel de lista actual
	var current_panel = Panel.new()
	current_panel.size = Vector2(1000, 150)
	current_panel.position = Vector2(100, 420)
	
	var current_style = StyleBoxFlat.new()
	current_style.bg_color = Color(0.15, 0.15, 0.2)
	current_style.border_width_top = 4
	current_style.border_width_bottom = 4
	current_style.border_width_left = 4
	current_style.border_width_right = 4
	current_style.border_color = game_colors.node
	current_style.corner_radius_top_left = 10
	current_style.corner_radius_top_right = 10
	current_style.corner_radius_bottom_left = 10
	current_style.corner_radius_bottom_right = 10
	current_panel.add_theme_stylebox_override("panel", current_style)
	add_child(current_panel)
	
	var current_label = Label.new()
	current_label.text = "TU LISTA ACTUAL:"
	current_label.add_theme_font_size_override("font_size", 28)
	current_label.add_theme_color_override("font_color", game_colors.node)
	current_label.position = Vector2(20, 10)
	current_panel.add_child(current_label)
	
	current_list_display = HBoxContainer.new()
	current_list_display.position = Vector2(30, 60)
	current_list_display.add_theme_constant_override("separation", 10)
	current_panel.add_child(current_list_display)
	
	# Panel de números disponibles
	available_panel = Panel.new()
	available_panel.size = Vector2(1000, 200)
	available_panel.position = Vector2(100, 580)
	
	var available_style = StyleBoxFlat.new()
	available_style.bg_color = Color(0.12, 0.12, 0.15)
	available_style.border_width_top = 3
	available_style.border_width_bottom = 3
	available_style.border_width_left = 3
	available_style.border_width_right = 3
	available_style.border_color = Color(0.4, 0.4, 0.5)
	available_style.corner_radius_top_left = 10
	available_style.corner_radius_top_right = 10
	available_style.corner_radius_bottom_left = 10
	available_style.corner_radius_bottom_right = 10
	available_panel.add_theme_stylebox_override("panel", available_style)
	add_child(available_panel)
	
	var available_label = Label.new()
	available_label.text = "OPERACIONES DISPONIBLES:"
	available_label.add_theme_font_size_override("font_size", 26)
	available_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	available_label.position = Vector2(20, 10)
	available_panel.add_child(available_label)
	
	available_buttons_container = HBoxContainer.new()
	available_buttons_container.position = Vector2(30, 60)
	available_buttons_container.add_theme_constant_override("separation", 20)
	available_panel.add_child(available_buttons_container)

func start_game():
	linked_list = LinkedList.new()
	game_active = true
	time_left = max_time
	operations_count = 0
	
	# Generar lista objetivo (5-7 números ordenados)
	var count = randi_range(4, 6)
	var numbers = []
	for i in range(10):  # Pool de números del 1 al 15
		numbers.append(i + 1)
	numbers.shuffle()
	
	target_list.clear()
	for i in range(count):
		target_list.append(numbers[i])
	target_list.sort()
	
	# Iniciar con algunos números ya en la lista
	var initial_count = randi_range(1,2)
	for i in range(initial_count):
		linked_list.add_sorted(target_list[i])
	
	# Generar números disponibles (incluye los que faltan y algunos extra)
	available_numbers.clear()
	for num in target_list:
		if not num in linked_list.get_values_array():
			available_numbers.append(num)
	
	# Agregar algunos números que NO deben estar
	for i in range(2):
		var extra = randi_range(11, 20)
		if not extra in available_numbers:
			available_numbers.append(extra)
	
	available_numbers.shuffle()
	
	# Actualizar displays
	update_displays()
	create_operation_buttons()
	
	status_label.text = "EN JUEGO"
	status_label.add_theme_color_override("font_color", game_colors.info)

func update_displays():
	# Limpiar displays
	for child in current_list_display.get_children():
		child.queue_free()
	for child in target_list_display.get_children():
		child.queue_free()
	
	# Mostrar lista objetivo
	for value in target_list:
		var node = create_node_visual(value, game_colors.success, false)
		target_list_display.add_child(node)
	
	# Mostrar lista actual con flechas
	var current_values = linked_list.get_values_array()
	for i in range(current_values.size()):
		var node = create_node_visual(current_values[i], game_colors.node, true)
		current_list_display.add_child(node)
		
		# Agregar flecha si no es el último
		if i < current_values.size() - 1:
			var arrow = Label.new()
			arrow.text = "→"
			arrow.add_theme_font_size_override("font_size", 36)
			arrow.add_theme_color_override("font_color", game_colors.node)
			current_list_display.add_child(arrow)
	
	# Si la lista está vacía, mostrar mensaje
	if current_values.is_empty():
		var empty_label = Label.new()
		empty_label.text = "[LISTA VACÍA]"
		empty_label.add_theme_font_size_override("font_size", 28)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		current_list_display.add_child(empty_label)

func create_node_visual(value: int, color: Color, can_delete: bool) -> Control:
	var container = Control.new()
	container.custom_minimum_size = Vector2(80, 80)
	
	var panel = Panel.new()
	panel.size = Vector2(80, 80)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS if can_delete else Control.MOUSE_FILTER_IGNORE
	
	var style = StyleBoxFlat.new()
	style.bg_color = color * 0.8
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_color = color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = str(value)
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.add_child(label)
	
	container.add_child(panel)
	
	if can_delete:
		panel.gui_input.connect(_on_node_clicked.bind(value))
		container.set_meta("value", value)
	
	return container

func create_operation_buttons():
	# Limpiar botones anteriores
	for child in available_buttons_container.get_children():
		child.queue_free()
	
	# Crear botones para agregar números disponibles
	var add_label = Label.new()
	add_label.text = "AGREGAR:"
	add_label.add_theme_font_size_override("font_size", 24)
	add_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	available_buttons_container.add_child(add_label)
	
	for num in available_numbers:
		var button = Button.new()
		button.text = "+ " + str(num)
		button.custom_minimum_size = Vector2(100, 60)
		button.add_theme_font_size_override("font_size", 28)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = game_colors.success * 0.6
		btn_style.border_width_top = 3
		btn_style.border_width_bottom = 3
		btn_style.border_width_left = 3
		btn_style.border_width_right = 3
		btn_style.border_color = game_colors.success
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		
		button.add_theme_stylebox_override("normal", btn_style)
		button.pressed.connect(_on_add_number.bind(num))
		available_buttons_container.add_child(button)

func _on_add_number(value: int):
	if not game_active:
		return
	
	if linked_list.add_sorted(value):
		operations_count += 1
		operations_label.text = "OPERACIONES: " + str(operations_count)
		
		# Remover de disponibles
		available_numbers.erase(value)
		create_operation_buttons()
		update_displays()
		
		# Verificar victoria
		check_win()
	else:
		status_label.text = "YA EXISTE"
		status_label.add_theme_color_override("font_color", game_colors.warning)

func _on_node_clicked(event: InputEvent, value: int):
	if not game_active:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Click derecho para eliminar
			if linked_list.remove_value(value):
				operations_count += 1
				operations_label.text = "OPERACIONES: " + str(operations_count)
				
				# Agregar de vuelta a disponibles si no es número objetivo
				if not value in target_list:
					available_numbers.append(value)
				else:
					available_numbers.append(value)
				
				available_numbers.sort()
				create_operation_buttons()
				update_displays()
				
				status_label.text = "ELIMINADO: " + str(value)
				status_label.add_theme_color_override("font_color", game_colors.error)

func check_win():
	var current_values = linked_list.get_values_array()
	
	if current_values == target_list:
		game_success()

func game_success():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	status_label.text = "¡CORRECTO!"
	status_label.add_theme_color_override("font_color", game_colors.success)

	var flash = ColorRect.new()
	flash.size = size
	flash.color = Color(0, 1, 0, 0.3)
	add_child(flash)

	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_completed")
	close_minigame()


func game_failed():
	audio.stream_paused=true
	perder.play()
	game_active = false
	status_label.text = "TIEMPO AGOTADO"
	status_label.add_theme_color_override("font_color", game_colors.error)

	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()


func _process(delta):
	if game_active:
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
			game_failed()

func _input(event):
	# Si se presiona R y el minijuego ya terminó, cerrar
	if event.is_action_pressed("restart") and not game_active:
		close_minigame()

func _on_close_pressed():
	close_minigame()
func close_minigame():
	emit_signal("list_minigame_completed")

	# 🔍 Buscar el player en todo el árbol de nodos
	var player = get_tree().get_root().find_child("Player", true, false)
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		print("🎮 Movimiento del jugador reactivado")

	# 🔄 Desvanecer y cerrar minijuego
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	queue_free()


func show_minigame():
	visible = true
	modulate.a = 1.0
	
	# Desactivar movimiento del player mientras esté abierto
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_node("player"):
		var player = game_manager.get_node("player")
		if player:
			player.set_process_input(false)
			player.set_physics_process(false)
			player.set_process(false)
