extends Control
@onready var perder= $perderNivel
@onready var ganar=$ganarNivel
@onready var audio=$AudioStreamPlayer
@onready var error =$error
@onready var correcto =$correcto
# Variables del minijuego
var email_list = []
var spam_count: int = 0
var legitimate_count: int = 0
var errors: int = 0
var max_errors: int = 3
var emails_processed: int = 0
var total_spam: int = 0

# Variables de tiempo
var time_left: float = 30.0
var max_time: float = 30.0
var game_active: bool = true

# Componentes UI
var emails_container: ScrollContainer
var emails_vbox: VBoxContainer
var timer_label: Label
var timer_bar: ProgressBar
var score_label: Label
var errors_label: Label
var status_label: Label

# Datos de correos
var spam_subjects = [
	"GANASTE $1,000,000 - RECLAMA AHORA!",
	"Oferta limitada - 90% descuento",
	"Hola guapo, quiero conocerte",
	"Felicidades! Ganaste un iPhone 15",
	"URGENTE: Verifica tu cuenta bancaria",
	"Pierde 20kg en 5 dias garantizado",
	"Click aqui para premio gratis",
	"Ayuda urgente para víctimas — dona ahora",
	"Herencia millonaria esperando",
	"Duplica tu dinero en 24 horas"
]

var spam_senders = [
	"noreply@prize-winner.com",
	"admin@fake-bank.net",
	"winner@lottery123.org",
	"prince@nigeria-funds.com",
	"offers@super-deals.biz",
	"alert@account-verify.net",
	"rewards@free-money.com",
	"support@phishing-site.org"
]

var legitimate_subjects = [
	"Reunion del equipo - Martes 3pm",
	"Factura mensual de servicios",
	"Confirmacion de tu pedido #4532",
	"Actualizacion del proyecto",
	"Recordatorio: Cita medica mañana",
	"Newsletter mensual - Marzo",
	"Resumen semanal del equipo",
	"Documentos para revision",
	"Invitacion: Evento de networking",
	"Reporte trimestral disponible"
]

var legitimate_senders = [
	"juan@empresa.com",
	"maria.garcia@trabajo.com",
	"noreply@amazon.com",
	"facturas@servicios.com",
	"dr.smith@clinica.com",
	"equipo@startup.com",
	"rrhh@compania.com",
	"newsletter@sitio-confiable.com"
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
	"spam": Color(0.9, 0.3, 0.3),
	"safe": Color(0.3, 0.7, 0.3)
}
signal puzzle_completed
signal puzzle_failed



func _ready():
	audio.play()
	randomize()
	setup_window()
	setup_ui()
	generate_emails()
	display_emails()

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
	title.text = "FILTRO ANTISPAM"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", game_colors.border)
	title.position = Vector2(410, 50)
	add_child(title)
	
	# Instrucciones
	var instruction = Label.new()
	instruction.text = "Elimina SOLO los correos SPAM - Ten cuidado con los correos legitimos"
	instruction.add_theme_font_size_override("font_size", 24)
	instruction.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	instruction.position = Vector2(240, 110)
	add_child(instruction)
	
	# Panel de información
	create_info_panel()
	
	# Panel de timer
	create_timer_panel()
	
	# Contenedor de correos
	create_email_container()
	
	# Estado
	status_label = Label.new()
	status_label.text = "Identifica y elimina los correos spam"
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	status_label.position = Vector2(380, 820)
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
	
	# Puntuación
	score_label = Label.new()
	score_label.text = "SPAM ELIMINADO: 0"
	score_label.add_theme_font_size_override("font_size", 28)
	score_label.add_theme_color_override("font_color", game_colors.success)
	score_label.position = Vector2(50, 20)
	info_panel.add_child(score_label)
	
	# Errores
	errors_label = Label.new()
	errors_label.text = "ERRORES: 0/3"
	errors_label.add_theme_font_size_override("font_size", 28)
	errors_label.add_theme_color_override("font_color", game_colors.warning)
	errors_label.position = Vector2(400, 20)
	info_panel.add_child(errors_label)
	
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

func create_email_container():
	# Panel de bandeja de entrada
	var inbox_panel = Panel.new()
	inbox_panel.size = Vector2(1000, 520)
	inbox_panel.position = Vector2(100, 290)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.18, 0.18, 0.22)
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 4
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_color = Color(0.3, 0.3, 0.4)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	inbox_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(inbox_panel)
	
	# Título de bandeja
	var inbox_title = Label.new()
	inbox_title.text = "BANDEJA DE ENTRADA"
	inbox_title.add_theme_font_size_override("font_size", 24)
	inbox_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	inbox_title.position = Vector2(400, 10)
	inbox_panel.add_child(inbox_title)
	
	# Scroll container
	emails_container = ScrollContainer.new()
	emails_container.size = Vector2(960, 470)
	emails_container.position = Vector2(20, 40)
	inbox_panel.add_child(emails_container)
	
	# VBox para los correos
	emails_vbox = VBoxContainer.new()
	emails_vbox.add_theme_constant_override("separation", 5)
	emails_container.add_child(emails_vbox)

func generate_emails():
	
	email_list.clear()
	
	# Generar mezcla de correos spam y legitimos
	var total_emails = 10
	var spam_emails = randi_range(4, 6)
	total_spam = spam_emails
	
	# Crear correos spam
	for i in range(spam_emails):
		var email = {
			"subject": spam_subjects[randi() % spam_subjects.size()],
			"sender": spam_senders[randi() % spam_senders.size()],
			"is_spam": true,
			"preview": "Contenido sospechoso con enlaces externos...",
			"time": str(randi_range(1, 23)) + "h"
		}
		email_list.append(email)
	
	# Crear correos legitimos
	for i in range(total_emails - spam_emails):
		var email = {
			"subject": legitimate_subjects[randi() % legitimate_subjects.size()],
			"sender": legitimate_senders[randi() % legitimate_senders.size()],
			"is_spam": false,
			"time": str(randi_range(1, 23)) + "h"
		}
		email_list.append(email)
	
	# Mezclar la lista
	email_list.shuffle()

func display_emails():
	# Limpiar correos anteriores
	for child in emails_vbox.get_children():
		child.queue_free()
	
	# Mostrar cada correo
	for i in range(email_list.size()):
		var email_item = create_email_item(email_list[i], i)
		emails_vbox.add_child(email_item)

func create_email_item(email_data: Dictionary, index: int) -> Panel:
	var email_panel = Panel.new()
	email_panel.custom_minimum_size = Vector2(940, 90)
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.25, 0.25, 0.3)
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_color = Color(0.4, 0.4, 0.45)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	email_panel.add_theme_stylebox_override("panel", panel_style)
	
	# Contenedor horizontal
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(10, 10)
	hbox.size = Vector2(920, 70)
	hbox.add_theme_constant_override("separation", 20)
	email_panel.add_child(hbox)
	
	# Información del correo
	var info_vbox = VBoxContainer.new()
	info_vbox.custom_minimum_size = Vector2(700, 70)
	hbox.add_child(info_vbox)
	
	# Remitente
	var sender_label = Label.new()
	sender_label.text = "De: " + email_data.sender
	sender_label.add_theme_font_size_override("font_size", 20)
	sender_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	info_vbox.add_child(sender_label)
	
	# Asunto
	var subject_label = Label.new()
	subject_label.text = email_data.subject
	subject_label.add_theme_font_size_override("font_size", 24)
	subject_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	info_vbox.add_child(subject_label)
	
	# Vista previa
	var preview_label = Label.new()
	preview_label.text = email_data.get("preview", "Mensaje normal sin riesgo")
	preview_label.add_theme_font_size_override("font_size", 18)
	preview_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	info_vbox.add_child(preview_label)
	
	# Tiempo
	var time_label = Label.new()
	time_label.text = email_data.time
	time_label.add_theme_font_size_override("font_size", 20)
	time_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	time_label.custom_minimum_size = Vector2(50, 70)
	hbox.add_child(time_label)
	
	# Botón eliminar
	var delete_button = Button.new()
	delete_button.text = "ELIMINAR"
	delete_button.custom_minimum_size = Vector2(120, 50)
	delete_button.add_theme_font_size_override("font_size", 20)
	
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = game_colors.error * 0.7
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 2
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_color = game_colors.error
	btn_style.corner_radius_top_left = 5
	btn_style.corner_radius_top_right = 5
	btn_style.corner_radius_bottom_left = 5
	btn_style.corner_radius_bottom_right = 5
	
	delete_button.add_theme_stylebox_override("normal", btn_style)
	delete_button.pressed.connect(_on_delete_email.bind(index, email_panel))
	hbox.add_child(delete_button)
	
	# Guardar datos
	email_panel.set_meta("is_spam", email_data.is_spam)
	email_panel.set_meta("index", index)
	
	return email_panel

func _on_delete_email(index: int, email_panel: Panel):
	if not game_active or index >= email_list.size():
		return
	
	var email = email_list[index]
	var is_spam = email.is_spam
	
	if is_spam:
		# Correcto - era spam
		correcto.play()
		spam_count += 1
		score_label.text = "SPAM ELIMINADO: " + str(spam_count)
		
		status_label.text = "Bien! Era un correo spam"
		status_label.add_theme_color_override("font_color", game_colors.success)
		
		# Efecto de eliminación correcta
		var tween = create_tween()
		tween.tween_property(email_panel, "modulate", Color(0, 1, 0, 0.5), 0.2)
		tween.tween_property(email_panel, "scale:x", 0.0, 0.3)
		tween.tween_callback(email_panel.queue_free)
	else:
		# Error - era legitimo
		error.play()
		errors += 1
		errors_label.text = "ERRORES: " + str(errors) + "/3"
		
		status_label.text = "ERROR! Ese era un correo legitimo!"
		status_label.add_theme_color_override("font_color", game_colors.error)
		
		# Efecto de error
		var tween = create_tween()
		tween.tween_property(email_panel, "modulate", Color(1, 0, 0, 1), 0.2)
		await get_tree().create_timer(0.5).timeout
		tween.tween_property(email_panel, "scale:x", 0.0, 0.3)
		tween.tween_callback(email_panel.queue_free)
		
		if errors >= max_errors:
			game_over()
			return
	
	emails_processed += 1
	
	# Verificar victoria
	if spam_count >= total_spam:
		ganar.play()
		game_success()

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
	win_label.text = "BANDEJA LIMPIA!"
	win_label.add_theme_font_size_override("font_size", 48)
	win_label.add_theme_color_override("font_color", game_colors.success)
	win_label.position = Vector2(120, 50)
	win_panel.add_child(win_label)
	
	var stats = Label.new()
	stats.text = "Todo el spam eliminado!\nErrores: " + str(errors) + "\nTiempo restante: " + str(int(time_left)) + " segundos\n\nBandeja de entrada protegida"
	stats.add_theme_font_size_override("font_size", 24)
	stats.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	stats.position = Vector2(130, 150)
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
	
	status_label.text = "Demasiados errores! Eliminaste correos importantes"
	status_label.add_theme_color_override("font_color", game_colors.error)
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("puzzle_failed")
	close_minigame()

func time_out():
	audio.stream_paused=true
	perder.play()
	game_active = false
	
	status_label.text = "Tiempo agotado! Quedaron " + str(total_spam - spam_count) + " spam sin eliminar"
	status_label.add_theme_color_override("font_color", game_colors.error)
	status_label.position = Vector2(300, 820)
	
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
