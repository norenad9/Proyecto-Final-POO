extends Control
@onready var perdida=$perdidaNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
# Variables del minijuego de contraseña
var password_input: LineEdit
var target_password: String = ""
var target_password_label: Label
var attempts_left: int = 3
var attempts_label: Label
var submit_button: Button
var feedback_label: Label
var show_password_timer: float = 5.0
var timer_label: Label

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

# Variables de estado
var password_visible: bool = true
var game_active: bool = true

# Señal para cuando se complete el minijuego
signal puzzle_completed
signal puzzle_failed

func _ready():
	audio.play()
	randomize()
	generate_secure_password()
	setup_window()
	setup_ui()

func generate_secure_password():
	# Generar contraseña de 12-14 caracteres que cumpla todos los requisitos
	var length = randi_range(4, 5)
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
	title.text = "SISTEMA DE AUTENTICACIÓN"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", cyber_colors.border)
	title.position = Vector2(290, 50)
	add_child(title)
	
	# Instrucciones
	var instruction = Label.new()
	instruction.text = "Memoriza y digita exactamente la contraseña mostrada"
	instruction.add_theme_font_size_override("font_size", 26)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction.position = Vector2(280, 110)
	add_child(instruction)
	
	# Panel de contraseña objetivo
	var target_container = Panel.new()
	target_container.size = Vector2(800, 150)
	target_container.position = Vector2(200, 180)
	
	var target_style = StyleBoxFlat.new()
	target_style.bg_color = Color(0.15, 0.15, 0.2)
	target_style.border_width_top = 4
	target_style.border_width_bottom = 4
	target_style.border_width_left = 4
	target_style.border_width_right = 4
	target_style.border_color = cyber_colors.warning
	target_style.corner_radius_top_left = 15
	target_style.corner_radius_top_right = 15
	target_style.corner_radius_bottom_left = 15
	target_style.corner_radius_bottom_right = 15
	target_container.add_theme_stylebox_override("panel", target_style)
	add_child(target_container)
	
	# Label de contraseña objetivo
	var target_title = Label.new()
	target_title.text = "CONTRASEÑA REQUERIDA:"
	target_title.add_theme_font_size_override("font_size", 24)
	target_title.add_theme_color_override("font_color", cyber_colors.warning)
	target_title.position = Vector2(250, 15)
	target_container.add_child(target_title)
	
	# Contraseña a mostrar
	target_password_label = Label.new()
	target_password_label.text = target_password
	target_password_label.add_theme_font_size_override("font_size", 42)
	target_password_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	target_password_label.position = Vector2(350, 45)
	target_container.add_child(target_password_label)
	
	# Timer para ocultar la contraseña
	timer_label = Label.new()
	timer_label.text = "Tiempo restante: 5 segundos"
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", cyber_colors.warning)
	timer_label.position = Vector2(250, 105)
	target_container.add_child(timer_label)
	
	# Container de entrada
	var input_container = Control.new()
	input_container.position = Vector2(200, 380)
	input_container.size = Vector2(800, 120)
	add_child(input_container)
	
	# Label de entrada
	var input_label = Label.new()
	input_label.text = "DIGITA LA CONTRASEÑA:"
	input_label.add_theme_font_size_override("font_size", 26)
	input_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	input_container.add_child(input_label)
	
	# Campo de entrada
	password_input = LineEdit.new()
	password_input.size = Vector2(700, 60)
	password_input.position = Vector2(0, 40)
	password_input.placeholder_text = "Ingresa la contraseña exacta..."
	password_input.add_theme_font_size_override("font_size", 32)
	password_input.editable = false  # Deshabilitado hasta que se oculte la contraseña
	
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
	input_container.add_child(password_input)
	
	# Intentos restantes
	attempts_label = Label.new()
	attempts_label.text = "Intentos restantes: 3"
	attempts_label.add_theme_font_size_override("font_size", 26)
	attempts_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	attempts_label.position = Vector2(200, 520)
	add_child(attempts_label)
	
	# Feedback
	feedback_label = Label.new()
	feedback_label.text = ""
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.position = Vector2(200, 570)
	add_child(feedback_label)
	
	# Botón de verificar
	submit_button = Button.new()
	submit_button.text = "VERIFICAR CONTRASEÑA"
	submit_button.size = Vector2(400, 70)
	submit_button.position = Vector2(400, 650)
	submit_button.add_theme_font_size_override("font_size", 30)
	submit_button.disabled = true  # Deshabilitado hasta que se oculte la contraseña
	
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
	
	var btn_disabled = btn_style.duplicate()
	btn_disabled.bg_color = Color(0.15, 0.15, 0.15)
	btn_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	submit_button.add_theme_stylebox_override("normal", btn_style)
	submit_button.add_theme_stylebox_override("hover", btn_hover)
	submit_button.add_theme_stylebox_override("disabled", btn_disabled)
	submit_button.pressed.connect(_on_submit_pressed)
	add_child(submit_button)
	
	# Botón de mostrar contraseña de nuevo (solo una vez)
	var show_again_button = Button.new()
	show_again_button.name = "ShowAgainButton"
	show_again_button.text = "MOSTRAR UNA VEZ MÁS"
	show_again_button.size = Vector2(250, 50)
	show_again_button.position = Vector2(750, 520)
	show_again_button.add_theme_font_size_override("font_size", 22)
	show_again_button.visible = false
	show_again_button.pressed.connect(_on_show_again_pressed)
	add_child(show_again_button)
	
func _process(delta):
	if password_visible and show_password_timer > 0:
		show_password_timer -= delta
		timer_label.text = "Tiempo restante: " + str(int(ceil(show_password_timer))) + " segundos"
		timer_label.position = Vector2(250, 163)  # 👈 Cambia aquí las coordenadas
		
		if show_password_timer <= 0:
			hide_password()


func hide_password():
	password_visible = false
	target_password_label.text = "* * * * * "
	target_password_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	target_password_label.position = Vector2(320, 60)  # 👈 posición de los asteriscos
	
	timer_label.text = "Contraseña oculta"
	timer_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	timer_label.position = Vector2(300, 100)  # 👈 posición del texto

	
	# Habilitar entrada
	password_input.editable = true
	submit_button.disabled = false
	password_input.grab_focus()
	
	# Mostrar botón de ver de nuevo (solo si quedan intentos)
	if attempts_left > 1:
		var show_again_btn = get_node_or_null("ShowAgainButton")
		if show_again_btn:
			show_again_btn.visible = true

func _on_show_again_pressed():
	var show_again_btn = get_node_or_null("ShowAgainButton")
	if show_again_btn:
		show_again_btn.visible = false
		show_again_btn.queue_free()
	
	# Mostrar contraseña por 3 segundos
	password_visible = true
	show_password_timer = 3.0
	target_password_label.text = target_password
	target_password_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	timer_label.add_theme_color_override("font_color", cyber_colors.warning)

func _on_submit_pressed():
	
	if not game_active:
		return
	
	var input_password = password_input.text
	
	if input_password == target_password:
		audio.stream_paused=true
		ganar.play()
		password_correct()
	else:
		error.play()
		password_incorrect()

func password_correct():
	
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
	success_label.position = Vector2(70, 60)
	success_panel.add_child(success_label)
	
	var info = Label.new()
	info.text = "Sistema de seguridad superado\ncontraseña verificada exitosamente"
	info.add_theme_font_size_override("font_size", 24)
	info.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info.position = Vector2(100, 150)
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
		
		# Mostrar pista si queda solo 1 intento
		if attempts_left == 1:
			show_hint()
	else:
		game_over()

func show_hint():
	var hint_label = Label.new()
	hint_label.text = "Pista: La contraseña tiene " + str(target_password.length()) + " caracteres"
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", cyber_colors.warning)
	hint_label.position = Vector2(200, 620)
	add_child(hint_label)

func game_over():
	audio.stream_paused=true
	perdida.play()
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
	reveal_label.position = Vector2(350, 620)
	add_child(reveal_label)
	
	await get_tree().create_timer(3.0).timeout
	emit_signal("puzzle_failed") 
	close_minigame()

func _on_close_pressed():
	
	emit_signal("puzzle_failed")
	close_minigame()

func close_minigame():
	audio.stream_paused
	perdida.play()
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
