extends Control

@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error

signal puzzle_completed
signal puzzle_failed
# Variables del minijuego de contraseña
var password_input: LineEdit
var strength_bar: ProgressBar
var requirements_list = []
var submit_button: Button
var feedback_label: Label

# Requisitos de la contraseña
var requirements = {
	"length": {"met": false, "text": "✗ Al menos 12 caracteres", "weight": 20},
	"uppercase": {"met": false, "text": "✗ Al menos una letra mayúscula (A-Z)", "weight": 20},
	"lowercase": {"met": false, "text": "✗ Al menos una letra minúscula (a-z)", "weight": 20},
	"number": {"met": false, "text": "✗ Al menos un número (0-9)", "weight": 20},
	"special": {"met": false, "text": "✗ Al menos un símbolo (!@#$%^&*)", "weight": 20}
}

# Contraseñas comunes que se deben evitar
var common_passwords = [
	"password", "123456", "12345678", "qwerty", "abc123", "monkey", "1234567890",
	"letmein", "password123", "admin", "welcome", "login", "admin123", "root",
	"toor", "pass", "password1", "123456789", "football", "iloveyou", "1234567",
	"baseball", "dragon", "master", "sunshine", "ashley", "bailey", "passw0rd",
	"shadow", "superman", "qazwsx", "michael", "password1234"
]

# Patrones débiles
var weak_patterns = [
	"1234", "2345", "3456", "4567", "5678", "6789", "7890",
	"abcd", "bcde", "cdef", "defg", "efgh", "fghi", "qwer", "wert", "erty",
	"asdf", "sdfg", "dfgh", "zxcv", "xcvb", "cvbn"
]

# Colores del tema de ciberseguridad (manteniendo los del puzzle)
var cyber_colors = {
	"normal": Color(0.5, 0.5, 0.5),
	"weak": Color(0.8, 0.2, 0.2),      # Rojo para contraseña débil
	"medium": Color(0.8, 0.8, 0.2),    # Amarillo para contraseña media
	"strong": Color(0.2, 0.8, 0.2),    # Verde para contraseña fuerte
	"very_strong": Color(0.2, 0.8, 0.8), # Cyan para contraseña muy fuerte
	"bg": Color(0.1, 0.1, 0.15),
	"border": Color(0.2, 0.8, 0.8)
}

# Variables de animación
var typing_timer = 0.0
var show_password = false


func _ready():
	setup_window()
	setup_ui()
	setup_requirements_display()

func setup_window():
	# Configurar la ventana del popup (mismo tamaño que el puzzle)
	var viewport_size = Vector2(get_viewport().size)
	
	# Tamaño de la ventana del minijuego - DUPLICADO del puzzle
	var window_size = Vector2(1200, 1000)
	
	# Centrar en la pantalla
	position = (viewport_size - window_size) / 2
	size = window_size
	
	# Crear fondo oscuro semi-transparente detrás
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0, 0, 0, 0.8)
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.position = -position
	bg.size = viewport_size
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)
	move_child(bg, 0)
	
	# Crear panel de la ventana del minijuego
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
	move_child(window_panel, 1)
	
	# Botón de cerrar (X) - mismo tamaño que el puzzle
	var close_button = Button.new()
	close_button.name = "CloseButton"
	close_button.text = "X"
	close_button.size = Vector2(60, 60)
	close_button.position = Vector2(window_size.x - 80, 20)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(_on_close_pressed)
	add_child(close_button)

func setup_ui():
	# Título del minijuego
	var title = Label.new()
	title.name = "Title"
	title.text = "SISTEMA DE SEGURIDAD"
	title.add_theme_font_size_override("font_size", 50)
	title.add_theme_color_override("font_color", cyber_colors.border)
	title.position = Vector2(320, 60)
	add_child(title)
	
	# Subtítulo con instrucciones
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "Crea una contraseña imposible de hackear"
	subtitle.add_theme_font_size_override("font_size", 30)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle.position = Vector2(300, 120)
	add_child(subtitle)
	
	# Container principal para el input
	var input_container = Control.new()
	input_container.position = Vector2(200, 200)
	input_container.size = Vector2(800, 100)
	add_child(input_container)
	
	# Label para el campo de contraseña
	var password_label = Label.new()
	password_label.text = "CONTRASEÑA:"
	password_label.add_theme_font_size_override("font_size", 28)
	password_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	password_label.position = Vector2(0, 0)
	input_container.add_child(password_label)
	
	# Campo de entrada de contraseña
	password_input = LineEdit.new()
	password_input.size = Vector2(600, 60)
	password_input.position = Vector2(0, 40)
	password_input.placeholder_text = "Ingresa tu contraseña súper segura..."
	password_input.secret = true
	password_input.add_theme_font_size_override("font_size", 28)
	
	# Estilo para el LineEdit
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
	
	password_input.text_changed.connect(_on_password_changed)
	input_container.add_child(password_input)
	
	# Botón para mostrar/ocultar contraseña
	var toggle_visibility = Button.new()
	toggle_visibility.size = Vector2(80, 60)
	toggle_visibility.position = Vector2(620, 40)
	toggle_visibility.add_theme_font_size_override("font_size", 32)
	toggle_visibility.pressed.connect(_toggle_password_visibility)
	input_container.add_child(toggle_visibility)
	
	# Barra de fuerza de la contraseña
	var strength_container = Control.new()
	strength_container.position = Vector2(200, 320)
	strength_container.size = Vector2(800, 80)
	add_child(strength_container)
	
	var strength_label = Label.new()
	strength_label.text = "NIVEL DE SEGURIDAD:"
	strength_label.add_theme_font_size_override("font_size", 24)
	strength_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	strength_container.add_child(strength_label)
	
	strength_bar = ProgressBar.new()
	strength_bar.size = Vector2(700, 40)
	strength_bar.position = Vector2(0, 35)
	strength_bar.min_value = 0
	strength_bar.max_value = 100
	strength_bar.value = 0
	strength_bar.show_percentage = false
	
	# Estilo para la barra de progreso
	var bar_bg_style = StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0.2, 0.2, 0.25)
	bar_bg_style.border_width_top = 2
	bar_bg_style.border_width_bottom = 2
	bar_bg_style.border_width_left = 2
	bar_bg_style.border_width_right = 2
	bar_bg_style.border_color = Color(0.3, 0.3, 0.35)
	bar_bg_style.corner_radius_top_left = 5
	bar_bg_style.corner_radius_top_right = 5
	bar_bg_style.corner_radius_bottom_left = 5
	bar_bg_style.corner_radius_bottom_right = 5
	strength_bar.add_theme_stylebox_override("background", bar_bg_style)
	
	var bar_fill_style = StyleBoxFlat.new()
	bar_fill_style.bg_color = cyber_colors.weak
	bar_fill_style.corner_radius_top_left = 5
	bar_fill_style.corner_radius_top_right = 5
	bar_fill_style.corner_radius_bottom_left = 5
	bar_fill_style.corner_radius_bottom_right = 5
	strength_bar.add_theme_stylebox_override("fill", bar_fill_style)
	
	strength_container.add_child(strength_bar)
	
	# Label de fuerza
	feedback_label = Label.new()
	feedback_label.text = "MUY DÉBIL"
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override("font_color", cyber_colors.weak)
	feedback_label.position = Vector2(720, 35)
	strength_container.add_child(feedback_label)
	
	# Botón de enviar
	submit_button = Button.new()
	submit_button.text = "ACTIVAR SEGURIDAD"
	submit_button.size = Vector2(400, 80)
	submit_button.position = Vector2(400, 850)
	submit_button.add_theme_font_size_override("font_size", 32)
	submit_button.disabled = true
	
	var button_style_normal = StyleBoxFlat.new()
	button_style_normal.bg_color = Color(0.3, 0.3, 0.3)
	button_style_normal.border_width_top = 3
	button_style_normal.border_width_bottom = 3
	button_style_normal.border_width_left = 3
	button_style_normal.border_width_right = 3
	button_style_normal.border_color = Color(0.5, 0.5, 0.5)
	button_style_normal.corner_radius_top_left = 15
	button_style_normal.corner_radius_top_right = 15
	button_style_normal.corner_radius_bottom_left = 15
	button_style_normal.corner_radius_bottom_right = 15
	
	var button_style_hover = button_style_normal.duplicate()
	button_style_hover.bg_color = cyber_colors.strong
	button_style_hover.border_color = Color(0.3, 1.0, 0.3)
	
	var button_style_disabled = button_style_normal.duplicate()
	button_style_disabled.bg_color = Color(0.2, 0.2, 0.2)
	button_style_disabled.border_color = Color(0.3, 0.3, 0.3)
	
	submit_button.add_theme_stylebox_override("normal", button_style_normal)
	submit_button.add_theme_stylebox_override("hover", button_style_hover)
	submit_button.add_theme_stylebox_override("disabled", button_style_disabled)
	submit_button.pressed.connect(_on_submit_pressed)
	add_child(submit_button)

func setup_requirements_display():
	# Container para los requisitos
	var req_container = VBoxContainer.new()
	req_container.position = Vector2(200, 440)
	req_container.size = Vector2(800, 400)
	req_container.add_theme_constant_override("separation", 20)
	add_child(req_container)
	
	# Título de requisitos
	var req_title = Label.new()
	req_title.text = "REQUISITOS DE SEGURIDAD:"
	req_title.add_theme_font_size_override("font_size", 28)
	req_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	req_container.add_child(req_title)
	
	# Crear labels para cada requisito
	for key in requirements:
		var req_label = Label.new()
		req_label.name = "Req_" + key
		req_label.text = requirements[key].text
		req_label.add_theme_font_size_override("font_size", 24)
		req_label.add_theme_color_override("font_color", cyber_colors.weak)
		req_container.add_child(req_label)
		requirements_list.append(req_label)

func _toggle_password_visibility():
	show_password = !show_password
	password_input.secret = !show_password

func _on_password_changed(new_text: String):
	check_requirements(new_text)
	update_strength_bar(new_text)
	check_common_passwords(new_text)
	
	# Habilitar botón solo si la contraseña es fuerte
	var strength = calculate_strength(new_text)
	submit_button.disabled = strength < 80

func check_requirements(password: String):
	# Verificar longitud
	requirements["length"]["met"] = password.length() >= 12
	
	# Verificar mayúsculas
	requirements["uppercase"]["met"] = false
	for c in password:
		if c >= 'A' and c <= 'Z':
			requirements["uppercase"]["met"] = true
			break
	
	# Verificar minúsculas
	requirements["lowercase"]["met"] = false
	for c in password:
		if c >= 'a' and c <= 'z':
			requirements["lowercase"]["met"] = true
			break
	
	# Verificar números
	requirements["number"]["met"] = false
	for c in password:
		if c >= '0' and c <= '9':
			requirements["number"]["met"] = true
			break
	
	# Verificar caracteres especiales
	var special_chars = "!@#$%^&*()_+-=[]{}|;:'\",.<>?/\\`~"
	requirements["special"]["met"] = false
	for c in password:
		if c in special_chars:
			requirements["special"]["met"] = true
			break
	
	# Actualizar visualización
	var i = 0
	for key in requirements:
		var label = requirements_list[i]
		if requirements[key]["met"]:
			label.text = "✓ " + requirements[key].text.substr(2)
			label.add_theme_color_override("font_color", cyber_colors.strong)
		else:
			label.text = requirements[key].text
			label.add_theme_color_override("font_color", cyber_colors.weak)
		i += 1

func calculate_strength(password: String) -> int:
	var strength = 0
	
	# Puntos por requisitos básicos
	for key in requirements:
		if requirements[key]["met"]:
			strength += requirements[key]["weight"]
	
	# Puntos extra por longitud
	if password.length() > 15:
		strength += 10
	if password.length() > 20:
		strength += 10
	
	# Penalización por contraseñas comunes
	if password.to_lower() in common_passwords:
		strength = min(20, strength)
		return strength
	
	# Penalización por patrones débiles
	for pattern in weak_patterns:
		if pattern in password.to_lower():
			strength -= 15
	
	# Penalización por caracteres repetidos
	var last_char = ""
	var repeat_count = 0
	for c in password:
		if c == last_char:
			repeat_count += 1
			if repeat_count > 2:
				strength -= 5
		else:
			repeat_count = 0
		last_char = c
	
	# Bonus por variedad de caracteres
	var unique_chars = {}
	for c in password:
		unique_chars[c] = true
	
	if unique_chars.size() > password.length() * 0.6:
		strength += 10
	
	return clamp(strength, 0, 100)

func update_strength_bar(password: String):
	var strength = calculate_strength(password)
	
	# Animar la barra de progreso
	var tween = create_tween()
	tween.tween_property(strength_bar, "value", strength, 0.3)
	
	# Actualizar color y texto según la fuerza
	var bar_fill_style = strength_bar.get_theme_stylebox("fill")
	
	if strength < 30:
		bar_fill_style.bg_color = cyber_colors.weak
		feedback_label.text = "MUY DÉBIL"
		feedback_label.add_theme_color_override("font_color", cyber_colors.weak)
	elif strength < 50:
		bar_fill_style.bg_color = Color(1.0, 0.5, 0.0)  # Naranja
		feedback_label.text = "DÉBIL"
		feedback_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
	elif strength < 70:
		bar_fill_style.bg_color = cyber_colors.medium
		feedback_label.text = "REGULAR"
		feedback_label.add_theme_color_override("font_color", cyber_colors.medium)
	elif strength < 90:
		bar_fill_style.bg_color = cyber_colors.strong
		feedback_label.text = "FUERTE"
		feedback_label.add_theme_color_override("font_color", cyber_colors.strong)
	else:
		bar_fill_style.bg_color = cyber_colors.very_strong
		feedback_label.text = "MUY FUERTE"
		feedback_label.add_theme_color_override("font_color", cyber_colors.very_strong)
		
		# Efecto de brillo para contraseñas muy fuertes
		var glow_tween = create_tween()
		glow_tween.set_loops(3)
		glow_tween.tween_property(feedback_label, "modulate", Color(1.5, 1.5, 1.5), 0.2)
		glow_tween.tween_property(feedback_label, "modulate", Color(1.0, 1.0, 1.0), 0.2)
	
	strength_bar.add_theme_stylebox_override("fill", bar_fill_style)

func check_common_passwords(password: String):
	if password.to_lower() in common_passwords:
		# Mostrar advertencia
		show_warning("¡PELIGRO! Esta es una contraseña muy común y fácil de hackear")

func show_warning(message: String):
	var warning_label = Label.new()
	warning_label.text =  message
	warning_label.add_theme_font_size_override("font_size", 24)
	warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	warning_label.position = Vector2(200, 390)
	add_child(warning_label)
	
	# Animación de parpadeo
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(warning_label, "modulate:a", 0.3, 0.3)
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.3)
	
	# Eliminar después de 3 segundos
	await get_tree().create_timer(3.0).timeout
	warning_label.queue_free()

func _on_submit_pressed():
	var password = password_input.text
	var strength = calculate_strength(password)

	if strength >= 80:
		show_success()
	else:
		show_error("La contraseña no es lo suficientemente fuerte")
		emit_signal("puzzle_failed")



func show_success():
	audio.stream_paused=true
	ganar.play()
	password_input.editable = false
	submit_button.disabled = true

	emit_signal("puzzle_completed") # avisar a Lab1

	await get_tree().create_timer(1.0).timeout
	# luego el panel de éxito

	# Crear mensaje de éxito visual
	var success_container = Control.new()
	success_container.position = Vector2(0, 0)
	success_container.size = size
	add_child(success_container)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = size
	success_container.add_child(overlay)

	var success_panel = Panel.new()
	success_panel.size = Vector2(800, 400)
	success_panel.position = Vector2(200, 300)

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.2, 0.15)
	panel_style.border_width_top = 6
	panel_style.border_width_bottom = 6
	panel_style.border_width_left = 6
	panel_style.border_width_right = 6
	panel_style.border_color = cyber_colors.very_strong
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	success_panel.add_theme_stylebox_override("panel", panel_style)
	success_container.add_child(success_panel)

	var success_label = Label.new()
	success_label.text = "¡SISTEMA PROTEGIDO!"
	success_label.add_theme_font_size_override("font_size", 56)
	success_label.add_theme_color_override("font_color", cyber_colors.very_strong)
	success_label.position = Vector2(105, 50)
	success_panel.add_child(success_label)

	var info_label = Label.new()
	info_label.text = "Tu contraseña es extremadamente segura.\n¡Ahora tu sistema está más protegido!"
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	info_label.position = Vector2(105, 200)
	success_panel.add_child(info_label)

	success_panel.scale = Vector2(0.1, 0.1)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(success_panel, "scale", Vector2(1.0, 1.0), 0.5)

	await get_tree().create_timer(2.0).timeout
	close_minigame()

func show_error(message: String):
	error.play()
	var error_label = Label.new()
	error_label.text =  message
	error_label.add_theme_font_size_override("font_size", 28)
	error_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	error_label.position = Vector2(300, 950)
	add_child(error_label)
	
	# Shake animation
	var tween = create_tween()
	var original_pos = error_label.position
	for i in range(5):
		tween.tween_property(error_label, "position:x", original_pos.x + 10, 0.05)
		tween.tween_property(error_label, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(error_label, "position:x", original_pos.x, 0.05)
	
	# Eliminar después de 2 segundos
	await get_tree().create_timer(2.0).timeout
	error_label.queue_free()

func _on_close_pressed():
	emit_signal("puzzle_failed")
	close_minigame()



func close_minigame():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished

	queue_free()


	
	# Ocultar y resetear
	visible = false
	modulate.a = 1.0
	queue_free()


func show_minigame():
	# Función para mostrar el minijuego
	visible = true
	password_input.grab_focus()

# Función para validación adicional en tiempo real
func _process(delta):
	if password_input and password_input.has_focus() and password_input.text.length() > 0:
		typing_timer += delta
		if typing_timer > 0.4:
			typing_timer = 0.0
			_start_feedback_blink()

func _start_feedback_blink():
	var tween = create_tween()
	tween.tween_property(feedback_label, "modulate:a", 0.5, 0.1)
	tween.tween_property(feedback_label, "modulate:a", 1.0, 0.1)
