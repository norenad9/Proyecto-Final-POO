extends Control
@onready var perder= $perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Variables del minijuego de contraseña
var password_input: LineEdit
var target_password: String = ""
var target_password_label: Label
var attempts_left: int = 3
var attempts_label: Label
var submit_button: Button
var feedback_label: Label
var time_left: float = 30.0
var max_time: float = 30.0
var timer_label: Label
var timer_bar: ProgressBar
var game_active: bool = true

# Componentes para generar contraseña segura
var uppercase_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
var lowercase_chars = "abcdefghijklmnopqrstuvwxyz"
var numbers = "0123456789"
var special_chars = "!@#$%&*+-="

# Colores del tema
var cyber_colors = {
	"normal": Color(0.5, 0.5, 0.5),
	"correct": Color(0.2, 0.8, 0.2),
	"incorrect": Color(0.8, 0.2, 0.2),
	"warning": Color(0.8, 0.8, 0.2),
	"bg": Color(0.1, 0.1, 0.15),
	"border": Color(0.2, 0.8, 0.8)
}
signal puzzle_completed
signal puzzle_failed


func _ready():
	randomize()
	generate_secure_password()
	setup_window()
	setup_ui()

func generate_secure_password():
	# Generar contraseña de 12-14 caracteres que cumpla todos los requisitos
	var length = randi_range(6, 7)
	var password_chars = []
	
	# Asegurar al menos un carácter de cada tipo
	password_chars.append(uppercase_chars[randi() % uppercase_chars.length()])
	password_chars.append(lowercase_chars[randi() % lowercase_chars.length()])
	password_chars.append(numbers[randi() % numbers.length()])
	password_chars.append(special_chars[randi() % special_chars.length()])
	
	# Llenar el resto con caracteres aleatorios
	var all_chars = uppercase_chars + lowercase_chars + numbers + special_chars
	for i in range(length - 4):
		password_chars.append(all_chars[randi() % all_chars.length()])
	
	# Mezclar los caracteres
	password_chars.shuffle()
	
	# Construir la contraseña
	target_password = ""
	for c in password_chars:
		target_password += c

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
	window_style.bg_color = cyber_colors.bg
	window_style.border_width_top = 6
	window_style.border_width_bottom = 6
	window_style.border_width_left = 6
	window_style.border_width_right = 6
	window_style.border_color = cyber_colors.border
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
	close_button.add_theme_color_override("font_color", cyber_colors.incorrect)
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func setup_ui():
	# Título
	var title = Label.new()
	title.text = "SISTEMA DE AUTENTICACIÓN RÁPIDA"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", cyber_colors.border)
	title.position = Vector2(180, 50)
	add_child(title)
	
	# Instrucciones
	var instruction = Label.new()
	instruction.text = "Digita exactamente la contraseña mostrada antes de que se acabe el tiempo"
	instruction.add_theme_font_size_override("font_size", 24)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction.position = Vector2(170, 110)
	add_child(instruction)
	
	# Panel de contraseña objetivo
	var target_container = Panel.new()
	target_container.size = Vector2(800, 130)
	target_container.position = Vector2(200, 160)
	
	var target_style = StyleBoxFlat.new()
	target_style.bg_color = Color(0.15, 0.2, 0.15)
	target_style.border_width_top = 4
	target_style.border_width_bottom = 4
	target_style.border_width_left = 4
	target_style.border_width_right = 4
	target_style.border_color = cyber_colors.correct
	target_style.corner_radius_top_left = 15
	target_style.corner_radius_top_right = 15
	target_style.corner_radius_bottom_left = 15
	target_style.corner_radius_bottom_right = 15
	target_container.add_theme_stylebox_override("panel", target_style)
	add_child(target_container)
	
	# Label de contraseña objetivo
	var target_title = Label.new()
	target_title.text = "CONTRASEÑA A COPIAR:"
	target_title.add_theme_font_size_override("font_size", 24)
	target_title.add_theme_color_override("font_color", cyber_colors.correct)
	target_title.position = Vector2(270, 15)
	target_container.add_child(target_title)
	
	# Contraseña visible siempre
	target_password_label = Label.new()
	target_password_label.text = target_password
	target_password_label.add_theme_font_size_override("font_size", 46)
	target_password_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	target_password_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0))
	target_password_label.add_theme_constant_override("shadow_offset_x", 2)
	target_password_label.add_theme_constant_override("shadow_offset_y", 2)
	
	# Centrar la contraseña
	var text_width = target_password.length() * 25  # Aproximado
	target_password_label.position = Vector2((800 - text_width) / 2, 50)
	target_container.add_child(target_password_label)
	
	# Panel de Timer
	var timer_panel = Panel.new()
	timer_panel.size = Vector2(800, 80)
	timer_panel.position = Vector2(200, 310)
	
	var timer_style = StyleBoxFlat.new()
	timer_style.bg_color = Color(0.12, 0.12, 0.15)
	timer_style.border_width_top = 3
	timer_style.border_width_bottom = 3
	timer_style.border_width_left = 3
	timer_style.border_width_right = 3
	timer_style.border_color = Color(0.4, 0.4, 0.5)
	timer_style.corner_radius_top_left = 10
	timer_style.corner_radius_top_right = 10
	timer_style.corner_radius_bottom_left = 10
	timer_style.corner_radius_bottom_right = 10
	timer_panel.add_theme_stylebox_override("panel", timer_style)
	add_child(timer_panel)
	
	# Timer label
	timer_label = Label.new()
	timer_label.text = "TIEMPO: 15"
	timer_label.add_theme_font_size_override("font_size", 28)
	timer_label.add_theme_color_override("font_color", cyber_colors.warning)
	timer_label.position = Vector2(30, 20)
	timer_panel.add_child(timer_label)
	
	# Barra de tiempo
	timer_bar = ProgressBar.new()
	timer_bar.size = Vector2(600, 30)
	timer_bar.position = Vector2(180, 25)
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
	bar_fill.bg_color = cyber_colors.warning
	bar_fill.corner_radius_top_left = 15
	bar_fill.corner_radius_top_right = 15
	bar_fill.corner_radius_bottom_left = 15
	bar_fill.corner_radius_bottom_right = 15
	
	timer_bar.add_theme_stylebox_override("background", bar_bg)
	timer_bar.add_theme_stylebox_override("fill", bar_fill)
	timer_panel.add_child(timer_bar)
	
	# Container de entrada
	var input_container = Control.new()
	input_container.position = Vector2(200, 420)
	input_container.size = Vector2(800, 120)
	add_child(input_container)
	
	# Label de entrada
	var input_label = Label.new()
	input_label.text = "TU RESPUESTA:"
	input_label.add_theme_font_size_override("font_size", 26)
	input_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	input_container.add_child(input_label)
	
	# Campo de entrada
	password_input = LineEdit.new()
	password_input.size = Vector2(700, 60)
	password_input.position = Vector2(0, 40)
	password_input.placeholder_text = "Escribe aquí la contraseña..."
	password_input.add_theme_font_size_override("font_size", 32)
	password_input.grab_focus()
	
	var input_style = StyleBoxFlat.new()
	input_style.bg_color = Color(0.15, 0.15, 0.2)
	input_style.border_width_top = 3
	input_style.border_width_bottom = 3
	input_style.border_width_left = 3
	input_style.border_width_right = 3
	input_style.border_color = Color(0.4, 0.4, 0.5)
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	password_input.add_theme_stylebox_override("normal", input_style)
	password_input.add_theme_stylebox_override("focus", input_style)
	
	# Conectar Enter para verificar
	password_input.text_submitted.connect(_on_text_submitted)
	input_container.add_child(password_input)
	
	# Intentos restantes
	attempts_label = Label.new()
	attempts_label.text = "Intentos restantes: 3"
	attempts_label.add_theme_font_size_override("font_size", 26)
	attempts_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	attempts_label.position = Vector2(200, 560)
	add_child(attempts_label)
	
	# Feedback
	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.position = Vector2(200, 610)
	add_child(feedback_label)
	
	# Botón de verificar
	submit_button = Button.new()
	submit_button.text = "VERIFICAR CONTRASEÑA"
	submit_button.size = Vector2(400, 70)
	submit_button.position = Vector2(400, 680)
	submit_button.add_theme_font_size_override("font_size", 30)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.2, 0.3, 0.5)
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 3
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	btn_style.border_color = cyber_colors.border
	btn_style.corner_radius_top_left = 15
	btn_style.corner_radius_top_right = 15
	btn_style.corner_radius_bottom_left = 15
	btn_style.corner_radius_bottom_right = 15
	
	var btn_hover = btn_style.duplicate()
	btn_hover.bg_color = Color(0.3, 0.4, 0.6)
	btn_hover.border_color = Color(0.3, 0.9, 0.9)
	
	submit_button.add_theme_stylebox_override("normal", btn_style)
	submit_button.add_theme_stylebox_override("hover", btn_hover)
	submit_button.pressed.connect(_on_submit_pressed)
	add_child(submit_button)

func _on_text_submitted(text: String):
	_on_submit_pressed()

func _process(delta):
	if game_active and time_left > 0:
		time_left -= delta
		time_left = max(0, time_left)
		
		timer_label.text = "TIEMPO: " + str(int(ceil(time_left)))
		timer_bar.value = (time_left / max_time) * 100
		
		# Cambiar color de la barra según el tiempo restante
		var bar_fill = timer_bar.get_theme_stylebox("fill")
		if time_left <= 5:
			bar_fill.bg_color = cyber_colors.incorrect
			timer_label.add_theme_color_override("font_color", cyber_colors.incorrect)
		elif time_left <= 10:
			bar_fill.bg_color = cyber_colors.warning
			timer_label.add_theme_color_override("font_color", cyber_colors.warning)
		else:
			bar_fill.bg_color = cyber_colors.correct
			timer_label.add_theme_color_override("font_color", cyber_colors.correct)
		timer_bar.add_theme_stylebox_override("fill", bar_fill)
		
		# Si se acaba el tiempo
		if time_left <= 0:
			time_out()

func time_out():
	audio.stream_paused=true
	perder.play()
	game_active = false
	password_input.editable = false
	submit_button.disabled = true
	
	feedback_label.text = "TIEMPO AGOTADO!"
	feedback_label.add_theme_color_override("font_color", cyber_colors.incorrect)
	
	# Mostrar la contraseña correcta
	var reveal_label = Label.new()
	reveal_label.text = "La contraseña era: " + target_password
	reveal_label.add_theme_font_size_override("font_size", 24)
	reveal_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	reveal_label.position = Vector2(350, 650)
	add_child(reveal_label)
	
	await get_tree().create_timer(3.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func _on_submit_pressed():
	if not game_active:
		return
	
	var input_password = password_input.text
	
	if input_password == target_password:
		password_correct()
	else:
		password_incorrect()

func password_correct():
	audio.stream_paused=true
	ganar.play()
	game_active = false
	password_input.editable = false
	submit_button.disabled = true
	
	feedback_label.text = "CONTRASEÑA CORRECTA!"
	feedback_label.add_theme_color_override("font_color", cyber_colors.correct)
	
	# Panel de éxito
	var success_panel = Panel.new()
	success_panel.size = Vector2(600, 300)
	success_panel.position = Vector2(300, 250)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.2, 0.15)
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_color = cyber_colors.correct
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	success_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(success_panel)
	
	var success_label = Label.new()
	success_label.text = "ACCESO CONCEDIDO"
	success_label.add_theme_font_size_override("font_size", 48)
	success_label.add_theme_color_override("font_color", cyber_colors.correct)
	success_label.position = Vector2(75, 60)
	success_panel.add_child(success_label)
	
	var info = Label.new()
	info.text = "Sistema de seguridad superado\nContraseña verificada exitosamente"
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info.position = Vector2(95, 150)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	success_panel.add_child(info)
	
	# Animación
	success_panel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(success_panel, "scale", Vector2(1.0, 1.0), 0.5)
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_completed")
	close_minigame()

func password_incorrect():
	attempts_left -= 1
	password_input.text = ""
	
	if attempts_left > 0:
		error.play()
		feedback_label.text = "CONTRASEÑA INCORRECTA"
		feedback_label.add_theme_color_override("font_color", cyber_colors.incorrect)
		attempts_label.text = "Intentos restantes: " + str(attempts_left)
		
		# Shake del campo de entrada
		var original_pos = password_input.position
		var tween = create_tween()
		for i in range(3):
			tween.tween_property(password_input, "position:x", original_pos.x + 10, 0.05)
			tween.tween_property(password_input, "position:x", original_pos.x - 10, 0.05)
		tween.tween_property(password_input, "position:x", original_pos.x, 0.05)
		
		password_input.grab_focus()
	else:
		game_over()

func game_over():
	audio.stream_paused=true
	perder.play()
	game_active = false
	password_input.editable = false
	submit_button.disabled = true
	
	feedback_label.text = "ACCESO DENEGADO - SIN INTENTOS"
	feedback_label.add_theme_color_override("font_color", cyber_colors.incorrect)
	
	# Mostrar la contraseña correcta
	var reveal_label = Label.new()
	reveal_label.text = "La contraseña era: " + target_password
	reveal_label.add_theme_font_size_override("font_size", 26)
	reveal_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	reveal_label.position = Vector2(500, 650)
	add_child(reveal_label)
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func _on_close_pressed():
	close_minigame()
func close_minigame():

	# 🔹 Animación de desaparición
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	visible = false
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
