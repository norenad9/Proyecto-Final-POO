extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Variables del minijuego
var moving_bar: ColorRect
var target_zone: ColorRect
var progress_bar_bg: Panel
var score: int = 0
var attempts_left: int = 3
var time_left: float = 20.0
var max_time: float = 20.0
var game_active: bool = true

# Variables de movimiento
var bar_position: float = 0.0
var bar_speed: float = 400.0  # Velocidad media
var bar_direction: int = 1  # 1 = derecha, -1 = izquierda
var bar_width: float = 10.0
var target_zone_start: float = 0.0
var target_zone_width: float = 80.0
var bar_container_width: float = 800.0

# Variables de UI
var score_label: Label
var attempts_label: Label
var timer_label: Label
var timer_bar: ProgressBar
var feedback_label: Label
var instruction_label: Label
var result_label: Label

# Colores del tema
var game_colors = {
	"bg": Color(0.1, 0.1, 0.15),
	"panel": Color(0.15, 0.15, 0.2),
	"border": Color(0.2, 0.8, 0.8),
	"success": Color(0.2, 0.9, 0.2),
	"error": Color(0.9, 0.2, 0.2),
	"warning": Color(0.9, 0.9, 0.2),
	"info": Color(0.4, 0.8, 1.0),
	"target": Color(1.0, 0.2, 0.2),
	"bar": Color(0.2, 0.8, 0.8)
}

signal puzzle_completed
signal puzzle_failed



func _ready():
	randomize()
	setup_window()
	setup_ui()
	setup_game_area()
	randomize_target_position()

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
	title.text = "PRUEBA DE PRECISIÓN"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(350, 50)
	add_child(title)
	
	# Instrucciones
	instruction_label = Label.new()
	instruction_label.text = "Haz click cuando la barra azul pase por la zona roja"
	instruction_label.add_theme_font_size_override("font_size", 26)
	instruction_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction_label.position = Vector2(300, 110)
	add_child(instruction_label)
	
	# Panel de información
	create_info_panel()
	
	# Panel de timer
	create_timer_panel()
	
	# Feedback
	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.add_theme_font_size_override("font_size", 32)
	feedback_label.position = Vector2(450, 550)
	add_child(feedback_label)
	
	# Resultado
	result_label = Label.new()
	result_label.text = ""
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.position = Vector2(400, 600)
	add_child(result_label)

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
	
	# Puntuación
	score_label = Label.new()
	score_label.text = "ACIERTOS: 0/3"
	score_label.add_theme_font_size_override("font_size", 30)
	score_label.add_theme_color_override("font_color", game_colors.success)
	score_label.position = Vector2(50, 18)
	info_panel.add_child(score_label)
	
	# Intentos
	attempts_label = Label.new()
	attempts_label.text = "INTENTOS: 3"
	attempts_label.add_theme_font_size_override("font_size", 30)
	attempts_label.add_theme_color_override("font_color", game_colors.warning)
	attempts_label.position = Vector2(400, 18)
	info_panel.add_child(attempts_label)
	
	# Timer
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 20"
	timer_label.add_theme_font_size_override("font_size", 30)
	timer_label.add_theme_color_override("font_color", game_colors.info)
	timer_label.position = Vector2(700, 18)
	info_panel.add_child(timer_label)

func create_timer_panel():
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(1000, 30)
	timer_panel.position = Vector2(100, 250)
	
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

func setup_game_area():
	# Contenedor del juego
	var game_container = Control.new()
	game_container.position = Vector2(200, 350)
	game_container.size = Vector2(800, 150)
	add_child(game_container)
	
	# Fondo de la barra de progreso
	progress_bar_bg = Panel.new()
	progress_bar_bg.size = Vector2(bar_container_width, 100)
	progress_bar_bg.position = Vector2(0, 25)
	
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.2)
	bg_style.border_width_top = 4
	bg_style.border_width_bottom = 4
	bg_style.border_width_left = 4
	bg_style.border_width_right = 4
	bg_style.border_color = Color(0.3, 0.3, 0.4)
	bg_style.corner_radius_top_left = 10
	bg_style.corner_radius_top_right = 10
	bg_style.corner_radius_bottom_left = 10
	bg_style.corner_radius_bottom_right = 10
	progress_bar_bg.add_theme_stylebox_override("panel", bg_style)
	game_container.add_child(progress_bar_bg)
	
	# Zona objetivo (roja)
	target_zone = ColorRect.new()
	target_zone.color = game_colors.target
	target_zone.size = Vector2(target_zone_width, 80)
	target_zone.position = Vector2(target_zone_start, 10)
	target_zone.modulate.a = 0.7
	progress_bar_bg.add_child(target_zone)
	
	# Barra móvil (azul)
	moving_bar = ColorRect.new()
	moving_bar.color = game_colors.bar
	moving_bar.size = Vector2(bar_width, 90)
	moving_bar.position = Vector2(0, 5)
	progress_bar_bg.add_child(moving_bar)
	
	# Líneas decorativas
	for i in range(5):
		var line = ColorRect.new()
		line.color = Color(0.3, 0.3, 0.3, 0.5)
		line.size = Vector2(2, 100)
		line.position = Vector2(i * 200, 0)
		progress_bar_bg.add_child(line)

func randomize_target_position():
	# Posicionar la zona objetivo en un lugar aleatorio
	target_zone_start = randf_range(100, bar_container_width - target_zone_width - 100)
	target_zone.position.x = target_zone_start

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
	if time_left <= 5:
		fill_style.bg_color = game_colors.error
	elif time_left <= 10:
		fill_style.bg_color = game_colors.warning
	else:
		fill_style.bg_color = game_colors.info
	timer_bar.add_theme_stylebox_override("fill", fill_style)
	
	if time_left <= 0:
		time_out()
	
	# Mover la barra
	bar_position += bar_speed * bar_direction * delta
	
	# Rebotar en los límites
	if bar_position <= 0:
		bar_position = 0
		bar_direction = 1
	elif bar_position >= bar_container_width - bar_width:
		bar_position = bar_container_width - bar_width
		bar_direction = -1
	
	# Actualizar posición visual
	moving_bar.position.x = bar_position
	
	# Efecto visual cuando está en la zona
	if is_in_target_zone():
		moving_bar.modulate = Color(1.2, 1.2, 1.2)
	else:
		moving_bar.modulate = Color(1.0, 1.0, 1.0)

func _input(event):
	if not game_active:
		return
	
	# Detectar click en cualquier parte
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			check_timing()

func is_in_target_zone() -> bool:
	var bar_center = bar_position + (bar_width / 2)
	var zone_start = target_zone_start
	var zone_end = target_zone_start + target_zone_width
	
	return bar_center >= zone_start and bar_center <= zone_end

func check_timing():
	if attempts_left <= 0:
		return
	
	attempts_left -= 1
	attempts_label.text = "INTENTOS: " + str(attempts_left)
	
	if is_in_target_zone():
		# Acierto
		correcto.play()
		score += 1
		score_label.text = "ACIERTOS: " + str(score) + "/3"
		
		feedback_label.text = "¡PERFECTO!"
		feedback_label.add_theme_color_override("font_color", game_colors.success)
		feedback_label.position = Vector2(510, 550)
		
		# Efecto visual de éxito
		create_success_effect()
		
		# Cambiar posición de la zona para el siguiente intento
		if score < 3:
			randomize_target_position()
			# Aumentar velocidad ligeramente
			bar_speed += 50
	else:
		# Fallo
		error.play()
		feedback_label.text = "¡FALLASTE!"
		feedback_label.add_theme_color_override("font_color", game_colors.error)
		feedback_label.position = Vector2(510, 550)
		
		# Efecto visual de error
		create_error_effect()
	
	# Verificar condiciones de victoria/derrota
	if score >= 2:
		game_success()
	elif attempts_left <= 0 and score < 2:
		game_over()

func create_success_effect():
	# Flash verde en la zona objetivo
	var flash = ColorRect.new()
	flash.color = Color(0, 1, 0, 0.5)
	flash.size = target_zone.size
	flash.position = target_zone.position
	progress_bar_bg.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func create_error_effect():
	# Flash rojo en toda la barra
	var flash = ColorRect.new()
	flash.color = Color(1, 0, 0, 0.3)
	flash.size = progress_bar_bg.size
	flash.position = Vector2(0, 0)
	progress_bar_bg.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func game_success():
	audio.stream_paused=true
	ganar.play()

	game_active = false
	
	result_label.text = "PRUEBA COMPLETADA CON ÉXITO!"
	result_label.add_theme_color_override("font_color", game_colors.success)
	result_label.position = Vector2(380, 610)
	
	# Panel de victoria
	var win_panel = Panel.new()
	win_panel.size = Vector2(600, 300)
	win_panel.position = Vector2(300, 250)
	
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
	win_label.text = "¡VICTORIA!"
	win_label.add_theme_font_size_override("font_size", 56)
	win_label.add_theme_color_override("font_color", game_colors.success)
	win_label.position = Vector2(160, 50)
	win_panel.add_child(win_label)
	
	var stats = Label.new()
	stats.text = "Completaste el desafío\n3 aciertos perfectos\nTiempo restante: " + str(int(time_left)) + " segundos"
	stats.add_theme_font_size_override("font_size", 26)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats.position = Vector2(110, 150)
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
	
	result_label.text = "NO LOGRASTE COMPLETAR EL DESAFÍO"
	result_label.add_theme_color_override("font_color", game_colors.error)
	result_label.position = Vector2(350, 610) 
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func time_out():
	game_active = false
	
	feedback_label.text = "TIEMPO AGOTADO!"
	feedback_label.add_theme_color_override("font_color", game_colors.error)
	
	await get_tree().create_timer(2.0).timeout
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
